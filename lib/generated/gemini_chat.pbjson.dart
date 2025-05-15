//
//  Generated code. Do not modify.
//  source: gemini_chat.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use audioInputDescriptor instead')
const AudioInput$json = {
  '1': 'AudioInput',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    {'1': 'format', '3': 2, '4': 1, '5': 9, '10': 'format'},
    {'1': 'sample_rate_hz', '3': 3, '4': 1, '5': 5, '10': 'sampleRateHz'},
  ],
};

/// Descriptor for `AudioInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioInputDescriptor = $convert.base64Decode(
    'CgpBdWRpb0lucHV0EhIKBGRhdGEYASABKAxSBGRhdGESFgoGZm9ybWF0GAIgASgJUgZmb3JtYX'
    'QSJAoOc2FtcGxlX3JhdGVfaHoYAyABKAVSDHNhbXBsZVJhdGVIeg==');

@$core.Deprecated('Use imageInputDescriptor instead')
const ImageInput$json = {
  '1': 'ImageInput',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    {'1': 'format', '3': 2, '4': 1, '5': 9, '10': 'format'},
    {'1': 'width', '3': 3, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 4, '4': 1, '5': 5, '10': 'height'},
  ],
};

/// Descriptor for `ImageInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageInputDescriptor = $convert.base64Decode(
    'CgpJbWFnZUlucHV0EhIKBGRhdGEYASABKAxSBGRhdGESFgoGZm9ybWF0GAIgASgJUgZmb3JtYX'
    'QSFAoFd2lkdGgYAyABKAVSBXdpZHRoEhYKBmhlaWdodBgEIAEoBVIGaGVpZ2h0');

@$core.Deprecated('Use multiImageInputDescriptor instead')
const MultiImageInput$json = {
  '1': 'MultiImageInput',
  '2': [
    {'1': 'images', '3': 1, '4': 3, '5': 11, '6': '.geminiChat.ImageInput', '10': 'images'},
  ],
};

/// Descriptor for `MultiImageInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List multiImageInputDescriptor = $convert.base64Decode(
    'Cg9NdWx0aUltYWdlSW5wdXQSLgoGaW1hZ2VzGAEgAygLMhYuZ2VtaW5pQ2hhdC5JbWFnZUlucH'
    'V0UgZpbWFnZXM=');

@$core.Deprecated('Use locationInputDescriptor instead')
const LocationInput$json = {
  '1': 'LocationInput',
  '2': [
    {'1': 'lat', '3': 1, '4': 1, '5': 2, '10': 'lat'},
    {'1': 'lng', '3': 2, '4': 1, '5': 2, '10': 'lng'},
  ],
};

/// Descriptor for `LocationInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List locationInputDescriptor = $convert.base64Decode(
    'Cg1Mb2NhdGlvbklucHV0EhAKA2xhdBgBIAEoAlIDbGF0EhAKA2xuZxgCIAEoAlIDbG5n');

@$core.Deprecated('Use chatRequestDescriptor instead')
const ChatRequest$json = {
  '1': 'ChatRequest',
  '2': [
    {'1': 'audio', '3': 1, '4': 1, '5': 11, '6': '.geminiChat.AudioInput', '9': 0, '10': 'audio', '17': true},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'text', '17': true},
    {'1': 'location', '3': 3, '4': 1, '5': 11, '6': '.geminiChat.LocationInput', '9': 2, '10': 'location', '17': true},
    {'1': 'multi_images', '3': 4, '4': 1, '5': 11, '6': '.geminiChat.MultiImageInput', '9': 3, '10': 'multiImages', '17': true},
  ],
  '8': [
    {'1': '_audio'},
    {'1': '_text'},
    {'1': '_location'},
    {'1': '_multi_images'},
  ],
};

/// Descriptor for `ChatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatRequestDescriptor = $convert.base64Decode(
    'CgtDaGF0UmVxdWVzdBIxCgVhdWRpbxgBIAEoCzIWLmdlbWluaUNoYXQuQXVkaW9JbnB1dEgAUg'
    'VhdWRpb4gBARIXCgR0ZXh0GAIgASgJSAFSBHRleHSIAQESOgoIbG9jYXRpb24YAyABKAsyGS5n'
    'ZW1pbmlDaGF0LkxvY2F0aW9uSW5wdXRIAlIIbG9jYXRpb26IAQESQwoMbXVsdGlfaW1hZ2VzGA'
    'QgASgLMhsuZ2VtaW5pQ2hhdC5NdWx0aUltYWdlSW5wdXRIA1ILbXVsdGlJbWFnZXOIAQFCCAoG'
    'X2F1ZGlvQgcKBV90ZXh0QgsKCV9sb2NhdGlvbkIPCg1fbXVsdGlfaW1hZ2Vz');

@$core.Deprecated('Use navigationResponseDescriptor instead')
const NavigationResponse$json = {
  '1': 'NavigationResponse',
  '2': [
    {'1': 'alert', '3': 1, '4': 1, '5': 9, '10': 'alert'},
    {'1': 'nav_status', '3': 2, '4': 1, '5': 8, '10': 'navStatus'},
    {'1': 'nav_description', '3': 3, '4': 1, '5': 9, '10': 'navDescription'},
  ],
};

/// Descriptor for `NavigationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List navigationResponseDescriptor = $convert.base64Decode(
    'ChJOYXZpZ2F0aW9uUmVzcG9uc2USFAoFYWxlcnQYASABKAlSBWFsZXJ0Eh0KCm5hdl9zdGF0dX'
    'MYAiABKAhSCW5hdlN0YXR1cxInCg9uYXZfZGVzY3JpcHRpb24YAyABKAlSDm5hdkRlc2NyaXB0'
    'aW9u');

@$core.Deprecated('Use chatResponseDescriptor instead')
const ChatResponse$json = {
  '1': 'ChatResponse',
  '2': [
    {'1': 'nav', '3': 1, '4': 1, '5': 11, '6': '.geminiChat.NavigationResponse', '10': 'nav'},
  ],
};

/// Descriptor for `ChatResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatResponseDescriptor = $convert.base64Decode(
    'CgxDaGF0UmVzcG9uc2USMAoDbmF2GAEgASgLMh4uZ2VtaW5pQ2hhdC5OYXZpZ2F0aW9uUmVzcG'
    '9uc2VSA25hdg==');

