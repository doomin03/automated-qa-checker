//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_execution_policy_native_apps_item_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_execution_policy_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentExecutionPolicyDto {
  /// Returns a new [AgentExecutionPolicyDto] instance.
  AgentExecutionPolicyDto({
    this.allowedOrigins = const [],

    this.allowProduction = false,

    this.nativeApps = const [],

    required this.platform,

    required this.resourceKey,

    this.secretRefs = const [],
  });

  @JsonKey(
    defaultValue: [],
    name: r'allowedOrigins',
    required: true,
    includeIfNull: false,
  )
  final List<String> allowedOrigins;

  /// Production execution requires BOTH this server policy and explicit local opt-in. Missing means deny.
  @JsonKey(
    defaultValue: false,
    name: r'allowProduction',
    required: true,
    includeIfNull: false,
  )
  final bool allowProduction;

  @JsonKey(
    defaultValue: [],
    name: r'nativeApps',
    required: true,
    includeIfNull: false,
  )
  final List<AgentExecutionPolicyNativeAppsItemDto> nativeApps;

  @JsonKey(name: r'platform', required: true, includeIfNull: false)
  final AgentExecutionPolicyDtoPlatformEnum platform;

  /// Must equal Lease.resourceKey; resolves only through registered local physical device/browser slot mapping.
  @JsonKey(name: r'resourceKey', required: true, includeIfNull: false)
  final String resourceKey;

  @JsonKey(
    defaultValue: [],
    name: r'secretRefs',
    required: true,
    includeIfNull: false,
  )
  final List<String> secretRefs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentExecutionPolicyDto &&
          other.allowedOrigins == allowedOrigins &&
          other.allowProduction == allowProduction &&
          other.nativeApps == nativeApps &&
          other.platform == platform &&
          other.resourceKey == resourceKey &&
          other.secretRefs == secretRefs;

  @override
  int get hashCode =>
      allowedOrigins.hashCode +
      allowProduction.hashCode +
      nativeApps.hashCode +
      platform.hashCode +
      resourceKey.hashCode +
      secretRefs.hashCode;

  factory AgentExecutionPolicyDto.fromJson(Map<String, dynamic> json) =>
      _$AgentExecutionPolicyDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentExecutionPolicyDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentExecutionPolicyDtoPlatformEnum {
  @JsonValue(r'web')
  web(r'web'),
  @JsonValue(r'android')
  android(r'android'),
  @JsonValue(r'ios')
  ios(r'ios');

  const AgentExecutionPolicyDtoPlatformEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
