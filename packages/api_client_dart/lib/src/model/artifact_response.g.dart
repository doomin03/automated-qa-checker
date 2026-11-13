// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtifactResponse _$ArtifactResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtifactResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'artifactId',
          'mimeType',
          'name',
          'sha256',
          'size',
          'uploaded',
        ],
      );
      final val = ArtifactResponse(
        artifactId: $checkedConvert('artifactId', (v) => v as String),
        mimeType: $checkedConvert('mimeType', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        sha256: $checkedConvert('sha256', (v) => v as String),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
        uploaded: $checkedConvert('uploaded', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$ArtifactResponseToJson(ArtifactResponse instance) =>
    <String, dynamic>{
      'artifactId': instance.artifactId,
      'mimeType': instance.mimeType,
      'name': instance.name,
      'sha256': instance.sha256,
      'size': instance.size,
      'uploaded': instance.uploaded,
    };
