// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_user_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedUserResponse _$ManagedUserResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ManagedUserResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'active',
          'displayName',
          'membershipRevision',
          'role',
          'userId',
          'userRevision',
        ],
      );
      final val = ManagedUserResponse(
        active: $checkedConvert('active', (v) => v as bool),
        displayName: $checkedConvert('displayName', (v) => v as String?),
        membershipRevision: $checkedConvert(
          'membershipRevision',
          (v) => (v as num).toInt(),
        ),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$ManagedUserResponseRoleEnumEnumMap, v),
        ),
        userId: $checkedConvert('userId', (v) => v as String),
        userRevision: $checkedConvert(
          'userRevision',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ManagedUserResponseToJson(
  ManagedUserResponse instance,
) => <String, dynamic>{
  'active': instance.active,
  'displayName': instance.displayName,
  'membershipRevision': instance.membershipRevision,
  'role': _$ManagedUserResponseRoleEnumEnumMap[instance.role]!,
  'userId': instance.userId,
  'userRevision': instance.userRevision,
};

const _$ManagedUserResponseRoleEnumEnumMap = {
  ManagedUserResponseRoleEnum.viewer: 'viewer',
  ManagedUserResponseRoleEnum.qaTester: 'qa_tester',
  ManagedUserResponseRoleEnum.qaEditor: 'qa_editor',
  ManagedUserResponseRoleEnum.qaManager: 'qa_manager',
  ManagedUserResponseRoleEnum.systemAdmin: 'system_admin',
};
