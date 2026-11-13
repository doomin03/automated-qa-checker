// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_claim_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentClaimRequestDto _$AgentClaimRequestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentClaimRequestDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'agentId',
      'capabilities',
      'claimRequestId',
      'engineContractSha256',
      'engineContractVersion',
      'engineVersion',
      'instanceId',
      'projectIds',
      'protocolVersion',
      'resourceKeys',
    ],
  );
  final val = AgentClaimRequestDto(
    agentId: $checkedConvert('agentId', (v) => v as String),
    capabilities: $checkedConvert(
      'capabilities',
      (v) => AgentCapabilitySetDto.fromJson(v as Map<String, dynamic>),
    ),
    claimRequestId: $checkedConvert('claimRequestId', (v) => v as String),
    engineContractSha256: $checkedConvert(
      'engineContractSha256',
      (v) => v as String,
    ),
    engineContractVersion: $checkedConvert(
      'engineContractVersion',
      (v) => v as String,
    ),
    engineVersion: $checkedConvert('engineVersion', (v) => v as String),
    instanceId: $checkedConvert('instanceId', (v) => v as String),
    projectIds: $checkedConvert(
      'projectIds',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    protocolVersion: $checkedConvert(
      'protocolVersion',
      (v) => $enumDecode(_$AgentClaimRequestDtoProtocolVersionEnumEnumMap, v),
    ),
    resourceKeys: $checkedConvert(
      'resourceKeys',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentClaimRequestDtoToJson(
  AgentClaimRequestDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'capabilities': instance.capabilities.toJson(),
  'claimRequestId': instance.claimRequestId,
  'engineContractSha256': instance.engineContractSha256,
  'engineContractVersion': instance.engineContractVersion,
  'engineVersion': instance.engineVersion,
  'instanceId': instance.instanceId,
  'projectIds': instance.projectIds,
  'protocolVersion':
      _$AgentClaimRequestDtoProtocolVersionEnumEnumMap[instance
          .protocolVersion]!,
  'resourceKeys': instance.resourceKeys,
};

const _$AgentClaimRequestDtoProtocolVersionEnumEnumMap = {
  AgentClaimRequestDtoProtocolVersionEnum.n0period1Period0DraftPeriod1:
      '0.1.0-draft.1',
};
