//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'administration_status.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdministrationStatus {
  /// Returns a new [AdministrationStatus] instance.
  AdministrationStatus({
    required this.identityStorage,

    required this.mutationSupported,
  });

  @JsonKey(name: r'identityStorage', required: true, includeIfNull: false)
  final AdministrationStatusIdentityStorageEnum identityStorage;

  @JsonKey(name: r'mutationSupported', required: true, includeIfNull: false)
  final bool mutationSupported;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdministrationStatus &&
          other.identityStorage == identityStorage &&
          other.mutationSupported == mutationSupported;

  @override
  int get hashCode => identityStorage.hashCode + mutationSupported.hashCode;

  factory AdministrationStatus.fromJson(Map<String, dynamic> json) =>
      _$AdministrationStatusFromJson(json);

  Map<String, dynamic> toJson() => _$AdministrationStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AdministrationStatusIdentityStorageEnum {
  @JsonValue(r'provisioned')
  provisioned(r'provisioned'),
  @JsonValue(r'managed')
  managed(r'managed');

  const AdministrationStatusIdentityStorageEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
