// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_enabled_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleEnabledInput _$ScheduleEnabledInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ScheduleEnabledInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['enabled']);
  final val = ScheduleEnabledInput(
    enabled: $checkedConvert('enabled', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$ScheduleEnabledInputToJson(
  ScheduleEnabledInput instance,
) => <String, dynamic>{'enabled': instance.enabled};
