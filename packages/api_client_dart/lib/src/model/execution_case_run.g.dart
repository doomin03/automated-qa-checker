// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_case_run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExecutionCaseRun _$ExecutionCaseRunFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExecutionCaseRun', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['caseId', 'runId']);
      final val = ExecutionCaseRun(
        caseId: $checkedConvert('caseId', (v) => v as String),
        runId: $checkedConvert('runId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ExecutionCaseRunToJson(ExecutionCaseRun instance) =>
    <String, dynamic>{'caseId': instance.caseId, 'runId': instance.runId};
