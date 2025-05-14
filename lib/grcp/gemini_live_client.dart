// lib/services/gemini_live_client.dart

import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:blind_assist_app/generated/blind_assist.pbgrpc.dart';

class GeminiLiveClientWrapper {
  late GeminiLiveClient stub;
  late ClientChannel channel;

  /// 初始化 gRPC 連線
  ///
  /// [host]: 你的後端 Domain 或 IP，不要帶 http/https 前綴
  /// [port]: gRPC 服務埠號，預設 443（HTTPS 常用埠）
  Future<void> init({
    required String host,
    int port = 443,
  }) async {
    // 建立一個安全（TLS）連線的 Channel
    channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.secure(),
      ),
    );

    // 產生對應的 stub，用來呼叫 proto 定義的方法
    stub = GeminiLiveClient(channel);
  }

  /// 建立雙向串流
  ///
  /// 傳入一個 ClientRequest 的 stream，回傳 ServerResponse 的 stream
  Stream<ServerResponse> chatStream(Stream<ClientRequest> reqs) {
    return stub.chatStream(reqs);
  }

  /// 關閉 channel，釋放資源
  Future<void> shutdown() => channel.shutdown();
}
