//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'schedule_enabled_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ScheduleEnabledInput {
  /// Returns a new [ScheduleEnabledInput] instance.
  ScheduleEnabledInput({required this.enabled});

  @JsonKey(name: r'enabled', required: true, includeIfNull: false)
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleEnabledInput && other.enabled == enabled;

  @override
  int get hashCode => enabled.hashCode;

  factory ScheduleEnabledInput.fromJson(Map<String, dynamic> json) =>
      _$ScheduleEnabledInputFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleEnabledInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
