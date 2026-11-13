//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/audit_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'audit_page.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuditPage {
  /// Returns a new [AuditPage] instance.
  AuditPage({required this.items, required this.nextCursor});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<AuditResponse> items;

  @JsonKey(name: r'nextCursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditPage &&
          other.items == items &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      items.hashCode + (nextCursor == null ? 0 : nextCursor.hashCode);

  factory AuditPage.fromJson(Map<String, dynamic> json) =>
      _$AuditPageFromJson(json);

  Map<String, dynamic> toJson() => _$AuditPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
