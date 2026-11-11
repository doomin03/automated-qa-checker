//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/draft_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'draft_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DraftPage {
  /// Returns a new [DraftPage] instance.
  DraftPage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<DraftResponse> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory DraftPage.fromJson(Map<String, dynamic> json) =>
      _$DraftPageFromJson(json);

  Map<String, dynamic> toJson() => _$DraftPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
