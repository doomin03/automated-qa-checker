//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_execution_policy_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'schedule_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ScheduleResponse {
  /// Returns a new [ScheduleResponse] instance.
  ScheduleResponse({
    required this.createdAt,

    required this.createdBy,

    required this.enabled,

    required this.executionPolicy,

    required this.id,

    required this.lastScannedAt,

    required this.latenessSeconds,

    required this.localTime,

    required this.projectId,

    required this.sha256,

    required this.suiteVersionId,

    required this.timezone,

    required this.versionId,

    required this.weekdays,
  });

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'createdBy', required: true, includeIfNull: false)
  final String createdBy;

  @JsonKey(name: r'enabled', required: true, includeIfNull: false)
  final bool enabled;

  @JsonKey(name: r'executionPolicy', required: true, includeIfNull: false)
  final AgentExecutionPolicyDto executionPolicy;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'lastScannedAt', required: true, includeIfNull: false)
  final DateTime lastScannedAt;

  // minimum: 1
  // maximum: 86400
  @JsonKey(name: r'latenessSeconds', required: true, includeIfNull: false)
  final int latenessSeconds;

  @JsonKey(name: r'localTime', required: true, includeIfNull: false)
  final String localTime;

  @JsonKey(name: r'projectId', required: true, includeIfNull: false)
  final String projectId;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @JsonKey(name: r'suiteVersionId', required: true, includeIfNull: true)
  final String? suiteVersionId;

  @JsonKey(name: r'timezone', required: true, includeIfNull: false)
  final String timezone;

  @JsonKey(name: r'versionId', required: true, includeIfNull: true)
  final String? versionId;

  @JsonKey(name: r'weekdays', required: true, includeIfNull: false)
  final List<num> weekdays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleResponse &&
          other.createdAt == createdAt &&
          other.createdBy == createdBy &&
          other.enabled == enabled &&
          other.executionPolicy == executionPolicy &&
          other.id == id &&
          other.lastScannedAt == lastScannedAt &&
          other.latenessSeconds == latenessSeconds &&
          other.localTime == localTime &&
          other.projectId == projectId &&
          other.sha256 == sha256 &&
          other.suiteVersionId == suiteVersionId &&
          other.timezone == timezone &&
          other.versionId == versionId &&
          other.weekdays == weekdays;

  @override
  int get hashCode =>
      createdAt.hashCode +
      createdBy.hashCode +
      enabled.hashCode +
      executionPolicy.hashCode +
      id.hashCode +
      lastScannedAt.hashCode +
      latenessSeconds.hashCode +
      localTime.hashCode +
      projectId.hashCode +
      sha256.hashCode +
      (suiteVersionId == null ? 0 : suiteVersionId.hashCode) +
      timezone.hashCode +
      (versionId == null ? 0 : versionId.hashCode) +
      weekdays.hashCode;

  factory ScheduleResponse.fromJson(Map<String, dynamic> json) =>
      _$ScheduleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
