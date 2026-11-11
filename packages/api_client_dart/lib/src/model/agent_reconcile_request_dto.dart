//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_known_lease_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_reconcile_request_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentReconcileRequestDto {
  /// Returns a new [AgentReconcileRequestDto] instance.
  AgentReconcileRequestDto({
    required this.agentId,

    required this.instanceId,

    required this.knownLeases,
  });

  @JsonKey(name: r'agentId', required: true, includeIfNull: false)
  final String agentId;

  @JsonKey(name: r'instanceId', required: true, includeIfNull: false)
  final String instanceId;

  @JsonKey(name: r'knownLeases', required: true, includeIfNull: false)
  final List<AgentKnownLeaseDto> knownLeases;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentReconcileRequestDto &&
          other.agentId == agentId &&
          other.instanceId == instanceId &&
          other.knownLeases == knownLeases;

  @override
  int get hashCode =>
      agentId.hashCode + instanceId.hashCode + knownLeases.hashCode;

  factory AgentReconcileRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AgentReconcileRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentReconcileRequestDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
