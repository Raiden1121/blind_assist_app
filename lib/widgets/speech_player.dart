// =======================================================
// speech_player.dart
// 此檔案實作「語音播放工具」
// ✅ 功能：使用 flutter_tts 套件，把文字轉成語音播放
// 用法：SpeechPlayer().speak("文字內容")
// =======================================================

import 'package:flutter_tts/flutter_tts.dart';
import 'package:blind_assist_app/services/settings_service.dart';

class SpeechPlayer {
  // 建立 flutter_tts 實例，用來執行 TTS 功能
  final FlutterTts _tts = FlutterTts();
  final SettingsService _settings = SettingsService();
  
  // 私有建構子
  SpeechPlayer._internal() {
    _initTts();
  }
  
  // 單例模式
  static final SpeechPlayer _instance = SpeechPlayer._internal();
  factory SpeechPlayer() => _instance;
  
  /// 初始化 TTS 引擎
  Future<void> _initTts() async {
    // 設定語言為美式英文
    await _tts.setLanguage("en-US");
    
    // 從設定服務取得語速
    final speechRate = await _settings.getSpeechRate();
    await _tts.setSpeechRate(speechRate);
    
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// 播放語音
  /// [text]：要朗讀的英文文字
  Future<void> speak(String text) async {
    // 確保使用最新的語速設定
    final speechRate = await _settings.getSpeechRate();
    await _tts.setSpeechRate(speechRate);
    
    // 開始播放語音
    await _tts.speak(text);
  }
  
  /// 停止語音播放
  Future<void> stop() async {
    await _tts.stop();
  }
  
  /// 更新語速設定
  Future<void> updateSpeechRate() async {
    final speechRate = await _settings.getSpeechRate();
    await _tts.setSpeechRate(speechRate);
  }
}