// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_instance_release_request_receipts_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentInstanceReleaseRequestReceiptsItemDto
_$AgentInstanceReleaseRequestReceiptsItemDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentInstanceReleaseRequestReceiptsItemDto', json, (
  $checkedConvert,
) {
  $checkKeys(
    json,
    requiredKeys: const ['acceptedThrough', 'completionReceipt', 'leaseId'],
  );
  final val = AgentInstanceReleaseRequestReceiptsItemDto(
    acceptedThrough: $checkedConvert(
      'acceptedThrough',
      (v) => (v as num).toInt(),
    ),
    completionReceipt: $checkedConvert('completionReceipt', (v) => v as String),
    leaseId: $checkedConvert('leaseId', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AgentInstanceReleaseRequestReceiptsItemDtoToJson(
  AgentInstanceReleaseRequestReceiptsItemDto instance,
) => <String, dynamic>{
  'acceptedThrough': instance.acceptedThrough,
  'completionReceipt': instance.completionReceipt,
  'leaseId': instance.leaseId,
};
