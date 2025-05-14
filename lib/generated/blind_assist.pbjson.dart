//
//  Generated code. Do not modify.
//  source: blind_assist.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use clientRequestDescriptor instead')
const ClientRequest$json = {
  '1': 'ClientRequest',
  '2': [
    {'1': 'initial_config', '3': 1, '4': 1, '5': 11, '6': '.geminilive.InitialConfigRequest', '9': 0, '10': 'initialConfig'},
    {'1': 'text_part', '3': 2, '4': 1, '5': 11, '6': '.geminilive.TextPart', '9': 0, '10': 'textPart'},
    {'1': 'image_part', '3': 3, '4': 1, '5': 11, '6': '.geminilive.ImagePart', '9': 0, '10': 'imagePart'},
    {'1': 'client_audio_part', '3': 4, '4': 1, '5': 11, '6': '.geminilive.AudioPart', '9': 0, '10': 'clientAudioPart'},
    {'1': 'end_of_turn', '3': 5, '4': 1, '5': 8, '9': 0, '10': 'endOfTurn'},
  ],
  '8': [
    {'1': 'request_data'},
  ],
};

/// Descriptor for `ClientRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientRequestDescriptor = $convert.base64Decode(
    'Cg1DbGllbnRSZXF1ZXN0EkkKDmluaXRpYWxfY29uZmlnGAEgASgLMiAuZ2VtaW5pbGl2ZS5Jbm'
    'l0aWFsQ29uZmlnUmVxdWVzdEgAUg1pbml0aWFsQ29uZmlnEjMKCXRleHRfcGFydBgCIAEoCzIU'
    'LmdlbWluaWxpdmUuVGV4dFBhcnRIAFIIdGV4dFBhcnQSNgoKaW1hZ2VfcGFydBgDIAEoCzIVLm'
    'dlbWluaWxpdmUuSW1hZ2VQYXJ0SABSCWltYWdlUGFydBJDChFjbGllbnRfYXVkaW9fcGFydBgE'
    'IAEoCzIVLmdlbWluaWxpdmUuQXVkaW9QYXJ0SABSD2NsaWVudEF1ZGlvUGFydBIgCgtlbmRfb2'
    'ZfdHVybhgFIAEoCEgAUgllbmRPZlR1cm5CDgoMcmVxdWVzdF9kYXRh');

@$core.Deprecated('Use initialConfigRequestDescriptor instead')
const InitialConfigRequest$json = {
  '1': 'InitialConfigRequest',
  '2': [
    {'1': 'model_name', '3': 1, '4': 1, '5': 9, '10': 'modelName'},
    {'1': 'response_modalities', '3': 2, '4': 3, '5': 9, '10': 'responseModalities'},
  ],
};

/// Descriptor for `InitialConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List initialConfigRequestDescriptor = $convert.base64Decode(
    'ChRJbml0aWFsQ29uZmlnUmVxdWVzdBIdCgptb2RlbF9uYW1lGAEgASgJUgltb2RlbE5hbWUSLw'
    'oTcmVzcG9uc2VfbW9kYWxpdGllcxgCIAMoCVIScmVzcG9uc2VNb2RhbGl0aWVz');

@$core.Deprecated('Use textPartDescriptor instead')
const TextPart$json = {
  '1': 'TextPart',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `TextPart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textPartDescriptor = $convert.base64Decode(
    'CghUZXh0UGFydBISCgR0ZXh0GAEgASgJUgR0ZXh0');

@$core.Deprecated('Use imagePartDescriptor instead')
const ImagePart$json = {
  '1': 'ImagePart',
  '2': [
    {'1': 'image_data', '3': 1, '4': 1, '5': 12, '10': 'imageData'},
    {'1': 'mime_type', '3': 2, '4': 1, '5': 9, '10': 'mimeType'},
  ],
};

/// Descriptor for `ImagePart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imagePartDescriptor = $convert.base64Decode(
    'CglJbWFnZVBhcnQSHQoKaW1hZ2VfZGF0YRgBIAEoDFIJaW1hZ2VEYXRhEhsKCW1pbWVfdHlwZR'
    'gCIAEoCVIIbWltZVR5cGU=');

@$core.Deprecated('Use audioPartDescriptor instead')
const AudioPart$json = {
  '1': 'AudioPart',
  '2': [
    {'1': 'audio_data', '3': 1, '4': 1, '5': 12, '10': 'audioData'},
    {'1': 'mime_type', '3': 2, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'sample_rate', '3': 3, '4': 1, '5': 5, '10': 'sampleRate'},
  ],
};

/// Descriptor for `AudioPart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioPartDescriptor = $convert.base64Decode(
    'CglBdWRpb1BhcnQSHQoKYXVkaW9fZGF0YRgBIAEoDFIJYXVkaW9EYXRhEhsKCW1pbWVfdHlwZR'
    'gCIAEoCVIIbWltZVR5cGUSHwoLc2FtcGxlX3JhdGUYAyABKAVSCnNhbXBsZVJhdGU=');

@$core.Deprecated('Use serverResponseDescriptor instead')
const ServerResponse$json = {
  '1': 'ServerResponse',
  '2': [
    {'1': 'text_part', '3': 1, '4': 1, '5': 11, '6': '.geminilive.TextPart', '9': 0, '10': 'textPart'},
    {'1': 'gemini_audio_part', '3': 2, '4': 1, '5': 11, '6': '.geminilive.AudioPart', '9': 0, '10': 'geminiAudioPart'},
    {'1': 'error_part', '3': 3, '4': 1, '5': 11, '6': '.geminilive.ErrorPart', '9': 0, '10': 'errorPart'},
    {'1': 'turn_complete', '3': 4, '4': 1, '5': 8, '9': 0, '10': 'turnComplete'},
  ],
  '8': [
    {'1': 'response_data'},
  ],
};

/// Descriptor for `ServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverResponseDescriptor = $convert.base64Decode(
    'Cg5TZXJ2ZXJSZXNwb25zZRIzCgl0ZXh0X3BhcnQYASABKAsyFC5nZW1pbmlsaXZlLlRleHRQYX'
    'J0SABSCHRleHRQYXJ0EkMKEWdlbWluaV9hdWRpb19wYXJ0GAIgASgLMhUuZ2VtaW5pbGl2ZS5B'
    'dWRpb1BhcnRIAFIPZ2VtaW5pQXVkaW9QYXJ0EjYKCmVycm9yX3BhcnQYAyABKAsyFS5nZW1pbm'
    'lsaXZlLkVycm9yUGFydEgAUgllcnJvclBhcnQSJQoNdHVybl9jb21wbGV0ZRgEIAEoCEgAUgx0'
    'dXJuQ29tcGxldGVCDwoNcmVzcG9uc2VfZGF0YQ==');

@$core.Deprecated('Use errorPartDescriptor instead')
const ErrorPart$json = {
  '1': 'ErrorPart',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
    {'1': 'code', '3': 2, '4': 1, '5': 5, '10': 'code'},
  ],
};

/// Descriptor for `ErrorPart`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List errorPartDescriptor = $convert.base64Decode(
    'CglFcnJvclBhcnQSGAoHbWVzc2FnZRgBIAEoCVIHbWVzc2FnZRISCgRjb2RlGAIgASgFUgRjb2'
    'Rl');

