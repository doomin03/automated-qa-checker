// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_delivery_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentDeliveryDto _$AgentDeliveryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentDeliveryDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['caseId', 'deliverySequence', 'engineEventJson'],
      );
      final val = AgentDeliveryDto(
        caseId: $checkedConvert('caseId', (v) => v as String),
        deliverySequence: $checkedConvert(
          'deliverySequence',
          (v) => (v as num).toInt(),
        ),
        engineEventJson: $checkedConvert('engineEventJson', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AgentDeliveryDtoToJson(AgentDeliveryDto instance) =>
    <String, dynamic>{
      'caseId': instance.caseId,
      'deliverySequence': instance.deliverySequence,
      'engineEventJson': instance.engineEventJson,
    };
