// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suite_draft_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuiteDraftInput _$SuiteDraftInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SuiteDraftInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['cases', 'packageId', 'stopOnFailure', 'title'],
      );
      final val = SuiteDraftInput(
        cases: $checkedConvert(
          'cases',
          (v) => (v as List<dynamic>)
              .map((e) => SuiteCase.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        packageId: $checkedConvert('packageId', (v) => v as String),
        stopOnFailure: $checkedConvert('stopOnFailure', (v) => v as bool),
        title: $checkedConvert('title', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SuiteDraftInputToJson(SuiteDraftInput instance) =>
    <String, dynamic>{
      'cases': instance.cases.map((e) => e.toJson()).toList(),
      'packageId': instance.packageId,
      'stopOnFailure': instance.stopOnFailure,
      'title': instance.title,
    };
