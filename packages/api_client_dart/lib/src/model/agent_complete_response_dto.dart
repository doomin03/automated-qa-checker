//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_artifact_receipt_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_complete_response_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentCompleteResponseDto {
  /// Returns a new [AgentCompleteResponseDto] instance.
  AgentCompleteResponseDto({
    required this.accepted,

    required this.acceptedThrough,

    required this.artifacts,

    required this.cleanupState,

    required this.completionReceipt,

    required this.deliveryClosed,

    required this.evidenceStatus,

    required this.fence,

    required this.leaseId,

    required this.quarantined,
  });

  @JsonKey(name: r'accepted', required: true, includeIfNull: false)
  final bool accepted;

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(name: r'acceptedThrough', required: true, includeIfNull: false)
  final int acceptedThrough;

  @JsonKey(name: r'artifacts', required: true, includeIfNull: false)
  final List<AgentArtifactReceiptDto> artifacts;

  @JsonKey(name: r'cleanupState', required: true, includeIfNull: false)
  final AgentCompleteResponseDtoCleanupStateEnum cleanupState;

  @JsonKey(name: r'completionReceipt', required: true, includeIfNull: true)
  final String? completionReceipt;

  @JsonKey(name: r'deliveryClosed', required: true, includeIfNull: false)
  final bool deliveryClosed;

  @JsonKey(name: r'evidenceStatus', required: true, includeIfNull: false)
  final AgentCompleteResponseDtoEvidenceStatusEnum evidenceStatus;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'fence', required: true, includeIfNull: false)
  final int fence;

  @JsonKey(name: r'leaseId', required: true, includeIfNull: false)
  final String leaseId;

  @JsonKey(name: r'quarantined', required: true, includeIfNull: false)
  final bool quarantined;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentCompleteResponseDto &&
          other.accepted == accepted &&
          other.acceptedThrough == acceptedThrough &&
          other.artifacts == artifacts &&
          other.cleanupState == cleanupState &&
          other.completionReceipt == completionReceipt &&
          other.deliveryClosed == deliveryClosed &&
          other.evidenceStatus == evidenceStatus &&
          other.fence == fence &&
          other.leaseId == leaseId &&
          other.quarantined == quarantined;

  @override
  int get hashCode =>
      accepted.hashCode +
      acceptedThrough.hashCode +
      artifacts.hashCode +
      cleanupState.hashCode +
      (completionReceipt == null ? 0 : completionReceipt.hashCode) +
      deliveryClosed.hashCode +
      evidenceStatus.hashCode +
      fence.hashCode +
      leaseId.hashCode +
      quarantined.hashCode;

  factory AgentCompleteResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AgentCompleteResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentCompleteResponseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentCompleteResponseDtoCleanupStateEnum {
  @JsonValue(r'confirmed')
  confirmed(r'confirmed'),
  @JsonValue(r'unknown')
  unknown(r'unknown'),
  @JsonValue(r'failed')
  failed(r'failed');

  const AgentCompleteResponseDtoCleanupStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum AgentCompleteResponseDtoEvidenceStatusEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'missing')
  missing(r'missing'),
  @JsonValue(r'verified')
  verified(r'verified');

  const AgentCompleteResponseDtoEvidenceStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
