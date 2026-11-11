//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_execution_policy_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'schedule_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ScheduleInput {
  /// Returns a new [ScheduleInput] instance.
  ScheduleInput({
    required this.enabled,

    required this.executionPolicy,

    required this.latenessSeconds,

    required this.localTime,

    required this.sha256,

    required this.suiteVersionId,

    required this.timezone,

    required this.versionId,

    required this.weekdays,
  });

  @JsonKey(name: r'enabled', required: true, includeIfNull: false)
  final bool enabled;

  @JsonKey(name: r'executionPolicy', required: true, includeIfNull: false)
  final AgentExecutionPolicyDto executionPolicy;

  // minimum: 1
  // maximum: 86400
  @JsonKey(name: r'latenessSeconds', required: true, includeIfNull: false)
  final int latenessSeconds;

  @JsonKey(name: r'localTime', required: true, includeIfNull: false)
  final String localTime;

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
      other is ScheduleInput &&
          other.enabled == enabled &&
          other.executionPolicy == executionPolicy &&
          other.latenessSeconds == latenessSeconds &&
          other.localTime == localTime &&
          other.sha256 == sha256 &&
          other.suiteVersionId == suiteVersionId &&
          other.timezone == timezone &&
          other.versionId == versionId &&
          other.weekdays == weekdays;

  @override
  int get hashCode =>
      enabled.hashCode +
      executionPolicy.hashCode +
      latenessSeconds.hashCode +
      localTime.hashCode +
      sha256.hashCode +
      (suiteVersionId == null ? 0 : suiteVersionId.hashCode) +
      timezone.hashCode +
      (versionId == null ? 0 : versionId.hashCode) +
      weekdays.hashCode;

  factory ScheduleInput.fromJson(Map<String, dynamic> json) =>
      _$ScheduleInputFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
