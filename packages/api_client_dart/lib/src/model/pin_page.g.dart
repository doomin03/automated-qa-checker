// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinPage _$PinPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PinPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = PinPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PinResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$PinPageToJson(PinPage instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': instance.nextCursor,
};
