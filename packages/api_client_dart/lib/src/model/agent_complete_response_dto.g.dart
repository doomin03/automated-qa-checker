// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_complete_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentCompleteResponseDto _$AgentCompleteResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentCompleteResponseDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'accepted',
      'acceptedThrough',
      'artifacts',
      'cleanupState',
      'completionReceipt',
      'deliveryClosed',
      'evidenceStatus',
      'fence',
      'leaseId',
      'quarantined',
    ],
  );
  final val = AgentCompleteResponseDto(
    accepted: $checkedConvert('accepted', (v) => v as bool),
    acceptedThrough: $checkedConvert(
      'acceptedThrough',
      (v) => (v as num).toInt(),
    ),
    artifacts: $checkedConvert(
      'artifacts',
      (v) => (v as List<dynamic>)
          .map(
            (e) => AgentArtifactReceiptDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    cleanupState: $checkedConvert(
      'cleanupState',
      (v) => $enumDecode(_$AgentCompleteResponseDtoCleanupStateEnumEnumMap, v),
    ),
    completionReceipt: $checkedConvert(
      'completionReceipt',
      (v) => v as String?,
    ),
    deliveryClosed: $checkedConvert('deliveryClosed', (v) => v as bool),
    evidenceStatus: $checkedConvert(
      'evidenceStatus',
      (v) =>
          $enumDecode(_$AgentCompleteResponseDtoEvidenceStatusEnumEnumMap, v),
    ),
    fence: $checkedConvert('fence', (v) => (v as num).toInt()),
    leaseId: $checkedConvert('leaseId', (v) => v as String),
    quarantined: $checkedConvert('quarantined', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$AgentCompleteResponseDtoToJson(
  AgentCompleteResponseDto instance,
) => <String, dynamic>{
  'accepted': instance.accepted,
  'acceptedThrough': instance.acceptedThrough,
  'artifacts': instance.artifacts.map((e) => e.toJson()).toList(),
  'cleanupState':
      _$AgentCompleteResponseDtoCleanupStateEnumEnumMap[instance.cleanupState]!,
  'completionReceipt': instance.completionReceipt,
  'deliveryClosed': instance.deliveryClosed,
  'evidenceStatus':
      _$AgentCompleteResponseDtoEvidenceStatusEnumEnumMap[instance
          .evidenceStatus]!,
  'fence': instance.fence,
  'leaseId': instance.leaseId,
  'quarantined': instance.quarantined,
};

const _$AgentCompleteResponseDtoCleanupStateEnumEnumMap = {
  AgentCompleteResponseDtoCleanupStateEnum.confirmed: 'confirmed',
  AgentCompleteResponseDtoCleanupStateEnum.unknown: 'unknown',
  AgentCompleteResponseDtoCleanupStateEnum.failed: 'failed',
};

const _$AgentCompleteResponseDtoEvidenceStatusEnumEnumMap = {
  AgentCompleteResponseDtoEvidenceStatusEnum.pending: 'pending',
  AgentCompleteResponseDtoEvidenceStatusEnum.missing: 'missing',
  AgentCompleteResponseDtoEvidenceStatusEnum.verified: 'verified',
};
