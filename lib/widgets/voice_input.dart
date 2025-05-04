// =======================================================
// voice_input.dart
// 此檔案實作「語音輸入元件」
// ✅ 功能：
// 1️⃣ 持續背景偵聽「喚醒字」（wake word，例如 "hey assistant"）
// 2️⃣ 被喚醒後 → 進入「語音指令」模式
// 3️⃣ 也可透過「長按」進入語音錄音（PTT 模式）
// 4️⃣ 將語音結果傳給外部 callback（onResult）
// =======================================================

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:blind_assist_app/widgets/speech_player.dart';

class VoiceInput extends StatefulWidget {
  final Function(String) onResult; // callback：當有語音輸入結果時回傳
  const VoiceInput({Key? key, required this.onResult}) : super(key: key);

  @override
  State<VoiceInput> createState() => _VoiceInputState();
}

class _VoiceInputState extends State<VoiceInput> {
  late stt.SpeechToText _speech; // 語音辨識實例
  final SpeechPlayer _speechPlayer = SpeechPlayer(); // 語音播報工具

  bool _isListening = false; // 是否正在錄音（PTT 或命令模式）
  bool _awake = false; // 是否已被喚醒（偵測到 wake word）
  final String wakeWord = "hey assistant"; // 設定喚醒字

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText(); // 建立語音辨識實例
    _initWakeWordListening(); // 一進入頁面就啟動「背景喚醒字偵聽」
  }

  /// 1️⃣ 持續背景偵聽「wake word」
  void _initWakeWordListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        // 當偵聽結束（status == done），且目前沒有錄音／命令 → 重新啟動背景偵聽
        if (status == 'done' && !_isListening && !_awake) {
          _initWakeWordListening();
        }
      },
      onError: (err) {
        // 👉 這裡可以印出 log 或處理錯誤
      },
    );
    if (!available) return;

    // 開始背景聽寫（partialResults: true → 持續更新文字）
    _speech.listen(
      onResult: _onWakeResult, // 當有語音結果時處理
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      localeId: 'en_US', // 語系：美式英文
      cancelOnError: true,
    );
  }

  /// 2️⃣ 處理背景偵聽結果
  /// 👉 如果偵測到 wake word → 進入「喚醒狀態」
  void _onWakeResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.toLowerCase();
    if (!_awake && text.contains(wakeWord)) {
      _awake = true;
      _speech.stop(); // 停止背景聽寫
      _speechPlayer.speak("Yes?"); // 播放提示音
      _startCommandListening(); // 進入語音指令模式
    }
  }

  /// 3️⃣ 進入語音指令模式
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
          widget.onResult(res.recognizedWords.trim()); // 把結果傳給外部 callback
          _stopCommandListening(); // 結束指令偵聽
        }
      },
      partialResults: false,
      listenMode: stt.ListenMode.dictation,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  /// 停止指令偵聽
  void _stopCommandListening() {
    _speech.stop();
    _resetToWakeWord();
  }

  /// 4️⃣ 長按錄音（PTT 模式）
  void _startHoldListening() async {
    await _speech.stop(); // 先停掉任何舊的偵聽
    setState(() => _isListening = true);
    bool available = await _speech.initialize();
    if (!available) {
      _resetToWakeWord();
      return;
    }
    _speech.listen(
      onResult: (SpeechRecognitionResult res) {
        if (res.finalResult) {
          widget.onResult(res.recognizedWords.trim()); // 傳出結果
          _stopHoldListening(); // 結束 PTT 錄音
        }
      },
      partialResults: false,
      listenMode: stt.ListenMode.dictation,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  /// 停止 PTT 錄音
  void _stopHoldListening() {
    _speech.stop();
    _resetToWakeWord();
  }

  /// 5️⃣ 重設狀態 → 回到「背景喚醒字偵聽」
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
        onPointerDown: (_) => _startHoldListening(), // 手指按下 → 開始錄音
        onPointerUp: (_) => _stopHoldListening(), // 手指放開 → 停止錄音
        onPointerCancel: (_) => _stopHoldListening(), // 手指被取消（滑出按鈕區域）
        child: FloatingActionButton(
          backgroundColor: _isListening ? Colors.redAccent : Colors.blueAccent,
          onPressed: () {}, // 👉 按鈕點擊事件不處理（用 Listener 控制）
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            size: 32,
          ),
        ),
      ),
    );
  }
}
