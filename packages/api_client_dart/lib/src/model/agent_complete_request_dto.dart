//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_artifact_manifest_dto.dart';
import 'package:api_client_dart/src/model/agent_case_result_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_complete_request_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentCompleteRequestDto {
  /// Returns a new [AgentCompleteRequestDto] instance.
  AgentCompleteRequestDto({
    required this.agentId,

    required this.artifactManifest,

    required this.caseResults,

    required this.cleanupState,

    required this.executionStatus,

    required this.fence,

    required this.instanceId,

    required this.reason,
  });

  @JsonKey(name: r'agentId', required: true, includeIfNull: false)
  final String agentId;

  @JsonKey(name: r'artifactManifest', required: true, includeIfNull: false)
  final List<AgentArtifactManifestDto> artifactManifest;

  @JsonKey(name: r'caseResults', required: true, includeIfNull: false)
  final List<AgentCaseResultDto> caseResults;

  @JsonKey(name: r'cleanupState', required: true, includeIfNull: false)
  final AgentCompleteRequestDtoCleanupStateEnum cleanupState;

  @JsonKey(name: r'executionStatus', required: true, includeIfNull: false)
  final AgentCompleteRequestDtoExecutionStatusEnum executionStatus;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'fence', required: true, includeIfNull: false)
  final int fence;

  @JsonKey(name: r'instanceId', required: true, includeIfNull: false)
  final String instanceId;

  @JsonKey(name: r'reason', required: true, includeIfNull: true)
  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentCompleteRequestDto &&
          other.agentId == agentId &&
          other.artifactManifest == artifactManifest &&
          other.caseResults == caseResults &&
          other.cleanupState == cleanupState &&
          other.executionStatus == executionStatus &&
          other.fence == fence &&
          other.instanceId == instanceId &&
          other.reason == reason;

  @override
  int get hashCode =>
      agentId.hashCode +
      artifactManifest.hashCode +
      caseResults.hashCode +
      cleanupState.hashCode +
      executionStatus.hashCode +
      fence.hashCode +
      instanceId.hashCode +
      (reason == null ? 0 : reason.hashCode);

  factory AgentCompleteRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AgentCompleteRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentCompleteRequestDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentCompleteRequestDtoCleanupStateEnum {
  @JsonValue(r'confirmed')
  confirmed(r'confirmed'),
  @JsonValue(r'unknown')
  unknown(r'unknown'),
  @JsonValue(r'failed')
  failed(r'failed');

  const AgentCompleteRequestDtoCleanupStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AgentCompleteRequestDtoExecutionStatusEnum {
  @JsonValue(r'finished')
  finished(r'finished'),
  @JsonValue(r'blocked')
  blocked(r'blocked'),
  @JsonValue(r'infra_error')
  infraError(r'infra_error'),
  @JsonValue(r'cancelled')
  cancelled(r'cancelled');

  const AgentCompleteRequestDtoExecutionStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
