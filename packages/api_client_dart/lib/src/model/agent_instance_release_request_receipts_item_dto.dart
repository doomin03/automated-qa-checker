//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_instance_release_request_receipts_item_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentInstanceReleaseRequestReceiptsItemDto {
  /// Returns a new [AgentInstanceReleaseRequestReceiptsItemDto] instance.
  AgentInstanceReleaseRequestReceiptsItemDto({
    required this.acceptedThrough,

    required this.completionReceipt,

    required this.leaseId,
  });

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(name: r'acceptedThrough', required: true, includeIfNull: false)
  final int acceptedThrough;

  @JsonKey(name: r'completionReceipt', required: true, includeIfNull: false)
  final String completionReceipt;

  @JsonKey(name: r'leaseId', required: true, includeIfNull: false)
  final String leaseId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentInstanceReleaseRequestReceiptsItemDto &&
          other.acceptedThrough == acceptedThrough &&
          other.completionReceipt == completionReceipt &&
          other.leaseId == leaseId;

  @override
  int get hashCode =>
      acceptedThrough.hashCode + completionReceipt.hashCode + leaseId.hashCode;

  factory AgentInstanceReleaseRequestReceiptsItemDto.fromJson(
    Map<String, dynamic> json,
  ) => _$AgentInstanceReleaseRequestReceiptsItemDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AgentInstanceReleaseRequestReceiptsItemDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
