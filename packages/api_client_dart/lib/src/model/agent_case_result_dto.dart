//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'agent_case_result_dto.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentCaseResultDto {
  /// Returns a new [AgentCaseResultDto] instance.
  AgentCaseResultDto({required this.caseId, required this.resultJson});

  @JsonKey(name: r'caseId', required: true, includeIfNull: false)
  final String caseId;

  /// Opaque Engine JSON; exact public Engine schema, UTF-8 byte/depth limits and immutable snapshot validation apply.
  @JsonKey(name: r'resultJson', required: true, includeIfNull: false)
  final String resultJson;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentCaseResultDto &&
          other.caseId == caseId &&
          other.resultJson == resultJson;

  @override
  int get hashCode => caseId.hashCode + resultJson.hashCode;

  factory AgentCaseResultDto.fromJson(Map<String, dynamic> json) =>
      _$AgentCaseResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AgentCaseResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
