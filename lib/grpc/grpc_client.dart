import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:blind_assist_app/generated/gemini_chat.pbgrpc.dart';
import 'package:uuid/uuid.dart';
import 'package:blind_assist_app/services/settings_service.dart';

class GrpcClient {
  static late ClientChannel channel;
  static late GeminiChatClient stub;
  static String sessionId =
      const Uuid().v4(); // Session ID for gRPC communication with UUID
  static String host = '192.168.12.39'; // gRPC 伺服器的主機名稱或 IP 地址
  static String host1 = '10.0.2.2';
  static int port = 50051; // gRPC 伺服器的埠號
  static final SettingsService _settings = SettingsService();

  /// 在 App 啟動時呼叫此方法完成初始化
  static Future<void> init() async {
    try {
      print('host: $host1');
      print('port: $port');
      channel = ClientChannel(
        host1,
        port: port,
        options: ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );
      stub = GeminiChatClient(
        channel,
        options: CallOptions(
          timeout: Duration(seconds: 30),
        ),
      );

      // Create session and get session ID from server
      final geminiApiKey = await _settings.getGeminiApiKey();
      final mapsApiKey = await _settings.getGoogleMapsApiKey();

      final sessionRequest = CreateSessionRequest();

      if (geminiApiKey != null) {
        sessionRequest.geminiApiKey = geminiApiKey;
      }
      if (mapsApiKey != null) {
        sessionRequest.mapsApiKey = mapsApiKey;
      }

      final sessionResponse = await stub.createSession(sessionRequest);
      sessionId = sessionResponse.sessionId;
      print('Session created with ID: $sessionId');
    } catch (e) {
      print('gRPC Client initialization failed: $e');
    }
  }

  static Stream<ChatResponse> chatStream(Stream<ChatRequest> requests) {
    // Add sessionId to each request
    requests = requests.map((request) {
      request.sessionId = sessionId;
      return request;
    });
    return stub.chatStream(requests);
  }

  /// App 結束前呼叫以釋放資源
  static Future<void> shutdown() async {
    try {
      await channel.shutdown();
    } catch (e) {
      print('gRPC Client shutdown failed: $e');
    }
  }

  /// 對 chatStream 做一次簡單的文字測試
  // static void testGrpc() {
  //   final reqController = StreamController<ChatRequest>();

  //   // 啟動 listener
  //   stub.chatStream(reqController.stream).listen(
  //     (ChatResponse response) {
  //       if (response.hasNav()) {
  //         print('✉️ nav.alert: ${response.nav.alert}');
  //         print('✉️ nav.description: ${response.nav.navDescription}');
  //       } else {
  //         print('✉️ Received response without nav: $response');
  //       }
  //     },
  //     onError: (err) => print('❌ gRPC Error: $err'),
  //     onDone: () => print('🔚 gRPC stream closed'),
  //     cancelOnError: true,
  //   );

  //   // 發送測試訊息
  //   final req = ChatRequest();
  //   req.sessionId = 'test_session_id' + sessionId;
  //   req.text = 'Hello,  gRPC!';
  //   req.location = (LocationInput()
  //     ..lat = 25.0478
  //     ..lng = 121.5319);
  //   reqController.add(req);

  //   // 延遲後關閉 stream controller
  //   Future.delayed(const Duration(seconds: 1), () {
  //     reqController.close();
  //   });
  // }
}
