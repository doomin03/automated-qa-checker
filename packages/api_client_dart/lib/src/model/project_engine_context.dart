//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'project_engine_context.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProjectEngineContext {
  /// Returns a new [ProjectEngineContext] instance.
  ProjectEngineContext({
    required this.archiveSha256,

    required this.contractSha256,

    required this.contractVersion,

    required this.engineVersion,
  });

  /// Installation archive pin metadata only; not a fresh archive verification guarantee. Null when unavailable.
  @JsonKey(name: r'archiveSha256', required: true, includeIfNull: true)
  final String? archiveSha256;

  @JsonKey(name: r'contractSha256', required: true, includeIfNull: false)
  final String contractSha256;

  @JsonKey(name: r'contractVersion', required: true, includeIfNull: false)
  final String contractVersion;

  @JsonKey(name: r'engineVersion', required: true, includeIfNull: false)
  final String engineVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectEngineContext &&
          other.archiveSha256 == archiveSha256 &&
          other.contractSha256 == contractSha256 &&
          other.contractVersion == contractVersion &&
          other.engineVersion == engineVersion;

  @override
  int get hashCode =>
      (archiveSha256 == null ? 0 : archiveSha256.hashCode) +
      contractSha256.hashCode +
      contractVersion.hashCode +
      engineVersion.hashCode;

  factory ProjectEngineContext.fromJson(Map<String, dynamic> json) =>
      _$ProjectEngineContextFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectEngineContextToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
