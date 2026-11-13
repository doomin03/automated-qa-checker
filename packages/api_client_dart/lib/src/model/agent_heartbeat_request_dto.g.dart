// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_heartbeat_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentHeartbeatRequestDto _$AgentHeartbeatRequestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentHeartbeatRequestDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'agentId',
      'cleanupState',
      'fence',
      'instanceId',
      'lastAcknowledgedSequence',
    ],
  );
  final val = AgentHeartbeatRequestDto(
    agentId: $checkedConvert('agentId', (v) => v as String),
    cleanupState: $checkedConvert(
      'cleanupState',
      (v) => $enumDecode(_$AgentHeartbeatRequestDtoCleanupStateEnumEnumMap, v),
    ),
    fence: $checkedConvert('fence', (v) => (v as num).toInt()),
    instanceId: $checkedConvert('instanceId', (v) => v as String),
    lastAcknowledgedSequence: $checkedConvert(
      'lastAcknowledgedSequence',
      (v) => (v as num).toInt(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentHeartbeatRequestDtoToJson(
  AgentHeartbeatRequestDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'cleanupState':
      _$AgentHeartbeatRequestDtoCleanupStateEnumEnumMap[instance.cleanupState]!,
  'fence': instance.fence,
  'instanceId': instance.instanceId,
  'lastAcknowledgedSequence': instance.lastAcknowledgedSequence,
};

const _$AgentHeartbeatRequestDtoCleanupStateEnumEnumMap = {
  AgentHeartbeatRequestDtoCleanupStateEnum.confirmed: 'confirmed',
  AgentHeartbeatRequestDtoCleanupStateEnum.unknown: 'unknown',
  AgentHeartbeatRequestDtoCleanupStateEnum.failed: 'failed',
};
