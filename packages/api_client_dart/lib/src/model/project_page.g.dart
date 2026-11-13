// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectPage _$ProjectPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProjectPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = ProjectPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ProjectResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ProjectPageToJson(ProjectPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
