// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upgrade_diff_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpgradeDiffResponse _$UpgradeDiffResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpgradeDiffResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['dependenciesChanged', 'from', 'to', 'xmlChanged'],
      );
      final val = UpgradeDiffResponse(
        dependenciesChanged: $checkedConvert(
          'dependenciesChanged',
          (v) => v as bool,
        ),
        from: $checkedConvert(
          'from',
          (v) => VersionResponse.fromJson(v as Map<String, dynamic>),
        ),
        to: $checkedConvert(
          'to',
          (v) => VersionResponse.fromJson(v as Map<String, dynamic>),
        ),
        xmlChanged: $checkedConvert('xmlChanged', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$UpgradeDiffResponseToJson(
  UpgradeDiffResponse instance,
) => <String, dynamic>{
  'dependenciesChanged': instance.dependenciesChanged,
  'from': instance.from.toJson(),
  'to': instance.to.toJson(),
  'xmlChanged': instance.xmlChanged,
};
