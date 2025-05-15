/// lib/services/gemini_live_client.dart
///
/// 這支程式碼封裝了對後端 gRPC Gemini Live 服務的呼叫，
/// 提供初始化連線、建立雙向串流以及關閉連線等功能。

import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:blind_assist_app/generated/blind_assist.pbgrpc.dart';

/// GeminiLiveClientWrapper
///
/// 此類別負責建立與管理 gRPC Channel 連線，並回傳 stub 以便呼叫 ChatStream。
class GeminiLiveClientWrapper {
  /// 預設後端 host
  static const String _defaultHost =
      'blind-liveapi-grpc-617941879669.asia-east1.run.app';

  /// 預設 gRPC 服務埠號
  static const int _defaultPort = 443;

  /// gRPC stub，用來呼叫 proto 定義的方法
  late GeminiLiveClient stub;

  /// gRPC channel，用來與後端建立連線
  late ClientChannel channel;

  /// 建立 gRPC 連線
  ///
  /// [host]: 後端 Domain 或 IP，不要帶 http/https 前綴，預設為 Cloud Run URL
  /// [port]: gRPC 服務埠號，預設為 443
  Future<void> init({
    String host = _defaultHost,
    int port = _defaultPort,
  }) async {
    // 使用 TLS 建立安全連線
    channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.secure(),
      ),
    );

    // 產生 stub，可呼叫 chatStream
    stub = GeminiLiveClient(channel);
  }

  /// 啟動 ChatStream 雙向串流
  ///
  /// 傳入一個 ClientRequest 的 Stream (reqs)，回傳 ServerResponse 的 Stream
  /// ClientRequest 可以包含:
  /// - initialConfig: 初始化模型與轉播設定
  /// - textPart: 文字輸入
  /// - audioPart: 音訊輸入 bytes
  /// - endOfTurn: 告知 server 本輪輸入結束，準備回應
  Stream<ServerResponse> chatStream(Stream<ClientRequest> reqs) {
    return stub.chatStream(reqs);
  }

  /// 關閉 channel，釋放資源
  Future<void> shutdown() async {
    await channel.shutdown();
  }

  /// 範例方法：快速發送一次 initialConfig + endOfTurn
  ///
  /// 方便單次對話測試，回傳 ServerResponse Stream
  Stream<ServerResponse> simpleTest({
    String modelName = 'models/gemini-2.0-flash-live-001',
  }) {
    // 建立控制器用來推送請求
    final controller = StreamController<ClientRequest>();

    // 1️⃣ 發 initialConfig
    controller.add(
      ClientRequest(
        initialConfig: InitialConfigRequest(
          modelName: modelName,
        ),
      ),
    );

    // 2️⃣ 發 endOfTurn 讓 server 回應
    controller.add(
      ClientRequest(endOfTurn: true),
    );

    // 關閉 controller
    controller.close();

    // 回傳 chatStream，用完記得 shutdown channel
    return stub.chatStream(controller.stream);
  }
}
