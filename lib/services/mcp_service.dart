import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:location/location.dart';
import 'package:camera/camera.dart';
import 'package:blind_assist_app/widgets/speech_player.dart';

class MCPService {
  static const String apiBase = " ";
  static final SpeechPlayer speechPlayer = SpeechPlayer();
  static final Location location = Location();
  static const int timeoutSeconds = 10;
  static const int maxRetries = 3;

  static Future<Map<String, dynamic>?> postWithRetry(
      String endpoint, Map<String, dynamic> body) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final response = await http
            .post(
              Uri.parse('$apiBase$endpoint'),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(body),
            )
            .timeout(Duration(seconds: timeoutSeconds));

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          print('Server error: ${response.statusCode}');
          return null;
        }
      } on TimeoutException catch (_) {
        attempt++;
        print('Timeout. Retrying ($attempt/$maxRetries)...');
      } catch (e) {
        attempt++;
        print('Error: $e. Retrying ($attempt/$maxRetries)...');
      }
    }
    await speechPlayer.speak("Network error. Please try again later.");
    return null;
  }

  static Future<void> analyzeCameraFrame(CameraImage image) async {
    var response = await postWithRetry("/capture_and_analyze_scene", {});
    if (response != null && response['speech'] != null) {
      await speechPlayer.speak(response['speech']);
    }
  }

  static Future<void> handleUserCommand(String command) async {
    var locData = await location.getLocation();
    var response = await postWithRetry("/navigate_to_location", {
      "destination": command,
      "user_location": {
        "lat": locData.latitude,
        "lng": locData.longitude,
      }
    });
    if (response != null && response['speech'] != null) {
      await speechPlayer.speak(response['speech']);
    }
  }
}
