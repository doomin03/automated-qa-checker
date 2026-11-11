import 'dart:convert';

import '../models/xml_block_document.dart';

/// Static authoring transform only. The public Engine validates and executes.
class XmlBlockCompiler {
  static Object? _canonical(Object? v) => v is Map
      ? {
          for (final k in (v.keys.cast<String>().toList()..sort()))
            k: _canonical(v[k]),
        }
      : v is List
      ? v.map(_canonical).toList()
      : v;
  static String canonical(Object? v) => jsonEncode(_canonical(v));
  static void checkAsset(XmlBlockAsset asset) {
    final b = asset.blueprint, f = b['flow'];
    void reject(String reason) => throw BlockDiagnostic(
      '${asset.name}: $reason. 직접 XML 문서로 열 수 있습니다.',
      assetId: asset.id,
    );
    if (f is! Map || f['nodes'] is! List || f['edges'] is! List) {
      reject('공개 Blueprint가 아닙니다');
    }
    if (b['references'] != null ||
        b['testCase'] != null ||
        b['metadata']?['preset'] != null ||
        f['metadata']?['preset'] != null ||
        b['target']?['profile'] != null) {
      reject('참조/TC/프리셋/캡처 프로필은 조합 범위 밖입니다');
    }
    final nodes = List<Map<String, dynamic>>.from(f['nodes']);
    if (nodes.where((n) => n['type'] == 'start').length != 1 ||
        nodes.where((n) => n['type'] == 'end').length != 1) {
      reject('시작과 종료가 하나씩 필요합니다');
    }
    if (nodes.length < 3) reject('시작과 종료 사이에 실행 동작이 필요합니다');
    for (final node in nodes) {
      if (![
        'start',
        'end',
        'action',
        'assertion',
        'branch',
      ].contains(node['type'])) {
        reject('지원하지 않는 블록 유형 ${node['type']}');
      }
      final p = node['params'] as Map? ?? {};
      if (p.containsKey('reference')) reject('파일 참조 동작은 조합 범위 밖입니다');
    }
  }

  XmlBlockCompilation compile(
    List<XmlBlockAsset> assets,
    List<XmlBlockInstance> instances,
    List<XmlBlockLink> links,
  ) {
    if (instances.isEmpty) {
      throw const BlockDiagnostic('XML 파일 블록을 캔버스에 추가하세요.');
    }
    final byId = {for (final n in instances) n.id: n},
        byAsset = {for (final a in assets) a.id: a};
    if (byId.length != instances.length) {
      throw const BlockDiagnostic('중복 인스턴스 ID입니다.');
    }
    for (final e in links) {
      if (!byId.containsKey(e.from) ||
          !byId.containsKey(e.to) ||
          e.from == e.to) {
        throw const BlockDiagnostic('연결 대상이 올바르지 않습니다.');
      }
    }
    for (final n in instances) {
      if (links.where((e) => e.from == n.id).length > 1 ||
          links.where((e) => e.to == n.id).length > 1) {
        throw BlockDiagnostic('외부 블록은 순차 연결만 지원합니다.', instanceId: n.id);
      }
    }
    final heads = instances
        .where((n) => !links.any((e) => e.to == n.id))
        .toList();
    if (heads.length != 1) {
      throw const BlockDiagnostic('모든 XML 블록을 하나의 순서로 연결하세요.');
    }
    final ordered = <XmlBlockInstance>[], seen = <String>{};
    var current = heads.single;
    while (true) {
      if (!seen.add(current.id)) {
        throw const BlockDiagnostic('순환 연결은 지원하지 않습니다.');
      }
      ordered.add(current);
      final next = links.where((e) => e.from == current.id).firstOrNull;
      if (next == null) break;
      current = byId[next.to]!;
    }
    if (ordered.length != instances.length ||
        links.length != instances.length - 1) {
      throw const BlockDiagnostic('연결되지 않거나 순환하는 XML 블록이 있습니다.');
    }
    final nodes = <Map<String, dynamic>>[
          {'id': 'composition_start', 'type': 'start'},
        ],
        edges = <Map<String, dynamic>>[],
        selectors = <String, dynamic>{},
        variables = <String, dynamic>{};
    final map = <String, Map<String, String>>{};
    Map<String, dynamic>? target;
    List<String> previous = ['composition_start'];
    for (final instance in ordered) {
      final asset = byAsset[instance.assetId];
      if (asset == null) {
        throw BlockDiagnostic('XML 자산을 찾을 수 없습니다.', instanceId: instance.id);
      }
      checkAsset(asset);
      final b = asset.blueprint, f = b['flow'] as Map<String, dynamic>;
      if (target != null && canonical(target) != canonical(b['target'])) {
        throw BlockDiagnostic(
          '${asset.name}: 실행 대상 선언이 다른 블록과 다릅니다.',
          instanceId: instance.id,
          assetId: asset.id,
        );
      }
      target ??= Map<String, dynamic>.from(b['target']);
      final originalNodes = List<Map<String, dynamic>>.from(f['nodes']),
          originalEdges = List<Map<String, dynamic>>.from(f['edges']);
      final start = originalNodes.singleWhere(
            (n) => n['type'] == 'start',
          )['id'],
          end = originalNodes.singleWhere((n) => n['type'] == 'end')['id'];
      String name(String type, String id) =>
          'b_${blockHash('${instance.id}/$type/$id').substring(0, 24)}';
      final nodeIds = {
        for (final n in originalNodes) n['id'] as String: name('node', n['id']),
      };
      final variableIds = {
        for (final key in (f['variables'] as Map? ?? {}).keys)
          key as String: name('variable', key),
      };
      final selectorIds = {
        for (final key in (b['selectors']['selectors'] as Map).keys)
          key as String: name('selector', key),
      };
      String remap(Map<String, String> names, Object? value, String field) {
        if (value is! String || !names.containsKey(value)) {
          throw BlockDiagnostic(
            '${asset.name}: $field 참조가 없습니다.',
            instanceId: instance.id,
          );
        }
        return names[value]!;
      }

      for (final entry in (f['variables'] as Map? ?? {}).entries) {
        variables[variableIds[entry.key]!] = entry.value;
      }
      for (final entry in (b['selectors']['selectors'] as Map).entries) {
        selectors[selectorIds[entry.key]!] = entry.value;
      }
      for (final original in originalNodes) {
        if (original['type'] == 'start' || original['type'] == 'end') continue;
        final node = blockCopy(original);
        node['id'] = nodeIds[original['id']];
        final params = node['params'] as Map<String, dynamic>?;
        if (params != null) {
          if (params.containsKey('selector')) {
            params['selector'] = remap(
              selectorIds,
              params['selector'],
              'selector',
            );
          }
          for (final key in ['valueRef', 'expectedRef']) {
            if (params.containsKey(key)) {
              params[key] = remap(variableIds, params[key], key);
            }
          }
          if (['captureText', 'captureValue'].contains(node['action']) &&
              params.containsKey('variable')) {
            params['variable'] = remap(
              variableIds,
              params['variable'],
              'capture.variable',
            );
          }
        }
        final condition = node['condition'] as Map<String, dynamic>?;
        if (condition != null && condition.containsKey('variable')) {
          condition['variable'] = remap(
            variableIds,
            condition['variable'],
            'condition.variable',
          );
        }
        nodes.add(node);
        map[node['id']] = {
          'instanceId': instance.id,
          'assetId': asset.id,
          'sourceNodeId': original['id'],
          'sourceFile': asset.path,
          'sourceHash': asset.hash,
        };
      }
      final entryEdges = originalEdges
          .where((e) => e['from'] == start)
          .toList();
      if (entryEdges.length != 1 || entryEdges.single['to'] == end) {
        throw BlockDiagnostic(
          '${asset.name}: 시작 다음 실행 동작이 필요합니다.',
          instanceId: instance.id,
        );
      }
      final entryId = nodeIds[entryEdges.single['to']]!;
      for (final id in previous) {
        edges.add({'from': id, 'to': entryId});
      }
      final exits = <String>[];
      for (final original in originalEdges) {
        if (original['from'] == start) continue;
        if (original['to'] == end) {
          // End edges may carry branch labels: retain them until the next entry is known.
          exits.add(nodeIds[original['from']]!);
          edges.add({
            'from': nodeIds[original['from']],
            'to': 'pending_${instance.id}',
            if (original['label'] != null) 'label': original['label'],
          });
        } else {
          edges.add({
            'from': nodeIds[original['from']],
            'to': nodeIds[original['to']],
            if (original['label'] != null) 'label': original['label'],
          });
        }
      }
      // Resolve prior block exit placeholders to this instance's entry.
      for (final edge in edges) {
        if ((edge['to'] as String).startsWith('pending_') &&
            edge['to'] != 'pending_${instance.id}') {
          edge['to'] = entryId;
        }
      }
      previous = [];
      if (exits.isEmpty) {
        throw BlockDiagnostic(
          '${asset.name}: 종료로 이어지는 연결이 없습니다.',
          instanceId: instance.id,
        );
      }
    }
    nodes.add({'id': 'composition_end', 'type': 'end'});
    for (final edge in edges) {
      if ((edge['to'] as String).startsWith('pending_')) {
        edge['to'] = 'composition_end';
      }
    }
    final blueprint = <String, dynamic>{
      'schemaVersion': 'qa.blueprint/v1',
      'id': 'xml-composition',
      'name': 'XML 블록 조합',
      'flow': {
        'schemaVersion': 'qa.flow/v1',
        'id': 'xml-composition-flow',
        'name': 'XML 블록 조합',
        'entryNode': 'composition_start',
        'variables': variables,
        'nodes': nodes,
        'edges': edges,
      },
      'selectors': {
        'schemaVersion': 'qa.selectors/v1',
        'id': 'xml-composition-selectors',
        'selectors': selectors,
      },
      'target': target,
    };
    return XmlBlockCompilation(blueprint, map);
  }
}
