//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'audit_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuditResponse {
  /// Returns a new [AuditResponse] instance.
  AuditResponse({
    required this.action,

    required this.actorId,

    required this.createdAt,

    required this.id,

    required this.resourceId,
  });

  @JsonKey(name: r'action', required: true, includeIfNull: false)
  final String action;

  @JsonKey(name: r'actorId', required: true, includeIfNull: false)
  final String actorId;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'resourceId', required: true, includeIfNull: false)
  final String resourceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditResponse &&
          other.action == action &&
          other.actorId == actorId &&
          other.createdAt == createdAt &&
          other.id == id &&
          other.resourceId == resourceId;

  @override
  int get hashCode =>
      action.hashCode +
      actorId.hashCode +
      createdAt.hashCode +
      id.hashCode +
      resourceId.hashCode;

  factory AuditResponse.fromJson(Map<String, dynamic> json) =>
      _$AuditResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuditResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
