//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_artifact_upload_request_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentArtifactUploadRequestDto {
  /// Returns a new [AgentArtifactUploadRequestDto] instance.
  AgentArtifactUploadRequestDto({
    required this.agentId,

    required this.artifactId,

    required this.base64,

    required this.caseId,

    required this.fence,

    required this.instanceId,

    required this.mimeType,

    required this.sha256,
  });

  @JsonKey(name: r'agentId', required: true, includeIfNull: false)
  final String agentId;

  @JsonKey(name: r'artifactId', required: true, includeIfNull: false)
  final String artifactId;

  @JsonKey(name: r'base64', required: true, includeIfNull: false)
  final String base64;

  @JsonKey(name: r'caseId', required: true, includeIfNull: false)
  final String caseId;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'fence', required: true, includeIfNull: false)
  final int fence;

  @JsonKey(name: r'instanceId', required: true, includeIfNull: false)
  final String instanceId;

  @JsonKey(name: r'mimeType', required: true, includeIfNull: false)
  final AgentArtifactUploadRequestDtoMimeTypeEnum mimeType;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentArtifactUploadRequestDto &&
          other.agentId == agentId &&
          other.artifactId == artifactId &&
          other.base64 == base64 &&
          other.caseId == caseId &&
          other.fence == fence &&
          other.instanceId == instanceId &&
          other.mimeType == mimeType &&
          other.sha256 == sha256;

  @override
  int get hashCode =>
      agentId.hashCode +
      artifactId.hashCode +
      base64.hashCode +
      caseId.hashCode +
      fence.hashCode +
      instanceId.hashCode +
      mimeType.hashCode +
      sha256.hashCode;

  factory AgentArtifactUploadRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AgentArtifactUploadRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentArtifactUploadRequestDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentArtifactUploadRequestDtoMimeTypeEnum {
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'application/json')
  applicationSlashJson(r'application/json');

  const AgentArtifactUploadRequestDtoMimeTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
