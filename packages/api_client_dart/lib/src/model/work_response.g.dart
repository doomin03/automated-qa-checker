// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkResponse _$WorkResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WorkResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'assigneeId',
          'revision',
          'runId',
          'status',
          'updatedAt',
        ],
      );
      final val = WorkResponse(
        assigneeId: $checkedConvert('assigneeId', (v) => v as String?),
        revision: $checkedConvert('revision', (v) => (v as num).toInt()),
        runId: $checkedConvert('runId', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$WorkResponseStatusEnumEnumMap, v),
        ),
        updatedAt: $checkedConvert('updatedAt', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$WorkResponseToJson(WorkResponse instance) =>
    <String, dynamic>{
      'assigneeId': instance.assigneeId,
      'revision': instance.revision,
      'runId': instance.runId,
      'status': _$WorkResponseStatusEnumEnumMap[instance.status]!,
      'updatedAt': instance.updatedAt,
    };

const _$WorkResponseStatusEnumEnumMap = {
  WorkResponseStatusEnum.todo: 'todo',
  WorkResponseStatusEnum.inProgress: 'in_progress',
  WorkResponseStatusEnum.done: 'done',
};
