// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_execution_policy_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentExecutionPolicyDto _$AgentExecutionPolicyDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentExecutionPolicyDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'allowedOrigins',
      'allowProduction',
      'nativeApps',
      'platform',
      'resourceKey',
      'secretRefs',
    ],
  );
  final val = AgentExecutionPolicyDto(
    allowedOrigins: $checkedConvert(
      'allowedOrigins',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    ),
    allowProduction: $checkedConvert(
      'allowProduction',
      (v) => v as bool? ?? false,
    ),
    nativeApps: $checkedConvert(
      'nativeApps',
      (v) =>
          (v as List<dynamic>?)
              ?.map(
                (e) => AgentExecutionPolicyNativeAppsItemDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    ),
    platform: $checkedConvert(
      'platform',
      (v) => $enumDecode(_$AgentExecutionPolicyDtoPlatformEnumEnumMap, v),
    ),
    resourceKey: $checkedConvert('resourceKey', (v) => v as String),
    secretRefs: $checkedConvert(
      'secretRefs',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentExecutionPolicyDtoToJson(
  AgentExecutionPolicyDto instance,
) => <String, dynamic>{
  'allowedOrigins': instance.allowedOrigins,
  'allowProduction': instance.allowProduction,
  'nativeApps': instance.nativeApps.map((e) => e.toJson()).toList(),
  'platform': _$AgentExecutionPolicyDtoPlatformEnumEnumMap[instance.platform]!,
  'resourceKey': instance.resourceKey,
  'secretRefs': instance.secretRefs,
};

const _$AgentExecutionPolicyDtoPlatformEnumEnumMap = {
  AgentExecutionPolicyDtoPlatformEnum.web: 'web',
  AgentExecutionPolicyDtoPlatformEnum.android: 'android',
  AgentExecutionPolicyDtoPlatformEnum.ios: 'ios',
};
