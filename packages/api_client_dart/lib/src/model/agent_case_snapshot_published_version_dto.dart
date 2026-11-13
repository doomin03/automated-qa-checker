//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_case_snapshot_published_version_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentCaseSnapshotPublishedVersionDto {
  /// Returns a new [AgentCaseSnapshotPublishedVersionDto] instance.
  AgentCaseSnapshotPublishedVersionDto({
    required this.sha256,

    required this.versionId,
  });

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @JsonKey(name: r'versionId', required: true, includeIfNull: false)
  final String versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentCaseSnapshotPublishedVersionDto &&
          other.sha256 == sha256 &&
          other.versionId == versionId;

  @override
  int get hashCode => sha256.hashCode + versionId.hashCode;

  factory AgentCaseSnapshotPublishedVersionDto.fromJson(
    Map<String, dynamic> json,
  ) => _$AgentCaseSnapshotPublishedVersionDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AgentCaseSnapshotPublishedVersionDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
