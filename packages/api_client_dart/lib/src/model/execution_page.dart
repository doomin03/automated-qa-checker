//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/execution_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'execution_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExecutionPage {
  /// Returns a new [ExecutionPage] instance.
  ExecutionPage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<ExecutionResponse> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory ExecutionPage.fromJson(Map<String, dynamic> json) =>
      _$ExecutionPageFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutionPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
