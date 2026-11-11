//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_operator_recovery_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'operator_recovery_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OperatorRecoveryResponse {
  /// Returns a new [OperatorRecoveryResponse] instance.
  OperatorRecoveryResponse({
    required this.executionId,

    required this.leaseId,

    required this.recovery,

    required this.resourceKey,
  });

  @JsonKey(name: r'executionId', required: true, includeIfNull: false)
  final String executionId;

  @JsonKey(name: r'leaseId', required: true, includeIfNull: false)
  final String leaseId;

  @JsonKey(name: r'recovery', required: true, includeIfNull: false)
  final AgentOperatorRecoveryDto recovery;

  @JsonKey(name: r'resourceKey', required: true, includeIfNull: false)
  final String resourceKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperatorRecoveryResponse &&
          other.executionId == executionId &&
          other.leaseId == leaseId &&
          other.recovery == recovery &&
          other.resourceKey == resourceKey;

  @override
  int get hashCode =>
      executionId.hashCode +
      leaseId.hashCode +
      recovery.hashCode +
      resourceKey.hashCode;

  factory OperatorRecoveryResponse.fromJson(Map<String, dynamic> json) =>
      _$OperatorRecoveryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OperatorRecoveryResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
