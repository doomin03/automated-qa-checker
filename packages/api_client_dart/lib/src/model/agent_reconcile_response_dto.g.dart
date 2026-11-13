// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_reconcile_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentReconcileResponseDto _$AgentReconcileResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentReconcileResponseDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'agentId',
      'decisions',
      'hasMore',
      'instanceId',
      'instanceState',
      'nextCursor',
    ],
  );
  final val = AgentReconcileResponseDto(
    agentId: $checkedConvert('agentId', (v) => v as String),
    decisions: $checkedConvert(
      'decisions',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                AgentReconcileDecisionDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    hasMore: $checkedConvert('hasMore', (v) => v as bool),
    instanceId: $checkedConvert('instanceId', (v) => v as String),
    instanceState: $checkedConvert(
      'instanceState',
      (v) =>
          $enumDecode(_$AgentReconcileResponseDtoInstanceStateEnumEnumMap, v),
    ),
    nextCursor: $checkedConvert('nextCursor', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$AgentReconcileResponseDtoToJson(
  AgentReconcileResponseDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'decisions': instance.decisions.map((e) => e.toJson()).toList(),
  'hasMore': instance.hasMore,
  'instanceId': instance.instanceId,
  'instanceState':
      _$AgentReconcileResponseDtoInstanceStateEnumEnumMap[instance
          .instanceState]!,
  'nextCursor': instance.nextCursor,
};

const _$AgentReconcileResponseDtoInstanceStateEnumEnumMap = {
  AgentReconcileResponseDtoInstanceStateEnum.active: 'active',
  AgentReconcileResponseDtoInstanceStateEnum.observer: 'observer',
  AgentReconcileResponseDtoInstanceStateEnum.quarantined: 'quarantined',
  AgentReconcileResponseDtoInstanceStateEnum.released: 'released',
};
