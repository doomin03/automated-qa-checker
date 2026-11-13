// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_occurrence_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleOccurrencePage _$ScheduleOccurrencePageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ScheduleOccurrencePage', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
  final val = ScheduleOccurrencePage(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                ScheduleOccurrenceResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$ScheduleOccurrencePageToJson(
  ScheduleOccurrencePage instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'nextCursor': instance.nextCursor,
};
