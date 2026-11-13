// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DraftInput _$DraftInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DraftInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['dependencies', 'packageId', 'title', 'xml'],
      );
      final val = DraftInput(
        dependencies: $checkedConvert(
          'dependencies',
          (v) => (v as List<dynamic>)
              .map((e) => DependencyPin.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        packageId: $checkedConvert('packageId', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        xml: $checkedConvert('xml', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DraftInputToJson(DraftInput instance) =>
    <String, dynamic>{
      'dependencies': instance.dependencies.map((e) => e.toJson()).toList(),
      'packageId': instance.packageId,
      'title': instance.title,
      'xml': instance.xml,
    };
