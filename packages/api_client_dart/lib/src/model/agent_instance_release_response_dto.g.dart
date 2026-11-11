// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_instance_release_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentInstanceReleaseResponseDto _$AgentInstanceReleaseResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentInstanceReleaseResponseDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'agentId',
      'ownerInstanceId',
      'released',
      'remainingReceipts',
      'reportingInstanceId',
    ],
  );
  final val = AgentInstanceReleaseResponseDto(
    agentId: $checkedConvert('agentId', (v) => v as String),
    ownerInstanceId: $checkedConvert('ownerInstanceId', (v) => v as String),
    released: $checkedConvert('released', (v) => v as bool),
    remainingReceipts: $checkedConvert(
      'remainingReceipts',
      (v) => (v as num).toInt(),
    ),
    reportingInstanceId: $checkedConvert(
      'reportingInstanceId',
      (v) => v as String,
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentInstanceReleaseResponseDtoToJson(
  AgentInstanceReleaseResponseDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'ownerInstanceId': instance.ownerInstanceId,
  'released': instance.released,
  'remainingReceipts': instance.remainingReceipts,
  'reportingInstanceId': instance.reportingInstanceId,
};
