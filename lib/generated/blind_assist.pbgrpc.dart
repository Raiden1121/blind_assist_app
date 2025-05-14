//
//  Generated code. Do not modify.
//  source: blind_assist.proto
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

import 'blind_assist.pb.dart' as $0;

export 'blind_assist.pb.dart';

@$pb.GrpcServiceName('geminilive.GeminiLive')
class GeminiLiveClient extends $grpc.Client {
  static final _$chatStream = $grpc.ClientMethod<$0.ClientRequest, $0.ServerResponse>(
      '/geminilive.GeminiLive/ChatStream',
      ($0.ClientRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ServerResponse.fromBuffer(value));

  GeminiLiveClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseStream<$0.ServerResponse> chatStream($async.Stream<$0.ClientRequest> request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$chatStream, request, options: options);
  }
}

@$pb.GrpcServiceName('geminilive.GeminiLive')
abstract class GeminiLiveServiceBase extends $grpc.Service {
  $core.String get $name => 'geminilive.GeminiLive';

  GeminiLiveServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ClientRequest, $0.ServerResponse>(
        'ChatStream',
        chatStream,
        true,
        true,
        ($core.List<$core.int> value) => $0.ClientRequest.fromBuffer(value),
        ($0.ServerResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.ServerResponse> chatStream($grpc.ServiceCall call, $async.Stream<$0.ClientRequest> request);
}
