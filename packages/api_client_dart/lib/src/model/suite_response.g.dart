// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suite_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuiteResponse _$SuiteResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SuiteResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'authorId',
          'cases',
          'contractVersion',
          'createdAt',
          'engineVersion',
          'id',
          'packageId',
          'projectId',
          'reviewerId',
          'sha256',
          'stopOnFailure',
          'title',
          'version',
        ],
      );
      final val = SuiteResponse(
        authorId: $checkedConvert('authorId', (v) => v as String),
        cases: $checkedConvert(
          'cases',
          (v) => (v as List<dynamic>)
              .map((e) => SuiteCase.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        contractVersion: $checkedConvert('contractVersion', (v) => v as String),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
        engineVersion: $checkedConvert('engineVersion', (v) => v as String),
        id: $checkedConvert('id', (v) => v as String),
        packageId: $checkedConvert('packageId', (v) => v as String),
        projectId: $checkedConvert('projectId', (v) => v as String),
        reviewerId: $checkedConvert('reviewerId', (v) => v as String),
        sha256: $checkedConvert('sha256', (v) => v as String),
        stopOnFailure: $checkedConvert('stopOnFailure', (v) => v as bool),
        title: $checkedConvert('title', (v) => v as String),
        version: $checkedConvert('version', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SuiteResponseToJson(SuiteResponse instance) =>
    <String, dynamic>{
      'authorId': instance.authorId,
      'cases': instance.cases.map((e) => e.toJson()).toList(),
      'contractVersion': instance.contractVersion,
      'createdAt': instance.createdAt.toIso8601String(),
      'engineVersion': instance.engineVersion,
      'id': instance.id,
      'packageId': instance.packageId,
      'projectId': instance.projectId,
      'reviewerId': instance.reviewerId,
      'sha256': instance.sha256,
      'stopOnFailure': instance.stopOnFailure,
      'title': instance.title,
      'version': instance.version,
    };
