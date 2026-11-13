//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/project_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SessionResponse {
  /// Returns a new [SessionResponse] instance.
  SessionResponse({
    required this.csrfToken,

    required this.localMode,

    required this.projects,

    required this.userId,
  });

  @JsonKey(name: r'csrfToken', required: true, includeIfNull: true)
  final String? csrfToken;

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
      other is SessionResponse &&
          other.csrfToken == csrfToken &&
          other.localMode == localMode &&
          other.projects == projects &&
          other.userId == userId;

  @override
  int get hashCode =>
      (csrfToken == null ? 0 : csrfToken.hashCode) +
      localMode.hashCode +
      projects.hashCode +
      userId.hashCode;

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SessionResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
