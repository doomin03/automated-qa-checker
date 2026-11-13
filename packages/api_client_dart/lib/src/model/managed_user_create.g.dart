// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_user_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedUserCreate _$ManagedUserCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ManagedUserCreate', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['displayName', 'role', 'userId']);
      final val = ManagedUserCreate(
        displayName: $checkedConvert('displayName', (v) => v as String?),
        role: $checkedConvert(
          'role',
          (v) => $enumDecode(_$ManagedUserCreateRoleEnumEnumMap, v),
        ),
        userId: $checkedConvert('userId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ManagedUserCreateToJson(ManagedUserCreate instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'role': _$ManagedUserCreateRoleEnumEnumMap[instance.role]!,
      'userId': instance.userId,
    };

const _$ManagedUserCreateRoleEnumEnumMap = {
  ManagedUserCreateRoleEnum.viewer: 'viewer',
  ManagedUserCreateRoleEnum.qaTester: 'qa_tester',
  ManagedUserCreateRoleEnum.qaEditor: 'qa_editor',
  ManagedUserCreateRoleEnum.qaManager: 'qa_manager',
};
