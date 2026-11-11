//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/project_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'identity_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IdentityResponse {
  /// Returns a new [IdentityResponse] instance.
  IdentityResponse({
    required this.localMode,

    required this.projects,

    required this.userId,
  });

  /// True for the explicitly configured local/test identity mode.
  @JsonKey(name: r'localMode', required: true, includeIfNull: false)
  final bool localMode;

  @JsonKey(name: r'projects', required: true, includeIfNull: false)
  final List<ProjectResponse> projects;

  @JsonKey(name: r'userId', required: true, includeIfNull: false)
  final String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentityResponse &&
          other.localMode == localMode &&
          other.projects == projects &&
          other.userId == userId;

  @override
  int get hashCode => localMode.hashCode + projects.hashCode + userId.hashCode;

  factory IdentityResponse.fromJson(Map<String, dynamic> json) =>
      _$IdentityResponseFromJson(json);

  Map<String, dynamic> toJson() => _$IdentityResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
