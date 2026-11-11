//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_known_lease_terminal_result_hashes_item_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_known_lease_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentKnownLeaseDto {
  /// Returns a new [AgentKnownLeaseDto] instance.
  AgentKnownLeaseDto({
    required this.cleanupState,

    required this.fence,

    required this.lastAcknowledgedSequence,

    required this.leaseId,

    required this.ownerInstanceId,

    required this.terminalResultHashes,
  });

  @JsonKey(name: r'cleanupState', required: true, includeIfNull: false)
  final AgentKnownLeaseDtoCleanupStateEnum cleanupState;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'fence', required: true, includeIfNull: false)
  final int fence;

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(
    name: r'lastAcknowledgedSequence',
    required: true,
    includeIfNull: false,
  )
  final int lastAcknowledgedSequence;

  @JsonKey(name: r'leaseId', required: true, includeIfNull: false)
  final String leaseId;

  @JsonKey(name: r'ownerInstanceId', required: true, includeIfNull: false)
  final String ownerInstanceId;

  @JsonKey(name: r'terminalResultHashes', required: true, includeIfNull: false)
  final List<AgentKnownLeaseTerminalResultHashesItemDto> terminalResultHashes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentKnownLeaseDto &&
          other.cleanupState == cleanupState &&
          other.fence == fence &&
          other.lastAcknowledgedSequence == lastAcknowledgedSequence &&
          other.leaseId == leaseId &&
          other.ownerInstanceId == ownerInstanceId &&
          other.terminalResultHashes == terminalResultHashes;

  @override
  int get hashCode =>
      cleanupState.hashCode +
      fence.hashCode +
      lastAcknowledgedSequence.hashCode +
      leaseId.hashCode +
      ownerInstanceId.hashCode +
      terminalResultHashes.hashCode;

  factory AgentKnownLeaseDto.fromJson(Map<String, dynamic> json) =>
      _$AgentKnownLeaseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentKnownLeaseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentKnownLeaseDtoCleanupStateEnum {
  @JsonValue(r'confirmed')
  confirmed(r'confirmed'),
  @JsonValue(r'unknown')
  unknown(r'unknown'),
  @JsonValue(r'failed')
  failed(r'failed');

  const AgentKnownLeaseDtoCleanupStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
