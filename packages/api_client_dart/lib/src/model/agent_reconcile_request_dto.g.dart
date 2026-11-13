// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_reconcile_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentReconcileRequestDto _$AgentReconcileRequestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentReconcileRequestDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['agentId', 'instanceId', 'knownLeases'],
  );
  final val = AgentReconcileRequestDto(
    agentId: $checkedConvert('agentId', (v) => v as String),
    instanceId: $checkedConvert('instanceId', (v) => v as String),
    knownLeases: $checkedConvert(
      'knownLeases',
      (v) => (v as List<dynamic>)
          .map((e) => AgentKnownLeaseDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentReconcileRequestDtoToJson(
  AgentReconcileRequestDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'instanceId': instance.instanceId,
  'knownLeases': instance.knownLeases.map((e) => e.toJson()).toList(),
};
