//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'logout_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LogoutResponse {
  /// Returns a new [LogoutResponse] instance.
  LogoutResponse({required this.loggedOut});

  @JsonKey(name: r'loggedOut', required: true, includeIfNull: false)
  final bool loggedOut;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogoutResponse && other.loggedOut == loggedOut;

  @override
  int get hashCode => loggedOut.hashCode;

  factory LogoutResponse.fromJson(Map<String, dynamic> json) =>
      _$LogoutResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LogoutResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
