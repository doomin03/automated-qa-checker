// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExecutionPage _$ExecutionPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExecutionPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = ExecutionPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ExecutionResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ExecutionPageToJson(ExecutionPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
