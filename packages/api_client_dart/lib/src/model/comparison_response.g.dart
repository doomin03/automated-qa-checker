// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comparison_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComparisonResponse _$ComparisonResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComparisonResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'baselineOutcome',
          'baselineRunId',
          'changedNodes',
          'classification',
          'comparable',
          'currentOutcome',
          'reason',
          'runId',
        ],
      );
      final val = ComparisonResponse(
        baselineOutcome: $checkedConvert(
          'baselineOutcome',
          (v) => v as String?,
        ),
        baselineRunId: $checkedConvert('baselineRunId', (v) => v as String?),
        changedNodes: $checkedConvert(
          'changedNodes',
          (v) => (v as List<dynamic>)
              .map((e) => ChangedNode.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        classification: $checkedConvert(
          'classification',
          (v) => $enumDecode(_$ComparisonResponseClassificationEnumEnumMap, v),
        ),
        comparable: $checkedConvert('comparable', (v) => v as bool),
        currentOutcome: $checkedConvert('currentOutcome', (v) => v as String?),
        reason: $checkedConvert('reason', (v) => v as String),
        runId: $checkedConvert('runId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ComparisonResponseToJson(
  ComparisonResponse instance,
) => <String, dynamic>{
  'baselineOutcome': instance.baselineOutcome,
  'baselineRunId': instance.baselineRunId,
  'changedNodes': instance.changedNodes.map((e) => e.toJson()).toList(),
  'classification':
      _$ComparisonResponseClassificationEnumEnumMap[instance.classification]!,
  'comparable': instance.comparable,
  'currentOutcome': instance.currentOutcome,
  'reason': instance.reason,
  'runId': instance.runId,
};

const _$ComparisonResponseClassificationEnumEnumMap = {
  ComparisonResponseClassificationEnum.incomparable: 'incomparable',
  ComparisonResponseClassificationEnum.regression: 'regression',
  ComparisonResponseClassificationEnum.improvement: 'improvement',
  ComparisonResponseClassificationEnum.unchanged: 'unchanged',
  ComparisonResponseClassificationEnum.changed: 'changed',
};
