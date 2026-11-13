//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/run_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunPage {
  /// Returns a new [RunPage] instance.
  RunPage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<RunResponse> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory RunPage.fromJson(Map<String, dynamic> json) =>
      _$RunPageFromJson(json);

  Map<String, dynamic> toJson() => _$RunPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
