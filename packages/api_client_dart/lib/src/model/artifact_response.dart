//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'artifact_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ArtifactResponse {
  /// Returns a new [ArtifactResponse] instance.
  ArtifactResponse({
    required this.artifactId,

    required this.mimeType,

    required this.name,

    required this.sha256,

    required this.size,

    required this.uploaded,
  });

  @JsonKey(name: r'artifactId', required: true, includeIfNull: false)
  final String artifactId;

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
      other is ArtifactResponse &&
          other.artifactId == artifactId &&
          other.mimeType == mimeType &&
          other.name == name &&
          other.sha256 == sha256 &&
          other.size == size &&
          other.uploaded == uploaded;

  @override
  int get hashCode =>
      artifactId.hashCode +
      mimeType.hashCode +
      name.hashCode +
      sha256.hashCode +
      size.hashCode +
      uploaded.hashCode;

  factory ArtifactResponse.fromJson(Map<String, dynamic> json) =>
      _$ArtifactResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ArtifactResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
