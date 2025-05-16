import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _speechRateKey = 'speech_rate';
  static const String _geminiApiKey = 'gemini_api_key';
  static const String _googleMapsApiKey = 'google_maps_api_key';

  // Default values
  static const double defaultSpeechRate = 0.5;
  
  // Singleton instance
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Cached values
  double? _speechRate;
  String? _geminiApiValue;
  String? _googleMapsApiValue;
  
  // Getters
  Future<double> getSpeechRate() async {
    if (_speechRate != null) return _speechRate!;
    final prefs = await SharedPreferences.getInstance();
    _speechRate = prefs.getDouble(_speechRateKey) ?? defaultSpeechRate;
    return _speechRate!;
  }
  
  Future<String?> getGeminiApiKey() async {
    if (_geminiApiValue != null) return _geminiApiValue;
    final prefs = await SharedPreferences.getInstance();
    _geminiApiValue = prefs.getString(_geminiApiKey) ?? '';
    return _geminiApiValue;
  }
  
  Future<String?> getGoogleMapsApiKey() async {
    if (_googleMapsApiValue != null) return _googleMapsApiValue;
    final prefs = await SharedPreferences.getInstance();
    _googleMapsApiValue = prefs.getString(_googleMapsApiKey) ?? '';
    return _googleMapsApiValue;
  }
  
  // Setters
  Future<void> setSpeechRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, value);
    _speechRate = value;
  }
  
  Future<void> setGeminiApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKey, value);
    _geminiApiValue = value;
  }
  
  Future<void> setGoogleMapsApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleMapsApiKey, value);
    _googleMapsApiValue = value;
  }
}