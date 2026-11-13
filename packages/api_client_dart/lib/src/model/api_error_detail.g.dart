// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiErrorDetail _$ApiErrorDetailFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ApiErrorDetail', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'field', 'message']);
      final val = ApiErrorDetail(
        code: $checkedConvert('code', (v) => v as String),
        field: $checkedConvert('field', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ApiErrorDetailToJson(ApiErrorDetail instance) =>
    <String, dynamic>{
      'code': instance.code,
      'field': instance.field,
      'message': instance.message,
    };
