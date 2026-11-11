// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_case_snapshot_published_version_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentCaseSnapshotPublishedVersionDto
_$AgentCaseSnapshotPublishedVersionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AgentCaseSnapshotPublishedVersionDto', json, (
      $checkedConvert,
    ) {
      $checkKeys(json, requiredKeys: const ['sha256', 'versionId']);
      final val = AgentCaseSnapshotPublishedVersionDto(
        sha256: $checkedConvert('sha256', (v) => v as String),
        versionId: $checkedConvert('versionId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AgentCaseSnapshotPublishedVersionDtoToJson(
  AgentCaseSnapshotPublishedVersionDto instance,
) => <String, dynamic>{
  'sha256': instance.sha256,
  'versionId': instance.versionId,
};
