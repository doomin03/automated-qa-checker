//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'managed_user_create.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagedUserCreate {
  /// Returns a new [ManagedUserCreate] instance.
  ManagedUserCreate({
    required this.displayName,

    required this.role,

    required this.userId,
  });

  @JsonKey(name: r'displayName', required: true, includeIfNull: true)
  final String? displayName;

  @JsonKey(name: r'role', required: true, includeIfNull: false)
  final ManagedUserCreateRoleEnum role;

  @JsonKey(name: r'userId', required: true, includeIfNull: false)
  final String userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedUserCreate &&
          other.displayName == displayName &&
          other.role == role &&
          other.userId == userId;

  @override
  int get hashCode =>
      (displayName == null ? 0 : displayName.hashCode) +
      role.hashCode +
      userId.hashCode;

  factory ManagedUserCreate.fromJson(Map<String, dynamic> json) =>
      _$ManagedUserCreateFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedUserCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ManagedUserCreateRoleEnum {
  @JsonValue(r'viewer')
  viewer(r'viewer'),
  @JsonValue(r'qa_tester')
  qaTester(r'qa_tester'),
  @JsonValue(r'qa_editor')
  qaEditor(r'qa_editor'),
  @JsonValue(r'qa_manager')
  qaManager(r'qa_manager');

  const ManagedUserCreateRoleEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
