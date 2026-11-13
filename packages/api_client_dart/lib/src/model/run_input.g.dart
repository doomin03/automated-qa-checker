// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunInput _$RunInputFromJson(Map<String, dynamic> json) => $checkedCreate(
  'RunInput',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'attempt',
        'blueprintJson',
        'engineRunId',
        'engineVersion',
        'snapshotHash',
        'startedEventJson',
      ],
    );
    final val = RunInput(
      attempt: $checkedConvert('attempt', (v) => (v as num).toInt()),
      blueprintJson: $checkedConvert('blueprintJson', (v) => v as String),
      engineRunId: $checkedConvert('engineRunId', (v) => v as String),
      engineVersion: $checkedConvert('engineVersion', (v) => v as String),
      snapshotHash: $checkedConvert('snapshotHash', (v) => v as String),
      startedEventJson: $checkedConvert('startedEventJson', (v) => v as String),
      versionId: $checkedConvert('versionId', (v) => v as String?),
    );
    return val;
  },
);

Map<String, dynamic> _$RunInputToJson(RunInput instance) => <String, dynamic>{
  'attempt': instance.attempt,
  'blueprintJson': instance.blueprintJson,
  'engineRunId': instance.engineRunId,
  'engineVersion': instance.engineVersion,
  'snapshotHash': instance.snapshotHash,
  'startedEventJson': instance.startedEventJson,
  'versionId': ?instance.versionId,
};
