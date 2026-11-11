//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'execution_case_run.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExecutionCaseRun {
  /// Returns a new [ExecutionCaseRun] instance.
  ExecutionCaseRun({required this.caseId, required this.runId});

  @JsonKey(name: r'caseId', required: true, includeIfNull: false)
  final String caseId;

  @JsonKey(name: r'runId', required: true, includeIfNull: false)
  final String runId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionCaseRun &&
          other.caseId == caseId &&
          other.runId == runId;

  @override
  int get hashCode => caseId.hashCode + runId.hashCode;

  factory ExecutionCaseRun.fromJson(Map<String, dynamic> json) =>
      _$ExecutionCaseRunFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutionCaseRunToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
