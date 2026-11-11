//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'baseline_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BaselineInput {
  /// Returns a new [BaselineInput] instance.
  BaselineInput({required this.baselineRunId});

  @JsonKey(name: r'baselineRunId', required: true, includeIfNull: false)
  final String baselineRunId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaselineInput && other.baselineRunId == baselineRunId;

  @override
  int get hashCode => baselineRunId.hashCode;

  factory BaselineInput.fromJson(Map<String, dynamic> json) =>
      _$BaselineInputFromJson(json);

  Map<String, dynamic> toJson() => _$BaselineInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
