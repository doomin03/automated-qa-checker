// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditResponse _$AuditResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AuditResponse', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['action', 'actorId', 'createdAt', 'id', 'resourceId'],
  );
  final val = AuditResponse(
    action: $checkedConvert('action', (v) => v as String),
    actorId: $checkedConvert('actorId', (v) => v as String),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    id: $checkedConvert('id', (v) => v as String),
    resourceId: $checkedConvert('resourceId', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$AuditResponseToJson(AuditResponse instance) =>
    <String, dynamic>{
      'action': instance.action,
      'actorId': instance.actorId,
      'createdAt': instance.createdAt.toIso8601String(),
      'id': instance.id,
      'resourceId': instance.resourceId,
    };
