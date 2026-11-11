// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baseline_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BaselineInput _$BaselineInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BaselineInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['baselineRunId']);
      final val = BaselineInput(
        baselineRunId: $checkedConvert('baselineRunId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$BaselineInputToJson(BaselineInput instance) =>
    <String, dynamic>{'baselineRunId': instance.baselineRunId};
