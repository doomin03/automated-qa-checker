//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'project_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProjectResponse {
  /// Returns a new [ProjectResponse] instance.
  ProjectResponse({required this.id, required this.name, required this.role});

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final ProjectResponseRoleEnum role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectResponse &&
          other.id == id &&
          other.name == name &&
          other.role == role;

  @override
  int get hashCode => id.hashCode + name.hashCode + role.hashCode;

  factory ProjectResponse.fromJson(Map<String, dynamic> json) =>
      _$ProjectResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ProjectResponseRoleEnum {
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

  const ProjectResponseRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
