// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtifactInput _$ArtifactInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtifactInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['artifactId', 'base64', 'mimeType', 'sha256'],
      );
      final val = ArtifactInput(
        artifactId: $checkedConvert('artifactId', (v) => v as String),
        base64: $checkedConvert('base64', (v) => v as String),
        mimeType: $checkedConvert(
          'mimeType',
          (v) => $enumDecode(_$ArtifactInputMimeTypeEnumEnumMap, v),
        ),
        sha256: $checkedConvert('sha256', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ArtifactInputToJson(ArtifactInput instance) =>
    <String, dynamic>{
      'artifactId': instance.artifactId,
      'base64': instance.base64,
      'mimeType': _$ArtifactInputMimeTypeEnumEnumMap[instance.mimeType]!,
      'sha256': instance.sha256,
    };

const _$ArtifactInputMimeTypeEnumEnumMap = {
  ArtifactInputMimeTypeEnum.imageSlashPng: 'image/png',
  ArtifactInputMimeTypeEnum.applicationSlashJson: 'application/json',
};
