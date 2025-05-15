import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:blind_assist_app/generated/gemini_chat.pbgrpc.dart';


class GrpcClient {
  static late ClientChannel channel;
  static late GeminiChatClient stub;

  static String host = '10.0.2.2'; // gRPC 伺服器的主機名稱或 IP 地址
  static int port = 50051; // gRPC 伺服器的埠號
 /// 在 App 啟動時呼叫此方法完成初始化
  static Future<void> init() async {
    try {
      print('host: $host');
      print('port: $port');
      channel = ClientChannel(
        host,
        port: port,
        options: ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );
      stub = GeminiChatClient(channel, 
        options: CallOptions(
          timeout: Duration(seconds: 30),
        ),
      );
    } catch (e) {
      print('gRPC Client initialization failed: $e');
    }
  }

  static Stream<ChatResponse> chatStream(Stream<ChatRequest> requests) {
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
  static void testGrpc() {
    final reqController = StreamController<ChatRequest>();

    // 啟動 listener
    stub
        .chatStream(reqController.stream)
        .listen(
      (ChatResponse response) {
        if (response.hasNav()) {
          print('✉️ nav.alert: ${response.nav.alert}');
          print('✉️ nav.description: ${response.nav.navDescription}');
        } else {
          print('✉️ Received response without nav: $response');
        }
      },
      onError: (err) => print('❌ gRPC Error: $err'),
      onDone: () => print('🔚 gRPC stream closed'),
      cancelOnError: true,
    );

    // 發送測試訊息
    final req = ChatRequest();
    req.text = 'Hello,  gRPC!';
    req.location = (LocationInput()
      ..lat = 25.0478
      ..lng = 121.5319);
    reqController.add(req);

    // 延遲後關閉 stream controller
    Future.delayed(const Duration(seconds: 1), () {
      reqController.close();
    });
  }
}
