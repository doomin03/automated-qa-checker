//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/artifact_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunResponse {
  /// Returns a new [RunResponse] instance.
  RunResponse({
    required this.artifacts,

    required this.attempt,

    required this.blueprintJson,

    required this.createdAt,

    required this.engineRunId,

    required this.engineVersion,

    required this.evidenceStatus,

    required this.id,

    required this.lastSequence,

    required this.ownerId,

    required this.projectId,

    required this.reportedOutcome,

    required this.resultJson,

    required this.snapshotHash,

    required this.terminal,

    required this.versionId,

    required this.workStatus,
  });

  @JsonKey(name: r'artifacts', required: true, includeIfNull: false)
  final List<ArtifactResponse> artifacts;

  @JsonKey(name: r'attempt', required: true, includeIfNull: false)
  final int attempt;

  /// Immutable normalized Engine Blueprint JSON used for this run.
  @JsonKey(name: r'blueprintJson', required: true, includeIfNull: false)
  final String blueprintJson;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'engineRunId', required: true, includeIfNull: false)
  final String engineRunId;

  @JsonKey(name: r'engineVersion', required: true, includeIfNull: false)
  final String engineVersion;

  @JsonKey(name: r'evidenceStatus', required: true, includeIfNull: false)
  final RunResponseEvidenceStatusEnum evidenceStatus;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'lastSequence', required: true, includeIfNull: false)
  final int lastSequence;

  @JsonKey(name: r'ownerId', required: true, includeIfNull: false)
  final String ownerId;

  @JsonKey(name: r'projectId', required: true, includeIfNull: false)
  final String projectId;

  /// Externally reported Engine outcome; never a server re-execution verdict.
  @JsonKey(name: r'reportedOutcome', required: true, includeIfNull: true)
  final String? reportedOutcome;

  @JsonKey(name: r'resultJson', required: true, includeIfNull: true)
  final String? resultJson;

  @JsonKey(name: r'snapshotHash', required: true, includeIfNull: false)
  final String snapshotHash;

  @JsonKey(name: r'terminal', required: true, includeIfNull: false)
  final bool terminal;

  @JsonKey(name: r'versionId', required: true, includeIfNull: true)
  final String? versionId;

  @JsonKey(name: r'workStatus', required: true, includeIfNull: false)
  final RunResponseWorkStatusEnum workStatus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunResponse &&
          other.artifacts == artifacts &&
          other.attempt == attempt &&
          other.blueprintJson == blueprintJson &&
          other.createdAt == createdAt &&
          other.engineRunId == engineRunId &&
          other.engineVersion == engineVersion &&
          other.evidenceStatus == evidenceStatus &&
          other.id == id &&
          other.lastSequence == lastSequence &&
          other.ownerId == ownerId &&
          other.projectId == projectId &&
          other.reportedOutcome == reportedOutcome &&
          other.resultJson == resultJson &&
          other.snapshotHash == snapshotHash &&
          other.terminal == terminal &&
          other.versionId == versionId &&
          other.workStatus == workStatus;

  @override
  int get hashCode =>
      artifacts.hashCode +
      attempt.hashCode +
      blueprintJson.hashCode +
      createdAt.hashCode +
      engineRunId.hashCode +
      engineVersion.hashCode +
      evidenceStatus.hashCode +
      id.hashCode +
      lastSequence.hashCode +
      ownerId.hashCode +
      projectId.hashCode +
      (reportedOutcome == null ? 0 : reportedOutcome.hashCode) +
      (resultJson == null ? 0 : resultJson.hashCode) +
      snapshotHash.hashCode +
      terminal.hashCode +
      (versionId == null ? 0 : versionId.hashCode) +
      workStatus.hashCode;

  factory RunResponse.fromJson(Map<String, dynamic> json) =>
      _$RunResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RunResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RunResponseEvidenceStatusEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'missing')
  missing(r'missing'),
  @JsonValue(r'verified')
  verified(r'verified');

  const RunResponseEvidenceStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum RunResponseWorkStatusEnum {
  @JsonValue(r'todo')
  todo(r'todo'),
  @JsonValue(r'in_progress')
  inProgress(r'in_progress'),
  @JsonValue(r'done')
  done(r'done');

  const RunResponseWorkStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
