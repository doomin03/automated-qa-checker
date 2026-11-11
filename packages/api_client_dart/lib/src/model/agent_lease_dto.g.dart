// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_lease_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentLeaseDto _$AgentLeaseDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentLeaseDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'acceptedThrough',
          'agentId',
          'cancelRequested',
          'cases',
          'engineContractSha256',
          'engineContractVersion',
          'engineVersion',
          'executionId',
          'executionPolicy',
          'fence',
          'heartbeatIntervalMs',
          'instanceId',
          'jobAttempt',
          'leaseId',
          'projectId',
          'protocolVersion',
          'requestTimeoutMs',
          'resourceKey',
          'safetyMarginMs',
          'state',
          'suitePolicy',
          'validForMs',
        ],
      );
      final val = AgentLeaseDto(
        acceptedThrough: $checkedConvert(
          'acceptedThrough',
          (v) => (v as num).toInt(),
        ),
        agentId: $checkedConvert('agentId', (v) => v as String),
        cancelRequested: $checkedConvert('cancelRequested', (v) => v as bool),
        cases: $checkedConvert(
          'cases',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AgentCaseSnapshotDto.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        engineContractSha256: $checkedConvert(
          'engineContractSha256',
          (v) => v as String,
        ),
        engineContractVersion: $checkedConvert(
          'engineContractVersion',
          (v) => v as String,
        ),
        engineVersion: $checkedConvert('engineVersion', (v) => v as String),
        executionId: $checkedConvert('executionId', (v) => v as String),
        executionPolicy: $checkedConvert(
          'executionPolicy',
          (v) => AgentExecutionPolicyDto.fromJson(v as Map<String, dynamic>),
        ),
        fence: $checkedConvert('fence', (v) => (v as num).toInt()),
        heartbeatIntervalMs: $checkedConvert(
          'heartbeatIntervalMs',
          (v) => $enumDecode(_$AgentLeaseDtoHeartbeatIntervalMsEnumEnumMap, v),
        ),
        instanceId: $checkedConvert('instanceId', (v) => v as String),
        jobAttempt: $checkedConvert('jobAttempt', (v) => (v as num).toInt()),
        leaseId: $checkedConvert('leaseId', (v) => v as String),
        projectId: $checkedConvert('projectId', (v) => v as String),
        protocolVersion: $checkedConvert(
          'protocolVersion',
          (v) => $enumDecode(_$AgentLeaseDtoProtocolVersionEnumEnumMap, v),
        ),
        requestTimeoutMs: $checkedConvert(
          'requestTimeoutMs',
          (v) => $enumDecode(_$AgentLeaseDtoRequestTimeoutMsEnumEnumMap, v),
        ),
        resourceKey: $checkedConvert('resourceKey', (v) => v as String),
        safetyMarginMs: $checkedConvert(
          'safetyMarginMs',
          (v) => $enumDecode(_$AgentLeaseDtoSafetyMarginMsEnumEnumMap, v),
        ),
        state: $checkedConvert(
          'state',
          (v) => $enumDecode(_$AgentLeaseDtoStateEnumEnumMap, v),
        ),
        suitePolicy: $checkedConvert(
          'suitePolicy',
          (v) => AgentSuitePolicyDto.fromJson(v as Map<String, dynamic>),
        ),
        validForMs: $checkedConvert('validForMs', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$AgentLeaseDtoToJson(
  AgentLeaseDto instance,
) => <String, dynamic>{
  'acceptedThrough': instance.acceptedThrough,
  'agentId': instance.agentId,
  'cancelRequested': instance.cancelRequested,
  'cases': instance.cases.map((e) => e.toJson()).toList(),
  'engineContractSha256': instance.engineContractSha256,
  'engineContractVersion': instance.engineContractVersion,
  'engineVersion': instance.engineVersion,
  'executionId': instance.executionId,
  'executionPolicy': instance.executionPolicy.toJson(),
  'fence': instance.fence,
  'heartbeatIntervalMs':
      _$AgentLeaseDtoHeartbeatIntervalMsEnumEnumMap[instance
          .heartbeatIntervalMs]!,
  'instanceId': instance.instanceId,
  'jobAttempt': instance.jobAttempt,
  'leaseId': instance.leaseId,
  'projectId': instance.projectId,
  'protocolVersion':
      _$AgentLeaseDtoProtocolVersionEnumEnumMap[instance.protocolVersion]!,
  'requestTimeoutMs':
      _$AgentLeaseDtoRequestTimeoutMsEnumEnumMap[instance.requestTimeoutMs]!,
  'resourceKey': instance.resourceKey,
  'safetyMarginMs':
      _$AgentLeaseDtoSafetyMarginMsEnumEnumMap[instance.safetyMarginMs]!,
  'state': _$AgentLeaseDtoStateEnumEnumMap[instance.state]!,
  'suitePolicy': instance.suitePolicy.toJson(),
  'validForMs': instance.validForMs,
};

const _$AgentLeaseDtoHeartbeatIntervalMsEnumEnumMap = {
  AgentLeaseDtoHeartbeatIntervalMsEnum.number5000: 5000,
};

const _$AgentLeaseDtoProtocolVersionEnumEnumMap = {
  AgentLeaseDtoProtocolVersionEnum.n0period1Period0DraftPeriod1:
      '0.1.0-draft.1',
};

const _$AgentLeaseDtoRequestTimeoutMsEnumEnumMap = {
  AgentLeaseDtoRequestTimeoutMsEnum.number5000: 5000,
};

const _$AgentLeaseDtoSafetyMarginMsEnumEnumMap = {
  AgentLeaseDtoSafetyMarginMsEnum.number5000: 5000,
};

const _$AgentLeaseDtoStateEnumEnumMap = {
  AgentLeaseDtoStateEnum.active: 'active',
  AgentLeaseDtoStateEnum.reporting: 'reporting',
  AgentLeaseDtoStateEnum.closed: 'closed',
  AgentLeaseDtoStateEnum.expired: 'expired',
  AgentLeaseDtoStateEnum.quarantined: 'quarantined',
  AgentLeaseDtoStateEnum.recovered: 'recovered',
};
