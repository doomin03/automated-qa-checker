// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dependency_pin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DependencyPin _$DependencyPinFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DependencyPin', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['sha256', 'versionId']);
      final val = DependencyPin(
        sha256: $checkedConvert('sha256', (v) => v as String),
        versionId: $checkedConvert('versionId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DependencyPinToJson(DependencyPin instance) =>
    <String, dynamic>{
      'sha256': instance.sha256,
      'versionId': instance.versionId,
    };
