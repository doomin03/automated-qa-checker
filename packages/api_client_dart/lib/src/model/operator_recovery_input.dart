//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'operator_recovery_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OperatorRecoveryInput {
  /// Returns a new [OperatorRecoveryInput] instance.
  OperatorRecoveryInput({
    required this.externalSessionsStopped,

    required this.fence,

    required this.ownerProcessesStopped,

    required this.reason,

    required this.requestId,

    required this.resourceKey,
  });

  @JsonKey(
    name: r'externalSessionsStopped',
    required: true,
    includeIfNull: false,
  )
  final bool externalSessionsStopped;

  // minimum: 1
  @JsonKey(name: r'fence', required: true, includeIfNull: false)
  final int fence;

  @JsonKey(name: r'ownerProcessesStopped', required: true, includeIfNull: false)
  final bool ownerProcessesStopped;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @JsonKey(name: r'requestId', required: true, includeIfNull: false)
  final String requestId;

  @JsonKey(name: r'resourceKey', required: true, includeIfNull: false)
  final String resourceKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperatorRecoveryInput &&
          other.externalSessionsStopped == externalSessionsStopped &&
          other.fence == fence &&
          other.ownerProcessesStopped == ownerProcessesStopped &&
          other.reason == reason &&
          other.requestId == requestId &&
          other.resourceKey == resourceKey;

  @override
  int get hashCode =>
      externalSessionsStopped.hashCode +
      fence.hashCode +
      ownerProcessesStopped.hashCode +
      reason.hashCode +
      requestId.hashCode +
      resourceKey.hashCode;

  factory OperatorRecoveryInput.fromJson(Map<String, dynamic> json) =>
      _$OperatorRecoveryInputFromJson(json);

  Map<String, dynamic> toJson() => _$OperatorRecoveryInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
