// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_complete_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentCompleteRequestDto _$AgentCompleteRequestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentCompleteRequestDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'agentId',
      'artifactManifest',
      'caseResults',
      'cleanupState',
      'executionStatus',
      'fence',
      'instanceId',
      'reason',
    ],
  );
  final val = AgentCompleteRequestDto(
    agentId: $checkedConvert('agentId', (v) => v as String),
    artifactManifest: $checkedConvert(
      'artifactManifest',
      (v) => (v as List<dynamic>)
          .map(
            (e) => AgentArtifactManifestDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    caseResults: $checkedConvert(
      'caseResults',
      (v) => (v as List<dynamic>)
          .map((e) => AgentCaseResultDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    cleanupState: $checkedConvert(
      'cleanupState',
      (v) => $enumDecode(_$AgentCompleteRequestDtoCleanupStateEnumEnumMap, v),
    ),
    executionStatus: $checkedConvert(
      'executionStatus',
      (v) =>
          $enumDecode(_$AgentCompleteRequestDtoExecutionStatusEnumEnumMap, v),
    ),
    fence: $checkedConvert('fence', (v) => (v as num).toInt()),
    instanceId: $checkedConvert('instanceId', (v) => v as String),
    reason: $checkedConvert('reason', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$AgentCompleteRequestDtoToJson(
  AgentCompleteRequestDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'artifactManifest': instance.artifactManifest.map((e) => e.toJson()).toList(),
  'caseResults': instance.caseResults.map((e) => e.toJson()).toList(),
  'cleanupState':
      _$AgentCompleteRequestDtoCleanupStateEnumEnumMap[instance.cleanupState]!,
  'executionStatus':
      _$AgentCompleteRequestDtoExecutionStatusEnumEnumMap[instance
          .executionStatus]!,
  'fence': instance.fence,
  'instanceId': instance.instanceId,
  'reason': instance.reason,
};

const _$AgentCompleteRequestDtoCleanupStateEnumEnumMap = {
  AgentCompleteRequestDtoCleanupStateEnum.confirmed: 'confirmed',
  AgentCompleteRequestDtoCleanupStateEnum.unknown: 'unknown',
  AgentCompleteRequestDtoCleanupStateEnum.failed: 'failed',
};

const _$AgentCompleteRequestDtoExecutionStatusEnumEnumMap = {
  AgentCompleteRequestDtoExecutionStatusEnum.finished: 'finished',
  AgentCompleteRequestDtoExecutionStatusEnum.blocked: 'blocked',
  AgentCompleteRequestDtoExecutionStatusEnum.infraError: 'infra_error',
  AgentCompleteRequestDtoExecutionStatusEnum.cancelled: 'cancelled',
};
