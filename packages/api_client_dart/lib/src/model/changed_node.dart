//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'changed_node.g.dart';

@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChangedNode {
  /// Returns a new [ChangedNode] instance.
  ChangedNode({
    required this.current,

    required this.nodeId,

    required this.previous,
  });

  @JsonKey(name: r'current', required: true, includeIfNull: false)
  final String current;

  @JsonKey(name: r'nodeId', required: true, includeIfNull: false)
  final String nodeId;

  @JsonKey(name: r'previous', required: true, includeIfNull: false)
  final String previous;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangedNode &&
          other.current == current &&
          other.nodeId == nodeId &&
          other.previous == previous;

  @override
  int get hashCode => current.hashCode + nodeId.hashCode + previous.hashCode;

  factory ChangedNode.fromJson(Map<String, dynamic> json) =>
      _$ChangedNodeFromJson(json);

  Map<String, dynamic> toJson() => _$ChangedNodeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
