// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_historical_evidence_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentHistoricalEvidenceResponseDto _$AgentHistoricalEvidenceResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentHistoricalEvidenceResponseDto', json, (
  $checkedConvert,
) {
  $checkKeys(
    json,
    requiredKeys: const [
      'disposition',
      'executionPermission',
      'leaseId',
      'receiptId',
      'recorded',
      'resourceReleased',
    ],
  );
  final val = AgentHistoricalEvidenceResponseDto(
    disposition: $checkedConvert(
      'disposition',
      (v) => $enumDecode(
        _$AgentHistoricalEvidenceResponseDtoDispositionEnumEnumMap,
        v,
      ),
    ),
    executionPermission: $checkedConvert(
      'executionPermission',
      (v) => v as bool,
    ),
    leaseId: $checkedConvert('leaseId', (v) => v as String),
    receiptId: $checkedConvert('receiptId', (v) => v as String),
    recorded: $checkedConvert('recorded', (v) => v as bool),
    resourceReleased: $checkedConvert('resourceReleased', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$AgentHistoricalEvidenceResponseDtoToJson(
  AgentHistoricalEvidenceResponseDto instance,
) => <String, dynamic>{
  'disposition':
      _$AgentHistoricalEvidenceResponseDtoDispositionEnumEnumMap[instance
          .disposition]!,
  'executionPermission': instance.executionPermission,
  'leaseId': instance.leaseId,
  'receiptId': instance.receiptId,
  'recorded': instance.recorded,
  'resourceReleased': instance.resourceReleased,
};

const _$AgentHistoricalEvidenceResponseDtoDispositionEnumEnumMap = {
  AgentHistoricalEvidenceResponseDtoDispositionEnum.historicalQuarantine:
      'historical_quarantine',
};
