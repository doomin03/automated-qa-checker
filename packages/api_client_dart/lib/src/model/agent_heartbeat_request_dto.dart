//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_heartbeat_request_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentHeartbeatRequestDto {
  /// Returns a new [AgentHeartbeatRequestDto] instance.
  AgentHeartbeatRequestDto({
    required this.agentId,

    required this.cleanupState,

    required this.fence,

    required this.instanceId,

    required this.lastAcknowledgedSequence,
  });

  @JsonKey(name: r'agentId', required: true, includeIfNull: false)
  final String agentId;

  @JsonKey(name: r'cleanupState', required: true, includeIfNull: false)
  final AgentHeartbeatRequestDtoCleanupStateEnum cleanupState;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'fence', required: true, includeIfNull: false)
  final int fence;

  @JsonKey(name: r'instanceId', required: true, includeIfNull: false)
  final String instanceId;

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(
    name: r'lastAcknowledgedSequence',
    required: true,
    includeIfNull: false,
  )
  final int lastAcknowledgedSequence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentHeartbeatRequestDto &&
          other.agentId == agentId &&
          other.cleanupState == cleanupState &&
          other.fence == fence &&
          other.instanceId == instanceId &&
          other.lastAcknowledgedSequence == lastAcknowledgedSequence;

  @override
  int get hashCode =>
      agentId.hashCode +
      cleanupState.hashCode +
      fence.hashCode +
      instanceId.hashCode +
      lastAcknowledgedSequence.hashCode;

  factory AgentHeartbeatRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AgentHeartbeatRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentHeartbeatRequestDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentHeartbeatRequestDtoCleanupStateEnum {
  @JsonValue(r'confirmed')
  confirmed(r'confirmed'),
  @JsonValue(r'unknown')
  unknown(r'unknown'),
  @JsonValue(r'failed')
  failed(r'failed');

  const AgentHeartbeatRequestDtoCleanupStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
