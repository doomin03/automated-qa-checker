// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VersionResponse _$VersionResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('VersionResponse', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'blueprintSnapshotHash',
      'createdAt',
      'dependencies',
      'engineVersion',
      'flowSnapshotHash',
      'id',
      'packageId',
      'projectId',
      'sha256',
      'title',
      'version',
      'xml',
    ],
  );
  final val = VersionResponse(
    blueprintSnapshotHash: $checkedConvert(
      'blueprintSnapshotHash',
      (v) => v as String,
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    dependencies: $checkedConvert(
      'dependencies',
      (v) => (v as List<dynamic>)
          .map((e) => DependencyPin.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    engineVersion: $checkedConvert('engineVersion', (v) => v as String),
    flowSnapshotHash: $checkedConvert('flowSnapshotHash', (v) => v as String),
    id: $checkedConvert('id', (v) => v as String),
    packageId: $checkedConvert('packageId', (v) => v as String),
    projectId: $checkedConvert('projectId', (v) => v as String),
    sha256: $checkedConvert('sha256', (v) => v as String),
    title: $checkedConvert('title', (v) => v as String),
    version: $checkedConvert('version', (v) => v as String),
    xml: $checkedConvert('xml', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$VersionResponseToJson(VersionResponse instance) =>
    <String, dynamic>{
      'blueprintSnapshotHash': instance.blueprintSnapshotHash,
      'createdAt': instance.createdAt.toIso8601String(),
      'dependencies': instance.dependencies.map((e) => e.toJson()).toList(),
      'engineVersion': instance.engineVersion,
      'flowSnapshotHash': instance.flowSnapshotHash,
      'id': instance.id,
      'packageId': instance.packageId,
      'projectId': instance.projectId,
      'sha256': instance.sha256,
      'title': instance.title,
      'version': instance.version,
      'xml': instance.xml,
    };
