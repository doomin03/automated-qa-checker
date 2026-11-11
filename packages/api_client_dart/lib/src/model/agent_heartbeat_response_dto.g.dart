// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_heartbeat_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentHeartbeatResponseDto _$AgentHeartbeatResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentHeartbeatResponseDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'acceptedThrough',
      'cancelRequested',
      'fence',
      'leaseId',
      'state',
      'validForMs',
    ],
  );
  final val = AgentHeartbeatResponseDto(
    acceptedThrough: $checkedConvert(
      'acceptedThrough',
      (v) => (v as num).toInt(),
    ),
    cancelRequested: $checkedConvert('cancelRequested', (v) => v as bool),
    fence: $checkedConvert('fence', (v) => (v as num).toInt()),
    leaseId: $checkedConvert('leaseId', (v) => v as String),
    state: $checkedConvert(
      'state',
      (v) => $enumDecode(_$AgentHeartbeatResponseDtoStateEnumEnumMap, v),
    ),
    validForMs: $checkedConvert('validForMs', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$AgentHeartbeatResponseDtoToJson(
  AgentHeartbeatResponseDto instance,
) => <String, dynamic>{
  'acceptedThrough': instance.acceptedThrough,
  'cancelRequested': instance.cancelRequested,
  'fence': instance.fence,
  'leaseId': instance.leaseId,
  'state': _$AgentHeartbeatResponseDtoStateEnumEnumMap[instance.state]!,
  'validForMs': instance.validForMs,
};

const _$AgentHeartbeatResponseDtoStateEnumEnumMap = {
  AgentHeartbeatResponseDtoStateEnum.active: 'active',
  AgentHeartbeatResponseDtoStateEnum.reporting: 'reporting',
  AgentHeartbeatResponseDtoStateEnum.expired: 'expired',
  AgentHeartbeatResponseDtoStateEnum.quarantined: 'quarantined',
};
