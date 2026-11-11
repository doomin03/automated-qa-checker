//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_operator_recovery_dto.dart';
import 'package:api_client_dart/src/model/agent_case_snapshot_dto.dart';
import 'package:api_client_dart/src/model/execution_case_run.dart';
import 'package:json_annotation/json_annotation.dart';

part 'execution_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExecutionResponse {
  /// Returns a new [ExecutionResponse] instance.
  ExecutionResponse({
    required this.cancelRequested,

    required this.caseRuns,

    required this.cases,

    required this.cleanupState,

    required this.createdAt,

    required this.deadlineAt,

    required this.evidenceStatus,

    required this.fence,

    required this.id,

    required this.leaseId,

    required this.operatorRecovery,

    required this.projectId,

    required this.reason,

    required this.reportedExecutionStatus,

    required this.resourceKey,

    required this.state,
  });

  @JsonKey(name: r'cancelRequested', required: true, includeIfNull: false)
  final bool cancelRequested;

  @JsonKey(name: r'caseRuns', required: true, includeIfNull: false)
  final List<ExecutionCaseRun> caseRuns;

  @JsonKey(name: r'cases', required: true, includeIfNull: false)
  final List<AgentCaseSnapshotDto> cases;

  @JsonKey(name: r'cleanupState', required: true, includeIfNull: true)
  final ExecutionResponseCleanupStateEnum? cleanupState;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'deadlineAt', required: true, includeIfNull: true)
  final DateTime? deadlineAt;

  @JsonKey(name: r'evidenceStatus', required: true, includeIfNull: true)
  final String? evidenceStatus;

  // minimum: 1
  @JsonKey(name: r'fence', required: true, includeIfNull: true)
  final int? fence;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'leaseId', required: true, includeIfNull: true)
  final String? leaseId;

  @JsonKey(name: r'operatorRecovery', required: true, includeIfNull: true)
  final AgentOperatorRecoveryDto? operatorRecovery;

  @JsonKey(name: r'projectId', required: true, includeIfNull: false)
  final String projectId;

  @JsonKey(name: r'reason', required: true, includeIfNull: true)
  final String? reason;

  @JsonKey(
    name: r'reportedExecutionStatus',
    required: true,
    includeIfNull: true,
  )
  final String? reportedExecutionStatus;

  /// Recovery metadata is visible to qa_manager and system_admin only.
  @JsonKey(name: r'resourceKey', required: true, includeIfNull: true)
  final String? resourceKey;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final String state;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionResponse &&
          other.cancelRequested == cancelRequested &&
          other.caseRuns == caseRuns &&
          other.cases == cases &&
          other.cleanupState == cleanupState &&
          other.createdAt == createdAt &&
          other.deadlineAt == deadlineAt &&
          other.evidenceStatus == evidenceStatus &&
          other.fence == fence &&
          other.id == id &&
          other.leaseId == leaseId &&
          other.operatorRecovery == operatorRecovery &&
          other.projectId == projectId &&
          other.reason == reason &&
          other.reportedExecutionStatus == reportedExecutionStatus &&
          other.resourceKey == resourceKey &&
          other.state == state;

  @override
  int get hashCode =>
      cancelRequested.hashCode +
      caseRuns.hashCode +
      cases.hashCode +
      (cleanupState == null ? 0 : cleanupState.hashCode) +
      createdAt.hashCode +
      (deadlineAt == null ? 0 : deadlineAt.hashCode) +
      (evidenceStatus == null ? 0 : evidenceStatus.hashCode) +
      (fence == null ? 0 : fence.hashCode) +
      id.hashCode +
      (leaseId == null ? 0 : leaseId.hashCode) +
      (operatorRecovery == null ? 0 : operatorRecovery.hashCode) +
      projectId.hashCode +
      (reason == null ? 0 : reason.hashCode) +
      (reportedExecutionStatus == null ? 0 : reportedExecutionStatus.hashCode) +
      (resourceKey == null ? 0 : resourceKey.hashCode) +
      state.hashCode;

  factory ExecutionResponse.fromJson(Map<String, dynamic> json) =>
      _$ExecutionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutionResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ExecutionResponseCleanupStateEnum {
  @JsonValue(r'confirmed')
  confirmed(r'confirmed'),
  @JsonValue(r'unknown')
  unknown(r'unknown'),
  @JsonValue(r'failed')
  failed(r'failed');

  const ExecutionResponseCleanupStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
