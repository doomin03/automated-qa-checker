// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_reconcile_decision_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentReconcileDecisionDto _$AgentReconcileDecisionDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentReconcileDecisionDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'cleanupState',
      'completionReceipt',
      'deliveryClosed',
      'directive',
      'evidenceStatus',
      'lease',
      'operatorRecovery',
      'reason',
    ],
  );
  final val = AgentReconcileDecisionDto(
    cleanupState: $checkedConvert(
      'cleanupState',
      (v) => $enumDecode(_$AgentReconcileDecisionDtoCleanupStateEnumEnumMap, v),
    ),
    completionReceipt: $checkedConvert(
      'completionReceipt',
      (v) => v as String?,
    ),
    deliveryClosed: $checkedConvert('deliveryClosed', (v) => v as bool),
    directive: $checkedConvert(
      'directive',
      (v) => $enumDecode(_$AgentReconcileDecisionDtoDirectiveEnumEnumMap, v),
    ),
    evidenceStatus: $checkedConvert(
      'evidenceStatus',
      (v) =>
          $enumDecode(_$AgentReconcileDecisionDtoEvidenceStatusEnumEnumMap, v),
    ),
    lease: $checkedConvert(
      'lease',
      (v) => AgentLeaseDto.fromJson(v as Map<String, dynamic>),
    ),
    operatorRecovery: $checkedConvert(
      'operatorRecovery',
      (v) => v == null
          ? null
          : AgentOperatorRecoveryDto.fromJson(v as Map<String, dynamic>),
    ),
    reason: $checkedConvert('reason', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AgentReconcileDecisionDtoToJson(
  AgentReconcileDecisionDto instance,
) => <String, dynamic>{
  'cleanupState':
      _$AgentReconcileDecisionDtoCleanupStateEnumEnumMap[instance
          .cleanupState]!,
  'completionReceipt': instance.completionReceipt,
  'deliveryClosed': instance.deliveryClosed,
  'directive':
      _$AgentReconcileDecisionDtoDirectiveEnumEnumMap[instance.directive]!,
  'evidenceStatus':
      _$AgentReconcileDecisionDtoEvidenceStatusEnumEnumMap[instance
          .evidenceStatus]!,
  'lease': instance.lease.toJson(),
  'operatorRecovery': instance.operatorRecovery?.toJson(),
  'reason': instance.reason,
};

const _$AgentReconcileDecisionDtoCleanupStateEnumEnumMap = {
  AgentReconcileDecisionDtoCleanupStateEnum.confirmed: 'confirmed',
  AgentReconcileDecisionDtoCleanupStateEnum.unknown: 'unknown',
  AgentReconcileDecisionDtoCleanupStateEnum.failed: 'failed',
};

const _$AgentReconcileDecisionDtoDirectiveEnumEnumMap = {
  AgentReconcileDecisionDtoDirectiveEnum.resume: 'resume',
  AgentReconcileDecisionDtoDirectiveEnum.cancel: 'cancel',
  AgentReconcileDecisionDtoDirectiveEnum.quarantine: 'quarantine',
  AgentReconcileDecisionDtoDirectiveEnum.observe: 'observe',
};

const _$AgentReconcileDecisionDtoEvidenceStatusEnumEnumMap = {
  AgentReconcileDecisionDtoEvidenceStatusEnum.pending: 'pending',
  AgentReconcileDecisionDtoEvidenceStatusEnum.missing: 'missing',
  AgentReconcileDecisionDtoEvidenceStatusEnum.verified: 'verified',
};
