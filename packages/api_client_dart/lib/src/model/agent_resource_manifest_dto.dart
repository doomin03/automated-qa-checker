//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_resource_manifest_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentResourceManifestDto {
  /// Returns a new [AgentResourceManifestDto] instance.
  AgentResourceManifestDto({
    required this.mimeType,

    required this.name,

    required this.resourceId,

    required this.sha256,

    required this.size,
  });

  @JsonKey(name: r'mimeType', required: true, includeIfNull: false)
  final AgentResourceManifestDtoMimeTypeEnum mimeType;

  /// Safe ASCII slash-separated path relative to isolated document root; reject absolute/UNC/backslash/traversal/symlink/case-fold collisions.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'resourceId', required: true, includeIfNull: false)
  final String resourceId;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  // minimum: 0
  // maximum: 10485760
  @JsonKey(name: r'size', required: true, includeIfNull: false)
  final int size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentResourceManifestDto &&
          other.mimeType == mimeType &&
          other.name == name &&
          other.resourceId == resourceId &&
          other.sha256 == sha256 &&
          other.size == size;

  @override
  int get hashCode =>
      mimeType.hashCode +
      name.hashCode +
      resourceId.hashCode +
      sha256.hashCode +
      size.hashCode;

  factory AgentResourceManifestDto.fromJson(Map<String, dynamic> json) =>
      _$AgentResourceManifestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentResourceManifestDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentResourceManifestDtoMimeTypeEnum {
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'application/json')
  applicationSlashJson(r'application/json'),
  @JsonValue(r'font/woff')
  fontSlashWoff(r'font/woff'),
  @JsonValue(r'font/woff2')
  fontSlashWoff2(r'font/woff2'),
  @JsonValue(r'font/ttf')
  fontSlashTtf(r'font/ttf'),
  @JsonValue(r'font/otf')
  fontSlashOtf(r'font/otf');

  const AgentResourceManifestDtoMimeTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
