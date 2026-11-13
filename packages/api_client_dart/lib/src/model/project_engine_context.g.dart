// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_engine_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectEngineContext _$ProjectEngineContextFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ProjectEngineContext', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'archiveSha256',
      'contractSha256',
      'contractVersion',
      'engineVersion',
    ],
  );
  final val = ProjectEngineContext(
    archiveSha256: $checkedConvert('archiveSha256', (v) => v as String?),
    contractSha256: $checkedConvert('contractSha256', (v) => v as String),
    contractVersion: $checkedConvert('contractVersion', (v) => v as String),
    engineVersion: $checkedConvert('engineVersion', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$ProjectEngineContextToJson(
  ProjectEngineContext instance,
) => <String, dynamic>{
  'archiveSha256': instance.archiveSha256,
  'contractSha256': instance.contractSha256,
  'contractVersion': instance.contractVersion,
  'engineVersion': instance.engineVersion,
};
