//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/suite_draft_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suite_draft_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SuiteDraftPage {
  /// Returns a new [SuiteDraftPage] instance.
  SuiteDraftPage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<SuiteDraftResponse> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuiteDraftPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory SuiteDraftPage.fromJson(Map<String, dynamic> json) =>
      _$SuiteDraftPageFromJson(json);

  Map<String, dynamic> toJson() => _$SuiteDraftPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
