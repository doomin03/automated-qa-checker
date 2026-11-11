// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunPage _$RunPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RunPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = RunPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => RunResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$RunPageToJson(RunPage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': instance.nextCursor,
};
