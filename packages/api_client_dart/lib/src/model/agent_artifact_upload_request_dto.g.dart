// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_artifact_upload_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentArtifactUploadRequestDto _$AgentArtifactUploadRequestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentArtifactUploadRequestDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'agentId',
      'artifactId',
      'base64',
      'caseId',
      'fence',
      'instanceId',
      'mimeType',
      'sha256',
    ],
  );
  final val = AgentArtifactUploadRequestDto(
    agentId: $checkedConvert('agentId', (v) => v as String),
    artifactId: $checkedConvert('artifactId', (v) => v as String),
    base64: $checkedConvert('base64', (v) => v as String),
    caseId: $checkedConvert('caseId', (v) => v as String),
    fence: $checkedConvert('fence', (v) => (v as num).toInt()),
    instanceId: $checkedConvert('instanceId', (v) => v as String),
    mimeType: $checkedConvert(
      'mimeType',
      (v) => $enumDecode(_$AgentArtifactUploadRequestDtoMimeTypeEnumEnumMap, v),
    ),
    sha256: $checkedConvert('sha256', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AgentArtifactUploadRequestDtoToJson(
  AgentArtifactUploadRequestDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'artifactId': instance.artifactId,
  'base64': instance.base64,
  'caseId': instance.caseId,
  'fence': instance.fence,
  'instanceId': instance.instanceId,
  'mimeType':
      _$AgentArtifactUploadRequestDtoMimeTypeEnumEnumMap[instance.mimeType]!,
  'sha256': instance.sha256,
};

const _$AgentArtifactUploadRequestDtoMimeTypeEnumEnumMap = {
  AgentArtifactUploadRequestDtoMimeTypeEnum.imageSlashPng: 'image/png',
  AgentArtifactUploadRequestDtoMimeTypeEnum.applicationSlashJson:
      'application/json',
};
