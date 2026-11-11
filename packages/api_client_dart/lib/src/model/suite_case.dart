//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'suite_case.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SuiteCase {
  /// Returns a new [SuiteCase] instance.
  SuiteCase({
    required this.caseId,

    required this.sha256,

    required this.versionId,
  });

  @JsonKey(name: r'caseId', required: true, includeIfNull: false)
  final String caseId;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @JsonKey(name: r'versionId', required: true, includeIfNull: false)
  final String versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuiteCase &&
          other.caseId == caseId &&
          other.sha256 == sha256 &&
          other.versionId == versionId;

  @override
  int get hashCode => caseId.hashCode + sha256.hashCode + versionId.hashCode;

  factory SuiteCase.fromJson(Map<String, dynamic> json) =>
      _$SuiteCaseFromJson(json);

  Map<String, dynamic> toJson() => _$SuiteCaseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
