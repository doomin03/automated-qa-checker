//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_suite_policy_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentSuitePolicyDto {
  /// Returns a new [AgentSuitePolicyDto] instance.
  AgentSuitePolicyDto({
    required this.publishedSha256,

    required this.publishedVersionId,

    required this.stopOnFailure,
  });

  @JsonKey(name: r'publishedSha256', required: true, includeIfNull: true)
  final String? publishedSha256;

  @JsonKey(name: r'publishedVersionId', required: true, includeIfNull: true)
  final String? publishedVersionId;

  @JsonKey(name: r'stopOnFailure', required: true, includeIfNull: false)
  final bool stopOnFailure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentSuitePolicyDto &&
          other.publishedSha256 == publishedSha256 &&
          other.publishedVersionId == publishedVersionId &&
          other.stopOnFailure == stopOnFailure;

  @override
  int get hashCode =>
      (publishedSha256 == null ? 0 : publishedSha256.hashCode) +
      (publishedVersionId == null ? 0 : publishedVersionId.hashCode) +
      stopOnFailure.hashCode;

  factory AgentSuitePolicyDto.fromJson(Map<String, dynamic> json) =>
      _$AgentSuitePolicyDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentSuitePolicyDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
