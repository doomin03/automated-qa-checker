//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/managed_user_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'managed_user_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagedUserPage {
  /// Returns a new [ManagedUserPage] instance.
  ManagedUserPage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<ManagedUserResponse> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedUserPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory ManagedUserPage.fromJson(Map<String, dynamic> json) =>
      _$ManagedUserPageFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedUserPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
