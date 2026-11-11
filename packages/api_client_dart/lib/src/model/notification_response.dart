//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'notification_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NotificationResponse {
  /// Returns a new [NotificationResponse] instance.
  NotificationResponse({
    required this.attempts,

    required this.createdAt,

    required this.id,

    required this.lastError,

    required this.nextAttemptAt,

    required this.runId,

    required this.state,
  });

  @JsonKey(name: r'attempts', required: true, includeIfNull: false)
  final int attempts;

  @JsonKey(name: r'createdAt', required: true, includeIfNull: false)
  final String createdAt;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'lastError', required: true, includeIfNull: true)
  final String? lastError;

  @JsonKey(name: r'nextAttemptAt', required: true, includeIfNull: false)
  final String nextAttemptAt;

  @JsonKey(name: r'runId', required: true, includeIfNull: false)
  final String runId;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final NotificationResponseStateEnum state;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationResponse &&
          other.attempts == attempts &&
          other.createdAt == createdAt &&
          other.id == id &&
          other.lastError == lastError &&
          other.nextAttemptAt == nextAttemptAt &&
          other.runId == runId &&
          other.state == state;

  @override
  int get hashCode =>
      attempts.hashCode +
      createdAt.hashCode +
      id.hashCode +
      (lastError == null ? 0 : lastError.hashCode) +
      nextAttemptAt.hashCode +
      runId.hashCode +
      state.hashCode;

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum NotificationResponseStateEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'sending')
  sending(r'sending'),
  @JsonValue(r'retrying')
  retrying(r'retrying'),
  @JsonValue(r'delivery_failed')
  deliveryFailed(r'delivery_failed'),
  @JsonValue(r'delivered')
  delivered(r'delivered');

  const NotificationResponseStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
