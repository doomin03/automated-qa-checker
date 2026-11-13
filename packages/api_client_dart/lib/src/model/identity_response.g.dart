// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IdentityResponse _$IdentityResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('IdentityResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['localMode', 'projects', 'userId']);
      final val = IdentityResponse(
        localMode: $checkedConvert('localMode', (v) => v as bool),
        projects: $checkedConvert(
          'projects',
          (v) => (v as List<dynamic>)
              .map((e) => ProjectResponse.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        userId: $checkedConvert('userId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$IdentityResponseToJson(IdentityResponse instance) =>
    <String, dynamic>{
      'localMode': instance.localMode,
      'projects': instance.projects.map((e) => e.toJson()).toList(),
      'userId': instance.userId,
    };
