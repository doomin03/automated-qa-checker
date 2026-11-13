// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchedulePage _$SchedulePageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SchedulePage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = SchedulePage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ScheduleResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SchedulePageToJson(SchedulePage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
