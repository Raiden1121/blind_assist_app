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
  static final _$createSession = $grpc.ClientMethod<$0.CreateSessionRequest, $0.CreateSessionResponse>(
      '/geminiChat.GeminiChat/CreateSession',
      ($0.CreateSessionRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CreateSessionResponse.fromBuffer(value));
  static final _$chatStream = $grpc.ClientMethod<$0.ChatRequest, $0.ChatResponse>(
      '/geminiChat.GeminiChat/ChatStream',
      ($0.ChatRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ChatResponse.fromBuffer(value));

  GeminiChatClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.CreateSessionResponse> createSession($0.CreateSessionRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createSession, request, options: options);
  }

  $grpc.ResponseStream<$0.ChatResponse> chatStream($async.Stream<$0.ChatRequest> request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$chatStream, request, options: options);
  }
}

@$pb.GrpcServiceName('geminiChat.GeminiChat')
abstract class GeminiChatServiceBase extends $grpc.Service {
  $core.String get $name => 'geminiChat.GeminiChat';

  GeminiChatServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.CreateSessionRequest, $0.CreateSessionResponse>(
        'CreateSession',
        createSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CreateSessionRequest.fromBuffer(value),
        ($0.CreateSessionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChatRequest, $0.ChatResponse>(
        'ChatStream',
        chatStream,
        true,
        true,
        ($core.List<$core.int> value) => $0.ChatRequest.fromBuffer(value),
        ($0.ChatResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.CreateSessionResponse> createSession_Pre($grpc.ServiceCall $call, $async.Future<$0.CreateSessionRequest> $request) async {
    return createSession($call, await $request);
  }

  $async.Future<$0.CreateSessionResponse> createSession($grpc.ServiceCall call, $0.CreateSessionRequest request);
  $async.Stream<$0.ChatResponse> chatStream($grpc.ServiceCall call, $async.Stream<$0.ChatRequest> request);
}
