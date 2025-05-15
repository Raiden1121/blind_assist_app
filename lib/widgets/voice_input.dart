import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:grpc/grpc.dart' as grpc;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../generated/blind_assist.pbgrpc.dart';

class VoiceInput extends StatefulWidget {
  const VoiceInput({Key? key}) : super(key: key);

  @override
  State<VoiceInput> createState() => _VoiceInputState();
}

class _VoiceInputState extends State<VoiceInput> {
  // === 改成 late、不要在此處 new ===
  late FlutterSoundRecorder _recorder;
  bool _isRecorderInited = false;
  bool _isRecording = false;

  StreamController<Uint8List>? _audioStreamController;
  StreamSubscription<Uint8List>? _recorderSubscription;

  late final grpc.ClientChannel _channel;
  late final GeminiLiveClient _grpcClient;
  late final StreamController<ClientRequest> _reqController;

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initGrpc();
    _initTts();
    _initRecorder(); // 延後 new FlutterSoundRecorder()
  }

  @override
  void dispose() {
    _recorderSubscription?.cancel();
    if (_isRecorderInited) {
      _recorder.closeRecorder();
    }
    _reqController.close();
    _channel.shutdown();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('zh-TW');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _initGrpc() {
    _channel = grpc.ClientChannel(
      'blind-liveapi-grpc-617941879669.asia-east1.run.app',
      port: 443,
      options: grpc.ChannelOptions(
        credentials: grpc.ChannelCredentials.secure(),
      ),
    );
    _grpcClient = GeminiLiveClient(_channel);
    _reqController = StreamController<ClientRequest>();
    _reqController.sink.add(ClientRequest(
      initialConfig: InitialConfigRequest(
        modelName: 'models/gemini-2.0-flash-live-001',
        responseModalities: ['TEXT', 'AUDIO'],
      ),
    ));
    _grpcClient.chatStream(_reqController.stream).listen(_onServerResponse,
        onError: (e) {
      debugPrint('❌ gRPC 錯誤：$e');
    });
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('❗ 麥克風權限被拒絕，無法錄音');
      return;
    }

    _recorder = FlutterSoundRecorder();
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));

    _isRecorderInited = true;
    debugPrint('✅ Recorder 初始化完成');
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInited) {
      debugPrint('❗ Recorder 尚未初始化');
      return;
    }
    if (_isRecording || _recorder.isRecording) return;

    _audioStreamController = StreamController<Uint8List>();
    _recorderSubscription = _audioStreamController!.stream.listen((chunk) {
      _reqController.sink.add(ClientRequest(
        clientAudioPart: AudioPart(
          audioData: chunk,
          mimeType: 'audio/pcm',
          sampleRate: 16000,
        ),
      ));
    });

    try {
      await _recorder.startRecorder(
        toStream: _audioStreamController!.sink,
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() => _isRecording = true);
      debugPrint('🎙️ 開始錄音');
    } catch (e) {
      debugPrint('🛑 startRecorder 失敗：$e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecorderInited) return;
    if (!_isRecording || !_recorder.isRecording) return;

    try {
      await _recorder.stopRecorder();
      await _recorderSubscription?.cancel();
      await _audioStreamController?.close();
      setState(() => _isRecording = false);
      _reqController.sink.add(ClientRequest(endOfTurn: true));
      debugPrint('⏹️ 停止錄音');
    } catch (e) {
      debugPrint('🛑 stopRecorder 失敗：$e');
    }
  }

  void _onServerResponse(ServerResponse resp) {
    if (resp.hasTextPart()) {
      _flutterTts.speak(resp.textPart.text);
    }
    if (resp.hasGeminiAudioPart()) {
      final bytes = Uint8List.fromList(resp.geminiAudioPart.audioData);
      _audioPlayer.play(BytesSource(bytes));
    }
    if (resp.hasErrorPart()) {
      debugPrint('⚠️ 錯誤 ${resp.errorPart.code}: ${resp.errorPart.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _startRecording(),
      onPointerUp: (_) => _stopRecording(),
      child: SizedBox(
        width: 100,
        height: 100,
        child: FloatingActionButton(
          backgroundColor: _isRecording ? Colors.redAccent : Colors.blueGrey,
          onPressed: () {},
          child: Icon(
            _isRecording ? Icons.mic : Icons.mic_none,
            size: 36,
          ),
        ),
      ),
    );
  }
}
