import 'package:flutter/material.dart';
import 'package:blind_assist_app/services/settings_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SettingsBottomSheet extends StatefulWidget {
  const SettingsBottomSheet({Key? key}) : super(key: key);

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  final SettingsService _settings = SettingsService();
  final FlutterTts _flutterTts = FlutterTts();
  
  // Local state
  double _speechRate = SettingsService.defaultSpeechRate;
  final TextEditingController _geminiApiController = TextEditingController();
  final TextEditingController _mapsApiController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final speechRate = await _settings.getSpeechRate();
    final geminiKey = await _settings.getGeminiApiKey();
    final mapsKey = await _settings.getGoogleMapsApiKey();
    
    setState(() {
      _speechRate = speechRate;
      if (geminiKey != null) _geminiApiController.text = geminiKey;
      if (mapsKey != null) _mapsApiController.text = mapsKey;
    });
  }
  
  void _saveSpeechRate(double value) async {
    setState(() => _speechRate = value);
    await _settings.setSpeechRate(value);
    
    // Apply new speech rate immediately
    await _flutterTts.setSpeechRate(value);
    
    // Announce the change to the user
    _flutterTts.speak("Speech rate set to ${(value * 100).round()} percent");
  }
  
  void _saveGeminiKey() async {
    await _settings.setGeminiApiKey(_geminiApiController.text);
    _flutterTts.speak("Gemini API key saved");
  }
  
  void _saveMapsKey() async {
    await _settings.setGoogleMapsApiKey(_mapsApiController.text);
    _flutterTts.speak("Google Maps API key saved");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Speech Rate Section
          _buildSectionHeader('Speech Rate', Icons.volume_up),
          Semantics(
            label: 'Speech rate slider. Current value: ${(_speechRate * 100).round()} percent',
            value: '${(_speechRate * 100).round()} percent',
            hint: 'Double tap and hold, then drag left or right to adjust speech rate',
            slider: true,
            child: Slider(
              value: _speechRate,
              min: 0.1,
              max: 1.0,
              divisions: 18,
              label: '${(_speechRate * 100).round()}%',
              onChanged: _saveSpeechRate,
            ),
          ),
          Text(
            '${(_speechRate * 100).round()}% speed',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          // Gemini API Key Section
          _buildSectionHeader('Gemini API Key', Icons.api),
          TextFormField(
            controller: _geminiApiController,
            decoration: InputDecoration(
              hintText: 'Enter your Gemini API Key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save Gemini API Key',
                onPressed: _saveGeminiKey,
              ),
            ),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: 24),
          
          // Google Maps API Key Section
          _buildSectionHeader('Google Maps API Key', Icons.map),
          TextFormField(
            controller: _mapsApiController,
            decoration: InputDecoration(
              hintText: 'Enter your Google Maps API Key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save Google Maps API Key',
                onPressed: _saveMapsKey,
              ),
            ),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: 40),
          
          // Close Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_circle),
              label: const Text('Done'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _geminiApiController.dispose();
    _mapsApiController.dispose();
    super.dispose();
  }
}