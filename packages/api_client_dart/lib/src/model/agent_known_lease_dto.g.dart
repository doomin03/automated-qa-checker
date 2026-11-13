// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_known_lease_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentKnownLeaseDto _$AgentKnownLeaseDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentKnownLeaseDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'cleanupState',
          'fence',
          'lastAcknowledgedSequence',
          'leaseId',
          'ownerInstanceId',
          'terminalResultHashes',
        ],
      );
      final val = AgentKnownLeaseDto(
        cleanupState: $checkedConvert(
          'cleanupState',
          (v) => $enumDecode(_$AgentKnownLeaseDtoCleanupStateEnumEnumMap, v),
        ),
        fence: $checkedConvert('fence', (v) => (v as num).toInt()),
        lastAcknowledgedSequence: $checkedConvert(
          'lastAcknowledgedSequence',
          (v) => (v as num).toInt(),
        ),
        leaseId: $checkedConvert('leaseId', (v) => v as String),
        ownerInstanceId: $checkedConvert('ownerInstanceId', (v) => v as String),
        terminalResultHashes: $checkedConvert(
          'terminalResultHashes',
          (v) => (v as List<dynamic>)
              .map(
                (e) => AgentKnownLeaseTerminalResultHashesItemDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AgentKnownLeaseDtoToJson(AgentKnownLeaseDto instance) =>
    <String, dynamic>{
      'cleanupState':
          _$AgentKnownLeaseDtoCleanupStateEnumEnumMap[instance.cleanupState]!,
      'fence': instance.fence,
      'lastAcknowledgedSequence': instance.lastAcknowledgedSequence,
      'leaseId': instance.leaseId,
      'ownerInstanceId': instance.ownerInstanceId,
      'terminalResultHashes': instance.terminalResultHashes
          .map((e) => e.toJson())
          .toList(),
    };

const _$AgentKnownLeaseDtoCleanupStateEnumEnumMap = {
  AgentKnownLeaseDtoCleanupStateEnum.confirmed: 'confirmed',
  AgentKnownLeaseDtoCleanupStateEnum.unknown: 'unknown',
  AgentKnownLeaseDtoCleanupStateEnum.failed: 'failed',
};
