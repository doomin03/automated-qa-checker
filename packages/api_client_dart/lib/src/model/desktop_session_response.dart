//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'desktop_session_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DesktopSessionResponse {
  /// Returns a new [DesktopSessionResponse] instance.
  DesktopSessionResponse({required this.expiresAt, required this.token});

  @JsonKey(name: r'expiresAt', required: true, includeIfNull: false)
  final DateTime expiresAt;

  @JsonKey(name: r'token', required: true, includeIfNull: false)
  final String token;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesktopSessionResponse &&
          other.expiresAt == expiresAt &&
          other.token == token;

  @override
  int get hashCode => expiresAt.hashCode + token.hashCode;

  factory DesktopSessionResponse.fromJson(Map<String, dynamic> json) =>
      _$DesktopSessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DesktopSessionResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
