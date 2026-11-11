//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'work_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkResponse {
  /// Returns a new [WorkResponse] instance.
  WorkResponse({
    required this.assigneeId,

    required this.revision,

    required this.runId,

    required this.status,

    required this.updatedAt,
  });

  @JsonKey(name: r'assigneeId', required: true, includeIfNull: true)
  final String? assigneeId;

  // minimum: 0
  @JsonKey(name: r'revision', required: true, includeIfNull: false)
  final int revision;

  @JsonKey(name: r'runId', required: true, includeIfNull: false)
  final String runId;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final WorkResponseStatusEnum status;

  @JsonKey(name: r'updatedAt', required: true, includeIfNull: true)
  final String? updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkResponse &&
          other.assigneeId == assigneeId &&
          other.revision == revision &&
          other.runId == runId &&
          other.status == status &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      (assigneeId == null ? 0 : assigneeId.hashCode) +
      revision.hashCode +
      runId.hashCode +
      status.hashCode +
      (updatedAt == null ? 0 : updatedAt.hashCode);

  factory WorkResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WorkResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum WorkResponseStatusEnum {
  @JsonValue(r'todo')
  todo(r'todo'),
  @JsonValue(r'in_progress')
  inProgress(r'in_progress'),
  @JsonValue(r'done')
  done(r'done');

  const WorkResponseStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
