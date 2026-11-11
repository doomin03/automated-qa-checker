// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleResponse _$ScheduleResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ScheduleResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'createdAt',
          'createdBy',
          'enabled',
          'executionPolicy',
          'id',
          'lastScannedAt',
          'latenessSeconds',
          'localTime',
          'projectId',
          'sha256',
          'suiteVersionId',
          'timezone',
          'versionId',
          'weekdays',
        ],
      );
      final val = ScheduleResponse(
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
        createdBy: $checkedConvert('createdBy', (v) => v as String),
        enabled: $checkedConvert('enabled', (v) => v as bool),
        executionPolicy: $checkedConvert(
          'executionPolicy',
          (v) => AgentExecutionPolicyDto.fromJson(v as Map<String, dynamic>),
        ),
        id: $checkedConvert('id', (v) => v as String),
        lastScannedAt: $checkedConvert(
          'lastScannedAt',
          (v) => DateTime.parse(v as String),
        ),
        latenessSeconds: $checkedConvert(
          'latenessSeconds',
          (v) => (v as num).toInt(),
        ),
        localTime: $checkedConvert('localTime', (v) => v as String),
        projectId: $checkedConvert('projectId', (v) => v as String),
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

Map<String, dynamic> _$ScheduleResponseToJson(ScheduleResponse instance) =>
    <String, dynamic>{
      'createdAt': instance.createdAt.toIso8601String(),
      'createdBy': instance.createdBy,
      'enabled': instance.enabled,
      'executionPolicy': instance.executionPolicy.toJson(),
      'id': instance.id,
      'lastScannedAt': instance.lastScannedAt.toIso8601String(),
      'latenessSeconds': instance.latenessSeconds,
      'localTime': instance.localTime,
      'projectId': instance.projectId,
      'sha256': instance.sha256,
      'suiteVersionId': instance.suiteVersionId,
      'timezone': instance.timezone,
      'versionId': instance.versionId,
      'weekdays': instance.weekdays,
    };
