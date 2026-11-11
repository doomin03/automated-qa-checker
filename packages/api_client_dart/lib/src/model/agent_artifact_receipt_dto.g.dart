// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_artifact_receipt_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentArtifactReceiptDto _$AgentArtifactReceiptDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentArtifactReceiptDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'artifactId',
      'caseId',
      'mimeType',
      'path',
      'sha256',
      'size',
      'uploaded',
    ],
  );
  final val = AgentArtifactReceiptDto(
    artifactId: $checkedConvert('artifactId', (v) => v as String),
    caseId: $checkedConvert('caseId', (v) => v as String),
    mimeType: $checkedConvert(
      'mimeType',
      (v) => $enumDecode(_$AgentArtifactReceiptDtoMimeTypeEnumEnumMap, v),
    ),
    path: $checkedConvert('path', (v) => v as String),
    sha256: $checkedConvert('sha256', (v) => v as String),
    size: $checkedConvert('size', (v) => (v as num).toInt()),
    uploaded: $checkedConvert('uploaded', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$AgentArtifactReceiptDtoToJson(
  AgentArtifactReceiptDto instance,
) => <String, dynamic>{
  'artifactId': instance.artifactId,
  'caseId': instance.caseId,
  'mimeType': _$AgentArtifactReceiptDtoMimeTypeEnumEnumMap[instance.mimeType]!,
  'path': instance.path,
  'sha256': instance.sha256,
  'size': instance.size,
  'uploaded': instance.uploaded,
};

const _$AgentArtifactReceiptDtoMimeTypeEnumEnumMap = {
  AgentArtifactReceiptDtoMimeTypeEnum.imageSlashPng: 'image/png',
  AgentArtifactReceiptDtoMimeTypeEnum.applicationSlashJson: 'application/json',
};
