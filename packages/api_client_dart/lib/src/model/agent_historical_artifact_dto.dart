//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_historical_artifact_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentHistoricalArtifactDto {
  /// Returns a new [AgentHistoricalArtifactDto] instance.
  AgentHistoricalArtifactDto({
    required this.base64,

    required this.caseId,

    required this.mimeType,

    required this.path,

    required this.sha256,

    required this.size,
  });

  @JsonKey(name: r'base64', required: true, includeIfNull: false)
  final String base64;

  @JsonKey(name: r'caseId', required: true, includeIfNull: false)
  final String caseId;

  @JsonKey(name: r'mimeType', required: true, includeIfNull: false)
  final AgentHistoricalArtifactDtoMimeTypeEnum mimeType;

  @JsonKey(name: r'path', required: true, includeIfNull: false)
  final String path;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  // minimum: 0
  // maximum: 10485760
  @JsonKey(name: r'size', required: true, includeIfNull: false)
  final int size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentHistoricalArtifactDto &&
          other.base64 == base64 &&
          other.caseId == caseId &&
          other.mimeType == mimeType &&
          other.path == path &&
          other.sha256 == sha256 &&
          other.size == size;

  @override
  int get hashCode =>
      base64.hashCode +
      caseId.hashCode +
      mimeType.hashCode +
      path.hashCode +
      sha256.hashCode +
      size.hashCode;

  factory AgentHistoricalArtifactDto.fromJson(Map<String, dynamic> json) =>
      _$AgentHistoricalArtifactDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentHistoricalArtifactDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentHistoricalArtifactDtoMimeTypeEnum {
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'application/json')
  applicationSlashJson(r'application/json');

  const AgentHistoricalArtifactDtoMimeTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
