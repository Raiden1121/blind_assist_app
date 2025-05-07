// =======================================================
// camera_view.dart
// ✅ 功能說明：
// 1️⃣ 控制相機鏡頭（開啟、關閉、切換）
// 2️⃣ 將相機畫面即時傳送到 MCPService 分析
// 3️⃣ 語音提示「Camera open / Camera closed」
// 4️⃣ 用 double-tap 切換相機開啟／關閉
// 5️⃣ 若後端回傳 danger 訊息 → 顯示滑入滑出的白色圓角卡片 3 秒
// =======================================================

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:blind_assist_app/services/mcp_service.dart'; // 串接後端 API
import 'package:blind_assist_app/widgets/speech_player.dart'; // 語音播放工具

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller; // 相機控制器
  bool _isSending = false; // 是否正在傳送影像分析
  List<CameraDescription> _backCams = []; // 可用的後鏡頭列表
  final SpeechPlayer _speechPlayer = SpeechPlayer(); // 語音播放工具

  // 🔥 危險提示狀態與訊息（滑入滑出卡片）
  bool _showDanger = false;
  String _dangerMessage = "";

  // 🔁 幀率計數器：每 5 幀才分析一次影像（避免過載）
  int _frameCounter = 0;
  final int _processFrameInterval = 5;

  @override
  void initState() {
    super.initState();
    // 預設不打開鏡頭，等待使用者 double-tap
  }

  /// 1️⃣ 初始化相機 → 開啟後鏡頭 & 開始影像串流
  Future<void> _initializeCamera() async {
    // 取得裝置上所有鏡頭
    final allCameras = await availableCameras();
    // 篩選後鏡頭
    _backCams = allCameras
        .where((cam) => cam.lensDirection == CameraLensDirection.back)
        .toList();

    // 選擇預設鏡頭（優先 wide 或 1x，不含 ultra/tele）
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

    // 建立相機控制器
    _controller = CameraController(
      chosen,
      ResolutionPreset.medium, // 避免解析度過高造成效能問題
      enableAudio: false,
    );
    await _controller!.initialize();

    // 啟動影像串流，每 5 幀分析一次
    _controller!.startImageStream((CameraImage img) async {
      _frameCounter++;
      if (!_isSending && _frameCounter % _processFrameInterval == 0) {
        _isSending = true;
        try {
          final response = await MCPService.analyzeCameraFrameRaw(img);

          // 🔔 若偵測到 danger → 顯示滑入卡片
          if (response != null && response['danger'] == true) {
            setState(() {
              _dangerMessage = response['speech'] ?? "Danger detected!";
              _showDanger = true;
            });
            // 顯示 3 秒後自動隱藏
            await Future.delayed(const Duration(seconds: 3));
            setState(() => _showDanger = false);
          }

          // 🔊 播放語音提示
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

    setState(() {}); // 更新畫面
    // 3️⃣ 開啟相機後播語音提示
    await _speechPlayer
        .speak("Camera open. Long press to speak. Where would you like to go?");
  }

  /// 4️⃣ 停止串流 & 釋放相機資源
  Future<void> _disposeCamera() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();

    _controller = null;
    _isSending = false;
    setState(() {});

    // 播放關閉相機語音提示
    await _speechPlayer
        .speak("Camera closed. We appreciate you using our app. Thank you.");
  }

  /// 5️⃣ build UI：相機畫面 + 滑入滑出提示卡片
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // double-tap 切換相機開關
      onDoubleTap: () {
        if (_controller == null) {
          _initializeCamera();
        } else {
          _disposeCamera();
        }
      },
      child: Stack(
        children: [
          // ─── 相機畫面或提示文字 ─────────────────────────────
          Container(
            color: Colors.black,
            child: _controller == null || !_controller!.value.isInitialized
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

          // ─── 滑入滑出「白色圓角卡片」提示 ───────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300), // 動畫時間
            curve: Curves.easeInOut, // 動畫曲線
            top: _showDanger
                ? MediaQuery.of(context).padding.top +
                    16 // 顯示時：status bar 下方 16px
                : -120, // 隱藏時：卡片移出螢幕上方
            left: 20,
            right: 20,
            child: Material(
              elevation: 8, // 陰影
              borderRadius: BorderRadius.circular(12), // 圓角
              color: Colors.white, // 卡片底色
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ⚠️ 左側圓圈 Icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 🅰️ 主標題 & 🅱️ 副標題
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Obstacle Ahead",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dangerMessage,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
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
