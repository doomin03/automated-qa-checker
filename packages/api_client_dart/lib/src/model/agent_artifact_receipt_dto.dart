//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_artifact_receipt_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentArtifactReceiptDto {
  /// Returns a new [AgentArtifactReceiptDto] instance.
  AgentArtifactReceiptDto({
    required this.artifactId,

    required this.caseId,

    required this.mimeType,

    required this.path,

    required this.sha256,

    required this.size,

    required this.uploaded,
  });

  @JsonKey(name: r'artifactId', required: true, includeIfNull: false)
  final String artifactId;

  @JsonKey(name: r'caseId', required: true, includeIfNull: false)
  final String caseId;

  @JsonKey(name: r'mimeType', required: true, includeIfNull: false)
  final AgentArtifactReceiptDtoMimeTypeEnum mimeType;

  @JsonKey(name: r'path', required: true, includeIfNull: false)
  final String path;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  // minimum: 0
  // maximum: 10485760
  @JsonKey(name: r'size', required: true, includeIfNull: false)
  final int size;

  @JsonKey(name: r'uploaded', required: true, includeIfNull: false)
  final bool uploaded;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentArtifactReceiptDto &&
          other.artifactId == artifactId &&
          other.caseId == caseId &&
          other.mimeType == mimeType &&
          other.path == path &&
          other.sha256 == sha256 &&
          other.size == size &&
          other.uploaded == uploaded;

  @override
  int get hashCode =>
      artifactId.hashCode +
      caseId.hashCode +
      mimeType.hashCode +
      path.hashCode +
      sha256.hashCode +
      size.hashCode +
      uploaded.hashCode;

  factory AgentArtifactReceiptDto.fromJson(Map<String, dynamic> json) =>
      _$AgentArtifactReceiptDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentArtifactReceiptDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentArtifactReceiptDtoMimeTypeEnum {
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'application/json')
  applicationSlashJson(r'application/json');

  const AgentArtifactReceiptDtoMimeTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
