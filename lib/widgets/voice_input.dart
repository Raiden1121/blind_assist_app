import 'dart:async';
import 'dart:typed_data';

// import 'package:blind_assist_app/generated/gemini_chat.pbjson.dart';
import 'package:blind_assist_app/grpc/grpc_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:grpc/grpc.dart' as grpc;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../generated/gemini_chat.pbgrpc.dart';

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
  StreamSubscription<Uint8List>? _audioSub;
  final List<Uint8List> _chunks = [];

  Timer? _locationUpdateTimer;

  // late final StreamController<ChatRequest> _reqController;
  // late final StreamSubscription<ChatResponse> _respSub;

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final loc.Location _location = loc.Location();

  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void initState() {
    super.initState();

    // _reqController = StreamController<ChatRequest>();
    // // 啟動 gRPC 串流
    // _respSub = GrpcClient.chatStream(_reqController.stream).listen(
    //     _onServerResponse,
    //     onError: (e) => debugPrint('❌ gRPC error: \$e'),
    //     onDone: () => debugPrint('✅ gRPC stream closed'));

    _initTts();
    _initRecorder(); // 延後 new FlutterSoundRecorder()
    _initLocationService();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    if (_isRecorderInited) {
      _recorder.closeRecorder();
    }
    // _respSub.cancel();
    // _reqController.close();
    _audioSub?.cancel();
    _audioStreamController?.close();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('zh-TW');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _initLocationService() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionStatus;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    permissionStatus = await _location.hasPermission();
    if (permissionStatus == loc.PermissionStatus.denied) {
      permissionStatus = await _location.requestPermission();
      if (permissionStatus != loc.PermissionStatus.granted) return;
    }

    // Get initial location
    try {
      final locationData = await _location.getLocation();
      setState(() {
        _latitude = locationData.latitude ?? 0.0;
        _longitude = locationData.longitude ?? 0.0;
        debugPrint('📍 Initial location: $_latitude, $_longitude');
      });
    } catch (e) {
      debugPrint('Error getting initial location: $e');
    }
  }

  // Method to send location data to the server
  Future<void> _sendLocationData() async {
    final locationData = await _location.getLocation();
    setState(() {
      _latitude = locationData.latitude ?? 0.0;
      _longitude = locationData.longitude ?? 0.0;
      debugPrint('📍 Initial location: $_latitude, $_longitude');
    });

    // _reqController.add(locationRequest);
    debugPrint('📍 Sent location: $_latitude, $_longitude');
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

    _audioStreamController = StreamController<Uint8List>.broadcast();

    _isRecorderInited = true;
    debugPrint('✅ Recorder 初始化完成');
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInited) {
      debugPrint('❗ Recorder 尚未初始化');
      return;
    }
    if (_isRecording || _recorder.isRecording) return;

    _audioSub = _audioStreamController?.stream.listen((chunk) {
      bool hasNonZeroData = chunk.any((byte) => byte != 0);
      if (hasNonZeroData) {
        _chunks.add(chunk);
      }
    });

    _sendLocationData();

    // Set up periodic location updates
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _sendLocationData();
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

    _locationUpdateTimer?.cancel();

    if (_chunks.isNotEmpty) {
      final builder = BytesBuilder();
      // 將所有 chunk 合併成一個 Uint8List
      for (final c in _chunks) {
        builder.add(c);
      }
      final merged = builder.takeBytes();
      final audioSize = merged.length / 1024; // KB
      final durationMs =
          (merged.length / 2 / 16000 * 1000).round(); // 16-bit samples at 16kHz
      debugPrint(
          '📊 Audio stats: ${audioSize.toStringAsFixed(1)}KB, ${durationMs}ms');

      // _reqController.add(
      //   ChatRequest()
      //     ..audio = (AudioInput()
      //       ..data = merged
      //       ..format = 'audio/wav'
      //       ..sampleRateHz = 16000)
      //     ..location = (LocationInput()
      //       ..lat = _latitude
      //       ..lng = _longitude),
      // );

      Stream<ChatRequest> request = Stream.fromIterable([
        ChatRequest()
          ..audio = (AudioInput()
            ..data = merged
            ..format = 'audio/raw'
            ..sampleRateHz = 16000)
          ..location = (LocationInput()
            ..lat = _latitude
            ..lng = _longitude),
      ]);

      GrpcClient.chatStream(request).listen(
        (resp) async {
          if (resp.hasNav()) {
            final nav = resp.nav;
            // if (nav.alert.isNotEmpty) {
            //   _flutterTts.speak(nav.alert);
            // }

            if (nav.navDescription != "") {
              await _flutterTts.speak(nav.navDescription);
            } else if(nav.navDescription.contains("Error")) {
              await _flutterTts.speak("Please try again.");
            }
          }
        },
        onError: (e) => debugPrint('❌ gRPC error: $e'),
        onDone: () => debugPrint('🔚 gRPC stream closed'),
      );

      _chunks.clear();
      await _audioSub?.cancel();

      debugPrint('🔊 Sent audio data: ${merged.length} bytes');
    }

    try {
      await _recorder.stopRecorder();
      setState(() => _isRecording = false);
      debugPrint('⏹️ 停止錄音');
    } catch (e) {
      debugPrint('🛑 stopRecorder 失敗：$e');
    }
  }

  // void _onServerResponse(ChatResponse response) async {
  //   if (response.hasNav()) {
  //     final nav = response.nav;
  //     // if (nav.alert.isNotEmpty) {
  //     //   await _flutterTts.speak(nav.alert);
  //     // }
  //     if (nav.navDescription != "") {
  //       await _flutterTts.speak(nav.navDescription);
  //       debugPrint('🔊 語音播報: ${nav.navDescription}');
  //     } else if (nav.navDescription.contains("Error")) {
  //       await _flutterTts.speak("Please try again.");
  //     }
  //   }
  // }

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
