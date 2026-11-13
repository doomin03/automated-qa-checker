// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_user_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedUserUpdate _$ManagedUserUpdateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ManagedUserUpdate', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['userRevision']);
  final val = ManagedUserUpdate(
    active: $checkedConvert('active', (v) => v as bool?),
    clearDisplayName: $checkedConvert('clearDisplayName', (v) => v as bool?),
    displayName: $checkedConvert('displayName', (v) => v as String?),
    userRevision: $checkedConvert('userRevision', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$ManagedUserUpdateToJson(ManagedUserUpdate instance) =>
    <String, dynamic>{
      'active': ?instance.active,
      'clearDisplayName': ?instance.clearDisplayName,
      'displayName': ?instance.displayName,
      'userRevision': instance.userRevision,
    };
