// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_known_lease_terminal_result_hashes_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentKnownLeaseTerminalResultHashesItemDto
_$AgentKnownLeaseTerminalResultHashesItemDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentKnownLeaseTerminalResultHashesItemDto', json, (
  $checkedConvert,
) {
  $checkKeys(json, requiredKeys: const ['caseId', 'sha256']);
  final val = AgentKnownLeaseTerminalResultHashesItemDto(
    caseId: $checkedConvert('caseId', (v) => v as String),
    sha256: $checkedConvert('sha256', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AgentKnownLeaseTerminalResultHashesItemDtoToJson(
  AgentKnownLeaseTerminalResultHashesItemDto instance,
) => <String, dynamic>{'caseId': instance.caseId, 'sha256': instance.sha256};
