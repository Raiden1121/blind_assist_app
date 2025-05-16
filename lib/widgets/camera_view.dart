// =======================================================
// camera_view.dart
// ✅ 功能說明：
//   1️⃣ 控制相機鏡頭（開啟、關閉、切換）
//   2️⃣ 將相機畫面即時傳送到後端 gRPC 服務分析
//   3️⃣ 語音提示「Camera open / Camera closed」
//   4️⃣ 用 double-tap 切換相機開啟／關閉
//   5️⃣ 若後端回傳 danger 訊息 → 顯示滑入滑出的白色圓角卡片 3 秒
// =======================================================
//
// ⚠️ 重點說明：
// openRecorder() → startRecorder() → stopRecorder() → closeRecorder()
//  必須依序呼叫，並用 _isRecorderInitialized 和 _isRecording 兩個旗標
//  避免重複呼叫錯誤。在 dispose() 中，如正在錄音則先 stop 再 close。

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as imglib;
// import 'package:blind_assist_app/grpc/gemini_live_client.dart';
// import 'package:blind_assist_app/generated/blind_assist.pb.dart';
// import 'package:blind_assist_app/generated/blind_assist.pbgrpc.dart';
import 'package:blind_assist_app/grpc/grpc_client.dart';
import 'package:blind_assist_app/generated/gemini_chat.pbgrpc.dart';
import 'package:blind_assist_app/generated/gemini_chat.pb.dart';
import 'package:blind_assist_app/widgets/speech_player.dart';
import 'package:audioplayers/audioplayers.dart';

// === JPEG 編碼：將 YUV420 轉成 RGB，再用 image 套件編碼 ===
Uint8List _encodeJpegIsolate(Map<String, dynamic> params) {
  final int width = params['width'];
  final int height = params['height'];
  final Uint8List y = params['y'];
  final Uint8List u = params['u'];
  final Uint8List v = params['v'];
  final int yRowStride = params['yRowStride'];
  final int uvRowStride = params['uvRowStride'];
  final int uvPixelStride = params['uvPixelStride'];

  final imglib.Image img = imglib.Image(width: width, height: height);

  for (int row = 0; row < height; row++) {
    for (int col = 0; col < width; col++) {
      final int yp = y[row * yRowStride + col];
      final int up = u[(row >> 1) * uvRowStride + (col >> 1) * uvPixelStride];
      final int vp = v[(row >> 1) * uvRowStride + (col >> 1) * uvPixelStride];
      int r = (yp + vp * 1.403 - 179).clamp(0, 255).toInt();
      int g = (yp - up * 0.344 + 44 - vp * 0.714 + 91).clamp(0, 255).toInt();
      int b = (yp + up * 1.770 - 227).clamp(0, 255).toInt();
      img.setPixelRgba(col, row, r, g, b, 255);
    }
  }

  return Uint8List.fromList(imglib.encodeJpg(img, quality: 80));
}

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  // === 地理位置 ===
  String _latitude = "";
  String _longitude = "";
  StreamSubscription<Position>? _positionSubscription;
  String _status = "Idle";

  // === 語音與警示音 ===
  final SpeechPlayer _speechPlayer = SpeechPlayer();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // === gRPC ===
  late final StreamController<ChatRequest> _reqCtrl;
  late final Stream<ChatResponse> _respStream;
  StreamSubscription<ChatResponse>? _respSubscription;
  // bool _grpcReady = false;

  CameraImage? _lastImage;
  Timer? _sendTimer;

  // === 相機控制 ===
  CameraController? _controller;
  bool _isStreaming = false;
  bool _isSending = false;
  // int _frameCounter = 0;
  // static const int _processFrameInterval = 5;

  // === 危險提示卡片 ===
  bool _showDanger = false;
  String _dangerMessage = "";

  @override
  void initState() {
    super.initState();
    _initLocation(); // 啟動 GPS
    _initGrpc(); // 初始化 gRPC 串流
  }

  @override
  void dispose() {
    // ① 先停 Timer，避免它在 dispose 後還呼叫 callback
    _sendTimer?.cancel();

    // ② 取消定位訂閱
    _positionSubscription?.cancel();

    // ③ 停影像串流（僅在 _isStreaming 時）
    if (_controller != null && _isStreaming) {
      try {
        _controller!.stopImageStream();
        _isStreaming = false;
      } catch (e) {
        print('❌ stopImageStream error: $e');
      }
    }

    // ④ 釋放 CameraController
    try {
      _controller?.dispose();
    } catch (e) {
      print('❌ controller.dispose error: $e');
    }
    _controller = null;

    // ⑤ 關閉 gRPC
    _respSubscription?.cancel();
    _reqCtrl.close();

    super.dispose();
  }

  // === GPS 初始化 ===
  Future<void> _initLocation() async {
    // 1. 先試著拿一次
    await _getCurrentLocation();
    // 2. 持續追蹤
    _positionSubscription = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high, distanceFilter: 1))
        .listen((pos) {
      setState(() {
        _latitude = pos.latitude.toStringAsFixed(5);
        _longitude = pos.longitude.toStringAsFixed(5);
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = pos.latitude.toStringAsFixed(5);
      _longitude = pos.longitude.toStringAsFixed(5);
    });
  }

  // === gRPC 初始化 ===
  Future<void> _initGrpc() async {
    // 建立 StreamController 並先送 initialConfig
    _reqCtrl = StreamController<ChatRequest>();
    _reqCtrl.add(ChatRequest()..text = 'Speak: Camera open');
    // 雙向串流
    _respStream = GrpcClient.chatStream(_reqCtrl.stream);
    _respSubscription = _respStream.listen(_handleResponse,
        onError: (e) => print('gRPC stream error: $e'),
        onDone: () => print('gRPC stream closed'));

    // _grpcReady = true;
  }

  // === 開啟相機 & 傳影像 ===
  Future<void> _openCamera() async {
    // 1️⃣ 選擇後置鏡頭
    _isStreaming = false; // ← 新增：重置
    _lastImage = null;

    final cams = await availableCameras();
    final back = cams.where((c) => c.lensDirection == CameraLensDirection.back);
    final chosen = back.first;

    // 2️⃣ 初始化 CameraController
    _controller =
        CameraController(chosen, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();

    // 3️⃣ 開始影像串流，每 N 幀傳一次
    // _controller!.startImageStream((img) async {
    //   _frameCounter++;
    //   if (!_isSending && _frameCounter % _processFrameInterval == 0) {
    //     _isSending = true;
    //     try {
    //       final bytes = _encodeJpeg(img); // 已實作
    //       _reqCtrl.add(ChatRequest()
    //         ..multiImages = (MultiImageInput()
    //           ..images.add(ImageInput()
    //             ..data = bytes
    //             ..format = 'image/jpeg'
    //             ..width = img.width
    //             ..height = img.height)));
    //     } catch (e) {
    //       print('❌ send frame error: $e');
    //     } finally {
    //       _isSending = false;
    //     }
    //   }
    // });

    // 每五秒傳一次影像
    _sendTimer?.cancel(); // 先取消舊的
    _sendTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || !_isStreaming || _isSending || _lastImage == null) {
        if (!mounted) timer.cancel();
        return;
      }
      _isSending = true;
      try {
        final img = _lastImage!;
        final params = {
          'width': img.width,
          'height': img.height,
          'y': img.planes[0].bytes,
          'u': img.planes[1].bytes,
          'v': img.planes[2].bytes,
          'yRowStride': img.planes[0].bytesPerRow,
          'uvRowStride': img.planes[1].bytesPerRow,
          'uvPixelStride': img.planes[1].bytesPerPixel,
        };
        final bytes = await compute(_encodeJpegIsolate, params);
        debugPrint("📸 send image: ${bytes.length} bytes");
        _reqCtrl.add(ChatRequest()
          ..multiImages = (MultiImageInput()
            ..images.add(ImageInput()
              ..data = bytes
              ..format = 'image/jpeg'
              ..width = img.width
              ..height = img.height)));
      } catch (e) {
        print('❌ encode/send error: $e');
      } finally {
        _isSending = false;
      }
    });

    // 然後才啟動攝影機串流

    _controller!.startImageStream((img) {
      _isStreaming = true;
      _lastImage = img;
    });
  }

  // === 關閉相機串流 ===
  Future<void> _disposeCamera() async {
    // ① 先停 Timer，避免它在 dispose 後還呼叫 callback
    _sendTimer?.cancel();

    // ② 取消定位訂閱
    _positionSubscription?.cancel();

    if (_controller != null) {
      try {
        _controller!.stopImageStream();
      } catch (e) {
        print('❌ stopImageStream error: $e');
      }
      try {
        _controller!.dispose();
      } catch (e) {
        print('❌ dispose error: $e');
      }
      _controller = null;
      setState(() {});
      await _speechPlayer.speak('Camera closed. Thank you.');
    }
  }

  // === 處理後端回應 ===
  void _handleResponse(ChatResponse resp) async {
    if (resp.hasNav()) {
      final nav = resp.nav;

      if (nav.alert.isNotEmpty) {
        final dm = nav.alert.substring(7).trim();
        setState(() {
          _showDanger = true;
          _dangerMessage = dm;
        });

        // 播放警示音效
        await _speechPlayer.stop();
        await _audioPlayer.play(AssetSource('assets/sounds/alarm.mp3'));
        await _audioPlayer.onPlayerComplete.first;
        await _speechPlayer.speak(dm);
        await Future.delayed(const Duration(seconds: 3));
        setState(() => _showDanger = false);
      } else {
        await _speechPlayer.speak(nav.alert);
      }
      return;
    }
    // if (resp.hasGeminiAudioPart()) {
    //   await _audioPlayer.play(
    //       BytesSource(Uint8List.fromList(resp.geminiAudioPart.audioData)));
    //   return;
    // }
    // if (resp.hasErrorPart()) {
    //   print('gRPC Error ${resp.errorPart.code}: ${resp.errorPart.message}');
    // }
  }

  // === UI & 手勢：雙擊開關鏡頭 ===
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () async {
        if (!mounted) return;

        if (_controller == null) {
          await _openCamera();
        } else {
          await _disposeCamera();
        }
      },
      child: Stack(
        children: [
          // — 相機預覽或提示
          Container(
            color: Colors.black,
            child: (_controller == null || !_controller!.value.isInitialized)
                ? const Center(
                    child: Text(
                      'Double-tap to open camera',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                : SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: _controller!.value.previewSize!.height,
                        height: _controller!.value.previewSize!.width,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  ),
          ),

          // — 經緯度 + 導航狀態
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lat: $_latitude',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                        Text('Lng: $_longitude',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                      ]),
                  Row(children: [
                    const Icon(Icons.navigation, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _status,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          // — 危險提示卡片
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _showDanger ? MediaQuery.of(context).padding.top + 16 : -120,
            left: 20,
            right: 20,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(children: [
                  IconButton(
                      onPressed: () => setState(() => _showDanger = false),
                      icon: Icon(Icons.close)),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Obstacle Ahead',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_dangerMessage,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54)),
                        ]),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
