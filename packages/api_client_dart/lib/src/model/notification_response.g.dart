// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationResponse _$NotificationResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('NotificationResponse', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'attempts',
      'createdAt',
      'id',
      'lastError',
      'nextAttemptAt',
      'runId',
      'state',
    ],
  );
  final val = NotificationResponse(
    attempts: $checkedConvert('attempts', (v) => (v as num).toInt()),
    createdAt: $checkedConvert('createdAt', (v) => v as String),
    id: $checkedConvert('id', (v) => v as String),
    lastError: $checkedConvert('lastError', (v) => v as String?),
    nextAttemptAt: $checkedConvert('nextAttemptAt', (v) => v as String),
    runId: $checkedConvert('runId', (v) => v as String),
    state: $checkedConvert(
      'state',
      (v) => $enumDecode(_$NotificationResponseStateEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$NotificationResponseToJson(
  NotificationResponse instance,
) => <String, dynamic>{
  'attempts': instance.attempts,
  'createdAt': instance.createdAt,
  'id': instance.id,
  'lastError': instance.lastError,
  'nextAttemptAt': instance.nextAttemptAt,
  'runId': instance.runId,
  'state': _$NotificationResponseStateEnumEnumMap[instance.state]!,
};

const _$NotificationResponseStateEnumEnumMap = {
  NotificationResponseStateEnum.pending: 'pending',
  NotificationResponseStateEnum.sending: 'sending',
  NotificationResponseStateEnum.retrying: 'retrying',
  NotificationResponseStateEnum.deliveryFailed: 'delivery_failed',
  NotificationResponseStateEnum.delivered: 'delivered',
};
