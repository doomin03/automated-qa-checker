//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_known_lease_terminal_result_hashes_item_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentKnownLeaseTerminalResultHashesItemDto {
  /// Returns a new [AgentKnownLeaseTerminalResultHashesItemDto] instance.
  AgentKnownLeaseTerminalResultHashesItemDto({
    required this.caseId,

    required this.sha256,
  });

  @JsonKey(name: r'caseId', required: true, includeIfNull: false)
  final String caseId;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentKnownLeaseTerminalResultHashesItemDto &&
          other.caseId == caseId &&
          other.sha256 == sha256;

  @override
  int get hashCode => caseId.hashCode + sha256.hashCode;

  factory AgentKnownLeaseTerminalResultHashesItemDto.fromJson(
    Map<String, dynamic> json,
  ) => _$AgentKnownLeaseTerminalResultHashesItemDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AgentKnownLeaseTerminalResultHashesItemDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
