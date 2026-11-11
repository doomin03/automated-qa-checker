// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultInput _$ResultInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ResultInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['resultJson']);
      final val = ResultInput(
        resultJson: $checkedConvert('resultJson', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ResultInputToJson(ResultInput instance) =>
    <String, dynamic>{'resultJson': instance.resultJson};
