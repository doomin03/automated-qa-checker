//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_capability_set_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_claim_request_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentClaimRequestDto {
  /// Returns a new [AgentClaimRequestDto] instance.
  AgentClaimRequestDto({
    required this.agentId,

    required this.capabilities,

    required this.claimRequestId,

    required this.engineContractSha256,

    required this.engineContractVersion,

    required this.engineVersion,

    required this.instanceId,

    required this.projectIds,

    required this.protocolVersion,

    required this.resourceKeys,
  });

  @JsonKey(name: r'agentId', required: true, includeIfNull: false)
  final String agentId;

  @JsonKey(name: r'capabilities', required: true, includeIfNull: false)
  final AgentCapabilitySetDto capabilities;

  @JsonKey(name: r'claimRequestId', required: true, includeIfNull: false)
  final String claimRequestId;

  /// SHA-256 of exact public Engine contracts/releases/qa-contract-<engineVersion>.json bytes; not the runtime file manifest or npm tarball hash.
  @JsonKey(name: r'engineContractSha256', required: true, includeIfNull: false)
  final String engineContractSha256;

  @JsonKey(name: r'engineContractVersion', required: true, includeIfNull: false)
  final String engineContractVersion;

  @JsonKey(name: r'engineVersion', required: true, includeIfNull: false)
  final String engineVersion;

  @JsonKey(name: r'instanceId', required: true, includeIfNull: false)
  final String instanceId;

  @JsonKey(name: r'projectIds', required: true, includeIfNull: false)
  final List<String> projectIds;

  @JsonKey(name: r'protocolVersion', required: true, includeIfNull: false)
  final AgentClaimRequestDtoProtocolVersionEnum protocolVersion;

  @JsonKey(name: r'resourceKeys', required: true, includeIfNull: false)
  final List<String> resourceKeys;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentClaimRequestDto &&
          other.agentId == agentId &&
          other.capabilities == capabilities &&
          other.claimRequestId == claimRequestId &&
          other.engineContractSha256 == engineContractSha256 &&
          other.engineContractVersion == engineContractVersion &&
          other.engineVersion == engineVersion &&
          other.instanceId == instanceId &&
          other.projectIds == projectIds &&
          other.protocolVersion == protocolVersion &&
          other.resourceKeys == resourceKeys;

  @override
  int get hashCode =>
      agentId.hashCode +
      capabilities.hashCode +
      claimRequestId.hashCode +
      engineContractSha256.hashCode +
      engineContractVersion.hashCode +
      engineVersion.hashCode +
      instanceId.hashCode +
      projectIds.hashCode +
      protocolVersion.hashCode +
      resourceKeys.hashCode;

  factory AgentClaimRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AgentClaimRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentClaimRequestDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentClaimRequestDtoProtocolVersionEnum {
  @JsonValue(r'0.1.0-draft.1')
  n0period1Period0DraftPeriod1(r'0.1.0-draft.1');

  const AgentClaimRequestDtoProtocolVersionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
