//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_operator_recovery_dto.dart';
import 'package:api_client_dart/src/model/agent_lease_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_reconcile_decision_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentReconcileDecisionDto {
  /// Returns a new [AgentReconcileDecisionDto] instance.
  AgentReconcileDecisionDto({
    required this.cleanupState,

    required this.completionReceipt,

    required this.deliveryClosed,

    required this.directive,

    required this.evidenceStatus,

    required this.lease,

    required this.operatorRecovery,

    required this.reason,
  });

  @JsonKey(name: r'cleanupState', required: true, includeIfNull: false)
  final AgentReconcileDecisionDtoCleanupStateEnum cleanupState;

  @JsonKey(name: r'completionReceipt', required: true, includeIfNull: true)
  final String? completionReceipt;

  @JsonKey(name: r'deliveryClosed', required: true, includeIfNull: false)
  final bool deliveryClosed;

  @JsonKey(name: r'directive', required: true, includeIfNull: false)
  final AgentReconcileDecisionDtoDirectiveEnum directive;

  @JsonKey(name: r'evidenceStatus', required: true, includeIfNull: false)
  final AgentReconcileDecisionDtoEvidenceStatusEnum evidenceStatus;

  @JsonKey(name: r'lease', required: true, includeIfNull: false)
  final AgentLeaseDto lease;

  @JsonKey(name: r'operatorRecovery', required: true, includeIfNull: true)
  final AgentOperatorRecoveryDto? operatorRecovery;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentReconcileDecisionDto &&
          other.cleanupState == cleanupState &&
          other.completionReceipt == completionReceipt &&
          other.deliveryClosed == deliveryClosed &&
          other.directive == directive &&
          other.evidenceStatus == evidenceStatus &&
          other.lease == lease &&
          other.operatorRecovery == operatorRecovery &&
          other.reason == reason;

  @override
  int get hashCode =>
      cleanupState.hashCode +
      (completionReceipt == null ? 0 : completionReceipt.hashCode) +
      deliveryClosed.hashCode +
      directive.hashCode +
      evidenceStatus.hashCode +
      lease.hashCode +
      (operatorRecovery == null ? 0 : operatorRecovery.hashCode) +
      reason.hashCode;

  factory AgentReconcileDecisionDto.fromJson(Map<String, dynamic> json) =>
      _$AgentReconcileDecisionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentReconcileDecisionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentReconcileDecisionDtoCleanupStateEnum {
  @JsonValue(r'confirmed')
  confirmed(r'confirmed'),
  @JsonValue(r'unknown')
  unknown(r'unknown'),
  @JsonValue(r'failed')
  failed(r'failed');

  const AgentReconcileDecisionDtoCleanupStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AgentReconcileDecisionDtoDirectiveEnum {
  @JsonValue(r'resume')
  resume(r'resume'),
  @JsonValue(r'cancel')
  cancel(r'cancel'),
  @JsonValue(r'quarantine')
  quarantine(r'quarantine'),
  @JsonValue(r'observe')
  observe(r'observe');

  const AgentReconcileDecisionDtoDirectiveEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AgentReconcileDecisionDtoEvidenceStatusEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'missing')
  missing(r'missing'),
  @JsonValue(r'verified')
  verified(r'verified');

  const AgentReconcileDecisionDtoEvidenceStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
