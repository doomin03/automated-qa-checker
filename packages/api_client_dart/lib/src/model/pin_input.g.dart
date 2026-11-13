// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinInput _$PinInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PinInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['sha256', 'versionId']);
      final val = PinInput(
        sha256: $checkedConvert('sha256', (v) => v as String),
        versionId: $checkedConvert('versionId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PinInputToJson(PinInput instance) => <String, dynamic>{
  'sha256': instance.sha256,
  'versionId': instance.versionId,
};
