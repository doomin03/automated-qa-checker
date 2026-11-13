// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_member_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectMemberPage _$ProjectMemberPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProjectMemberPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = ProjectMemberPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    ProjectMemberResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ProjectMemberPageToJson(ProjectMemberPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
