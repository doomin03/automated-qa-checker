// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_download.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtifactDownload _$ArtifactDownloadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ArtifactDownload', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'artifactId',
          'base64',
          'mimeType',
          'name',
          'sha256',
          'size',
          'uploaded',
        ],
      );
      final val = ArtifactDownload(
        artifactId: $checkedConvert('artifactId', (v) => v as String),
        base64: $checkedConvert('base64', (v) => v as String),
        mimeType: $checkedConvert('mimeType', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        sha256: $checkedConvert('sha256', (v) => v as String),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
        uploaded: $checkedConvert('uploaded', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$ArtifactDownloadToJson(ArtifactDownload instance) =>
    <String, dynamic>{
      'artifactId': instance.artifactId,
      'base64': instance.base64,
      'mimeType': instance.mimeType,
      'name': instance.name,
      'sha256': instance.sha256,
      'size': instance.size,
      'uploaded': instance.uploaded,
    };
