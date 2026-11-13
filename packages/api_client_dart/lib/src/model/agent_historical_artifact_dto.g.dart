// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_historical_artifact_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentHistoricalArtifactDto _$AgentHistoricalArtifactDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentHistoricalArtifactDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'base64',
      'caseId',
      'mimeType',
      'path',
      'sha256',
      'size',
    ],
  );
  final val = AgentHistoricalArtifactDto(
    base64: $checkedConvert('base64', (v) => v as String),
    caseId: $checkedConvert('caseId', (v) => v as String),
    mimeType: $checkedConvert(
      'mimeType',
      (v) => $enumDecode(_$AgentHistoricalArtifactDtoMimeTypeEnumEnumMap, v),
    ),
    path: $checkedConvert('path', (v) => v as String),
    sha256: $checkedConvert('sha256', (v) => v as String),
    size: $checkedConvert('size', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$AgentHistoricalArtifactDtoToJson(
  AgentHistoricalArtifactDto instance,
) => <String, dynamic>{
  'base64': instance.base64,
  'caseId': instance.caseId,
  'mimeType':
      _$AgentHistoricalArtifactDtoMimeTypeEnumEnumMap[instance.mimeType]!,
  'path': instance.path,
  'sha256': instance.sha256,
  'size': instance.size,
};

const _$AgentHistoricalArtifactDtoMimeTypeEnumEnumMap = {
  AgentHistoricalArtifactDtoMimeTypeEnum.imageSlashPng: 'image/png',
  AgentHistoricalArtifactDtoMimeTypeEnum.applicationSlashJson:
      'application/json',
};
