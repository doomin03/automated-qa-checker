//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/schedule_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'schedule_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SchedulePage {
  /// Returns a new [SchedulePage] instance.
  SchedulePage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<ScheduleResponse> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchedulePage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory SchedulePage.fromJson(Map<String, dynamic> json) =>
      _$SchedulePageFromJson(json);

  Map<String, dynamic> toJson() => _$SchedulePageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
