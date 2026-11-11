// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionResponse _$SessionResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SessionResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['csrfToken', 'localMode', 'projects', 'userId'],
      );
      final val = SessionResponse(
        csrfToken: $checkedConvert('csrfToken', (v) => v as String?),
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

Map<String, dynamic> _$SessionResponseToJson(SessionResponse instance) =>
    <String, dynamic>{
      'csrfToken': instance.csrfToken,
      'localMode': instance.localMode,
      'projects': instance.projects.map((e) => e.toJson()).toList(),
      'userId': instance.userId,
    };
