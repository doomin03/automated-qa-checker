// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiErrorResponse _$ApiErrorResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ApiErrorResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['code', 'details', 'message', 'requestId'],
      );
      final val = ApiErrorResponse(
        code: $checkedConvert('code', (v) => v as String),
        details: $checkedConvert(
          'details',
          (v) => (v as List<dynamic>)
              .map((e) => ApiErrorDetail.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        message: $checkedConvert('message', (v) => v as String),
        requestId: $checkedConvert('requestId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ApiErrorResponseToJson(ApiErrorResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'details': instance.details.map((e) => e.toJson()).toList(),
      'message': instance.message,
      'requestId': instance.requestId,
    };
