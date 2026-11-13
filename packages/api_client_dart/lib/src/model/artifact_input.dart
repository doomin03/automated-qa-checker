//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'artifact_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ArtifactInput {
  /// Returns a new [ArtifactInput] instance.
  ArtifactInput({
    required this.artifactId,

    required this.base64,

    required this.mimeType,

    required this.sha256,
  });

  /// Server issued ID from run.artifacts; never a filesystem path.
  @JsonKey(name: r'artifactId', required: true, includeIfNull: false)
  final String artifactId;

  /// Base64 bytes, maximum decoded 10 MiB; total run maximum 64 MiB.
  @JsonKey(name: r'base64', required: true, includeIfNull: false)
  final String base64;

  @JsonKey(name: r'mimeType', required: true, includeIfNull: false)
  final ArtifactInputMimeTypeEnum mimeType;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactInput &&
          other.artifactId == artifactId &&
          other.base64 == base64 &&
          other.mimeType == mimeType &&
          other.sha256 == sha256;

  @override
  int get hashCode =>
      artifactId.hashCode +
      base64.hashCode +
      mimeType.hashCode +
      sha256.hashCode;

  factory ArtifactInput.fromJson(Map<String, dynamic> json) =>
      _$ArtifactInputFromJson(json);

  Map<String, dynamic> toJson() => _$ArtifactInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ArtifactInputMimeTypeEnum {
  @JsonValue(r'image/png')
  imageSlashPng(r'image/png'),
  @JsonValue(r'application/json')
  applicationSlashJson(r'application/json');

  const ArtifactInputMimeTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
