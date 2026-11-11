//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'result_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ResultInput {
  /// Returns a new [ResultInput] instance.
  ResultInput({required this.resultJson});

  /// Opaque Engine qa.result/v1 JSON, immutable after acceptance.
  @JsonKey(name: r'resultJson', required: true, includeIfNull: false)
  final String resultJson;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultInput && other.resultJson == resultJson;

  @override
  int get hashCode => resultJson.hashCode;

  factory ResultInput.fromJson(Map<String, dynamic> json) =>
      _$ResultInputFromJson(json);

  Map<String, dynamic> toJson() => _$ResultInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
