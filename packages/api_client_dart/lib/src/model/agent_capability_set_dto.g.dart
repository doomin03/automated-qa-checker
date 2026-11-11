// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_capability_set_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentCapabilitySetDto _$AgentCapabilitySetDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentCapabilitySetDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['actions', 'platforms']);
  final val = AgentCapabilitySetDto(
    actions: $checkedConvert(
      'actions',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    ),
    platforms: $checkedConvert(
      'platforms',
      (v) =>
          (v as List<dynamic>?)
              ?.map(
                (e) =>
                    $enumDecode(_$AgentCapabilitySetDtoPlatformsEnumEnumMap, e),
              )
              .toList() ??
          [],
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentCapabilitySetDtoToJson(
  AgentCapabilitySetDto instance,
) => <String, dynamic>{
  'actions': instance.actions,
  'platforms': instance.platforms
      .map((e) => _$AgentCapabilitySetDtoPlatformsEnumEnumMap[e]!)
      .toList(),
};

const _$AgentCapabilitySetDtoPlatformsEnumEnumMap = {
  AgentCapabilitySetDtoPlatformsEnum.web: 'web',
  AgentCapabilitySetDtoPlatformsEnum.android: 'android',
  AgentCapabilitySetDtoPlatformsEnum.ios: 'ios',
};
