//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/version_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'version_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VersionPage {
  /// Returns a new [VersionPage] instance.
  VersionPage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<VersionResponse> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersionPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory VersionPage.fromJson(Map<String, dynamic> json) =>
      _$VersionPageFromJson(json);

  Map<String, dynamic> toJson() => _$VersionPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
