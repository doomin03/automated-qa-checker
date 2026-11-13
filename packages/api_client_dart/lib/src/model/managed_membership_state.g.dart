// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_membership_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedMembershipState _$ManagedMembershipStateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ManagedMembershipState', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['membershipRevision', 'role', 'userId'],
  );
  final val = ManagedMembershipState(
    membershipRevision: $checkedConvert(
      'membershipRevision',
      (v) => (v as num).toInt(),
    ),
    role: $checkedConvert(
      'role',
      (v) => $enumDecodeNullable(_$ManagedMembershipStateRoleEnumEnumMap, v),
    ),
    userId: $checkedConvert('userId', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ManagedMembershipStateToJson(
  ManagedMembershipState instance,
) => <String, dynamic>{
  'membershipRevision': instance.membershipRevision,
  'role': _$ManagedMembershipStateRoleEnumEnumMap[instance.role],
  'userId': instance.userId,
};

const _$ManagedMembershipStateRoleEnumEnumMap = {
  ManagedMembershipStateRoleEnum.viewer: 'viewer',
  ManagedMembershipStateRoleEnum.qaTester: 'qa_tester',
  ManagedMembershipStateRoleEnum.qaEditor: 'qa_editor',
  ManagedMembershipStateRoleEnum.qaManager: 'qa_manager',
  ManagedMembershipStateRoleEnum.systemAdmin: 'system_admin',
};
