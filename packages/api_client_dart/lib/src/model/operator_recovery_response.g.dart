// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operator_recovery_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OperatorRecoveryResponse _$OperatorRecoveryResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OperatorRecoveryResponse', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['executionId', 'leaseId', 'recovery', 'resourceKey'],
  );
  final val = OperatorRecoveryResponse(
    executionId: $checkedConvert('executionId', (v) => v as String),
    leaseId: $checkedConvert('leaseId', (v) => v as String),
    recovery: $checkedConvert(
      'recovery',
      (v) => AgentOperatorRecoveryDto.fromJson(v as Map<String, dynamic>),
    ),
    resourceKey: $checkedConvert('resourceKey', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$OperatorRecoveryResponseToJson(
  OperatorRecoveryResponse instance,
) => <String, dynamic>{
  'executionId': instance.executionId,
  'leaseId': instance.leaseId,
  'recovery': instance.recovery.toJson(),
  'resourceKey': instance.resourceKey,
};
