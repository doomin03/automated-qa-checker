// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_session_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DesktopSessionResponse _$DesktopSessionResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DesktopSessionResponse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['expiresAt', 'token']);
  final val = DesktopSessionResponse(
    expiresAt: $checkedConvert('expiresAt', (v) => DateTime.parse(v as String)),
    token: $checkedConvert('token', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$DesktopSessionResponseToJson(
  DesktopSessionResponse instance,
) => <String, dynamic>{
  'expiresAt': instance.expiresAt.toIso8601String(),
  'token': instance.token,
};
