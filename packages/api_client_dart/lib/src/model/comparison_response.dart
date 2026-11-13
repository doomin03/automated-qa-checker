//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/changed_node.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comparison_response.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComparisonResponse {
  /// Returns a new [ComparisonResponse] instance.
  ComparisonResponse({
    required this.baselineOutcome,

    required this.baselineRunId,

    required this.changedNodes,

    required this.classification,

    required this.comparable,

    required this.currentOutcome,

    required this.reason,

    required this.runId,
  });

  @JsonKey(name: r'baselineOutcome', required: true, includeIfNull: true)
  final String? baselineOutcome;

  @JsonKey(name: r'baselineRunId', required: true, includeIfNull: true)
  final String? baselineRunId;

  @JsonKey(name: r'changedNodes', required: true, includeIfNull: false)
  final List<ChangedNode> changedNodes;

  @JsonKey(name: r'classification', required: true, includeIfNull: false)
  final ComparisonResponseClassificationEnum classification;

  @JsonKey(name: r'comparable', required: true, includeIfNull: false)
  final bool comparable;

  @JsonKey(name: r'currentOutcome', required: true, includeIfNull: true)
  final String? currentOutcome;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @JsonKey(name: r'runId', required: true, includeIfNull: false)
  final String runId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonResponse &&
          other.baselineOutcome == baselineOutcome &&
          other.baselineRunId == baselineRunId &&
          other.changedNodes == changedNodes &&
          other.classification == classification &&
          other.comparable == comparable &&
          other.currentOutcome == currentOutcome &&
          other.reason == reason &&
          other.runId == runId;

  @override
  int get hashCode =>
      (baselineOutcome == null ? 0 : baselineOutcome.hashCode) +
      (baselineRunId == null ? 0 : baselineRunId.hashCode) +
      changedNodes.hashCode +
      classification.hashCode +
      comparable.hashCode +
      (currentOutcome == null ? 0 : currentOutcome.hashCode) +
      reason.hashCode +
      runId.hashCode;

  factory ComparisonResponse.fromJson(Map<String, dynamic> json) =>
      _$ComparisonResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComparisonResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ComparisonResponseClassificationEnum {
  @JsonValue(r'incomparable')
  incomparable(r'incomparable'),
  @JsonValue(r'regression')
  regression(r'regression'),
  @JsonValue(r'improvement')
  improvement(r'improvement'),
  @JsonValue(r'unchanged')
  unchanged(r'unchanged'),
  @JsonValue(r'changed')
  changed(r'changed');

  const ComparisonResponseClassificationEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
