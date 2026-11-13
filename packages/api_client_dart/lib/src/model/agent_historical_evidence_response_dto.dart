//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_historical_evidence_response_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentHistoricalEvidenceResponseDto {
  /// Returns a new [AgentHistoricalEvidenceResponseDto] instance.
  AgentHistoricalEvidenceResponseDto({
    required this.disposition,

    required this.executionPermission,

    required this.leaseId,

    required this.receiptId,

    required this.recorded,

    required this.resourceReleased,
  });

  @JsonKey(name: r'disposition', required: true, includeIfNull: false)
  final AgentHistoricalEvidenceResponseDtoDispositionEnum disposition;

  @JsonKey(name: r'executionPermission', required: true, includeIfNull: false)
  final bool executionPermission;

  @JsonKey(name: r'leaseId', required: true, includeIfNull: false)
  final String leaseId;

  @JsonKey(name: r'receiptId', required: true, includeIfNull: false)
  final String receiptId;

  @JsonKey(name: r'recorded', required: true, includeIfNull: false)
  final bool recorded;

  @JsonKey(name: r'resourceReleased', required: true, includeIfNull: false)
  final bool resourceReleased;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentHistoricalEvidenceResponseDto &&
          other.disposition == disposition &&
          other.executionPermission == executionPermission &&
          other.leaseId == leaseId &&
          other.receiptId == receiptId &&
          other.recorded == recorded &&
          other.resourceReleased == resourceReleased;

  @override
  int get hashCode =>
      disposition.hashCode +
      executionPermission.hashCode +
      leaseId.hashCode +
      receiptId.hashCode +
      recorded.hashCode +
      resourceReleased.hashCode;

  factory AgentHistoricalEvidenceResponseDto.fromJson(
    Map<String, dynamic> json,
  ) => _$AgentHistoricalEvidenceResponseDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AgentHistoricalEvidenceResponseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentHistoricalEvidenceResponseDtoDispositionEnum {
  @JsonValue(r'historical_quarantine')
  historicalQuarantine(r'historical_quarantine');

  const AgentHistoricalEvidenceResponseDtoDispositionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
