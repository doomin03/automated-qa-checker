//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'publish_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublishInput {
  /// Returns a new [PublishInput] instance.
  PublishInput({required this.version});

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final String version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublishInput && other.version == version;

  @override
  int get hashCode => version.hashCode;

  factory PublishInput.fromJson(Map<String, dynamic> json) =>
      _$PublishInputFromJson(json);

  Map<String, dynamic> toJson() => _$PublishInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
