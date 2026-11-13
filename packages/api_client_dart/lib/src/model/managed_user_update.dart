//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'managed_user_update.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ManagedUserUpdate {
  /// Returns a new [ManagedUserUpdate] instance.
  ManagedUserUpdate({
    this.active,

    this.clearDisplayName,

    this.displayName,

    required this.userRevision,
  });

  @JsonKey(name: r'active', required: false, includeIfNull: false)
  final bool? active;

  /// true clears the display name; mutually exclusive with displayName.
  @JsonKey(name: r'clearDisplayName', required: false, includeIfNull: false)
  final bool? clearDisplayName;

  @JsonKey(name: r'displayName', required: false, includeIfNull: false)
  final String? displayName;

  // minimum: 0
  // maximum: 9007199254740991
  @JsonKey(name: r'userRevision', required: true, includeIfNull: false)
  final int userRevision;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedUserUpdate &&
          other.active == active &&
          other.clearDisplayName == clearDisplayName &&
          other.displayName == displayName &&
          other.userRevision == userRevision;

  @override
  int get hashCode =>
      active.hashCode +
      clearDisplayName.hashCode +
      displayName.hashCode +
      userRevision.hashCode;

  factory ManagedUserUpdate.fromJson(Map<String, dynamic> json) =>
      _$ManagedUserUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedUserUpdateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
