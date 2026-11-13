// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_artifact_manifest_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentArtifactManifestDto _$AgentArtifactManifestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentArtifactManifestDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['caseId', 'mimeType', 'path', 'sha256', 'size'],
  );
  final val = AgentArtifactManifestDto(
    caseId: $checkedConvert('caseId', (v) => v as String),
    mimeType: $checkedConvert(
      'mimeType',
      (v) => $enumDecode(_$AgentArtifactManifestDtoMimeTypeEnumEnumMap, v),
    ),
    path: $checkedConvert('path', (v) => v as String),
    sha256: $checkedConvert('sha256', (v) => v as String),
    size: $checkedConvert('size', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$AgentArtifactManifestDtoToJson(
  AgentArtifactManifestDto instance,
) => <String, dynamic>{
  'caseId': instance.caseId,
  'mimeType': _$AgentArtifactManifestDtoMimeTypeEnumEnumMap[instance.mimeType]!,
  'path': instance.path,
  'sha256': instance.sha256,
  'size': instance.size,
};

const _$AgentArtifactManifestDtoMimeTypeEnumEnumMap = {
  AgentArtifactManifestDtoMimeTypeEnum.imageSlashPng: 'image/png',
  AgentArtifactManifestDtoMimeTypeEnum.applicationSlashJson: 'application/json',
};
