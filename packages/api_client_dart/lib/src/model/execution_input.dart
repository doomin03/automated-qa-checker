//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_execution_policy_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'execution_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExecutionInput {
  /// Returns a new [ExecutionInput] instance.
  ExecutionInput({
    required this.executionPolicy,

    required this.sha256,

    required this.suiteVersionId,

    required this.versionId,
  });

  @JsonKey(name: r'executionPolicy', required: true, includeIfNull: false)
  final AgentExecutionPolicyDto executionPolicy;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @JsonKey(name: r'suiteVersionId', required: true, includeIfNull: true)
  final String? suiteVersionId;

  @JsonKey(name: r'versionId', required: true, includeIfNull: true)
  final String? versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionInput &&
          other.executionPolicy == executionPolicy &&
          other.sha256 == sha256 &&
          other.suiteVersionId == suiteVersionId &&
          other.versionId == versionId;

  @override
  int get hashCode =>
      executionPolicy.hashCode +
      sha256.hashCode +
      (suiteVersionId == null ? 0 : suiteVersionId.hashCode) +
      (versionId == null ? 0 : versionId.hashCode);

  factory ExecutionInput.fromJson(Map<String, dynamic> json) =>
      _$ExecutionInputFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutionInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
