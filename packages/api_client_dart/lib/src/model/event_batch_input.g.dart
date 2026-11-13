// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_batch_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventBatchInput _$EventBatchInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EventBatchInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['eventsJson']);
      final val = EventBatchInput(
        eventsJson: $checkedConvert(
          'eventsJson',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EventBatchInputToJson(EventBatchInput instance) =>
    <String, dynamic>{'eventsJson': instance.eventsJson};
