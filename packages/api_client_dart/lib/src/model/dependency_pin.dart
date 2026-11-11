//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'dependency_pin.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DependencyPin {
  /// Returns a new [DependencyPin] instance.
  DependencyPin({required this.sha256, required this.versionId});

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @JsonKey(name: r'versionId', required: true, includeIfNull: false)
  final String versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DependencyPin &&
          other.sha256 == sha256 &&
          other.versionId == versionId;

  @override
  int get hashCode => sha256.hashCode + versionId.hashCode;

  factory DependencyPin.fromJson(Map<String, dynamic> json) =>
      _$DependencyPinFromJson(json);

  Map<String, dynamic> toJson() => _$DependencyPinToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
