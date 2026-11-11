//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'run_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunInput {
  /// Returns a new [RunInput] instance.
  RunInput({
    required this.attempt,

    required this.blueprintJson,

    required this.engineRunId,

    required this.engineVersion,

    required this.snapshotHash,

    required this.startedEventJson,

    this.versionId,
  });

  // minimum: 1
  // maximum: 1000000
  @JsonKey(name: r'attempt', required: true, includeIfNull: false)
  final int attempt;

  /// Immutable executed plan.blueprint JSON; Engine CLI recomputes the snapshot and node set.
  @JsonKey(name: r'blueprintJson', required: true, includeIfNull: false)
  final String blueprintJson;

  @JsonKey(name: r'engineRunId', required: true, includeIfNull: false)
  final String engineRunId;

  @JsonKey(name: r'engineVersion', required: true, includeIfNull: false)
  final String engineVersion;

  @JsonKey(name: r'snapshotHash', required: true, includeIfNull: false)
  final String snapshotHash;

  /// Actual Engine run.started JSON; identity and snapshot must match the fields above. Stored as sequence 1.
  @JsonKey(name: r'startedEventJson', required: true, includeIfNull: false)
  final String startedEventJson;

  @JsonKey(name: r'versionId', required: false, includeIfNull: false)
  final String? versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunInput &&
          other.attempt == attempt &&
          other.blueprintJson == blueprintJson &&
          other.engineRunId == engineRunId &&
          other.engineVersion == engineVersion &&
          other.snapshotHash == snapshotHash &&
          other.startedEventJson == startedEventJson &&
          other.versionId == versionId;

  @override
  int get hashCode =>
      attempt.hashCode +
      blueprintJson.hashCode +
      engineRunId.hashCode +
      engineVersion.hashCode +
      snapshotHash.hashCode +
      startedEventJson.hashCode +
      versionId.hashCode;

  factory RunInput.fromJson(Map<String, dynamic> json) =>
      _$RunInputFromJson(json);

  Map<String, dynamic> toJson() => _$RunInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
