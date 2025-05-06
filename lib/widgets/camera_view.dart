// =======================================================
// camera_view.dart
// ✅ 功能說明：
// 1️⃣ 控制相機鏡頭（開啟、關閉、切換）
// 2️⃣ 將相機畫面即時傳送到 MCPService 分析
// 3️⃣ 語音提示「Camera open / Camera closed」
// 4️⃣ 用 double-tap 切換相機開啟／關閉
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

  @override
  void initState() {
    super.initState();
    // ⚠️ 預設不自動開啟鏡頭，要手動 double-tap 開啟
  }

  /// 1️⃣ 初始化相機 → 開啟後鏡頭 & 開始影像串流
  Future<void> _initializeCamera() async {
    // 取得裝置上所有鏡頭
    final allCameras = await availableCameras();
    // 篩選後鏡頭
    _backCams = allCameras
        .where((cam) => cam.lensDirection == CameraLensDirection.back)
        .toList();

    // 預設選擇第一個後鏡頭
    CameraDescription chosen = _backCams.first;

    // 如果有「wide」或「1x」鏡頭 → 優先使用
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
      chosen, // 選定的鏡頭
      ResolutionPreset.max, // 最高解析度
      enableAudio: false, // 關閉音訊
    );
    await _controller!.initialize(); // 初始化控制器

    // 開始即時影像串流
    _controller!.startImageStream((CameraImage img) {
      if (!_isSending) {
        _isSending = true;
        // 傳送影像給 MCPService 分析
        MCPService.analyzeCameraFrame(img).then((_) {
          _isSending = false; // 分析完成 → 允許下一張
        });
      }
    });

    setState(() {}); // 更新 UI

    // 🔊 語音提示：相機已開啟
    await _speechPlayer.speak("Camera open, Where would you like to go Just say it out loud.");
  }

  /// 2️⃣ 停止串流 & 釋放相機資源
  Future<void> _disposeCamera() async {
    await _controller?.stopImageStream(); // 停止影像串流
    await _controller?.dispose(); // 釋放資源

    _controller = null;
    _isSending = false;
    setState(() {}); // 更新 UI

    // 🔊 語音提示：相機已關閉
    await _speechPlayer.speak("Camera closed, We appreciate you using our app. thanks for your using");
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // 3️⃣ double-tap → 切換相機開關
      onDoubleTap: () {
        if (_controller == null) {
          _initializeCamera(); // 如果尚未開啟 → 開啟
        } else {
          _disposeCamera(); // 如果已開啟 → 關閉
        }
      },
      child: Container(
        color: Colors.black,
        child: _controller == null || !_controller!.value.isInitialized
            // 尚未開啟相機 → 顯示提示文字
            ? const Center(
                child: Text(
                  'Double-tap to open camera',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
            // 相機已開啟 → 顯示 CameraPreview
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
    );
  }
}
