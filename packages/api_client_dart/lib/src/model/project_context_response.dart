//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/project_engine_context.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project_context_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProjectContextResponse {
  /// Returns a new [ProjectContextResponse] instance.
  ProjectContextResponse({
    required this.allowedActions,

    required this.engine,

    required this.projectId,

    required this.role,
  });

  /// Role-level entry hints for these capabilities only. Mutations still enforce current membership, ownership, independent review, revision and runtime compatibility.
  @JsonKey(name: r'allowedActions', required: true, includeIfNull: false)
  final List<ProjectContextResponseAllowedActionsEnum> allowedActions;

  @JsonKey(name: r'engine', required: true, includeIfNull: false)
  final ProjectEngineContext engine;

  @JsonKey(name: r'projectId', required: true, includeIfNull: false)
  final String projectId;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final ProjectContextResponseRoleEnum role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectContextResponse &&
          other.allowedActions == allowedActions &&
          other.engine == engine &&
          other.projectId == projectId &&
          other.role == role;

  @override
  int get hashCode =>
      allowedActions.hashCode +
      engine.hashCode +
      projectId.hashCode +
      role.hashCode;

  factory ProjectContextResponse.fromJson(Map<String, dynamic> json) =>
      _$ProjectContextResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectContextResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ProjectContextResponseAllowedActionsEnum {
  @JsonValue(r'readPublished')
  readPublished(r'readPublished'),
  @JsonValue(r'pinVersions')
  pinVersions(r'pinVersions'),
  @JsonValue(r'publishRuns')
  publishRuns(r'publishRuns'),
  @JsonValue(r'requestExecutions')
  requestExecutions(r'requestExecutions'),
  @JsonValue(r'manageSchedules')
  manageSchedules(r'manageSchedules'),
  @JsonValue(r'updateWork')
  updateWork(r'updateWork'),
  @JsonValue(r'createDrafts')
  createDrafts(r'createDrafts'),
  @JsonValue(r'reviewPublish')
  reviewPublish(r'reviewPublish'),
  @JsonValue(r'viewAudit')
  viewAudit(r'viewAudit'),
  @JsonValue(r'listMembers')
  listMembers(r'listMembers');

  const ProjectContextResponseAllowedActionsEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ProjectContextResponseRoleEnum {
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

  const ProjectContextResponseRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
