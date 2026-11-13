// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_user_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedUserPage _$ManagedUserPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ManagedUserPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'nextCursor']);
      final val = ManagedUserPage(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ManagedUserResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ManagedUserPageToJson(ManagedUserPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': instance.nextCursor,
    };
