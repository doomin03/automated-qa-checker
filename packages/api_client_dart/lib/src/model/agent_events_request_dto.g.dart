// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_events_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentEventsRequestDto _$AgentEventsRequestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentEventsRequestDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['agentId', 'events', 'fence', 'instanceId'],
  );
  final val = AgentEventsRequestDto(
    agentId: $checkedConvert('agentId', (v) => v as String),
    events: $checkedConvert(
      'events',
      (v) => (v as List<dynamic>)
          .map((e) => AgentDeliveryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    fence: $checkedConvert('fence', (v) => (v as num).toInt()),
    instanceId: $checkedConvert('instanceId', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AgentEventsRequestDtoToJson(
  AgentEventsRequestDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'events': instance.events.map((e) => e.toJson()).toList(),
  'fence': instance.fence,
  'instanceId': instance.instanceId,
};
