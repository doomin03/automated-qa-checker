//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/suite_case.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suite_draft_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SuiteDraftInput {
  /// Returns a new [SuiteDraftInput] instance.
  SuiteDraftInput({
    required this.cases,

    required this.packageId,

    required this.stopOnFailure,

    required this.title,
  });

  @JsonKey(name: r'cases', required: true, includeIfNull: false)
  final List<SuiteCase> cases;

  @JsonKey(name: r'packageId', required: true, includeIfNull: false)
  final String packageId;

  @JsonKey(name: r'stopOnFailure', required: true, includeIfNull: false)
  final bool stopOnFailure;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuiteDraftInput &&
          other.cases == cases &&
          other.packageId == packageId &&
          other.stopOnFailure == stopOnFailure &&
          other.title == title;

  @override
  int get hashCode =>
      cases.hashCode +
      packageId.hashCode +
      stopOnFailure.hashCode +
      title.hashCode;

  factory SuiteDraftInput.fromJson(Map<String, dynamic> json) =>
      _$SuiteDraftInputFromJson(json);

  Map<String, dynamic> toJson() => _$SuiteDraftInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
