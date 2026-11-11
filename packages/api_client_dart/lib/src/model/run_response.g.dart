// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunResponse _$RunResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RunResponse', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'artifacts',
      'attempt',
      'blueprintJson',
      'createdAt',
      'engineRunId',
      'engineVersion',
      'evidenceStatus',
      'id',
      'lastSequence',
      'ownerId',
      'projectId',
      'reportedOutcome',
      'resultJson',
      'snapshotHash',
      'terminal',
      'versionId',
      'workStatus',
    ],
  );
  final val = RunResponse(
    artifacts: $checkedConvert(
      'artifacts',
      (v) => (v as List<dynamic>)
          .map((e) => ArtifactResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    attempt: $checkedConvert('attempt', (v) => (v as num).toInt()),
    blueprintJson: $checkedConvert('blueprintJson', (v) => v as String),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    engineRunId: $checkedConvert('engineRunId', (v) => v as String),
    engineVersion: $checkedConvert('engineVersion', (v) => v as String),
    evidenceStatus: $checkedConvert(
      'evidenceStatus',
      (v) => $enumDecode(_$RunResponseEvidenceStatusEnumEnumMap, v),
    ),
    id: $checkedConvert('id', (v) => v as String),
    lastSequence: $checkedConvert('lastSequence', (v) => (v as num).toInt()),
    ownerId: $checkedConvert('ownerId', (v) => v as String),
    projectId: $checkedConvert('projectId', (v) => v as String),
    reportedOutcome: $checkedConvert('reportedOutcome', (v) => v as String?),
    resultJson: $checkedConvert('resultJson', (v) => v as String?),
    snapshotHash: $checkedConvert('snapshotHash', (v) => v as String),
    terminal: $checkedConvert('terminal', (v) => v as bool),
    versionId: $checkedConvert('versionId', (v) => v as String?),
    workStatus: $checkedConvert(
      'workStatus',
      (v) => $enumDecode(_$RunResponseWorkStatusEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$RunResponseToJson(RunResponse instance) =>
    <String, dynamic>{
      'artifacts': instance.artifacts.map((e) => e.toJson()).toList(),
      'attempt': instance.attempt,
      'blueprintJson': instance.blueprintJson,
      'createdAt': instance.createdAt.toIso8601String(),
      'engineRunId': instance.engineRunId,
      'engineVersion': instance.engineVersion,
      'evidenceStatus':
          _$RunResponseEvidenceStatusEnumEnumMap[instance.evidenceStatus]!,
      'id': instance.id,
      'lastSequence': instance.lastSequence,
      'ownerId': instance.ownerId,
      'projectId': instance.projectId,
      'reportedOutcome': instance.reportedOutcome,
      'resultJson': instance.resultJson,
      'snapshotHash': instance.snapshotHash,
      'terminal': instance.terminal,
      'versionId': instance.versionId,
      'workStatus': _$RunResponseWorkStatusEnumEnumMap[instance.workStatus]!,
    };

const _$RunResponseEvidenceStatusEnumEnumMap = {
  RunResponseEvidenceStatusEnum.pending: 'pending',
  RunResponseEvidenceStatusEnum.missing: 'missing',
  RunResponseEvidenceStatusEnum.verified: 'verified',
};

const _$RunResponseWorkStatusEnumEnumMap = {
  RunResponseWorkStatusEnum.todo: 'todo',
  RunResponseWorkStatusEnum.inProgress: 'in_progress',
  RunResponseWorkStatusEnum.done: 'done',
};
