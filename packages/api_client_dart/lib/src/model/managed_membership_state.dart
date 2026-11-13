//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'managed_membership_state.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagedMembershipState {
  /// Returns a new [ManagedMembershipState] instance.
  ManagedMembershipState({
    required this.membershipRevision,

    required this.role,

    required this.userId,
  });

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(name: r'membershipRevision', required: true, includeIfNull: false)
  final int membershipRevision;

  @JsonKey(name: r'role', required: true, includeIfNull: true)
  final ManagedMembershipStateRoleEnum? role;

  @JsonKey(name: r'userId', required: true, includeIfNull: false)
  final String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedMembershipState &&
          other.membershipRevision == membershipRevision &&
          other.role == role &&
          other.userId == userId;

  @override
  int get hashCode =>
      membershipRevision.hashCode +
      (role == null ? 0 : role.hashCode) +
      userId.hashCode;

  factory ManagedMembershipState.fromJson(Map<String, dynamic> json) =>
      _$ManagedMembershipStateFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedMembershipStateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ManagedMembershipStateRoleEnum {
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

  const ManagedMembershipStateRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
