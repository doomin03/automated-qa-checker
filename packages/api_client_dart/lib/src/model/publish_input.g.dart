// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublishInput _$PublishInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublishInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['version']);
      final val = PublishInput(
        version: $checkedConvert('version', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PublishInputToJson(PublishInput instance) =>
    <String, dynamic>{'version': instance.version};
