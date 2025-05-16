//
//  Generated code. Do not modify.
//  source: gemini_chat.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'gemini_chat.pb.dart' as $0;
import 'gemini_chat.pbjson.dart';

export 'gemini_chat.pb.dart';

abstract class GeminiChatServiceBase extends $pb.GeneratedService {
  $async.Future<$0.ChatResponse> chatStream($pb.ServerContext ctx, $0.ChatRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ChatStream': return $0.ChatRequest();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ChatStream': return this.chatStream(ctx, request as $0.ChatRequest);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => GeminiChatServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => GeminiChatServiceBase$messageJson;
}

