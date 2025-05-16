// =======================================================
// speech_player.dart
// 此檔案實作「語音播放工具」
// ✅ 功能：使用 flutter_tts 套件，把文字轉成語音播放
// 用法：SpeechPlayer().speak("文字內容")
// =======================================================

import 'package:flutter_tts/flutter_tts.dart';

class SpeechPlayer {
  // 建立 flutter_tts 實例，用來執行 TTS 功能
  final FlutterTts _tts = FlutterTts();

  /// 播放語音
  /// [text]：要朗讀的英文文字
  Future<void> speak(String text) async {
    // 設定語言為美式英文
    await _tts.setLanguage("en-US");

    // 設定語速（0.0 ~ 1.0，越大越快）
    await _tts.setSpeechRate(0.5);

    // 開始播放語音
    await _tts.speak(text);
  }
  /// 停止語音播放
  Future<void> stop() async {
    await _tts.stop();
  }
}
