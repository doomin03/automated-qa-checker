// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExecutionInput _$ExecutionInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExecutionInput', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'executionPolicy',
          'sha256',
          'suiteVersionId',
          'versionId',
        ],
      );
      final val = ExecutionInput(
        executionPolicy: $checkedConvert(
          'executionPolicy',
          (v) => AgentExecutionPolicyDto.fromJson(v as Map<String, dynamic>),
        ),
        sha256: $checkedConvert('sha256', (v) => v as String),
        suiteVersionId: $checkedConvert('suiteVersionId', (v) => v as String?),
        versionId: $checkedConvert('versionId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ExecutionInputToJson(ExecutionInput instance) =>
    <String, dynamic>{
      'executionPolicy': instance.executionPolicy.toJson(),
      'sha256': instance.sha256,
      'suiteVersionId': instance.suiteVersionId,
      'versionId': instance.versionId,
    };
