//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'work_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkInput {
  /// Returns a new [WorkInput] instance.
  WorkInput({
    required this.assigneeId,

    required this.revision,

    required this.status,
  });

  @JsonKey(name: r'assigneeId', required: true, includeIfNull: true)
  final String? assigneeId;

  // minimum: 0
  @JsonKey(name: r'revision', required: true, includeIfNull: false)
  final int revision;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final WorkInputStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkInput &&
          other.assigneeId == assigneeId &&
          other.revision == revision &&
          other.status == status;

  @override
  int get hashCode =>
      (assigneeId == null ? 0 : assigneeId.hashCode) +
      revision.hashCode +
      status.hashCode;

  factory WorkInput.fromJson(Map<String, dynamic> json) =>
      _$WorkInputFromJson(json);

  Map<String, dynamic> toJson() => _$WorkInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum WorkInputStatusEnum {
  @JsonValue(r'todo')
  todo(r'todo'),
  @JsonValue(r'in_progress')
  inProgress(r'in_progress'),
  @JsonValue(r'done')
  done(r'done');

  const WorkInputStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
