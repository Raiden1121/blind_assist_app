// lib/widgets/camera_view.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:blind_assist_app/services/mcp_service.dart';
// 新增：引入語音回饋
import 'package:blind_assist_app/widgets/speech_player.dart';

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  bool _isSending = false;
  List<CameraDescription> _backCams = [];
  // 新增：SpeechPlayer 實例
  final SpeechPlayer _speechPlayer = SpeechPlayer();

  @override
  void initState() {
    super.initState();
    // 不自動初始化鏡頭
  }

  /// 啟動鏡頭並開始影像串流
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

    _controller = CameraController(
      chosen,
      ResolutionPreset.max,
      enableAudio: false,
    );
    await _controller!.initialize();

    _controller!.startImageStream((CameraImage img) {
      if (!_isSending) {
        _isSending = true;
        MCPService.analyzeCameraFrame(img).then((_) {
          _isSending = false;
        });
      }
    });

    setState(() {});
    // 語音回饋：鏡頭已開啟
    await _speechPlayer.speak("Camera open");
  }

  /// 停止串流並釋放鏡頭資源
  Future<void> _disposeCamera() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();

    _controller = null;
    _isSending = false;
    setState(() {});
    // 語音回饋：鏡頭已關閉
    await _speechPlayer.speak("Camera closed");
  }

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
      child: Container(
        color: Colors.black,
        child: _controller == null || !_controller!.value.isInitialized
            // 尚未開啟鏡頭：顯示提示文字
            ? const Center(
                child: Text(
                  'Double-tap to open camera',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
            // 鏡頭已開啟：顯示 CameraPreview，維持原本的 fitWidth 版型
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
