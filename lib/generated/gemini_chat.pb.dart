//
//  Generated code. Do not modify.
//  source: gemini_chat.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// 音訊輸入訊息
class AudioInput extends $pb.GeneratedMessage {
  factory AudioInput({
    $core.List<$core.int>? data,
    $core.String? format,
    $core.int? sampleRateHz,
  }) {
    final $result = create();
    if (data != null) {
      $result.data = data;
    }
    if (format != null) {
      $result.format = format;
    }
    if (sampleRateHz != null) {
      $result.sampleRateHz = sampleRateHz;
    }
    return $result;
  }
  AudioInput._() : super();
  factory AudioInput.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AudioInput.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AudioInput', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminiChat'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'format')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'sampleRateHz', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AudioInput clone() => AudioInput()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AudioInput copyWith(void Function(AudioInput) updates) => super.copyWith((message) => updates(message as AudioInput)) as AudioInput;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AudioInput create() => AudioInput._();
  AudioInput createEmptyInstance() => create();
  static $pb.PbList<AudioInput> createRepeated() => $pb.PbList<AudioInput>();
  @$core.pragma('dart2js:noInline')
  static AudioInput getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AudioInput>(create);
  static AudioInput? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get format => $_getSZ(1);
  @$pb.TagNumber(2)
  set format($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sampleRateHz => $_getIZ(2);
  @$pb.TagNumber(3)
  set sampleRateHz($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSampleRateHz() => $_has(2);
  @$pb.TagNumber(3)
  void clearSampleRateHz() => $_clearField(3);
}

/// 影像輸入訊息
class ImageInput extends $pb.GeneratedMessage {
  factory ImageInput({
    $core.List<$core.int>? data,
    $core.String? format,
    $core.int? width,
    $core.int? height,
  }) {
    final $result = create();
    if (data != null) {
      $result.data = data;
    }
    if (format != null) {
      $result.format = format;
    }
    if (width != null) {
      $result.width = width;
    }
    if (height != null) {
      $result.height = height;
    }
    return $result;
  }
  ImageInput._() : super();
  factory ImageInput.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ImageInput.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ImageInput', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminiChat'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'format')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'width', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'height', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ImageInput clone() => ImageInput()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ImageInput copyWith(void Function(ImageInput) updates) => super.copyWith((message) => updates(message as ImageInput)) as ImageInput;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ImageInput create() => ImageInput._();
  ImageInput createEmptyInstance() => create();
  static $pb.PbList<ImageInput> createRepeated() => $pb.PbList<ImageInput>();
  @$core.pragma('dart2js:noInline')
  static ImageInput getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ImageInput>(create);
  static ImageInput? _defaultInstance;

  /// 原始影像二進位資料 (例如 JPEG/PNG)
  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);

  /// 影像格式 (e.g. "jpeg", "png")
  @$pb.TagNumber(2)
  $core.String get format => $_getSZ(1);
  @$pb.TagNumber(2)
  set format($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get width => $_getIZ(2);
  @$pb.TagNumber(3)
  set width($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasWidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearWidth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get height => $_getIZ(3);
  @$pb.TagNumber(4)
  set height($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasHeight() => $_has(3);
  @$pb.TagNumber(4)
  void clearHeight() => $_clearField(4);
}

class MultiImageInput extends $pb.GeneratedMessage {
  factory MultiImageInput({
    $core.Iterable<ImageInput>? images,
  }) {
    final $result = create();
    if (images != null) {
      $result.images.addAll(images);
    }
    return $result;
  }
  MultiImageInput._() : super();
  factory MultiImageInput.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MultiImageInput.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MultiImageInput', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminiChat'), createEmptyInstance: create)
    ..pc<ImageInput>(1, _omitFieldNames ? '' : 'images', $pb.PbFieldType.PM, subBuilder: ImageInput.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MultiImageInput clone() => MultiImageInput()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MultiImageInput copyWith(void Function(MultiImageInput) updates) => super.copyWith((message) => updates(message as MultiImageInput)) as MultiImageInput;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MultiImageInput create() => MultiImageInput._();
  MultiImageInput createEmptyInstance() => create();
  static $pb.PbList<MultiImageInput> createRepeated() => $pb.PbList<MultiImageInput>();
  @$core.pragma('dart2js:noInline')
  static MultiImageInput getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MultiImageInput>(create);
  static MultiImageInput? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ImageInput> get images => $_getList(0);
}

class LocationInput extends $pb.GeneratedMessage {
  factory LocationInput({
    $core.double? lat,
    $core.double? lng,
  }) {
    final $result = create();
    if (lat != null) {
      $result.lat = lat;
    }
    if (lng != null) {
      $result.lng = lng;
    }
    return $result;
  }
  LocationInput._() : super();
  factory LocationInput.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LocationInput.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LocationInput', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminiChat'), createEmptyInstance: create)
    ..a<$core.double>(1, _omitFieldNames ? '' : 'lat', $pb.PbFieldType.OF)
    ..a<$core.double>(2, _omitFieldNames ? '' : 'lng', $pb.PbFieldType.OF)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LocationInput clone() => LocationInput()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LocationInput copyWith(void Function(LocationInput) updates) => super.copyWith((message) => updates(message as LocationInput)) as LocationInput;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocationInput create() => LocationInput._();
  LocationInput createEmptyInstance() => create();
  static $pb.PbList<LocationInput> createRepeated() => $pb.PbList<LocationInput>();
  @$core.pragma('dart2js:noInline')
  static LocationInput getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LocationInput>(create);
  static LocationInput? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get lat => $_getN(0);
  @$pb.TagNumber(1)
  set lat($core.double v) { $_setFloat(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasLat() => $_has(0);
  @$pb.TagNumber(1)
  void clearLat() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get lng => $_getN(1);
  @$pb.TagNumber(2)
  set lng($core.double v) { $_setFloat(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLng() => $_has(1);
  @$pb.TagNumber(2)
  void clearLng() => $_clearField(2);
}

/// 輸入訊息封包：音訊或影像（或文字）
class ChatRequest extends $pb.GeneratedMessage {
  factory ChatRequest({
    AudioInput? audio,
    $core.String? text,
    LocationInput? location,
    MultiImageInput? multiImages,
  }) {
    final $result = create();
    if (audio != null) {
      $result.audio = audio;
    }
    if (text != null) {
      $result.text = text;
    }
    if (location != null) {
      $result.location = location;
    }
    if (multiImages != null) {
      $result.multiImages = multiImages;
    }
    return $result;
  }
  ChatRequest._() : super();
  factory ChatRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChatRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChatRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminiChat'), createEmptyInstance: create)
    ..aOM<AudioInput>(1, _omitFieldNames ? '' : 'audio', subBuilder: AudioInput.create)
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aOM<LocationInput>(3, _omitFieldNames ? '' : 'location', subBuilder: LocationInput.create)
    ..aOM<MultiImageInput>(4, _omitFieldNames ? '' : 'multiImages', subBuilder: MultiImageInput.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ChatRequest clone() => ChatRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ChatRequest copyWith(void Function(ChatRequest) updates) => super.copyWith((message) => updates(message as ChatRequest)) as ChatRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatRequest create() => ChatRequest._();
  ChatRequest createEmptyInstance() => create();
  static $pb.PbList<ChatRequest> createRepeated() => $pb.PbList<ChatRequest>();
  @$core.pragma('dart2js:noInline')
  static ChatRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChatRequest>(create);
  static ChatRequest? _defaultInstance;

  @$pb.TagNumber(1)
  AudioInput get audio => $_getN(0);
  @$pb.TagNumber(1)
  set audio(AudioInput v) { $_setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAudio() => $_has(0);
  @$pb.TagNumber(1)
  void clearAudio() => $_clearField(1);
  @$pb.TagNumber(1)
  AudioInput ensureAudio() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);

  @$pb.TagNumber(3)
  LocationInput get location => $_getN(2);
  @$pb.TagNumber(3)
  set location(LocationInput v) { $_setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasLocation() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocation() => $_clearField(3);
  @$pb.TagNumber(3)
  LocationInput ensureLocation() => $_ensure(2);

  @$pb.TagNumber(4)
  MultiImageInput get multiImages => $_getN(3);
  @$pb.TagNumber(4)
  set multiImages(MultiImageInput v) { $_setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasMultiImages() => $_has(3);
  @$pb.TagNumber(4)
  void clearMultiImages() => $_clearField(4);
  @$pb.TagNumber(4)
  MultiImageInput ensureMultiImages() => $_ensure(3);
}

class NavigationResponse extends $pb.GeneratedMessage {
  factory NavigationResponse({
    $core.String? alert,
    $core.bool? navStatus,
    $core.String? navDescription,
  }) {
    final $result = create();
    if (alert != null) {
      $result.alert = alert;
    }
    if (navStatus != null) {
      $result.navStatus = navStatus;
    }
    if (navDescription != null) {
      $result.navDescription = navDescription;
    }
    return $result;
  }
  NavigationResponse._() : super();
  factory NavigationResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NavigationResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NavigationResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminiChat'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'alert')
    ..aOB(2, _omitFieldNames ? '' : 'navStatus')
    ..aOS(3, _omitFieldNames ? '' : 'navDescription')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NavigationResponse clone() => NavigationResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NavigationResponse copyWith(void Function(NavigationResponse) updates) => super.copyWith((message) => updates(message as NavigationResponse)) as NavigationResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NavigationResponse create() => NavigationResponse._();
  NavigationResponse createEmptyInstance() => create();
  static $pb.PbList<NavigationResponse> createRepeated() => $pb.PbList<NavigationResponse>();
  @$core.pragma('dart2js:noInline')
  static NavigationResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NavigationResponse>(create);
  static NavigationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get alert => $_getSZ(0);
  @$pb.TagNumber(1)
  set alert($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAlert() => $_has(0);
  @$pb.TagNumber(1)
  void clearAlert() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get navStatus => $_getBF(1);
  @$pb.TagNumber(2)
  set navStatus($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNavStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearNavStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get navDescription => $_getSZ(2);
  @$pb.TagNumber(3)
  set navDescription($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNavDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearNavDescription() => $_clearField(3);
}

class ChatResponse extends $pb.GeneratedMessage {
  factory ChatResponse({
    NavigationResponse? nav,
  }) {
    final $result = create();
    if (nav != null) {
      $result.nav = nav;
    }
    return $result;
  }
  ChatResponse._() : super();
  factory ChatResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ChatResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ChatResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'geminiChat'), createEmptyInstance: create)
    ..aOM<NavigationResponse>(1, _omitFieldNames ? '' : 'nav', subBuilder: NavigationResponse.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ChatResponse clone() => ChatResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ChatResponse copyWith(void Function(ChatResponse) updates) => super.copyWith((message) => updates(message as ChatResponse)) as ChatResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChatResponse create() => ChatResponse._();
  ChatResponse createEmptyInstance() => create();
  static $pb.PbList<ChatResponse> createRepeated() => $pb.PbList<ChatResponse>();
  @$core.pragma('dart2js:noInline')
  static ChatResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChatResponse>(create);
  static ChatResponse? _defaultInstance;

  @$pb.TagNumber(1)
  NavigationResponse get nav => $_getN(0);
  @$pb.TagNumber(1)
  set nav(NavigationResponse v) { $_setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasNav() => $_has(0);
  @$pb.TagNumber(1)
  void clearNav() => $_clearField(1);
  @$pb.TagNumber(1)
  NavigationResponse ensureNav() => $_ensure(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
