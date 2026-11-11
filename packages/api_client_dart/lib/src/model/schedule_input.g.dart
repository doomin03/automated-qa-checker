// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleInput _$ScheduleInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ScheduleInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'enabled',
          'executionPolicy',
          'latenessSeconds',
          'localTime',
          'sha256',
          'suiteVersionId',
          'timezone',
          'versionId',
          'weekdays',
        ],
      );
      final val = ScheduleInput(
        enabled: $checkedConvert('enabled', (v) => v as bool),
        executionPolicy: $checkedConvert(
          'executionPolicy',
          (v) => AgentExecutionPolicyDto.fromJson(v as Map<String, dynamic>),
        ),
        latenessSeconds: $checkedConvert(
          'latenessSeconds',
          (v) => (v as num).toInt(),
        ),
        localTime: $checkedConvert('localTime', (v) => v as String),
        sha256: $checkedConvert('sha256', (v) => v as String),
        suiteVersionId: $checkedConvert('suiteVersionId', (v) => v as String?),
        timezone: $checkedConvert('timezone', (v) => v as String),
        versionId: $checkedConvert('versionId', (v) => v as String?),
        weekdays: $checkedConvert(
          'weekdays',
          (v) => (v as List<dynamic>).map((e) => e as num).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ScheduleInputToJson(ScheduleInput instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'executionPolicy': instance.executionPolicy.toJson(),
      'latenessSeconds': instance.latenessSeconds,
      'localTime': instance.localTime,
      'sha256': instance.sha256,
      'suiteVersionId': instance.suiteVersionId,
      'timezone': instance.timezone,
      'versionId': instance.versionId,
      'weekdays': instance.weekdays,
    };
