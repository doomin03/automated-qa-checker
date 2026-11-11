//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'health_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HealthResponse {
  /// Returns a new [HealthResponse] instance.
  HealthResponse({
    required this.apiVersion,

    required this.client,

    required this.service,

    required this.status,
  });

  @JsonKey(name: r'apiVersion', required: true, includeIfNull: false)
  final HealthResponseApiVersionEnum apiVersion;

  @JsonKey(name: r'client', required: true, includeIfNull: true)
  final HealthResponseClientEnum? client;

  @JsonKey(name: r'service', required: true, includeIfNull: false)
  final HealthResponseServiceEnum service;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final HealthResponseStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthResponse &&
          other.apiVersion == apiVersion &&
          other.client == client &&
          other.service == service &&
          other.status == status;

  @override
  int get hashCode =>
      apiVersion.hashCode +
      (client == null ? 0 : client.hashCode) +
      service.hashCode +
      status.hashCode;

  factory HealthResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HealthResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum HealthResponseApiVersionEnum {
  @JsonValue(r'v1')
  v1(r'v1');

  const HealthResponseApiVersionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum HealthResponseClientEnum {
  @JsonValue(r'web')
  web(r'web'),
  @JsonValue(r'app')
  app(r'app');

  const HealthResponseClientEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum HealthResponseServiceEnum {
  @JsonValue(r'automated-qa-checker')
  automatedQaChecker(r'automated-qa-checker');

  const HealthResponseServiceEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum HealthResponseStatusEnum {
  @JsonValue(r'ok')
  ok(r'ok');

  const HealthResponseStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
