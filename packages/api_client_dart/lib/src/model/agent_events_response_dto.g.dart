// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_events_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentEventsResponseDto _$AgentEventsResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentEventsResponseDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['acceptedThrough', 'fence', 'leaseId']);
  final val = AgentEventsResponseDto(
    acceptedThrough: $checkedConvert(
      'acceptedThrough',
      (v) => (v as num).toInt(),
    ),
    fence: $checkedConvert('fence', (v) => (v as num).toInt()),
    leaseId: $checkedConvert('leaseId', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AgentEventsResponseDtoToJson(
  AgentEventsResponseDto instance,
) => <String, dynamic>{
  'acceptedThrough': instance.acceptedThrough,
  'fence': instance.fence,
  'leaseId': instance.leaseId,
};
