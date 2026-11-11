//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_delivery_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_events_request_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentEventsRequestDto {
  /// Returns a new [AgentEventsRequestDto] instance.
  AgentEventsRequestDto({
    required this.agentId,

    required this.events,

    required this.fence,

    required this.instanceId,
  });

  @JsonKey(name: r'agentId', required: true, includeIfNull: false)
  final String agentId;

  @JsonKey(name: r'events', required: true, includeIfNull: false)
  final List<AgentDeliveryDto> events;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'fence', required: true, includeIfNull: false)
  final int fence;

  @JsonKey(name: r'instanceId', required: true, includeIfNull: false)
  final String instanceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentEventsRequestDto &&
          other.agentId == agentId &&
          other.events == events &&
          other.fence == fence &&
          other.instanceId == instanceId;

  @override
  int get hashCode =>
      agentId.hashCode + events.hashCode + fence.hashCode + instanceId.hashCode;

  factory AgentEventsRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AgentEventsRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentEventsRequestDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
