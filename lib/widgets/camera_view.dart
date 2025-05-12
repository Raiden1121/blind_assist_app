// =======================================================
// camera_view.dart
// ✅ 功能說明：
// 1️⃣ 控制相機鏡頭（開啟、關閉、切換）
// 2️⃣ 將相機畫面即時傳送到 MCPService 分析
// 3️⃣ 語音提示「Camera open / Camera closed」
// 4️⃣ 用 double-tap 切換相機開啟／關閉
// 5️⃣ 若後端回傳 danger 訊息 → 顯示滑入滑出的白色圓角卡片 3 秒
// =======================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:blind_assist_app/services/mcp_service.dart';
import 'package:blind_assist_app/widgets/speech_player.dart';

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  String _latitude = "";
  String _longitude = "";
  bool _isNavigating = false;

  CameraController? _controller;
  bool _isSending = false;
  List<CameraDescription> _backCams = [];
  final SpeechPlayer _speechPlayer = SpeechPlayer();

  bool _showDanger = false;
  String _dangerMessage = "";

  int _frameCounter = 0;
  final int _processFrameInterval = 5;

  StreamSubscription<Position>? _positionSubscription; // ✅ 地理位置訂閱

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationUpdates(); // ✅ 啟動即時位置追蹤
  }

  @override
  void dispose() {
    _disposeCamera();
    _positionSubscription?.cancel(); // ✅ 停止位置追蹤
    super.dispose();
  }

  /// 1️⃣ 初始化相機
  Future<void> _initializeCamera() async {
    final allCameras = await availableCameras();
    _backCams = allCameras
        .where((cam) => cam.lensDirection == CameraLensDirection.back)
        .toList();

    CameraDescription chosen = _backCams.first;
    for (var cam in _backCams) {
      final name = cam.name.toLowerCase();
      if ((name.contains('wide') || name.contains('1x')) &&
          !name.contains('ultra') &&
          !name.contains('tele')) {
        chosen = cam;
        break;
      }
    }

    _controller =
        CameraController(chosen, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();

    _controller!.startImageStream((CameraImage img) async {
      _frameCounter++;
      if (!_isSending && _frameCounter % _processFrameInterval == 0) {
        _isSending = true;
        try {
          final response = await MCPService.analyzeCameraFrameRaw(img);

          if (response != null && response['danger'] == true) {
            setState(() {
              _dangerMessage = response['speech'] ?? "Danger detected!";
              _showDanger = true;
            });
            await Future.delayed(const Duration(seconds: 3));
            setState(() => _showDanger = false);
          }

          if (response != null && response['speech'] != null) {
            await _speechPlayer.speak(response['speech']);
          }
        } catch (e) {
          print("❌ analyzeCameraFrame error: $e");
        } finally {
          _isSending = false;
        }
      }
    });

    setState(() {});
    await _speechPlayer
        .speak("Camera open. Long press to speak. Where would you like to go?");
  }

  /// 2️⃣ 關閉相機
  Future<void> _disposeCamera() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
    _isSending = false;
    setState(() {});
    await _speechPlayer
        .speak("Camera closed. We appreciate you using our app. Thank you.");
  }

  /// 3️⃣ 單次抓取目前位置
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = position.latitude.toStringAsFixed(5);
      _longitude = position.longitude.toStringAsFixed(5);
    });
  }

  /// ✅ 即時追蹤使用者位置
  void _startLocationUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high, // 設置精度為高
        distanceFilter: 1, // 當位置變動超過 1 米時才觸發更新
      ),
    ).listen((Position position) {
      setState(() {
        _latitude = position.latitude.toStringAsFixed(5);
        _longitude = position.longitude.toStringAsFixed(5);
      });
    });
  }

  /// 5️⃣ UI
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {
        if (_controller == null) {
          _initializeCamera();
        } else {
          _disposeCamera();
        }
      },
      child: Stack(
        children: [
          // 相機畫面或提示
          Container(
            color: Colors.black,
            child: _controller == null || !_controller!.value.isInitialized
                ? const Center(
                    child: Text('Double-tap to open camera',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
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

          // 上方資訊欄
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
                      Text("Lat: $_latitude",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                      Text("Lng: $_longitude",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.navigation,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _isNavigating ? "Navigating" : "Idle",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 危險提示卡片
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          const Text("Obstacle Ahead",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(_dangerMessage,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
