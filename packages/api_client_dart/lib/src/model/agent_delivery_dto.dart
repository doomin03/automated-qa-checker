//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_delivery_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentDeliveryDto {
  /// Returns a new [AgentDeliveryDto] instance.
  AgentDeliveryDto({
    required this.caseId,

    required this.deliverySequence,

    required this.engineEventJson,
  });

  @JsonKey(name: r'caseId', required: true, includeIfNull: false)
  final String caseId;

  // minimum: 1
  // maximum: 9007199254740991
  @JsonKey(name: r'deliverySequence', required: true, includeIfNull: false)
  final int deliverySequence;

  /// Opaque Engine JSON; exact public Engine schema, UTF-8 byte/depth limits and immutable snapshot validation apply.
  @JsonKey(name: r'engineEventJson', required: true, includeIfNull: false)
  final String engineEventJson;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentDeliveryDto &&
          other.caseId == caseId &&
          other.deliverySequence == deliverySequence &&
          other.engineEventJson == engineEventJson;

  @override
  int get hashCode =>
      caseId.hashCode + deliverySequence.hashCode + engineEventJson.hashCode;

  factory AgentDeliveryDto.fromJson(Map<String, dynamic> json) =>
      _$AgentDeliveryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentDeliveryDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
