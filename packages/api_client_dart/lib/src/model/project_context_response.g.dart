// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_context_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectContextResponse _$ProjectContextResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ProjectContextResponse', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['allowedActions', 'engine', 'projectId', 'role'],
  );
  final val = ProjectContextResponse(
    allowedActions: $checkedConvert(
      'allowedActions',
      (v) => (v as List<dynamic>)
          .map(
            (e) => $enumDecode(
              _$ProjectContextResponseAllowedActionsEnumEnumMap,
              e,
            ),
          )
          .toList(),
    ),
    engine: $checkedConvert(
      'engine',
      (v) => ProjectEngineContext.fromJson(v as Map<String, dynamic>),
    ),
    projectId: $checkedConvert('projectId', (v) => v as String),
    role: $checkedConvert(
      'role',
      (v) => $enumDecode(_$ProjectContextResponseRoleEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$ProjectContextResponseToJson(
  ProjectContextResponse instance,
) => <String, dynamic>{
  'allowedActions': instance.allowedActions
      .map((e) => _$ProjectContextResponseAllowedActionsEnumEnumMap[e]!)
      .toList(),
  'engine': instance.engine.toJson(),
  'projectId': instance.projectId,
  'role': _$ProjectContextResponseRoleEnumEnumMap[instance.role]!,
};

const _$ProjectContextResponseAllowedActionsEnumEnumMap = {
  ProjectContextResponseAllowedActionsEnum.readPublished: 'readPublished',
  ProjectContextResponseAllowedActionsEnum.pinVersions: 'pinVersions',
  ProjectContextResponseAllowedActionsEnum.publishRuns: 'publishRuns',
  ProjectContextResponseAllowedActionsEnum.requestExecutions:
      'requestExecutions',
  ProjectContextResponseAllowedActionsEnum.manageSchedules: 'manageSchedules',
  ProjectContextResponseAllowedActionsEnum.updateWork: 'updateWork',
  ProjectContextResponseAllowedActionsEnum.createDrafts: 'createDrafts',
  ProjectContextResponseAllowedActionsEnum.reviewPublish: 'reviewPublish',
  ProjectContextResponseAllowedActionsEnum.viewAudit: 'viewAudit',
  ProjectContextResponseAllowedActionsEnum.listMembers: 'listMembers',
};

const _$ProjectContextResponseRoleEnumEnumMap = {
  ProjectContextResponseRoleEnum.viewer: 'viewer',
  ProjectContextResponseRoleEnum.qaTester: 'qa_tester',
  ProjectContextResponseRoleEnum.qaEditor: 'qa_editor',
  ProjectContextResponseRoleEnum.qaManager: 'qa_manager',
  ProjectContextResponseRoleEnum.systemAdmin: 'system_admin',
};
