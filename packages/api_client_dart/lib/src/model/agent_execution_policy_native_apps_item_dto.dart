//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_execution_policy_native_apps_item_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentExecutionPolicyNativeAppsItemDto {
  /// Returns a new [AgentExecutionPolicyNativeAppsItemDto] instance.
  AgentExecutionPolicyNativeAppsItemDto({
    this.activities = const [],

    required this.appId,

    required this.platform,
  });

  @JsonKey(
    defaultValue: [],
    name: r'activities',
    required: true,
    includeIfNull: false,
  )
  final List<String> activities;

  @JsonKey(name: r'appId', required: true, includeIfNull: false)
  final String appId;

  @JsonKey(name: r'platform', required: true, includeIfNull: false)
  final AgentExecutionPolicyNativeAppsItemDtoPlatformEnum platform;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentExecutionPolicyNativeAppsItemDto &&
          other.activities == activities &&
          other.appId == appId &&
          other.platform == platform;

  @override
  int get hashCode => activities.hashCode + appId.hashCode + platform.hashCode;

  factory AgentExecutionPolicyNativeAppsItemDto.fromJson(
    Map<String, dynamic> json,
  ) => _$AgentExecutionPolicyNativeAppsItemDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AgentExecutionPolicyNativeAppsItemDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentExecutionPolicyNativeAppsItemDtoPlatformEnum {
  @JsonValue(r'android')
  android(r'android'),
  @JsonValue(r'ios')
  ios(r'ios');

  const AgentExecutionPolicyNativeAppsItemDtoPlatformEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
