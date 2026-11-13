//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/project_member_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project_member_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProjectMemberPage {
  /// Returns a new [ProjectMemberPage] instance.
  ProjectMemberPage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<ProjectMemberResponse> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectMemberPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory ProjectMemberPage.fromJson(Map<String, dynamic> json) =>
      _$ProjectMemberPageFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectMemberPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
