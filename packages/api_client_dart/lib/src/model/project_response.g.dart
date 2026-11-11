// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectResponse _$ProjectResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProjectResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'name', 'role']);
      final val = ProjectResponse(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$ProjectResponseRoleEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ProjectResponseToJson(ProjectResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'role': _$ProjectResponseRoleEnumEnumMap[instance.role]!,
    };

const _$ProjectResponseRoleEnumEnumMap = {
  ProjectResponseRoleEnum.viewer: 'viewer',
  ProjectResponseRoleEnum.qaTester: 'qa_tester',
  ProjectResponseRoleEnum.qaEditor: 'qa_editor',
  ProjectResponseRoleEnum.qaManager: 'qa_manager',
  ProjectResponseRoleEnum.systemAdmin: 'system_admin',
};
