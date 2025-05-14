// =======================================================
// gemini_live_client.dart
// 此檔案實作「gRPC GeminiLive 客戶端」
// 功能：
// 1️⃣ 初始化與 Python gRPC 服務的連線
// 2️⃣ 提供 chatStream 方法（雙向串流）
// 3️⃣ 支援關閉 channel
// 4️⃣ 附帶 Flutter Widget 範例
// =======================================================

import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import '../generated/blind_assist.pbgrpc.dart';
import 'dart:async';

class GeminiLiveClientWrapper {
  late GeminiLiveClient stub;
  late ClientChannel channel;

  /// 1️⃣ 初始化連線
  Future<void> init() async {
    channel = ClientChannel(
      'localhost', // Python server IP
      port: 50051,
      options: const ChannelOptions(
        credentials:
            ChannelCredentials.insecure(), // Use secure if you set up TLS
      ),
    );
    stub = GeminiLiveClient(channel);
  }

  /// 2️⃣ 雙向串流：傳送 ClientRequest 並接收 ServerResponse
  Stream<ServerResponse> chatStream(Stream<ClientRequest> requestStream) {
    return stub.chatStream(requestStream);
  }

  /// 3️⃣ 關閉 channel
  Future<void> shutdown() async {
    await channel.shutdown();
  }
}

/// 4️⃣ Flutter Widget 範例
class GeminiLiveTestWidget extends StatefulWidget {
  const GeminiLiveTestWidget({Key? key}) : super(key: key);

  @override
  State<GeminiLiveTestWidget> createState() => _GeminiLiveTestWidgetState();
}

class _GeminiLiveTestWidgetState extends State<GeminiLiveTestWidget> {
  final GeminiLiveClientWrapper client = GeminiLiveClientWrapper();
  String responseText = '';

  @override
  void initState() {
    super.initState();
    client.init();
  }

  @override
  void dispose() {
    client.shutdown();
    super.dispose();
  }

  void _sendTest() async {
    // 建立一個 Stream，傳送一個 TextPart
    final requestController = StreamController<ClientRequest>();
    final responses = client.chatStream(requestController.stream);

    // 傳送一個 TextPart
    requestController.add(
        ClientRequest()..textPart = (TextPart()..text = "Hello from Flutter!"));

    // 關閉 stream（如果只要發送一次）
    await requestController.close();

    // 監聽回應
    await for (final resp in responses) {
      setState(() {
        if (resp.hasTextPart()) {
          responseText = resp.textPart.text;
        } else if (resp.hasErrorPart()) {
          responseText = "Error: ${resp.errorPart.message}";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('gRPC GeminiLive Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Test ChatStream'),
              onPressed: _sendTest,
            ),
            const SizedBox(height: 20),
            Text('Server Response: $responseText'),
          ],
        ),
      ),
    );
  }
}
