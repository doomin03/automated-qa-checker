//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/dependency_pin.dart';
import 'package:json_annotation/json_annotation.dart';

part 'draft_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DraftResponse {
  /// Returns a new [DraftResponse] instance.
  DraftResponse({
    required this.authorId,

    required this.createdAt,

    required this.dependencies,

    required this.id,

    required this.packageId,

    required this.projectId,

    required this.reviewerId,

    required this.sha256,

    required this.state,

    required this.title,

    required this.xml,
  });

  @JsonKey(name: r'authorId', required: true, includeIfNull: false)
  final String authorId;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'dependencies', required: true, includeIfNull: false)
  final List<DependencyPin> dependencies;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'packageId', required: true, includeIfNull: false)
  final String packageId;

  @JsonKey(name: r'projectId', required: true, includeIfNull: false)
  final String projectId;

  @JsonKey(name: r'reviewerId', required: true, includeIfNull: true)
  final String? reviewerId;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final DraftResponseStateEnum state;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'xml', required: true, includeIfNull: false)
  final String xml;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftResponse &&
          other.authorId == authorId &&
          other.createdAt == createdAt &&
          other.dependencies == dependencies &&
          other.id == id &&
          other.packageId == packageId &&
          other.projectId == projectId &&
          other.reviewerId == reviewerId &&
          other.sha256 == sha256 &&
          other.state == state &&
          other.title == title &&
          other.xml == xml;

  @override
  int get hashCode =>
      authorId.hashCode +
      createdAt.hashCode +
      dependencies.hashCode +
      id.hashCode +
      packageId.hashCode +
      projectId.hashCode +
      (reviewerId == null ? 0 : reviewerId.hashCode) +
      sha256.hashCode +
      state.hashCode +
      title.hashCode +
      xml.hashCode;

  factory DraftResponse.fromJson(Map<String, dynamic> json) =>
      _$DraftResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DraftResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum DraftResponseStateEnum {
  @JsonValue(r'draft')
  draft(r'draft'),
  @JsonValue(r'reviewed')
  reviewed(r'reviewed'),
  @JsonValue(r'published')
  published(r'published');

  const DraftResponseStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
