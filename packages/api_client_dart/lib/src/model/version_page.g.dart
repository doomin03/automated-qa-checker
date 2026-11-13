// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VersionPage _$VersionPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VersionPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = VersionPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => VersionResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$VersionPageToJson(VersionPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
