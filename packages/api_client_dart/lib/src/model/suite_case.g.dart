// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suite_case.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuiteCase _$SuiteCaseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SuiteCase', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['caseId', 'sha256', 'versionId']);
      final val = SuiteCase(
        caseId: $checkedConvert('caseId', (v) => v as String),
        sha256: $checkedConvert('sha256', (v) => v as String),
        versionId: $checkedConvert('versionId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SuiteCaseToJson(SuiteCase instance) => <String, dynamic>{
  'caseId': instance.caseId,
  'sha256': instance.sha256,
  'versionId': instance.versionId,
};
