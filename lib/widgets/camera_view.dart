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

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as imglib;
import 'package:blind_assist_app/grcp/gemini_live_client.dart';
import 'package:blind_assist_app/generated/blind_assist.pb.dart';
import 'package:blind_assist_app/generated/blind_assist.pbgrpc.dart';
import 'package:blind_assist_app/widgets/speech_player.dart';
import 'package:audioplayers/audioplayers.dart';

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

  // === 語音與警示音 ===
  final SpeechPlayer _speechPlayer = SpeechPlayer();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // === gRPC ===
  late final GeminiLiveClientWrapper _grpcClient;
  late final StreamController<ClientRequest> _reqCtrl;
  late final Stream<ServerResponse> _respStream;
  StreamSubscription<ServerResponse>? _respSubscription;
  bool _grpcReady = false;

  // === 相機控制 ===
  CameraController? _controller;
  bool _isSending = false;
  int _frameCounter = 0;
  static const int _processFrameInterval = 5;

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
    // 1. 取消 GPS
    _positionSubscription?.cancel();

    // 2. 關閉相機
    _disposeCamera();

    // 3. 關閉 gRPC
    if (_grpcReady) {
      _respSubscription?.cancel(); // 取消訂閱
      _reqCtrl.close(); // 關閉輸出
      _grpcClient.shutdown(); // await optional
    }

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
    _grpcClient = GeminiLiveClientWrapper();
    // 傳入 host & port
    await _grpcClient.init(
      host: 'blind-liveapi-grpc-617941879669.asia-east1.run.app',
      port: 443,
    );

    // 建立 StreamController 並先送 initialConfig
    _reqCtrl = StreamController<ClientRequest>();
    _reqCtrl.add(
      ClientRequest(
        initialConfig: InitialConfigRequest(
          modelName: 'models/gemini-2.0-flash-live-001',
          responseModalities: ['AUDIO', 'TEXT'],
        ),
      ),
    );

    // 雙向串流
    _respStream = _grpcClient.chatStream(_reqCtrl.stream);
    _respSubscription = _respStream.listen(
      _handleResponse,
      onError: (e) => print('gRPC stream error: $e'),
    );

    _grpcReady = true;
  }

  // === 開啟相機 & 傳影像 ===
  Future<void> _openCamera() async {
    // 1️⃣ 選擇後置鏡頭
    final cams = await availableCameras();
    final back = cams.where((c) => c.lensDirection == CameraLensDirection.back);
    final chosen = back.first;

    // 2️⃣ 初始化 CameraController
    _controller =
        CameraController(chosen, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();

    // 3️⃣ 開始影像串流，每 N 幀傳一次
    _controller!.startImageStream((img) async {
      _frameCounter++;
      if (!_isSending && _frameCounter % _processFrameInterval == 0) {
        _isSending = true;
        try {
          final bytes = _encodeJpeg(img); // 已實作
          _reqCtrl.add(
            ClientRequest()
              ..imagePart = (ImagePart()
                ..imageData = bytes
                ..mimeType = 'image/jpeg'),
          );
        } catch (e) {
          print('❌ send frame error: $e');
        } finally {
          _isSending = false;
        }
      }
    });

    setState(() {});
    await _speechPlayer.speak('Camera open. Double-tap to close.');
  }

  // === 關閉相機串流 ===
  Future<void> _disposeCamera() async {
    if (_controller != null) {
      await _controller!.stopImageStream();
      await _controller!.dispose();
      _controller = null;
      setState(() {});
      await _speechPlayer.speak('Camera closed. Thank you.');
    }
  }

  // === 處理後端回應 ===
  void _handleResponse(ServerResponse resp) async {
    if (resp.hasTextPart()) {
      final msg = resp.textPart.text;
      if (msg.startsWith('DANGER:')) {
        final dm = msg.substring(7).trim();
        setState(() {
          _showDanger = true;
          _dangerMessage = dm;
        });
        await _audioPlayer.play(AssetSource('assets/sounds/alarm.mp3'));
        await _speechPlayer.speak(dm);
        await Future.delayed(const Duration(seconds: 3));
        setState(() => _showDanger = false);
      } else {
        await _speechPlayer.speak(msg);
      }
      return;
    }
    if (resp.hasGeminiAudioPart()) {
      await _audioPlayer.play(
          BytesSource(Uint8List.fromList(resp.geminiAudioPart.audioData)));
      return;
    }
    if (resp.hasErrorPart()) {
      print('gRPC Error ${resp.errorPart.code}: ${resp.errorPart.message}');
    }
  }

  // === JPEG 編碼：將 YUV420 轉成 RGB，再用 image 套件編碼 ===
  Uint8List _encodeJpeg(CameraImage image) {
    final width = image.width;
    final height = image.height;
    // 建立空白 RGB 影像
    final img = imglib.Image(width: width, height: height);
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yp = yPlane.bytes[yPlane.bytesPerRow * y + x];
        final up = uPlane.bytes[uPlane.bytesPerRow * (y >> 1) + (x >> 1)];
        final vp = vPlane.bytes[vPlane.bytesPerRow * (y >> 1) + (x >> 1)];
        // YUV→RGB 轉換
        int r = (yp + vp * 1.403 - 179).clamp(0, 255).toInt();
        int g = (yp - up * 0.344 + 44 - vp * 0.714 + 91).clamp(0, 255).toInt();
        int b = (yp + up * 1.770 - 227).clamp(0, 255).toInt();
        img.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    // 編碼成 JPEG（品質 80%）
    return Uint8List.fromList(imglib.encodeJpg(img, quality: 80));
  }

  // === UI & 手勢：雙擊開關鏡頭 ===
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () async {
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
                      'Idle',
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
