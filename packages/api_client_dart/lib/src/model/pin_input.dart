//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'pin_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PinInput {
  /// Returns a new [PinInput] instance.
  PinInput({required this.sha256, required this.versionId});

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @JsonKey(name: r'versionId', required: true, includeIfNull: false)
  final String versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PinInput &&
          other.sha256 == sha256 &&
          other.versionId == versionId;

  @override
  int get hashCode => sha256.hashCode + versionId.hashCode;

  factory PinInput.fromJson(Map<String, dynamic> json) =>
      _$PinInputFromJson(json);

  Map<String, dynamic> toJson() => _$PinInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
