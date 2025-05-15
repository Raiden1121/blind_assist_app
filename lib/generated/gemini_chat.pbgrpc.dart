//
//  Generated code. Do not modify.
//  source: gemini_chat.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'gemini_chat.pb.dart' as $0;

export 'gemini_chat.pb.dart';

@$pb.GrpcServiceName('geminiChat.GeminiChat')
class GeminiChatClient extends $grpc.Client {
  static final _$chatStream = $grpc.ClientMethod<$0.ChatRequest, $0.ChatResponse>(
      '/geminiChat.GeminiChat/ChatStream',
      ($0.ChatRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ChatResponse.fromBuffer(value));

  GeminiChatClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseStream<$0.ChatResponse> chatStream($async.Stream<$0.ChatRequest> request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$chatStream, request, options: options);
  }
}

@$pb.GrpcServiceName('geminiChat.GeminiChat')
abstract class GeminiChatServiceBase extends $grpc.Service {
  $core.String get $name => 'geminiChat.GeminiChat';

  GeminiChatServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ChatRequest, $0.ChatResponse>(
        'ChatStream',
        chatStream,
        true,
        true,
        ($core.List<$core.int> value) => $0.ChatRequest.fromBuffer(value),
        ($0.ChatResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.ChatResponse> chatStream($grpc.ServiceCall call, $async.Stream<$0.ChatRequest> request);
}
