// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'changed_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangedNode _$ChangedNodeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ChangedNode', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['current', 'nodeId', 'previous']);
      final val = ChangedNode(
        current: $checkedConvert('current', (v) => v as String),
        nodeId: $checkedConvert('nodeId', (v) => v as String),
        previous: $checkedConvert('previous', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ChangedNodeToJson(ChangedNode instance) =>
    <String, dynamic>{
      'current': instance.current,
      'nodeId': instance.nodeId,
      'previous': instance.previous,
    };
