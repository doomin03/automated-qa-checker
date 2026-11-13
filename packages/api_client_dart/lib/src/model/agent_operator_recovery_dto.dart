//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_operator_recovery_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentOperatorRecoveryDto {
  /// Returns a new [AgentOperatorRecoveryDto] instance.
  AgentOperatorRecoveryDto({
    required this.confirmedAt,

    required this.id,

    required this.newFence,

    required this.priorFence,
  });

  @JsonKey(name: r'confirmedAt', required: true, includeIfNull: false)
  final DateTime confirmedAt;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  // minimum: 2
  // maximum: 9007199254740991
  @JsonKey(name: r'newFence', required: true, includeIfNull: false)
  final int newFence;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'priorFence', required: true, includeIfNull: false)
  final int priorFence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentOperatorRecoveryDto &&
          other.confirmedAt == confirmedAt &&
          other.id == id &&
          other.newFence == newFence &&
          other.priorFence == priorFence;

  @override
  int get hashCode =>
      confirmedAt.hashCode +
      id.hashCode +
      newFence.hashCode +
      priorFence.hashCode;

  factory AgentOperatorRecoveryDto.fromJson(Map<String, dynamic> json) =>
      _$AgentOperatorRecoveryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentOperatorRecoveryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
