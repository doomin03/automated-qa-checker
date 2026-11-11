//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_lease_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_claim_response_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentClaimResponseDto {
  /// Returns a new [AgentClaimResponseDto] instance.
  AgentClaimResponseDto({required this.claimRequestId, required this.lease});

  @JsonKey(name: r'claimRequestId', required: true, includeIfNull: false)
  final String claimRequestId;

  @JsonKey(name: r'lease', required: true, includeIfNull: false)
  final AgentLeaseDto lease;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentClaimResponseDto &&
          other.claimRequestId == claimRequestId &&
          other.lease == lease;

  @override
  int get hashCode => claimRequestId.hashCode + lease.hashCode;

  factory AgentClaimResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AgentClaimResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentClaimResponseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
