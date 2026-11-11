//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'api_error_detail.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiErrorDetail {
  /// Returns a new [ApiErrorDetail] instance.
  ApiErrorDetail({
    required this.code,

    required this.field,

    required this.message,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'field', required: true, includeIfNull: false)
  final String field;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiErrorDetail &&
          other.code == code &&
          other.field == field &&
          other.message == message;

  @override
  int get hashCode => code.hashCode + field.hashCode + message.hashCode;

  factory ApiErrorDetail.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
