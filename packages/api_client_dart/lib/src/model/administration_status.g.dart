// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'administration_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdministrationStatus _$AdministrationStatusFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdministrationStatus', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['identityStorage', 'mutationSupported'],
  );
  final val = AdministrationStatus(
    identityStorage: $checkedConvert(
      'identityStorage',
      (v) => $enumDecode(_$AdministrationStatusIdentityStorageEnumEnumMap, v),
    ),
    mutationSupported: $checkedConvert('mutationSupported', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$AdministrationStatusToJson(
  AdministrationStatus instance,
) => <String, dynamic>{
  'identityStorage':
      _$AdministrationStatusIdentityStorageEnumEnumMap[instance
          .identityStorage]!,
  'mutationSupported': instance.mutationSupported,
};

const _$AdministrationStatusIdentityStorageEnumEnumMap = {
  AdministrationStatusIdentityStorageEnum.provisioned: 'provisioned',
  AdministrationStatusIdentityStorageEnum.managed: 'managed',
};
