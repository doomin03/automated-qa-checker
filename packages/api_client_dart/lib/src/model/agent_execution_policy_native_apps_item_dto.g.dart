// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_execution_policy_native_apps_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentExecutionPolicyNativeAppsItemDto
_$AgentExecutionPolicyNativeAppsItemDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentExecutionPolicyNativeAppsItemDto', json, (
      $checkedConvert,
    ) {
      $checkKeys(json, requiredKeys: const ['activities', 'appId', 'platform']);
      final val = AgentExecutionPolicyNativeAppsItemDto(
        activities: $checkedConvert(
          'activities',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        ),
        appId: $checkedConvert('appId', (v) => v as String),
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecode(
            _$AgentExecutionPolicyNativeAppsItemDtoPlatformEnumEnumMap,
            v,
          ),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AgentExecutionPolicyNativeAppsItemDtoToJson(
  AgentExecutionPolicyNativeAppsItemDto instance,
) => <String, dynamic>{
  'activities': instance.activities,
  'appId': instance.appId,
  'platform':
      _$AgentExecutionPolicyNativeAppsItemDtoPlatformEnumEnumMap[instance
          .platform]!,
};

const _$AgentExecutionPolicyNativeAppsItemDtoPlatformEnumEnumMap = {
  AgentExecutionPolicyNativeAppsItemDtoPlatformEnum.android: 'android',
  AgentExecutionPolicyNativeAppsItemDtoPlatformEnum.ios: 'ios',
};
