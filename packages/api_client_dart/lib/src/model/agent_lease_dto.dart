//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_case_snapshot_dto.dart';
import 'package:api_client_dart/src/model/agent_execution_policy_dto.dart';
import 'package:api_client_dart/src/model/agent_suite_policy_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_lease_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentLeaseDto {
  /// Returns a new [AgentLeaseDto] instance.
  AgentLeaseDto({
    required this.acceptedThrough,

    required this.agentId,

    required this.cancelRequested,

    required this.cases,

    required this.engineContractSha256,

    required this.engineContractVersion,

    required this.engineVersion,

    required this.executionId,

    required this.executionPolicy,

    required this.fence,

    required this.heartbeatIntervalMs,

    required this.instanceId,

    required this.jobAttempt,

    required this.leaseId,

    required this.projectId,

    required this.protocolVersion,

    required this.requestTimeoutMs,

    required this.resourceKey,

    required this.safetyMarginMs,

    required this.state,

    required this.suitePolicy,

    required this.validForMs,
  });

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(name: r'acceptedThrough', required: true, includeIfNull: false)
  final int acceptedThrough;

  @JsonKey(name: r'agentId', required: true, includeIfNull: false)
  final String agentId;

  @JsonKey(name: r'cancelRequested', required: true, includeIfNull: false)
  final bool cancelRequested;

  @JsonKey(name: r'cases', required: true, includeIfNull: false)
  final List<AgentCaseSnapshotDto> cases;

  /// SHA-256 of exact public Engine contracts/releases/qa-contract-<engineVersion>.json bytes; not the runtime file manifest or npm tarball hash.
  @JsonKey(name: r'engineContractSha256', required: true, includeIfNull: false)
  final String engineContractSha256;

  @JsonKey(name: r'engineContractVersion', required: true, includeIfNull: false)
  final String engineContractVersion;

  @JsonKey(name: r'engineVersion', required: true, includeIfNull: false)
  final String engineVersion;

  @JsonKey(name: r'executionId', required: true, includeIfNull: false)
  final String executionId;

  @JsonKey(name: r'executionPolicy', required: true, includeIfNull: false)
  final AgentExecutionPolicyDto executionPolicy;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'fence', required: true, includeIfNull: false)
  final int fence;

  @JsonKey(name: r'heartbeatIntervalMs', required: true, includeIfNull: false)
  final AgentLeaseDtoHeartbeatIntervalMsEnum heartbeatIntervalMs;

  @JsonKey(name: r'instanceId', required: true, includeIfNull: false)
  final String instanceId;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'jobAttempt', required: true, includeIfNull: false)
  final int jobAttempt;

  @JsonKey(name: r'leaseId', required: true, includeIfNull: false)
  final String leaseId;

  @JsonKey(name: r'projectId', required: true, includeIfNull: false)
  final String projectId;

  @JsonKey(name: r'protocolVersion', required: true, includeIfNull: false)
  final AgentLeaseDtoProtocolVersionEnum protocolVersion;

  @JsonKey(name: r'requestTimeoutMs', required: true, includeIfNull: false)
  final AgentLeaseDtoRequestTimeoutMsEnum requestTimeoutMs;

  @JsonKey(name: r'resourceKey', required: true, includeIfNull: false)
  final String resourceKey;

  @JsonKey(name: r'safetyMarginMs', required: true, includeIfNull: false)
  final AgentLeaseDtoSafetyMarginMsEnum safetyMarginMs;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final AgentLeaseDtoStateEnum state;

  @JsonKey(name: r'suitePolicy', required: true, includeIfNull: false)
  final AgentSuitePolicyDto suitePolicy;

  // minimum: 0
  // maximum: 30000
  @JsonKey(name: r'validForMs', required: true, includeIfNull: false)
  final int validForMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentLeaseDto &&
          other.acceptedThrough == acceptedThrough &&
          other.agentId == agentId &&
          other.cancelRequested == cancelRequested &&
          other.cases == cases &&
          other.engineContractSha256 == engineContractSha256 &&
          other.engineContractVersion == engineContractVersion &&
          other.engineVersion == engineVersion &&
          other.executionId == executionId &&
          other.executionPolicy == executionPolicy &&
          other.fence == fence &&
          other.heartbeatIntervalMs == heartbeatIntervalMs &&
          other.instanceId == instanceId &&
          other.jobAttempt == jobAttempt &&
          other.leaseId == leaseId &&
          other.projectId == projectId &&
          other.protocolVersion == protocolVersion &&
          other.requestTimeoutMs == requestTimeoutMs &&
          other.resourceKey == resourceKey &&
          other.safetyMarginMs == safetyMarginMs &&
          other.state == state &&
          other.suitePolicy == suitePolicy &&
          other.validForMs == validForMs;

  @override
  int get hashCode =>
      acceptedThrough.hashCode +
      agentId.hashCode +
      cancelRequested.hashCode +
      cases.hashCode +
      engineContractSha256.hashCode +
      engineContractVersion.hashCode +
      engineVersion.hashCode +
      executionId.hashCode +
      executionPolicy.hashCode +
      fence.hashCode +
      heartbeatIntervalMs.hashCode +
      instanceId.hashCode +
      jobAttempt.hashCode +
      leaseId.hashCode +
      projectId.hashCode +
      protocolVersion.hashCode +
      requestTimeoutMs.hashCode +
      resourceKey.hashCode +
      safetyMarginMs.hashCode +
      state.hashCode +
      suitePolicy.hashCode +
      validForMs.hashCode;

  factory AgentLeaseDto.fromJson(Map<String, dynamic> json) =>
      _$AgentLeaseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentLeaseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentLeaseDtoHeartbeatIntervalMsEnum {
  @JsonValue(5000)
  number5000('5000');

  const AgentLeaseDtoHeartbeatIntervalMsEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AgentLeaseDtoProtocolVersionEnum {
  @JsonValue(r'0.1.0-draft.1')
  n0period1Period0DraftPeriod1(r'0.1.0-draft.1');

  const AgentLeaseDtoProtocolVersionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AgentLeaseDtoRequestTimeoutMsEnum {
  @JsonValue(5000)
  number5000('5000');

  const AgentLeaseDtoRequestTimeoutMsEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AgentLeaseDtoSafetyMarginMsEnum {
  @JsonValue(5000)
  number5000('5000');

  const AgentLeaseDtoSafetyMarginMsEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AgentLeaseDtoStateEnum {
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'reporting')
  reporting(r'reporting'),
  @JsonValue(r'closed')
  closed(r'closed'),
  @JsonValue(r'expired')
  expired(r'expired'),
  @JsonValue(r'quarantined')
  quarantined(r'quarantined'),
  @JsonValue(r'recovered')
  recovered(r'recovered');

  const AgentLeaseDtoStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
