//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/dependency_pin.dart';
import 'package:json_annotation/json_annotation.dart';

part 'version_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VersionResponse {
  /// Returns a new [VersionResponse] instance.
  VersionResponse({
    required this.blueprintSnapshotHash,

    required this.createdAt,

    required this.dependencies,

    required this.engineVersion,

    required this.flowSnapshotHash,

    required this.id,

    required this.packageId,

    required this.projectId,

    required this.sha256,

    required this.title,

    required this.version,

    required this.xml,
  });

  @JsonKey(name: r'blueprintSnapshotHash', required: true, includeIfNull: false)
  final String blueprintSnapshotHash;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'dependencies', required: true, includeIfNull: false)
  final List<DependencyPin> dependencies;

  @JsonKey(name: r'engineVersion', required: true, includeIfNull: false)
  final String engineVersion;

  @JsonKey(name: r'flowSnapshotHash', required: true, includeIfNull: false)
  final String flowSnapshotHash;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'packageId', required: true, includeIfNull: false)
  final String packageId;

  @JsonKey(name: r'projectId', required: true, includeIfNull: false)
  final String projectId;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final String version;

  @JsonKey(name: r'xml', required: true, includeIfNull: false)
  final String xml;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersionResponse &&
          other.blueprintSnapshotHash == blueprintSnapshotHash &&
          other.createdAt == createdAt &&
          other.dependencies == dependencies &&
          other.engineVersion == engineVersion &&
          other.flowSnapshotHash == flowSnapshotHash &&
          other.id == id &&
          other.packageId == packageId &&
          other.projectId == projectId &&
          other.sha256 == sha256 &&
          other.title == title &&
          other.version == version &&
          other.xml == xml;

  @override
  int get hashCode =>
      blueprintSnapshotHash.hashCode +
      createdAt.hashCode +
      dependencies.hashCode +
      engineVersion.hashCode +
      flowSnapshotHash.hashCode +
      id.hashCode +
      packageId.hashCode +
      projectId.hashCode +
      sha256.hashCode +
      title.hashCode +
      version.hashCode +
      xml.hashCode;

  factory VersionResponse.fromJson(Map<String, dynamic> json) =>
      _$VersionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VersionResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
