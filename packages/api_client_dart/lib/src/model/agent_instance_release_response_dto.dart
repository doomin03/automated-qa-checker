//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_instance_release_response_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentInstanceReleaseResponseDto {
  /// Returns a new [AgentInstanceReleaseResponseDto] instance.
  AgentInstanceReleaseResponseDto({
    required this.agentId,

    required this.ownerInstanceId,

    required this.released,

    required this.remainingReceipts,

    required this.reportingInstanceId,
  });

  @JsonKey(name: r'agentId', required: true, includeIfNull: false)
  final String agentId;

  @JsonKey(name: r'ownerInstanceId', required: true, includeIfNull: false)
  final String ownerInstanceId;

  /// False acknowledges this bounded receipt batch but keeps the owner; true only when all owned leases are independently releasable.
  @JsonKey(name: r'released', required: true, includeIfNull: false)
  final bool released;

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(name: r'remainingReceipts', required: true, includeIfNull: false)
  final int remainingReceipts;

  @JsonKey(name: r'reportingInstanceId', required: true, includeIfNull: false)
  final String reportingInstanceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentInstanceReleaseResponseDto &&
          other.agentId == agentId &&
          other.ownerInstanceId == ownerInstanceId &&
          other.released == released &&
          other.remainingReceipts == remainingReceipts &&
          other.reportingInstanceId == reportingInstanceId;

  @override
  int get hashCode =>
      agentId.hashCode +
      ownerInstanceId.hashCode +
      released.hashCode +
      remainingReceipts.hashCode +
      reportingInstanceId.hashCode;

  factory AgentInstanceReleaseResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AgentInstanceReleaseResponseDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AgentInstanceReleaseResponseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
