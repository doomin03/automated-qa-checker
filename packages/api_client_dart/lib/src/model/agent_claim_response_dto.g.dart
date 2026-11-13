// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_claim_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentClaimResponseDto _$AgentClaimResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentClaimResponseDto', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['claimRequestId', 'lease']);
  final val = AgentClaimResponseDto(
    claimRequestId: $checkedConvert('claimRequestId', (v) => v as String),
    lease: $checkedConvert(
      'lease',
      (v) => AgentLeaseDto.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentClaimResponseDtoToJson(
  AgentClaimResponseDto instance,
) => <String, dynamic>{
  'claimRequestId': instance.claimRequestId,
  'lease': instance.lease.toJson(),
};
