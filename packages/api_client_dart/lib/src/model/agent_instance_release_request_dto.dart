//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_instance_release_request_receipts_item_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_instance_release_request_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentInstanceReleaseRequestDto {
  /// Returns a new [AgentInstanceReleaseRequestDto] instance.
  AgentInstanceReleaseRequestDto({
    required this.agentId,

    required this.ownerInstanceId,

    required this.ownerStopped,

    required this.receipts,

    required this.reportingInstanceId,
  });

  @JsonKey(name: r'agentId', required: true, includeIfNull: false)
  final String agentId;

  @JsonKey(name: r'ownerInstanceId', required: true, includeIfNull: false)
  final String ownerInstanceId;

  @JsonKey(name: r'ownerStopped', required: true, includeIfNull: false)
  final bool ownerStopped;

  @JsonKey(name: r'receipts', required: true, includeIfNull: false)
  final List<AgentInstanceReleaseRequestReceiptsItemDto> receipts;

  @JsonKey(name: r'reportingInstanceId', required: true, includeIfNull: false)
  final String reportingInstanceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentInstanceReleaseRequestDto &&
          other.agentId == agentId &&
          other.ownerInstanceId == ownerInstanceId &&
          other.ownerStopped == ownerStopped &&
          other.receipts == receipts &&
          other.reportingInstanceId == reportingInstanceId;

  @override
  int get hashCode =>
      agentId.hashCode +
      ownerInstanceId.hashCode +
      ownerStopped.hashCode +
      receipts.hashCode +
      reportingInstanceId.hashCode;

  factory AgentInstanceReleaseRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AgentInstanceReleaseRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentInstanceReleaseRequestDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
