//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/notification_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NotificationPage {
  /// Returns a new [NotificationPage] instance.
  NotificationPage({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<NotificationResponse> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPage && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      _$NotificationPageFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
