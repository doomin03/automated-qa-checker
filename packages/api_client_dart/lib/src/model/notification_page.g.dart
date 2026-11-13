// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationPage _$NotificationPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NotificationPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = NotificationPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => NotificationResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$NotificationPageToJson(NotificationPage instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
