// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_resource_bytes_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentResourceBytesDto _$AgentResourceBytesDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AgentResourceBytesDto', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'base64',
      'mimeType',
      'name',
      'resourceId',
      'sha256',
      'size',
    ],
  );
  final val = AgentResourceBytesDto(
    base64: $checkedConvert('base64', (v) => v as String),
    mimeType: $checkedConvert(
      'mimeType',
      (v) => $enumDecode(_$AgentResourceBytesDtoMimeTypeEnumEnumMap, v),
    ),
    name: $checkedConvert('name', (v) => v as String),
    resourceId: $checkedConvert('resourceId', (v) => v as String),
    sha256: $checkedConvert('sha256', (v) => v as String),
    size: $checkedConvert('size', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$AgentResourceBytesDtoToJson(
  AgentResourceBytesDto instance,
) => <String, dynamic>{
  'base64': instance.base64,
  'mimeType': _$AgentResourceBytesDtoMimeTypeEnumEnumMap[instance.mimeType]!,
  'name': instance.name,
  'resourceId': instance.resourceId,
  'sha256': instance.sha256,
  'size': instance.size,
};

const _$AgentResourceBytesDtoMimeTypeEnumEnumMap = {
  AgentResourceBytesDtoMimeTypeEnum.imageSlashPng: 'image/png',
  AgentResourceBytesDtoMimeTypeEnum.applicationSlashJson: 'application/json',
  AgentResourceBytesDtoMimeTypeEnum.fontSlashWoff: 'font/woff',
  AgentResourceBytesDtoMimeTypeEnum.fontSlashWoff2: 'font/woff2',
  AgentResourceBytesDtoMimeTypeEnum.fontSlashTtf: 'font/ttf',
  AgentResourceBytesDtoMimeTypeEnum.fontSlashOtf: 'font/otf',
};
