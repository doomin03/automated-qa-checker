// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_occurrence_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleOccurrenceResponse _$ScheduleOccurrenceResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ScheduleOccurrenceResponse', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'executionId',
      'id',
      'localDate',
      'occurrenceAt',
      'reason',
      'scheduleId',
      'state',
    ],
  );
  final val = ScheduleOccurrenceResponse(
    executionId: $checkedConvert('executionId', (v) => v as String?),
    id: $checkedConvert('id', (v) => v as String),
    localDate: $checkedConvert('localDate', (v) => v as String),
    occurrenceAt: $checkedConvert(
      'occurrenceAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    reason: $checkedConvert('reason', (v) => v as String?),
    scheduleId: $checkedConvert('scheduleId', (v) => v as String),
    state: $checkedConvert('state', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ScheduleOccurrenceResponseToJson(
  ScheduleOccurrenceResponse instance,
) => <String, dynamic>{
  'executionId': instance.executionId,
  'id': instance.id,
  'localDate': instance.localDate,
  'occurrenceAt': instance.occurrenceAt?.toIso8601String(),
  'reason': instance.reason,
  'scheduleId': instance.scheduleId,
  'state': instance.state,
};
