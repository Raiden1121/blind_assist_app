//
//  Generated code. Do not modify.
//  source: blind_assist.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

enum ClientRequest_RequestData {
  initialConfig, 
  textPart, 
  imagePart, 
  clientAudioPart, 
  endOfTurn, 
  notSet
}

/// Message from client to server
class ClientRequest extends $pb.GeneratedMessage {
  factory ClientRequest({
    InitialConfigRequest? initialConfig,
    TextPart? textPart,
    ImagePart? imagePart,
    AudioPart? clientAudioPart,
    $core.bool? endOfTurn,
  }) {
    final $result = create();
    if (initialConfig != null) {
      $result.initialConfig = initialConfig;
    }
    if (textPart != null) {
      $result.textPart = textPart;
    }
    if (imagePart != null) {
      $result.imagePart = imagePart;
    }
    if (clientAudioPart != null) {
      $result.clientAudioPart = clientAudioPart;
    }
    if (endOfTurn != null) {
      $result.endOfTurn = endOfTurn;
    }
    return $result;
  }
  ClientRequest._() : super();
  factory ClientRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ClientRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, ClientRequest_RequestData> _ClientRequest_RequestDataByTag = {
    1 : ClientRequest_RequestData.initialConfig,
    2 : ClientRequest_RequestData.textPart,
    3 : ClientRequest_RequestData.imagePart,
    4 : ClientRequest_RequestData.clientAudioPart,
    5 : ClientRequest_RequestData.endOfTurn,
    0 : ClientRequest_RequestData.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ClientRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminilive'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5])
    ..aOM<InitialConfigRequest>(1, _omitFieldNames ? '' : 'initialConfig', subBuilder: InitialConfigRequest.create)
    ..aOM<TextPart>(2, _omitFieldNames ? '' : 'textPart', subBuilder: TextPart.create)
    ..aOM<ImagePart>(3, _omitFieldNames ? '' : 'imagePart', subBuilder: ImagePart.create)
    ..aOM<AudioPart>(4, _omitFieldNames ? '' : 'clientAudioPart', subBuilder: AudioPart.create)
    ..aOB(5, _omitFieldNames ? '' : 'endOfTurn')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ClientRequest clone() => ClientRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ClientRequest copyWith(void Function(ClientRequest) updates) => super.copyWith((message) => updates(message as ClientRequest)) as ClientRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientRequest create() => ClientRequest._();
  ClientRequest createEmptyInstance() => create();
  static $pb.PbList<ClientRequest> createRepeated() => $pb.PbList<ClientRequest>();
  @$core.pragma('dart2js:noInline')
  static ClientRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClientRequest>(create);
  static ClientRequest? _defaultInstance;

  ClientRequest_RequestData whichRequestData() => _ClientRequest_RequestDataByTag[$_whichOneof(0)]!;
  void clearRequestData() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  InitialConfigRequest get initialConfig => $_getN(0);
  @$pb.TagNumber(1)
  set initialConfig(InitialConfigRequest v) { $_setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasInitialConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearInitialConfig() => $_clearField(1);
  @$pb.TagNumber(1)
  InitialConfigRequest ensureInitialConfig() => $_ensure(0);

  @$pb.TagNumber(2)
  TextPart get textPart => $_getN(1);
  @$pb.TagNumber(2)
  set textPart(TextPart v) { $_setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTextPart() => $_has(1);
  @$pb.TagNumber(2)
  void clearTextPart() => $_clearField(2);
  @$pb.TagNumber(2)
  TextPart ensureTextPart() => $_ensure(1);

  @$pb.TagNumber(3)
  ImagePart get imagePart => $_getN(2);
  @$pb.TagNumber(3)
  set imagePart(ImagePart v) { $_setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasImagePart() => $_has(2);
  @$pb.TagNumber(3)
  void clearImagePart() => $_clearField(3);
  @$pb.TagNumber(3)
  ImagePart ensureImagePart() => $_ensure(2);

  @$pb.TagNumber(4)
  AudioPart get clientAudioPart => $_getN(3);
  @$pb.TagNumber(4)
  set clientAudioPart(AudioPart v) { $_setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasClientAudioPart() => $_has(3);
  @$pb.TagNumber(4)
  void clearClientAudioPart() => $_clearField(4);
  @$pb.TagNumber(4)
  AudioPart ensureClientAudioPart() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.bool get endOfTurn => $_getBF(4);
  @$pb.TagNumber(5)
  set endOfTurn($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasEndOfTurn() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndOfTurn() => $_clearField(5);
}

class InitialConfigRequest extends $pb.GeneratedMessage {
  factory InitialConfigRequest({
    $core.String? modelName,
    $core.Iterable<$core.String>? responseModalities,
  }) {
    final $result = create();
    if (modelName != null) {
      $result.modelName = modelName;
    }
    if (responseModalities != null) {
      $result.responseModalities.addAll(responseModalities);
    }
    return $result;
  }
  InitialConfigRequest._() : super();
  factory InitialConfigRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InitialConfigRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InitialConfigRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminilive'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'modelName')
    ..pPS(2, _omitFieldNames ? '' : 'responseModalities')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InitialConfigRequest clone() => InitialConfigRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InitialConfigRequest copyWith(void Function(InitialConfigRequest) updates) => super.copyWith((message) => updates(message as InitialConfigRequest)) as InitialConfigRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InitialConfigRequest create() => InitialConfigRequest._();
  InitialConfigRequest createEmptyInstance() => create();
  static $pb.PbList<InitialConfigRequest> createRepeated() => $pb.PbList<InitialConfigRequest>();
  @$core.pragma('dart2js:noInline')
  static InitialConfigRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InitialConfigRequest>(create);
  static InitialConfigRequest? _defaultInstance;

  /// model_name is optional; server can use a default if not provided.
  @$pb.TagNumber(1)
  $core.String get modelName => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelName($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasModelName() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelName() => $_clearField(1);

  /// response_modalities is optional; server can use defaults like ["AUDIO", "TEXT"].
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get responseModalities => $_getList(1);
}

class TextPart extends $pb.GeneratedMessage {
  factory TextPart({
    $core.String? text,
  }) {
    final $result = create();
    if (text != null) {
      $result.text = text;
    }
    return $result;
  }
  TextPart._() : super();
  factory TextPart.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TextPart.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TextPart', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminilive'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TextPart clone() => TextPart()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TextPart copyWith(void Function(TextPart) updates) => super.copyWith((message) => updates(message as TextPart)) as TextPart;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextPart create() => TextPart._();
  TextPart createEmptyInstance() => create();
  static $pb.PbList<TextPart> createRepeated() => $pb.PbList<TextPart>();
  @$core.pragma('dart2js:noInline')
  static TextPart getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextPart>(create);
  static TextPart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);
}

class ImagePart extends $pb.GeneratedMessage {
  factory ImagePart({
    $core.List<$core.int>? imageData,
    $core.String? mimeType,
  }) {
    final $result = create();
    if (imageData != null) {
      $result.imageData = imageData;
    }
    if (mimeType != null) {
      $result.mimeType = mimeType;
    }
    return $result;
  }
  ImagePart._() : super();
  factory ImagePart.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImagePart.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImagePart', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminilive'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'imageData', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'mimeType')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ImagePart clone() => ImagePart()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ImagePart copyWith(void Function(ImagePart) updates) => super.copyWith((message) => updates(message as ImagePart)) as ImagePart;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImagePart create() => ImagePart._();
  ImagePart createEmptyInstance() => create();
  static $pb.PbList<ImagePart> createRepeated() => $pb.PbList<ImagePart>();
  @$core.pragma('dart2js:noInline')
  static ImagePart getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImagePart>(create);
  static ImagePart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get imageData => $_getN(0);
  @$pb.TagNumber(1)
  set imageData($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasImageData() => $_has(0);
  @$pb.TagNumber(1)
  void clearImageData() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get mimeType => $_getSZ(1);
  @$pb.TagNumber(2)
  set mimeType($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMimeType() => $_has(1);
  @$pb.TagNumber(2)
  void clearMimeType() => $_clearField(2);
}

class AudioPart extends $pb.GeneratedMessage {
  factory AudioPart({
    $core.List<$core.int>? audioData,
    $core.String? mimeType,
    $core.int? sampleRate,
  }) {
    final $result = create();
    if (audioData != null) {
      $result.audioData = audioData;
    }
    if (mimeType != null) {
      $result.mimeType = mimeType;
    }
    if (sampleRate != null) {
      $result.sampleRate = sampleRate;
    }
    return $result;
  }
  AudioPart._() : super();
  factory AudioPart.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AudioPart.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AudioPart', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminilive'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'audioData', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'mimeType')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'sampleRate', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AudioPart clone() => AudioPart()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AudioPart copyWith(void Function(AudioPart) updates) => super.copyWith((message) => updates(message as AudioPart)) as AudioPart;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioPart create() => AudioPart._();
  AudioPart createEmptyInstance() => create();
  static $pb.PbList<AudioPart> createRepeated() => $pb.PbList<AudioPart>();
  @$core.pragma('dart2js:noInline')
  static AudioPart getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AudioPart>(create);
  static AudioPart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get audioData => $_getN(0);
  @$pb.TagNumber(1)
  set audioData($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAudioData() => $_has(0);
  @$pb.TagNumber(1)
  void clearAudioData() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get mimeType => $_getSZ(1);
  @$pb.TagNumber(2)
  set mimeType($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMimeType() => $_has(1);
  @$pb.TagNumber(2)
  void clearMimeType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sampleRate => $_getIZ(2);
  @$pb.TagNumber(3)
  set sampleRate($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSampleRate() => $_has(2);
  @$pb.TagNumber(3)
  void clearSampleRate() => $_clearField(3);
}

enum ServerResponse_ResponseData {
  textPart, 
  geminiAudioPart, 
  errorPart, 
  turnComplete, 
  notSet
}

/// Message from server to client
class ServerResponse extends $pb.GeneratedMessage {
  factory ServerResponse({
    TextPart? textPart,
    AudioPart? geminiAudioPart,
    ErrorPart? errorPart,
    $core.bool? turnComplete,
  }) {
    final $result = create();
    if (textPart != null) {
      $result.textPart = textPart;
    }
    if (geminiAudioPart != null) {
      $result.geminiAudioPart = geminiAudioPart;
    }
    if (errorPart != null) {
      $result.errorPart = errorPart;
    }
    if (turnComplete != null) {
      $result.turnComplete = turnComplete;
    }
    return $result;
  }
  ServerResponse._() : super();
  factory ServerResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ServerResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, ServerResponse_ResponseData> _ServerResponse_ResponseDataByTag = {
    1 : ServerResponse_ResponseData.textPart,
    2 : ServerResponse_ResponseData.geminiAudioPart,
    3 : ServerResponse_ResponseData.errorPart,
    4 : ServerResponse_ResponseData.turnComplete,
    0 : ServerResponse_ResponseData.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ServerResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminilive'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..aOM<TextPart>(1, _omitFieldNames ? '' : 'textPart', subBuilder: TextPart.create)
    ..aOM<AudioPart>(2, _omitFieldNames ? '' : 'geminiAudioPart', subBuilder: AudioPart.create)
    ..aOM<ErrorPart>(3, _omitFieldNames ? '' : 'errorPart', subBuilder: ErrorPart.create)
    ..aOB(4, _omitFieldNames ? '' : 'turnComplete')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ServerResponse clone() => ServerResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ServerResponse copyWith(void Function(ServerResponse) updates) => super.copyWith((message) => updates(message as ServerResponse)) as ServerResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerResponse create() => ServerResponse._();
  ServerResponse createEmptyInstance() => create();
  static $pb.PbList<ServerResponse> createRepeated() => $pb.PbList<ServerResponse>();
  @$core.pragma('dart2js:noInline')
  static ServerResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ServerResponse>(create);
  static ServerResponse? _defaultInstance;

  ServerResponse_ResponseData whichResponseData() => _ServerResponse_ResponseDataByTag[$_whichOneof(0)]!;
  void clearResponseData() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  TextPart get textPart => $_getN(0);
  @$pb.TagNumber(1)
  set textPart(TextPart v) { $_setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTextPart() => $_has(0);
  @$pb.TagNumber(1)
  void clearTextPart() => $_clearField(1);
  @$pb.TagNumber(1)
  TextPart ensureTextPart() => $_ensure(0);

  @$pb.TagNumber(2)
  AudioPart get geminiAudioPart => $_getN(1);
  @$pb.TagNumber(2)
  set geminiAudioPart(AudioPart v) { $_setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGeminiAudioPart() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeminiAudioPart() => $_clearField(2);
  @$pb.TagNumber(2)
  AudioPart ensureGeminiAudioPart() => $_ensure(1);

  @$pb.TagNumber(3)
  ErrorPart get errorPart => $_getN(2);
  @$pb.TagNumber(3)
  set errorPart(ErrorPart v) { $_setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasErrorPart() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrorPart() => $_clearField(3);
  @$pb.TagNumber(3)
  ErrorPart ensureErrorPart() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get turnComplete => $_getBF(3);
  @$pb.TagNumber(4)
  set turnComplete($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTurnComplete() => $_has(3);
  @$pb.TagNumber(4)
  void clearTurnComplete() => $_clearField(4);
}

class ErrorPart extends $pb.GeneratedMessage {
  factory ErrorPart({
    $core.String? message,
    $core.int? code,
  }) {
    final $result = create();
    if (message != null) {
      $result.message = message;
    }
    if (code != null) {
      $result.code = code;
    }
    return $result;
  }
  ErrorPart._() : super();
  factory ErrorPart.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ErrorPart.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ErrorPart', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminilive'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'code', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ErrorPart clone() => ErrorPart()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ErrorPart copyWith(void Function(ErrorPart) updates) => super.copyWith((message) => updates(message as ErrorPart)) as ErrorPart;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ErrorPart create() => ErrorPart._();
  ErrorPart createEmptyInstance() => create();
  static $pb.PbList<ErrorPart> createRepeated() => $pb.PbList<ErrorPart>();
  @$core.pragma('dart2js:noInline')
  static ErrorPart getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ErrorPart>(create);
  static ErrorPart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get code => $_getIZ(1);
  @$pb.TagNumber(2)
  set code($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
