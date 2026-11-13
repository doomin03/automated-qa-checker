//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_case_snapshot_published_version_dto.dart';
import 'package:api_client_dart/src/model/agent_resource_manifest_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_case_snapshot_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentCaseSnapshotDto {
  /// Returns a new [AgentCaseSnapshotDto] instance.
  AgentCaseSnapshotDto({
    required this.blueprintJson,

    required this.blueprintSnapshotHash,

    required this.caseId,

    required this.publishedVersion,

    required this.resources,
  });

  /// Opaque Engine JSON; exact public Engine schema, UTF-8 byte/depth limits and immutable snapshot validation apply.
  @JsonKey(name: r'blueprintJson', required: true, includeIfNull: false)
  final String blueprintJson;

  @JsonKey(name: r'blueprintSnapshotHash', required: true, includeIfNull: false)
  final String blueprintSnapshotHash;

  @JsonKey(name: r'caseId', required: true, includeIfNull: false)
  final String caseId;

  @JsonKey(name: r'publishedVersion', required: true, includeIfNull: true)
  final AgentCaseSnapshotPublishedVersionDto? publishedVersion;

  @JsonKey(name: r'resources', required: true, includeIfNull: false)
  final List<AgentResourceManifestDto> resources;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentCaseSnapshotDto &&
          other.blueprintJson == blueprintJson &&
          other.blueprintSnapshotHash == blueprintSnapshotHash &&
          other.caseId == caseId &&
          other.publishedVersion == publishedVersion &&
          other.resources == resources;

  @override
  int get hashCode =>
      blueprintJson.hashCode +
      blueprintSnapshotHash.hashCode +
      caseId.hashCode +
      (publishedVersion == null ? 0 : publishedVersion.hashCode) +
      resources.hashCode;

  factory AgentCaseSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$AgentCaseSnapshotDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentCaseSnapshotDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
