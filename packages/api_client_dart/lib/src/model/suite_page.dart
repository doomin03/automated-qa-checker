//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/suite_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suite_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SuitePage {
  /// Returns a new [SuitePage] instance.
  SuitePage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<SuiteResponse> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuitePage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory SuitePage.fromJson(Map<String, dynamic> json) =>
      _$SuitePageFromJson(json);

  Map<String, dynamic> toJson() => _$SuitePageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
