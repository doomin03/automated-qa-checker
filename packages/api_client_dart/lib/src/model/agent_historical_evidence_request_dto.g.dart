// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_historical_evidence_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentHistoricalEvidenceRequestDto _$AgentHistoricalEvidenceRequestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentHistoricalEvidenceRequestDto', json, (
  $checkedConvert,
) {
  $checkKeys(
    json,
    requiredKeys: const [
      'agentId',
      'caseResults',
      'cleanupState',
      'events',
      'evidenceRequestId',
      'fence',
      'ownerInstanceId',
      'reportingInstanceId',
    ],
  );
  final val = AgentHistoricalEvidenceRequestDto(
    agentId: $checkedConvert('agentId', (v) => v as String),
    artifact: $checkedConvert(
      'artifact',
      (v) => v == null
          ? null
          : AgentHistoricalArtifactDto.fromJson(v as Map<String, dynamic>),
    ),
    caseResults: $checkedConvert(
      'caseResults',
      (v) => (v as List<dynamic>)
          .map((e) => AgentCaseResultDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    cleanupState: $checkedConvert(
      'cleanupState',
      (v) => $enumDecode(
        _$AgentHistoricalEvidenceRequestDtoCleanupStateEnumEnumMap,
        v,
      ),
    ),
    events: $checkedConvert(
      'events',
      (v) => (v as List<dynamic>)
          .map((e) => AgentDeliveryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    evidenceRequestId: $checkedConvert('evidenceRequestId', (v) => v as String),
    fence: $checkedConvert('fence', (v) => (v as num).toInt()),
    ownerInstanceId: $checkedConvert('ownerInstanceId', (v) => v as String),
    reportingInstanceId: $checkedConvert(
      'reportingInstanceId',
      (v) => v as String,
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentHistoricalEvidenceRequestDtoToJson(
  AgentHistoricalEvidenceRequestDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'artifact': ?instance.artifact?.toJson(),
  'caseResults': instance.caseResults.map((e) => e.toJson()).toList(),
  'cleanupState':
      _$AgentHistoricalEvidenceRequestDtoCleanupStateEnumEnumMap[instance
          .cleanupState]!,
  'events': instance.events.map((e) => e.toJson()).toList(),
  'evidenceRequestId': instance.evidenceRequestId,
  'fence': instance.fence,
  'ownerInstanceId': instance.ownerInstanceId,
  'reportingInstanceId': instance.reportingInstanceId,
};

const _$AgentHistoricalEvidenceRequestDtoCleanupStateEnumEnumMap = {
  AgentHistoricalEvidenceRequestDtoCleanupStateEnum.confirmed: 'confirmed',
  AgentHistoricalEvidenceRequestDtoCleanupStateEnum.unknown: 'unknown',
  AgentHistoricalEvidenceRequestDtoCleanupStateEnum.failed: 'failed',
};
