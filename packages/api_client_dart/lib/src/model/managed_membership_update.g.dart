// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_membership_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedMembershipUpdate _$ManagedMembershipUpdateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ManagedMembershipUpdate', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['membershipRevision', 'role']);
  final val = ManagedMembershipUpdate(
    membershipRevision: $checkedConvert(
      'membershipRevision',
      (v) => (v as num).toInt(),
    ),
    role: $checkedConvert(
      'role',
      (v) => $enumDecode(_$ManagedMembershipUpdateRoleEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$ManagedMembershipUpdateToJson(
  ManagedMembershipUpdate instance,
) => <String, dynamic>{
  'membershipRevision': instance.membershipRevision,
  'role': _$ManagedMembershipUpdateRoleEnumEnumMap[instance.role]!,
};

const _$ManagedMembershipUpdateRoleEnumEnumMap = {
  ManagedMembershipUpdateRoleEnum.viewer: 'viewer',
  ManagedMembershipUpdateRoleEnum.qaTester: 'qa_tester',
  ManagedMembershipUpdateRoleEnum.qaEditor: 'qa_editor',
  ManagedMembershipUpdateRoleEnum.qaManager: 'qa_manager',
};
