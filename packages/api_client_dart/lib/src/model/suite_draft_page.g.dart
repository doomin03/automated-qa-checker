// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suite_draft_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuiteDraftPage _$SuiteDraftPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SuiteDraftPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = SuiteDraftPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => SuiteDraftResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SuiteDraftPageToJson(SuiteDraftPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
