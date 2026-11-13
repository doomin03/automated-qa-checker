// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_resource_manifest_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentResourceManifestDto _$AgentResourceManifestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentResourceManifestDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['mimeType', 'name', 'resourceId', 'sha256', 'size'],
  );
  final val = AgentResourceManifestDto(
    mimeType: $checkedConvert(
      'mimeType',
      (v) => $enumDecode(_$AgentResourceManifestDtoMimeTypeEnumEnumMap, v),
    ),
    name: $checkedConvert('name', (v) => v as String),
    resourceId: $checkedConvert('resourceId', (v) => v as String),
    sha256: $checkedConvert('sha256', (v) => v as String),
    size: $checkedConvert('size', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$AgentResourceManifestDtoToJson(
  AgentResourceManifestDto instance,
) => <String, dynamic>{
  'mimeType': _$AgentResourceManifestDtoMimeTypeEnumEnumMap[instance.mimeType]!,
  'name': instance.name,
  'resourceId': instance.resourceId,
  'sha256': instance.sha256,
  'size': instance.size,
};

const _$AgentResourceManifestDtoMimeTypeEnumEnumMap = {
  AgentResourceManifestDtoMimeTypeEnum.imageSlashPng: 'image/png',
  AgentResourceManifestDtoMimeTypeEnum.applicationSlashJson: 'application/json',
  AgentResourceManifestDtoMimeTypeEnum.fontSlashWoff: 'font/woff',
  AgentResourceManifestDtoMimeTypeEnum.fontSlashWoff2: 'font/woff2',
  AgentResourceManifestDtoMimeTypeEnum.fontSlashTtf: 'font/ttf',
  AgentResourceManifestDtoMimeTypeEnum.fontSlashOtf: 'font/otf',
};
