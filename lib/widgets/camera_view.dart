import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:blind_assist_app/services/mcp_service.dart';

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  bool _isSending = false;
  List<CameraDescription> _backCams = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // 1. 讀取所有鏡頭，過濾後置
    final all = await availableCameras();
    _backCams =
        all.where((c) => c.lensDirection == CameraLensDirection.back).toList();

    // 2. 自動挑「Wide」鏡頭（name 包含 'wide' 或 '1x'，排除 'ultra','tele'）
    CameraDescription chosen = _backCams.first;
    for (var cam in _backCams) {
      final n = cam.name.toLowerCase();
      if ((n.contains('wide') || n.contains('1x')) &&
          !n.contains('ultra') &&
          !n.contains('tele')) {
        chosen = cam;
        break;
      }
    }

    // 3. 用最高解析度（通常是 4:3）初始化 Controller
    _controller = CameraController(
      chosen,
      ResolutionPreset.max,
      enableAudio: false,
    );
    await _controller!.initialize();

    // 4. 啟動影像串流送後端分析
    _controller!.startImageStream((CameraImage img) {
      if (!_isSending) {
        _isSending = true;
        MCPService.analyzeCameraFrame(img).then((_) {
          _isSending = false;
        });
      }
    });

    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 尚未初始化完成前
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // 取得 CameraPreview 物理尺寸，並交換為「直立」的寬高
    final previewSize = _controller!.value.previewSize!;
    final previewWidth = previewSize.height;
    final previewHeight = previewSize.width;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.fitWidth, // 依照螢幕寬度拉滿，僅上下裁切
        alignment: Alignment.center,
        child: SizedBox(
          width: previewWidth,
          height: previewHeight,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }
}
