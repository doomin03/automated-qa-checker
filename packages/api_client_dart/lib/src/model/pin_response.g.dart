// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinResponse _$PinResponseFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PinResponse',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['packageId', 'sha256', 'versionId']);
    final val = PinResponse(
      packageId: $checkedConvert('packageId', (v) => v as String),
      sha256: $checkedConvert('sha256', (v) => v as String),
      versionId: $checkedConvert('versionId', (v) => v as String),
    );
    return val;
  },
);

Map<String, dynamic> _$PinResponseToJson(PinResponse instance) =>
    <String, dynamic>{
      'packageId': instance.packageId,
      'sha256': instance.sha256,
      'versionId': instance.versionId,
    };
