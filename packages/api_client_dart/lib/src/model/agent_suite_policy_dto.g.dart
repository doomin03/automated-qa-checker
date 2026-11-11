// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_suite_policy_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentSuitePolicyDto _$AgentSuitePolicyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentSuitePolicyDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'publishedSha256',
          'publishedVersionId',
          'stopOnFailure',
        ],
      );
      final val = AgentSuitePolicyDto(
        publishedSha256: $checkedConvert(
          'publishedSha256',
          (v) => v as String?,
        ),
        publishedVersionId: $checkedConvert(
          'publishedVersionId',
          (v) => v as String?,
        ),
        stopOnFailure: $checkedConvert('stopOnFailure', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$AgentSuitePolicyDtoToJson(
  AgentSuitePolicyDto instance,
) => <String, dynamic>{
  'publishedSha256': instance.publishedSha256,
  'publishedVersionId': instance.publishedVersionId,
  'stopOnFailure': instance.stopOnFailure,
};
