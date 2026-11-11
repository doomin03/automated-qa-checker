// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkInput _$WorkInputFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WorkInput',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['assigneeId', 'revision', 'status']);
    final val = WorkInput(
      assigneeId: $checkedConvert('assigneeId', (v) => v as String?),
      revision: $checkedConvert('revision', (v) => (v as num).toInt()),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$WorkInputStatusEnumEnumMap, v),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$WorkInputToJson(WorkInput instance) => <String, dynamic>{
  'assigneeId': instance.assigneeId,
  'revision': instance.revision,
  'status': _$WorkInputStatusEnumEnumMap[instance.status]!,
};

const _$WorkInputStatusEnumEnumMap = {
  WorkInputStatusEnum.todo: 'todo',
  WorkInputStatusEnum.inProgress: 'in_progress',
  WorkInputStatusEnum.done: 'done',
};
