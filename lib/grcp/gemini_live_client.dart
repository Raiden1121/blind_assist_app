// lib/services/gemini_live_client.dart
import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:blind_assist_app/generated/blind_assist.pbgrpc.dart';

class GeminiLiveClientWrapper {
  late GeminiLiveClient stub;
  late ClientChannel channel;

  /// 初始化連線，host 改成你部署的 domain（Cloud Run／VM IP）
  Future<void> init({required String host}) async {
    channel = ClientChannel(
      'blind-grpc-server-617941879669.asia-east1.run.app', // host
      port: 443,
      options: const ChannelOptions(
        credentials: ChannelCredentials.secure(),
      ),
    );
    stub = GeminiLiveClient(channel);
  }

  /// 建立雙向串流
  Stream<ServerResponse> chatStream(Stream<ClientRequest> reqs) {
    return stub.chatStream(reqs);
  }

  /// 關閉 channel
  Future<void> shutdown() => channel.shutdown();
}
