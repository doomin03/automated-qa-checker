// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExecutionResponse _$ExecutionResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ExecutionResponse', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'cancelRequested',
      'caseRuns',
      'cases',
      'cleanupState',
      'createdAt',
      'deadlineAt',
      'evidenceStatus',
      'fence',
      'id',
      'leaseId',
      'operatorRecovery',
      'projectId',
      'reason',
      'reportedExecutionStatus',
      'resourceKey',
      'state',
    ],
  );
  final val = ExecutionResponse(
    cancelRequested: $checkedConvert('cancelRequested', (v) => v as bool),
    caseRuns: $checkedConvert(
      'caseRuns',
      (v) => (v as List<dynamic>)
          .map((e) => ExecutionCaseRun.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    cases: $checkedConvert(
      'cases',
      (v) => (v as List<dynamic>)
          .map((e) => AgentCaseSnapshotDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    cleanupState: $checkedConvert(
      'cleanupState',
      (v) => $enumDecodeNullable(_$ExecutionResponseCleanupStateEnumEnumMap, v),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    deadlineAt: $checkedConvert(
      'deadlineAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    evidenceStatus: $checkedConvert('evidenceStatus', (v) => v as String?),
    fence: $checkedConvert('fence', (v) => (v as num?)?.toInt()),
    id: $checkedConvert('id', (v) => v as String),
    leaseId: $checkedConvert('leaseId', (v) => v as String?),
    operatorRecovery: $checkedConvert(
      'operatorRecovery',
      (v) => v == null
          ? null
          : AgentOperatorRecoveryDto.fromJson(v as Map<String, dynamic>),
    ),
    projectId: $checkedConvert('projectId', (v) => v as String),
    reason: $checkedConvert('reason', (v) => v as String?),
    reportedExecutionStatus: $checkedConvert(
      'reportedExecutionStatus',
      (v) => v as String?,
    ),
    resourceKey: $checkedConvert('resourceKey', (v) => v as String?),
    state: $checkedConvert('state', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ExecutionResponseToJson(ExecutionResponse instance) =>
    <String, dynamic>{
      'cancelRequested': instance.cancelRequested,
      'caseRuns': instance.caseRuns.map((e) => e.toJson()).toList(),
      'cases': instance.cases.map((e) => e.toJson()).toList(),
      'cleanupState':
          _$ExecutionResponseCleanupStateEnumEnumMap[instance.cleanupState],
      'createdAt': instance.createdAt.toIso8601String(),
      'deadlineAt': instance.deadlineAt?.toIso8601String(),
      'evidenceStatus': instance.evidenceStatus,
      'fence': instance.fence,
      'id': instance.id,
      'leaseId': instance.leaseId,
      'operatorRecovery': instance.operatorRecovery?.toJson(),
      'projectId': instance.projectId,
      'reason': instance.reason,
      'reportedExecutionStatus': instance.reportedExecutionStatus,
      'resourceKey': instance.resourceKey,
      'state': instance.state,
    };

const _$ExecutionResponseCleanupStateEnumEnumMap = {
  ExecutionResponseCleanupStateEnum.confirmed: 'confirmed',
  ExecutionResponseCleanupStateEnum.unknown: 'unknown',
  ExecutionResponseCleanupStateEnum.failed: 'failed',
};
