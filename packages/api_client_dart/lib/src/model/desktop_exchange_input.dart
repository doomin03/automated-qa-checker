//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'desktop_exchange_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DesktopExchangeInput {
  /// Returns a new [DesktopExchangeInput] instance.
  DesktopExchangeInput({
    required this.code,

    required this.redirectUri,

    required this.verifier,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'redirectUri', required: true, includeIfNull: false)
  final String redirectUri;

  @JsonKey(name: r'verifier', required: true, includeIfNull: false)
  final String verifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesktopExchangeInput &&
          other.code == code &&
          other.redirectUri == redirectUri &&
          other.verifier == verifier;

  @override
  int get hashCode => code.hashCode + redirectUri.hashCode + verifier.hashCode;

  factory DesktopExchangeInput.fromJson(Map<String, dynamic> json) =>
      _$DesktopExchangeInputFromJson(json);

  Map<String, dynamic> toJson() => _$DesktopExchangeInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
