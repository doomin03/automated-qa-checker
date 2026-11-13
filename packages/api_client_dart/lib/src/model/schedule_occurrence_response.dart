//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'schedule_occurrence_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ScheduleOccurrenceResponse {
  /// Returns a new [ScheduleOccurrenceResponse] instance.
  ScheduleOccurrenceResponse({
    required this.executionId,

    required this.id,

    required this.localDate,

    required this.occurrenceAt,

    required this.reason,

    required this.scheduleId,

    required this.state,
  });

  @JsonKey(name: r'executionId', required: true, includeIfNull: true)
  final String? executionId;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'localDate', required: true, includeIfNull: false)
  final String localDate;

  @JsonKey(name: r'occurrenceAt', required: true, includeIfNull: true)
  final DateTime? occurrenceAt;

  @JsonKey(name: r'reason', required: true, includeIfNull: true)
  final String? reason;

  @JsonKey(name: r'scheduleId', required: true, includeIfNull: false)
  final String scheduleId;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final String state;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleOccurrenceResponse &&
          other.executionId == executionId &&
          other.id == id &&
          other.localDate == localDate &&
          other.occurrenceAt == occurrenceAt &&
          other.reason == reason &&
          other.scheduleId == scheduleId &&
          other.state == state;

  @override
  int get hashCode =>
      (executionId == null ? 0 : executionId.hashCode) +
      id.hashCode +
      localDate.hashCode +
      (occurrenceAt == null ? 0 : occurrenceAt.hashCode) +
      (reason == null ? 0 : reason.hashCode) +
      scheduleId.hashCode +
      state.hashCode;

  factory ScheduleOccurrenceResponse.fromJson(Map<String, dynamic> json) =>
      _$ScheduleOccurrenceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleOccurrenceResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
