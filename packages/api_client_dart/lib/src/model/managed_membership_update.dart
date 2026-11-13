//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'managed_membership_update.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagedMembershipUpdate {
  /// Returns a new [ManagedMembershipUpdate] instance.
  ManagedMembershipUpdate({
    required this.membershipRevision,

    required this.role,
  });

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(name: r'membershipRevision', required: true, includeIfNull: false)
  final int membershipRevision;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final ManagedMembershipUpdateRoleEnum role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedMembershipUpdate &&
          other.membershipRevision == membershipRevision &&
          other.role == role;

  @override
  int get hashCode => membershipRevision.hashCode + role.hashCode;

  factory ManagedMembershipUpdate.fromJson(Map<String, dynamic> json) =>
      _$ManagedMembershipUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedMembershipUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ManagedMembershipUpdateRoleEnum {
  @JsonValue(r'viewer')
  viewer(r'viewer'),
  @JsonValue(r'qa_tester')
  qaTester(r'qa_tester'),
  @JsonValue(r'qa_editor')
  qaEditor(r'qa_editor'),
  @JsonValue(r'qa_manager')
  qaManager(r'qa_manager');

  const ManagedMembershipUpdateRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
