import 'package:api_client_dart/src/model/agent_artifact_manifest_dto.dart';
import 'package:api_client_dart/src/model/agent_artifact_receipt_dto.dart';
import 'package:api_client_dart/src/model/agent_artifact_upload_request_dto.dart';
import 'package:api_client_dart/src/model/agent_capability_set_dto.dart';
import 'package:api_client_dart/src/model/agent_case_result_dto.dart';
import 'package:api_client_dart/src/model/agent_case_snapshot_dto.dart';
import 'package:api_client_dart/src/model/agent_case_snapshot_published_version_dto.dart';
import 'package:api_client_dart/src/model/agent_claim_request_dto.dart';
import 'package:api_client_dart/src/model/agent_claim_response_dto.dart';
import 'package:api_client_dart/src/model/agent_complete_request_dto.dart';
import 'package:api_client_dart/src/model/agent_complete_response_dto.dart';
import 'package:api_client_dart/src/model/agent_delivery_dto.dart';
import 'package:api_client_dart/src/model/agent_events_request_dto.dart';
import 'package:api_client_dart/src/model/agent_events_response_dto.dart';
import 'package:api_client_dart/src/model/agent_execution_policy_dto.dart';
import 'package:api_client_dart/src/model/agent_execution_policy_native_apps_item_dto.dart';
import 'package:api_client_dart/src/model/agent_heartbeat_request_dto.dart';
import 'package:api_client_dart/src/model/agent_heartbeat_response_dto.dart';
import 'package:api_client_dart/src/model/agent_historical_artifact_dto.dart';
import 'package:api_client_dart/src/model/agent_historical_evidence_request_dto.dart';
import 'package:api_client_dart/src/model/agent_historical_evidence_response_dto.dart';
import 'package:api_client_dart/src/model/agent_instance_release_request_dto.dart';
import 'package:api_client_dart/src/model/agent_instance_release_request_receipts_item_dto.dart';
import 'package:api_client_dart/src/model/agent_instance_release_response_dto.dart';
import 'package:api_client_dart/src/model/agent_known_lease_dto.dart';
import 'package:api_client_dart/src/model/agent_known_lease_terminal_result_hashes_item_dto.dart';
import 'package:api_client_dart/src/model/agent_lease_dto.dart';
import 'package:api_client_dart/src/model/agent_operator_recovery_dto.dart';
import 'package:api_client_dart/src/model/agent_reconcile_decision_dto.dart';
import 'package:api_client_dart/src/model/agent_reconcile_request_dto.dart';
import 'package:api_client_dart/src/model/agent_reconcile_response_dto.dart';
import 'package:api_client_dart/src/model/agent_resource_bytes_dto.dart';
import 'package:api_client_dart/src/model/agent_resource_manifest_dto.dart';
import 'package:api_client_dart/src/model/agent_suite_policy_dto.dart';
import 'package:api_client_dart/src/model/api_error_detail.dart';
import 'package:api_client_dart/src/model/api_error_response.dart';
import 'package:api_client_dart/src/model/artifact_download.dart';
import 'package:api_client_dart/src/model/artifact_input.dart';
import 'package:api_client_dart/src/model/artifact_response.dart';
import 'package:api_client_dart/src/model/audit_page.dart';
import 'package:api_client_dart/src/model/audit_response.dart';
import 'package:api_client_dart/src/model/baseline_input.dart';
import 'package:api_client_dart/src/model/changed_node.dart';
import 'package:api_client_dart/src/model/comparison_response.dart';
import 'package:api_client_dart/src/model/dependency_pin.dart';
import 'package:api_client_dart/src/model/desktop_exchange_input.dart';
import 'package:api_client_dart/src/model/desktop_session_response.dart';
import 'package:api_client_dart/src/model/draft_input.dart';
import 'package:api_client_dart/src/model/draft_page.dart';
import 'package:api_client_dart/src/model/draft_response.dart';
import 'package:api_client_dart/src/model/event_batch_input.dart';
import 'package:api_client_dart/src/model/events_response.dart';
import 'package:api_client_dart/src/model/execution_case_run.dart';
import 'package:api_client_dart/src/model/execution_input.dart';
import 'package:api_client_dart/src/model/execution_page.dart';
import 'package:api_client_dart/src/model/execution_response.dart';
import 'package:api_client_dart/src/model/health_response.dart';
import 'package:api_client_dart/src/model/identity_response.dart';
import 'package:api_client_dart/src/model/logout_response.dart';
import 'package:api_client_dart/src/model/notification_page.dart';
import 'package:api_client_dart/src/model/notification_response.dart';
import 'package:api_client_dart/src/model/operator_recovery_input.dart';
import 'package:api_client_dart/src/model/operator_recovery_response.dart';
import 'package:api_client_dart/src/model/pin_input.dart';
import 'package:api_client_dart/src/model/pin_page.dart';
import 'package:api_client_dart/src/model/pin_response.dart';
import 'package:api_client_dart/src/model/project_page.dart';
import 'package:api_client_dart/src/model/project_response.dart';
import 'package:api_client_dart/src/model/publish_input.dart';
import 'package:api_client_dart/src/model/result_input.dart';
import 'package:api_client_dart/src/model/run_input.dart';
import 'package:api_client_dart/src/model/run_page.dart';
import 'package:api_client_dart/src/model/run_response.dart';
import 'package:api_client_dart/src/model/schedule_enabled_input.dart';
import 'package:api_client_dart/src/model/schedule_input.dart';
import 'package:api_client_dart/src/model/schedule_occurrence_page.dart';
import 'package:api_client_dart/src/model/schedule_occurrence_response.dart';
import 'package:api_client_dart/src/model/schedule_page.dart';
import 'package:api_client_dart/src/model/schedule_response.dart';
import 'package:api_client_dart/src/model/session_response.dart';
import 'package:api_client_dart/src/model/suite_case.dart';
import 'package:api_client_dart/src/model/suite_draft_input.dart';
import 'package:api_client_dart/src/model/suite_draft_page.dart';
import 'package:api_client_dart/src/model/suite_draft_response.dart';
import 'package:api_client_dart/src/model/suite_page.dart';
import 'package:api_client_dart/src/model/suite_response.dart';
import 'package:api_client_dart/src/model/upgrade_diff_response.dart';
import 'package:api_client_dart/src/model/version_page.dart';
import 'package:api_client_dart/src/model/version_response.dart';
import 'package:api_client_dart/src/model/work_input.dart';
import 'package:api_client_dart/src/model/work_response.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

ReturnType deserialize<ReturnType, BaseType>(
  dynamic value,
  String targetType, {
  bool growable = true,
}) {
  switch (targetType) {
    case 'String':
      return '$value' as ReturnType;
    case 'int':
      return (value is int ? value : int.parse('$value')) as ReturnType;
    case 'bool':
      if (value is bool) {
        return value as ReturnType;
      }
      final valueString = '$value'.toLowerCase();
      return (valueString == 'true' || valueString == '1') as ReturnType;
    case 'double':
      return (value is double ? value : double.parse('$value')) as ReturnType;
    case 'AgentArtifactManifestDto':
      return AgentArtifactManifestDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentArtifactReceiptDto':
      return AgentArtifactReceiptDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentArtifactUploadRequestDto':
      return AgentArtifactUploadRequestDto.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'AgentCapabilitySetDto':
      return AgentCapabilitySetDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentCaseResultDto':
      return AgentCaseResultDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentCaseSnapshotDto':
      return AgentCaseSnapshotDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentCaseSnapshotPublishedVersionDto':
      return AgentCaseSnapshotPublishedVersionDto.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'AgentClaimRequestDto':
      return AgentClaimRequestDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentClaimResponseDto':
      return AgentClaimResponseDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentCompleteRequestDto':
      return AgentCompleteRequestDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentCompleteResponseDto':
      return AgentCompleteResponseDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentDeliveryDto':
      return AgentDeliveryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentEventsRequestDto':
      return AgentEventsRequestDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentEventsResponseDto':
      return AgentEventsResponseDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentExecutionPolicyDto':
      return AgentExecutionPolicyDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentExecutionPolicyNativeAppsItemDto':
      return AgentExecutionPolicyNativeAppsItemDto.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'AgentHeartbeatRequestDto':
      return AgentHeartbeatRequestDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentHeartbeatResponseDto':
      return AgentHeartbeatResponseDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentHistoricalArtifactDto':
      return AgentHistoricalArtifactDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentHistoricalEvidenceRequestDto':
      return AgentHistoricalEvidenceRequestDto.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'AgentHistoricalEvidenceResponseDto':
      return AgentHistoricalEvidenceResponseDto.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'AgentInstanceReleaseRequestDto':
      return AgentInstanceReleaseRequestDto.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'AgentInstanceReleaseRequestReceiptsItemDto':
      return AgentInstanceReleaseRequestReceiptsItemDto.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'AgentInstanceReleaseResponseDto':
      return AgentInstanceReleaseResponseDto.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'AgentKnownLeaseDto':
      return AgentKnownLeaseDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentKnownLeaseTerminalResultHashesItemDto':
      return AgentKnownLeaseTerminalResultHashesItemDto.fromJson(
        value as Map<String, dynamic>,
      ) as ReturnType;
    case 'AgentLeaseDto':
      return AgentLeaseDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentOperatorRecoveryDto':
      return AgentOperatorRecoveryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentReconcileDecisionDto':
      return AgentReconcileDecisionDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentReconcileRequestDto':
      return AgentReconcileRequestDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentReconcileResponseDto':
      return AgentReconcileResponseDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentResourceBytesDto':
      return AgentResourceBytesDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentResourceManifestDto':
      return AgentResourceManifestDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AgentSuitePolicyDto':
      return AgentSuitePolicyDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ApiErrorDetail':
      return ApiErrorDetail.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ApiErrorResponse':
      return ApiErrorResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ArtifactDownload':
      return ArtifactDownload.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ArtifactInput':
      return ArtifactInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ArtifactResponse':
      return ArtifactResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AuditPage':
      return AuditPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AuditResponse':
      return AuditResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'BaselineInput':
      return BaselineInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ChangedNode':
      return ChangedNode.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ComparisonResponse':
      return ComparisonResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DependencyPin':
      return DependencyPin.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DesktopExchangeInput':
      return DesktopExchangeInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DesktopSessionResponse':
      return DesktopSessionResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DraftInput':
      return DraftInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DraftPage':
      return DraftPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'DraftResponse':
      return DraftResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EventBatchInput':
      return EventBatchInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EventsResponse':
      return EventsResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExecutionCaseRun':
      return ExecutionCaseRun.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExecutionInput':
      return ExecutionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExecutionPage':
      return ExecutionPage.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExecutionResponse':
      return ExecutionResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HealthResponse':
      return HealthResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'IdentityResponse':
      return IdentityResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LogoutResponse':
      return LogoutResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'NotificationPage':
      return NotificationPage.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'NotificationResponse':
      return NotificationResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OperatorRecoveryInput':
      return OperatorRecoveryInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'OperatorRecoveryResponse':
      return OperatorRecoveryResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PinInput':
      return PinInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PinPage':
      return PinPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PinResponse':
      return PinResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProjectPage':
      return ProjectPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ProjectResponse':
      return ProjectResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PublishInput':
      return PublishInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ResultInput':
      return ResultInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RunInput':
      return RunInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RunPage':
      return RunPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'RunResponse':
      return RunResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ScheduleEnabledInput':
      return ScheduleEnabledInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ScheduleInput':
      return ScheduleInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ScheduleOccurrencePage':
      return ScheduleOccurrencePage.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ScheduleOccurrenceResponse':
      return ScheduleOccurrenceResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SchedulePage':
      return SchedulePage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ScheduleResponse':
      return ScheduleResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SessionResponse':
      return SessionResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SuiteCase':
      return SuiteCase.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SuiteDraftInput':
      return SuiteDraftInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SuiteDraftPage':
      return SuiteDraftPage.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SuiteDraftResponse':
      return SuiteDraftResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SuitePage':
      return SuitePage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SuiteResponse':
      return SuiteResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'UpgradeDiffResponse':
      return UpgradeDiffResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VersionPage':
      return VersionPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'VersionResponse':
      return VersionResponse.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'WorkInput':
      return WorkInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'WorkResponse':
      return WorkResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
    default:
      RegExpMatch? match;

      if (value is List && (match = _regList.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toList(growable: growable)
            as ReturnType;
      }
      if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toSet()
            as ReturnType;
      }
      if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
        targetType = match![1]!.trim(); // ignore: parameter_assignments
        return Map<String, BaseType>.fromIterables(
          value.keys as Iterable<String>,
          value.values.map(
            (dynamic v) => deserialize<BaseType, BaseType>(
              v,
              targetType,
              growable: growable,
            ),
          ),
        ) as ReturnType;
      }
      break;
  }
  throw Exception('Cannot deserialize');
}
