// =======================================================
// mcp_service.dart
// ✅ 功能說明：
// 1️⃣ 封裝與 MCP API 的 HTTP 呼叫（含 retry / timeout 機制）
// 2️⃣ analyzeCameraFrame：送出影像 → 後端辨識 → 播語音
// 3️⃣ handleUserCommand：送出指令 + 定位 → 後端導航 → 播語音
// =======================================================

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:location/location.dart';
import 'package:camera/camera.dart';
import 'package:blind_assist_app/widgets/speech_player.dart';

class MCPService {
  static const String apiBase = " "; // MCP API 基本 URL (⚠️ 請填入實際網址)
  static final SpeechPlayer speechPlayer = SpeechPlayer(); // 語音播放工具
  static final Location location = Location(); // 取得使用者定位
  static const int timeoutSeconds = 10; // 每次 API 呼叫 timeout 秒數
  static const int maxRetries = 3; // 最多重試次數

  /// 1️⃣ HTTP POST + Retry 機制
  /// [endpoint]：API 路徑（ex: "/capture_and_analyze_scene"）
  /// [body]：要傳送的 JSON 資料
  /// 回傳：Map 格式的 JSON 或 null
  static Future<Map<String, dynamic>?> postWithRetry(
      String endpoint, Map<String, dynamic> body) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        // 發送 HTTP POST 請求
        final response = await http
            .post(
              Uri.parse('$apiBase$endpoint'), // 合併 URL
              headers: {"Content-Type": "application/json"}, // JSON header
              body: jsonEncode(body), // 編碼 JSON
            )
            .timeout(Duration(seconds: timeoutSeconds)); // 設定 timeout

        if (response.statusCode == 200) {
          // ✅ 成功 → 回傳 JSON Map
          return jsonDecode(response.body);
        } else {
          print('Server error: ${response.statusCode}');
          return null;
        }
      } on TimeoutException catch (_) {
        // ⚠️ 超時 → 重試
        attempt++;
        print('Timeout. Retrying ($attempt/$maxRetries)...');
      } catch (e) {
        // ⚠️ 其他錯誤 → 重試
        attempt++;
        print('Error: $e. Retrying ($attempt/$maxRetries)...');
      }
    }
    // ⚠️ 全部重試失敗 → 播放語音錯誤提示
    await speechPlayer.speak("Network error. Please try again later.");
    return null;
  }

  /// 2️⃣ analyzeCameraFrame
  /// 功能：將相機影像送到 API 分析 → 播放後端回傳的語音內容
  static Future<void> analyzeCameraFrame(CameraImage image) async {
    var response = await postWithRetry("/capture_and_analyze_scene", {});
    if (response != null && response['speech'] != null) {
      await speechPlayer.speak(response['speech']);
    }
  }

  /// 3️⃣ handleUserCommand
  /// 功能：將指令 & 定位送到 API → 播放後端回傳的語音導航
  static Future<void> handleUserCommand(String command) async {
    var locData = await location.getLocation(); // 取得 GPS 位置
    var response = await postWithRetry("/navigate_to_location", {
      "destination": command, // 目的地（使用者語音輸入）
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
