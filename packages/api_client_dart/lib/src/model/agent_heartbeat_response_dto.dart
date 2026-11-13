//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_heartbeat_response_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentHeartbeatResponseDto {
  /// Returns a new [AgentHeartbeatResponseDto] instance.
  AgentHeartbeatResponseDto({
    required this.acceptedThrough,

    required this.cancelRequested,

    required this.fence,

    required this.leaseId,

    required this.state,

    required this.validForMs,
  });

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(name: r'acceptedThrough', required: true, includeIfNull: false)
  final int acceptedThrough;

  @JsonKey(name: r'cancelRequested', required: true, includeIfNull: false)
  final bool cancelRequested;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'fence', required: true, includeIfNull: false)
  final int fence;

  @JsonKey(name: r'leaseId', required: true, includeIfNull: false)
  final String leaseId;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final AgentHeartbeatResponseDtoStateEnum state;

  // minimum: 0
  // maximum: 30000
  @JsonKey(name: r'validForMs', required: true, includeIfNull: false)
  final int validForMs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentHeartbeatResponseDto &&
          other.acceptedThrough == acceptedThrough &&
          other.cancelRequested == cancelRequested &&
          other.fence == fence &&
          other.leaseId == leaseId &&
          other.state == state &&
          other.validForMs == validForMs;

  @override
  int get hashCode =>
      acceptedThrough.hashCode +
      cancelRequested.hashCode +
      fence.hashCode +
      leaseId.hashCode +
      state.hashCode +
      validForMs.hashCode;

  factory AgentHeartbeatResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AgentHeartbeatResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentHeartbeatResponseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentHeartbeatResponseDtoStateEnum {
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'reporting')
  reporting(r'reporting'),
  @JsonValue(r'expired')
  expired(r'expired'),
  @JsonValue(r'quarantined')
  quarantined(r'quarantined');

  const AgentHeartbeatResponseDtoStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
