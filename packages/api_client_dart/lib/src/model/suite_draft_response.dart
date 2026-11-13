//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/suite_case.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suite_draft_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SuiteDraftResponse {
  /// Returns a new [SuiteDraftResponse] instance.
  SuiteDraftResponse({
    required this.authorId,

    required this.cases,

    required this.contractVersion,

    required this.createdAt,

    required this.engineVersion,

    required this.id,

    required this.packageId,

    required this.projectId,

    required this.reviewerId,

    required this.state,

    required this.stopOnFailure,

    required this.title,
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

  @JsonKey(name: r'reviewerId', required: true, includeIfNull: true)
  final String? reviewerId;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final SuiteDraftResponseStateEnum state;

  @JsonKey(name: r'stopOnFailure', required: true, includeIfNull: false)
  final bool stopOnFailure;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuiteDraftResponse &&
          other.authorId == authorId &&
          other.cases == cases &&
          other.contractVersion == contractVersion &&
          other.createdAt == createdAt &&
          other.engineVersion == engineVersion &&
          other.id == id &&
          other.packageId == packageId &&
          other.projectId == projectId &&
          other.reviewerId == reviewerId &&
          other.state == state &&
          other.stopOnFailure == stopOnFailure &&
          other.title == title;

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
      (reviewerId == null ? 0 : reviewerId.hashCode) +
      state.hashCode +
      stopOnFailure.hashCode +
      title.hashCode;

  factory SuiteDraftResponse.fromJson(Map<String, dynamic> json) =>
      _$SuiteDraftResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SuiteDraftResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SuiteDraftResponseStateEnum {
  @JsonValue(r'draft')
  draft(r'draft'),
  @JsonValue(r'reviewed')
  reviewed(r'reviewed'),
  @JsonValue(r'published')
  published(r'published');

  const SuiteDraftResponseStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
