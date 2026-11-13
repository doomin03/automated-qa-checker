//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_events_response_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentEventsResponseDto {
  /// Returns a new [AgentEventsResponseDto] instance.
  AgentEventsResponseDto({
    required this.acceptedThrough,

    required this.fence,

    required this.leaseId,
  });

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(name: r'acceptedThrough', required: true, includeIfNull: false)
  final int acceptedThrough;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'fence', required: true, includeIfNull: false)
  final int fence;

  @JsonKey(name: r'leaseId', required: true, includeIfNull: false)
  final String leaseId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentEventsResponseDto &&
          other.acceptedThrough == acceptedThrough &&
          other.fence == fence &&
          other.leaseId == leaseId;

  @override
  int get hashCode =>
      acceptedThrough.hashCode + fence.hashCode + leaseId.hashCode;

  factory AgentEventsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AgentEventsResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentEventsResponseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
