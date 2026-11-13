// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_member_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectMemberResponse _$ProjectMemberResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ProjectMemberResponse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['displayName', 'role', 'userId']);
  final val = ProjectMemberResponse(
    displayName: $checkedConvert('displayName', (v) => v as String?),
    role: $checkedConvert(
      'role',
      (v) => $enumDecode(_$ProjectMemberResponseRoleEnumEnumMap, v),
    ),
    userId: $checkedConvert('userId', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ProjectMemberResponseToJson(
  ProjectMemberResponse instance,
) => <String, dynamic>{
  'displayName': instance.displayName,
  'role': _$ProjectMemberResponseRoleEnumEnumMap[instance.role]!,
  'userId': instance.userId,
};

const _$ProjectMemberResponseRoleEnumEnumMap = {
  ProjectMemberResponseRoleEnum.viewer: 'viewer',
  ProjectMemberResponseRoleEnum.qaTester: 'qa_tester',
  ProjectMemberResponseRoleEnum.qaEditor: 'qa_editor',
  ProjectMemberResponseRoleEnum.qaManager: 'qa_manager',
  ProjectMemberResponseRoleEnum.systemAdmin: 'system_admin',
};
