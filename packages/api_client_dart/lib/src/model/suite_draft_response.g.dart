// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suite_draft_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuiteDraftResponse _$SuiteDraftResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SuiteDraftResponse', json, ($checkedConvert) {
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
          'state',
          'stopOnFailure',
          'title',
        ],
      );
      final val = SuiteDraftResponse(
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
        reviewerId: $checkedConvert('reviewerId', (v) => v as String?),
        state: $checkedConvert(
          'state',
          (v) => $enumDecode(_$SuiteDraftResponseStateEnumEnumMap, v),
        ),
        stopOnFailure: $checkedConvert('stopOnFailure', (v) => v as bool),
        title: $checkedConvert('title', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SuiteDraftResponseToJson(SuiteDraftResponse instance) =>
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
      'state': _$SuiteDraftResponseStateEnumEnumMap[instance.state]!,
      'stopOnFailure': instance.stopOnFailure,
      'title': instance.title,
    };

const _$SuiteDraftResponseStateEnumEnumMap = {
  SuiteDraftResponseStateEnum.draft: 'draft',
  SuiteDraftResponseStateEnum.reviewed: 'reviewed',
  SuiteDraftResponseStateEnum.published: 'published',
};
