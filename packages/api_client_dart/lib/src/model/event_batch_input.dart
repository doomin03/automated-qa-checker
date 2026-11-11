//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'event_batch_input.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EventBatchInput {
  /// Returns a new [EventBatchInput] instance.
  EventBatchInput({required this.eventsJson});

  /// Opaque Engine event JSON strings. All-or-nothing validation/append.
  @JsonKey(name: r'eventsJson', required: true, includeIfNull: false)
  final List<String> eventsJson;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventBatchInput && other.eventsJson == eventsJson;

  @override
  int get hashCode => eventsJson.hashCode;

  factory EventBatchInput.fromJson(Map<String, dynamic> json) =>
      _$EventBatchInputFromJson(json);

  Map<String, dynamic> toJson() => _$EventBatchInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
