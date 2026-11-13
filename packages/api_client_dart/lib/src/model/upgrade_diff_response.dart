//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/version_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'upgrade_diff_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpgradeDiffResponse {
  /// Returns a new [UpgradeDiffResponse] instance.
  UpgradeDiffResponse({
    required this.dependenciesChanged,

    required this.from,

    required this.to,

    required this.xmlChanged,
  });

  @JsonKey(name: r'dependenciesChanged', required: true, includeIfNull: false)
  final bool dependenciesChanged;

  @JsonKey(name: r'from', required: true, includeIfNull: false)
  final VersionResponse from;

  @JsonKey(name: r'to', required: true, includeIfNull: false)
  final VersionResponse to;

  @JsonKey(name: r'xmlChanged', required: true, includeIfNull: false)
  final bool xmlChanged;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpgradeDiffResponse &&
          other.dependenciesChanged == dependenciesChanged &&
          other.from == from &&
          other.to == to &&
          other.xmlChanged == xmlChanged;

  @override
  int get hashCode =>
      dependenciesChanged.hashCode +
      from.hashCode +
      to.hashCode +
      xmlChanged.hashCode;

  factory UpgradeDiffResponse.fromJson(Map<String, dynamic> json) =>
      _$UpgradeDiffResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UpgradeDiffResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
