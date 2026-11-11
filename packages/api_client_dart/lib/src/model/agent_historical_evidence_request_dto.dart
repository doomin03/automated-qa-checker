//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_delivery_dto.dart';
import 'package:api_client_dart/src/model/agent_historical_artifact_dto.dart';
import 'package:api_client_dart/src/model/agent_case_result_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_historical_evidence_request_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentHistoricalEvidenceRequestDto {
  /// Returns a new [AgentHistoricalEvidenceRequestDto] instance.
  AgentHistoricalEvidenceRequestDto({
    required this.agentId,

    this.artifact,

    required this.caseResults,

    required this.cleanupState,

    required this.events,

    required this.evidenceRequestId,

    required this.fence,

    required this.ownerInstanceId,

    required this.reportingInstanceId,
  });

  @JsonKey(name: r'agentId', required: true, includeIfNull: false)
  final String agentId;

  @JsonKey(name: r'artifact', required: false, includeIfNull: false)
  final AgentHistoricalArtifactDto? artifact;

  @JsonKey(name: r'caseResults', required: true, includeIfNull: false)
  final List<AgentCaseResultDto> caseResults;

  @JsonKey(name: r'cleanupState', required: true, includeIfNull: false)
  final AgentHistoricalEvidenceRequestDtoCleanupStateEnum cleanupState;

  @JsonKey(name: r'events', required: true, includeIfNull: false)
  final List<AgentDeliveryDto> events;

  @JsonKey(name: r'evidenceRequestId', required: true, includeIfNull: false)
  final String evidenceRequestId;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'fence', required: true, includeIfNull: false)
  final int fence;

  @JsonKey(name: r'ownerInstanceId', required: true, includeIfNull: false)
  final String ownerInstanceId;

  @JsonKey(name: r'reportingInstanceId', required: true, includeIfNull: false)
  final String reportingInstanceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentHistoricalEvidenceRequestDto &&
          other.agentId == agentId &&
          other.artifact == artifact &&
          other.caseResults == caseResults &&
          other.cleanupState == cleanupState &&
          other.events == events &&
          other.evidenceRequestId == evidenceRequestId &&
          other.fence == fence &&
          other.ownerInstanceId == ownerInstanceId &&
          other.reportingInstanceId == reportingInstanceId;

  @override
  int get hashCode =>
      agentId.hashCode +
      artifact.hashCode +
      caseResults.hashCode +
      cleanupState.hashCode +
      events.hashCode +
      evidenceRequestId.hashCode +
      fence.hashCode +
      ownerInstanceId.hashCode +
      reportingInstanceId.hashCode;

  factory AgentHistoricalEvidenceRequestDto.fromJson(
    Map<String, dynamic> json,
  ) => _$AgentHistoricalEvidenceRequestDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AgentHistoricalEvidenceRequestDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentHistoricalEvidenceRequestDtoCleanupStateEnum {
  @JsonValue(r'confirmed')
  confirmed(r'confirmed'),
  @JsonValue(r'unknown')
  unknown(r'unknown'),
  @JsonValue(r'failed')
  failed(r'failed');

  const AgentHistoricalEvidenceRequestDtoCleanupStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
