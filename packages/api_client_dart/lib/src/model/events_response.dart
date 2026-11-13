//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'events_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EventsResponse {
  /// Returns a new [EventsResponse] instance.
  EventsResponse({
    required this.attempt,

    required this.engineRunId,

    required this.eventsJson,

    required this.hasMore,

    required this.nextSequence,

    required this.runId,

    required this.snapshotHash,

    required this.terminal,
  });

  @JsonKey(name: r'attempt', required: true, includeIfNull: false)
  final int attempt;

  @JsonKey(name: r'engineRunId', required: true, includeIfNull: false)
  final String engineRunId;

  @JsonKey(name: r'eventsJson', required: true, includeIfNull: false)
  final List<String> eventsJson;

  @JsonKey(name: r'hasMore', required: true, includeIfNull: false)
  final bool hasMore;

  @JsonKey(name: r'nextSequence', required: true, includeIfNull: false)
  final int nextSequence;

  @JsonKey(name: r'runId', required: true, includeIfNull: false)
  final String runId;

  @JsonKey(name: r'snapshotHash', required: true, includeIfNull: false)
  final String snapshotHash;

  @JsonKey(name: r'terminal', required: true, includeIfNull: false)
  final bool terminal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventsResponse &&
          other.attempt == attempt &&
          other.engineRunId == engineRunId &&
          other.eventsJson == eventsJson &&
          other.hasMore == hasMore &&
          other.nextSequence == nextSequence &&
          other.runId == runId &&
          other.snapshotHash == snapshotHash &&
          other.terminal == terminal;

  @override
  int get hashCode =>
      attempt.hashCode +
      engineRunId.hashCode +
      eventsJson.hashCode +
      hasMore.hashCode +
      nextSequence.hashCode +
      runId.hashCode +
      snapshotHash.hashCode +
      terminal.hashCode;

  factory EventsResponse.fromJson(Map<String, dynamic> json) =>
      _$EventsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EventsResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
