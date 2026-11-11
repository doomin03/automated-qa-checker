// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_operator_recovery_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentOperatorRecoveryDto _$AgentOperatorRecoveryDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentOperatorRecoveryDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['confirmedAt', 'id', 'newFence', 'priorFence'],
  );
  final val = AgentOperatorRecoveryDto(
    confirmedAt: $checkedConvert(
      'confirmedAt',
      (v) => DateTime.parse(v as String),
    ),
    id: $checkedConvert('id', (v) => v as String),
    newFence: $checkedConvert('newFence', (v) => (v as num).toInt()),
    priorFence: $checkedConvert('priorFence', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$AgentOperatorRecoveryDtoToJson(
  AgentOperatorRecoveryDto instance,
) => <String, dynamic>{
  'confirmedAt': instance.confirmedAt.toIso8601String(),
  'id': instance.id,
  'newFence': instance.newFence,
  'priorFence': instance.priorFence,
};
