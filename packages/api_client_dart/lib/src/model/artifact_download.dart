//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'artifact_download.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ArtifactDownload {
  /// Returns a new [ArtifactDownload] instance.
  ArtifactDownload({
    required this.artifactId,

    required this.base64,

    required this.mimeType,

    required this.name,

    required this.sha256,

    required this.size,

    required this.uploaded,
  });

  @JsonKey(name: r'artifactId', required: true, includeIfNull: false)
  final String artifactId;

  @JsonKey(name: r'base64', required: true, includeIfNull: false)
  final String base64;

  @JsonKey(name: r'mimeType', required: true, includeIfNull: false)
  final String mimeType;

  /// Engine logical artifact name; not a server path.
  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

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
      other is ArtifactDownload &&
          other.artifactId == artifactId &&
          other.base64 == base64 &&
          other.mimeType == mimeType &&
          other.name == name &&
          other.sha256 == sha256 &&
          other.size == size &&
          other.uploaded == uploaded;

  @override
  int get hashCode =>
      artifactId.hashCode +
      base64.hashCode +
      mimeType.hashCode +
      name.hashCode +
      sha256.hashCode +
      size.hashCode +
      uploaded.hashCode;

  factory ArtifactDownload.fromJson(Map<String, dynamic> json) =>
      _$ArtifactDownloadFromJson(json);

  Map<String, dynamic> toJson() => _$ArtifactDownloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
