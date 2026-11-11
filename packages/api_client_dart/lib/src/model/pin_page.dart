//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/pin_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pin_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PinPage {
  /// Returns a new [PinPage] instance.
  PinPage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<PinResponse> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PinPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory PinPage.fromJson(Map<String, dynamic> json) =>
      _$PinPageFromJson(json);

  Map<String, dynamic> toJson() => _$PinPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
