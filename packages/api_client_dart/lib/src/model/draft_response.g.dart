// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DraftResponse _$DraftResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DraftResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'authorId',
          'createdAt',
          'dependencies',
          'id',
          'packageId',
          'projectId',
          'reviewerId',
          'sha256',
          'state',
          'title',
          'xml',
        ],
      );
      final val = DraftResponse(
        authorId: $checkedConvert('authorId', (v) => v as String),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
        dependencies: $checkedConvert(
          'dependencies',
          (v) => (v as List<dynamic>)
              .map((e) => DependencyPin.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        id: $checkedConvert('id', (v) => v as String),
        packageId: $checkedConvert('packageId', (v) => v as String),
        projectId: $checkedConvert('projectId', (v) => v as String),
        reviewerId: $checkedConvert('reviewerId', (v) => v as String?),
        sha256: $checkedConvert('sha256', (v) => v as String),
        state: $checkedConvert(
          'state',
          (v) => $enumDecode(_$DraftResponseStateEnumEnumMap, v),
        ),
        title: $checkedConvert('title', (v) => v as String),
        xml: $checkedConvert('xml', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DraftResponseToJson(DraftResponse instance) =>
    <String, dynamic>{
      'authorId': instance.authorId,
      'createdAt': instance.createdAt.toIso8601String(),
      'dependencies': instance.dependencies.map((e) => e.toJson()).toList(),
      'id': instance.id,
      'packageId': instance.packageId,
      'projectId': instance.projectId,
      'reviewerId': instance.reviewerId,
      'sha256': instance.sha256,
      'state': _$DraftResponseStateEnumEnumMap[instance.state]!,
      'title': instance.title,
      'xml': instance.xml,
    };

const _$DraftResponseStateEnumEnumMap = {
  DraftResponseStateEnum.draft: 'draft',
  DraftResponseStateEnum.reviewed: 'reviewed',
  DraftResponseStateEnum.published: 'published',
};
