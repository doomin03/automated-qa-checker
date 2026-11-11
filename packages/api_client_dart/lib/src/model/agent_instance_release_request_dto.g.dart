// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_instance_release_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentInstanceReleaseRequestDto _$AgentInstanceReleaseRequestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentInstanceReleaseRequestDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'agentId',
      'ownerInstanceId',
      'ownerStopped',
      'receipts',
      'reportingInstanceId',
    ],
  );
  final val = AgentInstanceReleaseRequestDto(
    agentId: $checkedConvert('agentId', (v) => v as String),
    ownerInstanceId: $checkedConvert('ownerInstanceId', (v) => v as String),
    ownerStopped: $checkedConvert('ownerStopped', (v) => v as bool),
    receipts: $checkedConvert(
      'receipts',
      (v) => (v as List<dynamic>)
          .map(
            (e) => AgentInstanceReleaseRequestReceiptsItemDto.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    reportingInstanceId: $checkedConvert(
      'reportingInstanceId',
      (v) => v as String,
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentInstanceReleaseRequestDtoToJson(
  AgentInstanceReleaseRequestDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'ownerInstanceId': instance.ownerInstanceId,
  'ownerStopped': instance.ownerStopped,
  'receipts': instance.receipts.map((e) => e.toJson()).toList(),
  'reportingInstanceId': instance.reportingInstanceId,
};
