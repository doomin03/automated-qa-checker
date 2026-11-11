// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_case_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentCaseResultDto _$AgentCaseResultDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentCaseResultDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['caseId', 'resultJson']);
      final val = AgentCaseResultDto(
        caseId: $checkedConvert('caseId', (v) => v as String),
        resultJson: $checkedConvert('resultJson', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AgentCaseResultDtoToJson(AgentCaseResultDto instance) =>
    <String, dynamic>{
      'caseId': instance.caseId,
      'resultJson': instance.resultJson,
    };
