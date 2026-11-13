//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'pin_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PinResponse {
  /// Returns a new [PinResponse] instance.
  PinResponse({
    required this.packageId,

    required this.sha256,

    required this.versionId,
  });

  @JsonKey(name: r'packageId', required: true, includeIfNull: false)
  final String packageId;

  @JsonKey(name: r'sha256', required: true, includeIfNull: false)
  final String sha256;

  @JsonKey(name: r'versionId', required: true, includeIfNull: false)
  final String versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PinResponse &&
          other.packageId == packageId &&
          other.sha256 == sha256 &&
          other.versionId == versionId;

  @override
  int get hashCode => packageId.hashCode + sha256.hashCode + versionId.hashCode;

  factory PinResponse.fromJson(Map<String, dynamic> json) =>
      _$PinResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PinResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
