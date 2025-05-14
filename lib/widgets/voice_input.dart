// =======================================================
// voice_input.dart
// ✅ 功能說明：
//   1️⃣ 長按錄音，松手結束
//   2️⃣ 即時收集 PCM raw audio chunk
//   3️⃣ 結束後將 buffer 中音訊轉成 Uint8List
//   4️⃣ 透過 gRPC ChatStream 串流送到後端
// =======================================================

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'; // 錄音工具
import 'package:permission_handler/permission_handler.dart'; // 權限處理
import 'package:grpc/grpc.dart' as grpc;

// gRPC Stub（protoc 生成）
import '../generated/blind_assist.pbgrpc.dart';

class VoiceInput extends StatefulWidget {
  const VoiceInput({Key? key}) : super(key: key);

  @override
  State<VoiceInput> createState() => _VoiceInputState();
}

class _VoiceInputState extends State<VoiceInput> {
  // === 錄音相關 ===
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false; // 標記目前是否在錄音
  final List<int> _rawDataBuffer = []; // PCM buffer（如果還要保留）

  StreamController<Uint8List>? _audioStreamController;
  StreamSubscription<Uint8List>? _recorderSubscription;

  // === gRPC 相關 ===
  late final grpc.ClientChannel _channel;
  late final GeminiLiveClient _grpcClient;
  late final StreamController<ClientRequest> _reqController;

  @override
  void initState() {
    super.initState();
    _initGrpc(); // 初始化 gRPC channel & client & 串流
    _initRecorder(); // 初始化錄音器並請求權限
  }

  @override
  void dispose() async {
    await _recorderSubscription?.cancel();
    await _recorder.closeRecorder();
    await _reqController.close();
    await _channel.shutdown(); // <- await
    super.dispose();
  }

  /// 初始化 gRPC Channel、Client，並啟動 ChatStream 雙向串流
  void _initGrpc() {
    _channel = grpc.ClientChannel(
      'blind-grpc-server-617941879669.asia-east1.run.app',
      port: 443,
      options: grpc.ChannelOptions(
        credentials: grpc.ChannelCredentials.secure(), // 放在 options 裡面
        idleTimeout: const Duration(seconds: 60), // 避免太久沒有活動就被 server 關線
        codecRegistry: grpc.CodecRegistry(codecs: const [
          grpc.GzipCodec(), // 可選：gzip 壓縮
          grpc.IdentityCodec(),
        ]),
      ),
    );

    _grpcClient = GeminiLiveClient(_channel);
    _reqController = StreamController<ClientRequest>();

    // 1️⃣ 先送 InitialConfigRequest
    _reqController.sink.add(ClientRequest(
      initialConfig: InitialConfigRequest(
        modelName: 'gemini-1', // ← 可改
        responseModalities: ['TEXT', 'AUDIO'],
      ),
    ));

    // 2️⃣ 啟動雙向串流，並監聽伺服器回應
    _grpcClient.chatStream(_reqController.stream).listen(
          _onServerResponse,
          onError: (e) => debugPrint('❌ gRPC 錯誤：$e'),
        );
  }

  /// 初始化錄音器：請求麥克風權限後開啟錄音器
  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      await _recorder.openRecorder();
      // 設定錄音訂閱頻率（影響 chunk 大小）
      await _recorder
          .setSubscriptionDuration(const Duration(milliseconds: 100));
    } else {
      debugPrint('❗ 麥克風權限被拒絕，無法錄音');
    }
  }

  /// 開始錄音：
  /// - 清空 buffer（如要保留）
  /// - 建立 PCM chunk StreamController
  /// - startRecorder 並把 sink 接到 controller
  Future<void> _startRecording() async {
    _rawDataBuffer.clear();
    _audioStreamController = StreamController<Uint8List>();
    _recorderSubscription = _audioStreamController!.stream.listen((chunk) {
      // 1️⃣ 保留在本地 buffer（可選）
      _rawDataBuffer.addAll(chunk);
      // 2️⃣ 透過 gRPC 打包成 AudioPart 串流送出
      _reqController.sink.add(ClientRequest(
        clientAudioPart: AudioPart(
          audioData: chunk,
          mimeType: 'audio/pcm',
          sampleRate: 16000,
        ),
      ));
    });

    await _recorder.startRecorder(
      toStream: _audioStreamController!.sink,
      codec: Codec.pcm16, // PCM 16-bit raw
      sampleRate: 16000, // 每秒 16000 samples
      numChannels: 1, // 單聲道
    );

    setState(() => _isRecording = true);
  }

  /// 停止錄音：
  /// - stopRecorder
  /// - 取消訂閱 & 關閉 controller
  /// - 送 end_of_turn=true 給伺服器
  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    await _recorderSubscription?.cancel();
    await _audioStreamController?.close();
    setState(() => _isRecording = false);

    // 通知伺服器這一輪語音已經結束
    _reqController.sink.add(ClientRequest(endOfTurn: true));
  }

  /// 處理伺服器回應
  void _onServerResponse(ServerResponse resp) {
    if (resp.hasTextPart()) {
      final text = resp.textPart.text;
      debugPrint('💬 回傳文字：$text');
      // TODO: 顯示到畫面上
    }
    if (resp.hasGeminiAudioPart()) {
      final audio = resp.geminiAudioPart.audioData;
      debugPrint('🔈 收到語音回覆，共 ${audio.length} bytes');
      // TODO: 播放或存檔
    }
    if (resp.hasErrorPart()) {
      debugPrint('⚠️ 錯誤 ${resp.errorPart.code}: ${resp.errorPart.message}');
    }
    if (resp.turnComplete) {
      debugPrint('🔔 Gemini 回合結束');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _startRecording(), // 長按開始
      onPointerUp: (_) => _stopRecording(), // 放開停止
      child: FloatingActionButton(
        backgroundColor: _isRecording
            ? const Color.fromARGB(255, 219, 54, 54) // 錄音中紅色
            : const Color.fromARGB(255, 113, 52, 52), // 待命
        onPressed: () {}, // 使用 Listener 而非 onPressed
        child: Icon(
          _isRecording ? Icons.mic : Icons.mic_none,
          size: 60,
        ),
      ),
    );
  }
}
