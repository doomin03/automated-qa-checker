// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthResponse _$HealthResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HealthResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['apiVersion', 'client', 'service', 'status'],
      );
      final val = HealthResponse(
        apiVersion: $checkedConvert(
          'apiVersion',
          (v) => $enumDecode(_$HealthResponseApiVersionEnumEnumMap, v),
        ),
        client: $checkedConvert(
          'client',
          (v) => $enumDecodeNullable(_$HealthResponseClientEnumEnumMap, v),
        ),
        service: $checkedConvert(
          'service',
          (v) => $enumDecode(_$HealthResponseServiceEnumEnumMap, v),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$HealthResponseStatusEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HealthResponseToJson(HealthResponse instance) =>
    <String, dynamic>{
      'apiVersion': _$HealthResponseApiVersionEnumEnumMap[instance.apiVersion]!,
      'client': _$HealthResponseClientEnumEnumMap[instance.client],
      'service': _$HealthResponseServiceEnumEnumMap[instance.service]!,
      'status': _$HealthResponseStatusEnumEnumMap[instance.status]!,
    };

const _$HealthResponseApiVersionEnumEnumMap = {
  HealthResponseApiVersionEnum.v1: 'v1',
};

const _$HealthResponseClientEnumEnumMap = {
  HealthResponseClientEnum.web: 'web',
  HealthResponseClientEnum.app: 'app',
};

const _$HealthResponseServiceEnumEnumMap = {
  HealthResponseServiceEnum.automatedQaChecker: 'automated-qa-checker',
};

const _$HealthResponseStatusEnumEnumMap = {HealthResponseStatusEnum.ok: 'ok'};
