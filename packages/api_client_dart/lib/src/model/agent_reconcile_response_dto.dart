//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/agent_reconcile_decision_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_reconcile_response_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentReconcileResponseDto {
  /// Returns a new [AgentReconcileResponseDto] instance.
  AgentReconcileResponseDto({
    required this.agentId,

    required this.decisions,

    required this.hasMore,

    required this.instanceId,

    required this.instanceState,

    required this.nextCursor,
  });

  @JsonKey(name: r'agentId', required: true, includeIfNull: false)
  final String agentId;

  @JsonKey(name: r'decisions', required: true, includeIfNull: false)
  final List<AgentReconcileDecisionDto> decisions;

  @JsonKey(name: r'hasMore', required: true, includeIfNull: false)
  final bool hasMore;

  @JsonKey(name: r'instanceId', required: true, includeIfNull: false)
  final String instanceId;

  @JsonKey(name: r'instanceState', required: true, includeIfNull: false)
  final AgentReconcileResponseDtoInstanceStateEnum instanceState;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentReconcileResponseDto &&
          other.agentId == agentId &&
          other.decisions == decisions &&
          other.hasMore == hasMore &&
          other.instanceId == instanceId &&
          other.instanceState == instanceState &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      agentId.hashCode +
      decisions.hashCode +
      hasMore.hashCode +
      instanceId.hashCode +
      instanceState.hashCode +
      (nextCursor == null ? 0 : nextCursor.hashCode);

  factory AgentReconcileResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AgentReconcileResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentReconcileResponseDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AgentReconcileResponseDtoInstanceStateEnum {
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'observer')
  observer(r'observer'),
  @JsonValue(r'quarantined')
  quarantined(r'quarantined'),
  @JsonValue(r'released')
  released(r'released');

  const AgentReconcileResponseDtoInstanceStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
