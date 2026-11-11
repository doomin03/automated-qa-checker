//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/api_error_detail.dart';
import 'package:json_annotation/json_annotation.dart';

part 'api_error_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApiErrorResponse {
  /// Returns a new [ApiErrorResponse] instance.
  ApiErrorResponse({
    required this.code,

    required this.details,

    required this.message,

    required this.requestId,
  });

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'details', required: true, includeIfNull: false)
  final List<ApiErrorDetail> details;

  @JsonKey(name: r'message', required: true, includeIfNull: false)
  final String message;

  @JsonKey(name: r'requestId', required: true, includeIfNull: false)
  final String requestId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiErrorResponse &&
          other.code == code &&
          other.details == details &&
          other.message == message &&
          other.requestId == requestId;

  @override
  int get hashCode =>
      code.hashCode + details.hashCode + message.hashCode + requestId.hashCode;

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
