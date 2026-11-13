//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'project_member_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProjectMemberResponse {
  /// Returns a new [ProjectMemberResponse] instance.
  ProjectMemberResponse({
    required this.displayName,

    required this.role,

    required this.userId,
  });

  /// Null: the current identity store has no display name field.
  @JsonKey(name: r'displayName', required: true, includeIfNull: true)
  final String? displayName;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final ProjectMemberResponseRoleEnum role;

  @JsonKey(name: r'userId', required: true, includeIfNull: false)
  final String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectMemberResponse &&
          other.displayName == displayName &&
          other.role == role &&
          other.userId == userId;

  @override
  int get hashCode =>
      (displayName == null ? 0 : displayName.hashCode) +
      role.hashCode +
      userId.hashCode;

  factory ProjectMemberResponse.fromJson(Map<String, dynamic> json) =>
      _$ProjectMemberResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectMemberResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ProjectMemberResponseRoleEnum {
  @JsonValue(r'viewer')
  viewer(r'viewer'),
  @JsonValue(r'qa_tester')
  qaTester(r'qa_tester'),
  @JsonValue(r'qa_editor')
  qaEditor(r'qa_editor'),
  @JsonValue(r'qa_manager')
  qaManager(r'qa_manager'),
  @JsonValue(r'system_admin')
  systemAdmin(r'system_admin');

  const ProjectMemberResponseRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
