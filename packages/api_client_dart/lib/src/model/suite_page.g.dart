// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suite_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuitePage _$SuitePageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SuitePage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = SuitePage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => SuiteResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SuitePageToJson(SuitePage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': instance.nextCursor,
};
