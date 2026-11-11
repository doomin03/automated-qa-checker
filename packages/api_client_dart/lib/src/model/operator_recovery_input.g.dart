// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operator_recovery_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OperatorRecoveryInput _$OperatorRecoveryInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OperatorRecoveryInput', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'externalSessionsStopped',
      'fence',
      'ownerProcessesStopped',
      'reason',
      'requestId',
      'resourceKey',
    ],
  );
  final val = OperatorRecoveryInput(
    externalSessionsStopped: $checkedConvert(
      'externalSessionsStopped',
      (v) => v as bool,
    ),
    fence: $checkedConvert('fence', (v) => (v as num).toInt()),
    ownerProcessesStopped: $checkedConvert(
      'ownerProcessesStopped',
      (v) => v as bool,
    ),
    reason: $checkedConvert('reason', (v) => v as String),
    requestId: $checkedConvert('requestId', (v) => v as String),
    resourceKey: $checkedConvert('resourceKey', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$OperatorRecoveryInputToJson(
  OperatorRecoveryInput instance,
) => <String, dynamic>{
  'externalSessionsStopped': instance.externalSessionsStopped,
  'fence': instance.fence,
  'ownerProcessesStopped': instance.ownerProcessesStopped,
  'reason': instance.reason,
  'requestId': instance.requestId,
  'resourceKey': instance.resourceKey,
};
