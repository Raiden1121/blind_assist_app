import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:blind_assist_app/widgets/speech_player.dart';

class VoiceInput extends StatefulWidget {
  final Function(String) onResult;
  const VoiceInput({Key? key, required this.onResult}) : super(key: key);

  @override
  State<VoiceInput> createState() => _VoiceInputState();
}

class _VoiceInputState extends State<VoiceInput> {
  late stt.SpeechToText _speech;
  final SpeechPlayer _speechPlayer = SpeechPlayer();

  bool _isListening = false; // 是否正在錄音（PTT 或命令模式）
  bool _awake = false; // 喚醒字已觸發，正在命令偵聽
  final String wakeWord = "hey assistant";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initWakeWordListening(); // 一進來就啟動背景喚醒字偵聽
  }

  /// 1. 背景持續偵聽「wake word」
  void _initWakeWordListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        // 當 listen 完成（如因為 stop()），且不在錄音或命令模式，就自動重啟
        if (status == 'done' && !_isListening && !_awake) {
          _initWakeWordListening();
        }
      },
      onError: (err) {
        // 初始化或偵聽錯誤時可以在此處 log
      },
    );
    if (!available) return;
    _speech.listen(
      onResult: _onWakeResult,
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  /// 2. 處理背景偵聽結果，若抓到 wake word 就喚醒
  void _onWakeResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.toLowerCase();
    if (!_awake && text.contains(wakeWord)) {
      _awake = true;
      _speech.stop(); // 停掉背景偵聽
      _speechPlayer.speak("Yes?"); // 播放回饋提示
      _startCommandListening(); // 進入一次完整命令偵聽
    }
  }

  /// 3. 喚醒後的完整命令聆聽（finalResult）
  void _startCommandListening() async {
    setState(() => _isListening = true);
    bool available = await _speech.initialize();
    if (!available) {
      _resetToWakeWord();
      return;
    }
    _speech.listen(
      onResult: (SpeechRecognitionResult res) {
        if (res.finalResult) {
          widget.onResult(res.recognizedWords.trim());
          _stopCommandListening();
        }
      },
      partialResults: false,
      listenMode: stt.ListenMode.dictation,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  void _stopCommandListening() {
    _speech.stop();
    _resetToWakeWord();
  }

  /// 4. PTT 模式：長按錄音
  void _startHoldListening() async {
    await _speech.stop(); // 暫停任何現有聽寫
    setState(() => _isListening = true);
    bool available = await _speech.initialize();
    if (!available) {
      _resetToWakeWord();
      return;
    }
    _speech.listen(
      onResult: (SpeechRecognitionResult res) {
        if (res.finalResult) {
          widget.onResult(res.recognizedWords.trim());
          _stopHoldListening();
        }
      },
      partialResults: false,
      listenMode: stt.ListenMode.dictation,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  void _stopHoldListening() {
    _speech.stop();
    _resetToWakeWord();
  }

  /// 重設狀態並回到背景喚醒字偵聽
  void _resetToWakeWord() {
    setState(() {
      _isListening = false;
      _awake = false;
    });
    _initWakeWordListening();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Listener(
        onPointerDown: (_) => _startHoldListening(),
        onPointerUp: (_) => _stopHoldListening(),
        onPointerCancel: (_) => _stopHoldListening(),
        child: FloatingActionButton(
          backgroundColor: _isListening ? Colors.redAccent : Colors.blueAccent,
          onPressed: () {}, // 真正的錄音由 Listener 控制
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            size: 32,
          ),
        ),
      ),
    );
  }
}
