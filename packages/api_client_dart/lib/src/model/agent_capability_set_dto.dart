//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_capability_set_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentCapabilitySetDto {
  /// Returns a new [AgentCapabilitySetDto] instance.
  AgentCapabilitySetDto({this.actions = const [], this.platforms = const []});

  @JsonKey(
    defaultValue: [],
    name: r'actions',
    required: true,
    includeIfNull: false,
  )
  final List<String> actions;

  @JsonKey(
    defaultValue: [],
    name: r'platforms',
    required: true,
    includeIfNull: false,
  )
  final List<AgentCapabilitySetDtoPlatformsEnum> platforms;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentCapabilitySetDto &&
          other.actions == actions &&
          other.platforms == platforms;

  @override
  int get hashCode => actions.hashCode + platforms.hashCode;

  factory AgentCapabilitySetDto.fromJson(Map<String, dynamic> json) =>
      _$AgentCapabilitySetDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentCapabilitySetDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentCapabilitySetDtoPlatformsEnum {
  @JsonValue(r'web')
  web(r'web'),
  @JsonValue(r'android')
  android(r'android'),
  @JsonValue(r'ios')
  ios(r'ios');

  const AgentCapabilitySetDtoPlatformsEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
