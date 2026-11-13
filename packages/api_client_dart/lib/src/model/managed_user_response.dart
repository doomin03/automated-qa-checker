//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'managed_user_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagedUserResponse {
  /// Returns a new [ManagedUserResponse] instance.
  ManagedUserResponse({
    required this.active,

    required this.displayName,

    required this.membershipRevision,

    required this.role,

    required this.userId,

    required this.userRevision,
  });

  @JsonKey(name: r'active', required: true, includeIfNull: false)
  final bool active;

  @JsonKey(name: r'displayName', required: true, includeIfNull: true)
  final String? displayName;

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(name: r'membershipRevision', required: true, includeIfNull: false)
  final int membershipRevision;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final ManagedUserResponseRoleEnum role;

  @JsonKey(name: r'userId', required: true, includeIfNull: false)
  final String userId;

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(name: r'userRevision', required: true, includeIfNull: false)
  final int userRevision;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedUserResponse &&
          other.active == active &&
          other.displayName == displayName &&
          other.membershipRevision == membershipRevision &&
          other.role == role &&
          other.userId == userId &&
          other.userRevision == userRevision;

  @override
  int get hashCode =>
      active.hashCode +
      (displayName == null ? 0 : displayName.hashCode) +
      membershipRevision.hashCode +
      role.hashCode +
      userId.hashCode +
      userRevision.hashCode;

  factory ManagedUserResponse.fromJson(Map<String, dynamic> json) =>
      _$ManagedUserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedUserResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ManagedUserResponseRoleEnum {
  @JsonValue(r'viewer')
  viewer(r'viewer'),
  @JsonValue(r'qa_tester')
  qaTester(r'qa_tester'),
  @JsonValue(r'qa_editor')
  qaEditor(r'qa_editor'),
  @JsonValue(r'qa_manager')
  qaManager(r'qa_manager'),
  @JsonValue(r'system_admin')
  systemAdmin(r'system_admin');

  const ManagedUserResponseRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
