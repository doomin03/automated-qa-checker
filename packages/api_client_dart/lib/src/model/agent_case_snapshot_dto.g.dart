// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_case_snapshot_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentCaseSnapshotDto _$AgentCaseSnapshotDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentCaseSnapshotDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'blueprintJson',
      'blueprintSnapshotHash',
      'caseId',
      'publishedVersion',
      'resources',
    ],
  );
  final val = AgentCaseSnapshotDto(
    blueprintJson: $checkedConvert('blueprintJson', (v) => v as String),
    blueprintSnapshotHash: $checkedConvert(
      'blueprintSnapshotHash',
      (v) => v as String,
    ),
    caseId: $checkedConvert('caseId', (v) => v as String),
    publishedVersion: $checkedConvert(
      'publishedVersion',
      (v) => v == null
          ? null
          : AgentCaseSnapshotPublishedVersionDto.fromJson(
              v as Map<String, dynamic>,
            ),
    ),
    resources: $checkedConvert(
      'resources',
      (v) => (v as List<dynamic>)
          .map(
            (e) => AgentResourceManifestDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AgentCaseSnapshotDtoToJson(
  AgentCaseSnapshotDto instance,
) => <String, dynamic>{
  'blueprintJson': instance.blueprintJson,
  'blueprintSnapshotHash': instance.blueprintSnapshotHash,
  'caseId': instance.caseId,
  'publishedVersion': instance.publishedVersion?.toJson(),
  'resources': instance.resources.map((e) => e.toJson()).toList(),
};
