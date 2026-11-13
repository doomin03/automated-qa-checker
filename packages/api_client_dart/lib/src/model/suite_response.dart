//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/suite_case.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suite_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SuiteResponse {
  /// Returns a new [SuiteResponse] instance.
  SuiteResponse({
    required this.authorId,

    required this.cases,

    required this.contractVersion,

    required this.createdAt,

    required this.engineVersion,

    required this.id,

    required this.packageId,

    required this.projectId,

    required this.reviewerId,

    required this.sha256,

    required this.stopOnFailure,

    required this.title,

    required this.version,
  });

  @JsonKey(name: r'authorId', required: true, includeIfNull: false)
  final String authorId;

  @JsonKey(name: r'cases', required: true, includeIfNull: false)
  final List<SuiteCase> cases;

  @JsonKey(name: r'contractVersion', required: true, includeIfNull: false)
  final String contractVersion;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'engineVersion', required: true, includeIfNull: false)
  final String engineVersion;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'packageId', required: true, includeIfNull: false)
  final String packageId;

  @JsonKey(name: r'projectId', required: true, includeIfNull: false)
  final String projectId;

  @JsonKey(name: r'reviewerId', required: true, includeIfNull: false)
  final String reviewerId;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @JsonKey(name: r'stopOnFailure', required: true, includeIfNull: false)
  final bool stopOnFailure;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final String version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuiteResponse &&
          other.authorId == authorId &&
          other.cases == cases &&
          other.contractVersion == contractVersion &&
          other.createdAt == createdAt &&
          other.engineVersion == engineVersion &&
          other.id == id &&
          other.packageId == packageId &&
          other.projectId == projectId &&
          other.reviewerId == reviewerId &&
          other.sha256 == sha256 &&
          other.stopOnFailure == stopOnFailure &&
          other.title == title &&
          other.version == version;

  @override
  int get hashCode =>
      authorId.hashCode +
      cases.hashCode +
      contractVersion.hashCode +
      createdAt.hashCode +
      engineVersion.hashCode +
      id.hashCode +
      packageId.hashCode +
      projectId.hashCode +
      reviewerId.hashCode +
      sha256.hashCode +
      stopOnFailure.hashCode +
      title.hashCode +
      version.hashCode;

  factory SuiteResponse.fromJson(Map<String, dynamic> json) =>
      _$SuiteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SuiteResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
