import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../repositories/blueprint_catalog.dart';

class FlowEditorViewModel extends ChangeNotifier {
  FlowEditorViewModel(this._catalog);
  final BlueprintCatalog _catalog;
  Map<String, dynamic>? _contract;
  Map<String, dynamic>? _draft;
  final List<String> _undo = [];
  final List<String> _redo = [];
  String? error;
  int revision = 0;
  bool _disposed = false;
  List<Map<String, dynamic>> get presets =>
      List<Map<String, dynamic>>.from(_contract?['presets'] ?? []);
  List<dynamic> get _variants =>
      _contract?['schema']['definitions']['flow']['properties']['nodes']['items']['oneOf'] ??
      [];
  List<String> get nodeTypes => _variants
      .map((v) => v['properties']['type']['const'])
      .whereType<String>()
      .toSet()
      .toList();
  List<String> get actions => _variants
      .map((v) => v['properties']['action']?['const'])
      .whereType<String>()
      .toSet()
      .toList();
  Map<String, dynamic>? get blueprint => _draft == null
      ? null
      : jsonDecode(jsonEncode(_draft)) as Map<String, dynamic>;
  List<Map<String, dynamic>> get nodes =>
      List<Map<String, dynamic>>.from(blueprint?['flow']['nodes'] ?? []);
  List<Map<String, dynamic>> get edges =>
      List<Map<String, dynamic>>.from(blueprint?['flow']['edges'] ?? []);
  String get source => const JsonEncoder.withIndent('  ').convert(_draft);
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  List<String> actionsFor(String type) => _variants
      .where((v) => v['properties']['type']['const'] == type)
      .map((v) => v['properties']['action']?['const'])
      .whereType<String>()
      .toList();
  Map<String, dynamic> paramsFor(String type, String? action) =>
      Map<String, dynamic>.from(
        _variants
                .where(
                  (v) =>
                      v['properties']['type']['const'] == type &&
                      v['properties']['action']?['const'] == action,
                )
                .firstOrNull?['properties']['params']?['properties'] ??
            {},
      );
  List<String> get locatorStrategies => List<String>.from(
    _contract?['schema']['definitions']['locator']['properties']['strategy']['enum'] ??
        [],
  );
  Map<String, List<String>> get platformStrategies => {
    'web': locatorStrategies,
    for (final platform in ['android', 'ios'])
      platform: List<String>.from(
        _contract?['schema']['definitions']['selectors']['properties']['selectors']['additionalProperties']['properties'][platform]['properties']['strategy']['enum'] ??
            [],
      ),
  };

  bool _renderable(Map<String, dynamic> value) {
    for (final key in ['id', 'name']) {
      if (value[key] != null && value[key] is! String) return false;
    }
    final flow = value['flow'];
    if (flow is! Map || flow['nodes'] is! List || flow['edges'] is! List) {
      return false;
    }
    if (value['selectors'] is! Map ||
        value['selectors']['selectors'] is! Map ||
        value['target'] is! Map) {
      return false;
    }
    final ids = <String>{};
    if (flow['entryNode'] is! String) return false;
    for (final node in flow['nodes']) {
      if (node is! Map ||
          node['id'] is! String ||
          (node['id'] as String).isEmpty ||
          node['type'] is! String ||
          !ids.add(node['id'])) {
        return false;
      }
      for (final key in ['params', 'condition', 'retry']) {
        if (node[key] != null && node[key] is! Map) return false;
      }
      if (node['action'] != null && node['action'] is! String) return false;
      for (final key in ['variable', 'operator']) {
        if (node['condition']?[key] != null &&
            node['condition'][key] is! String) {
          return false;
        }
      }
    }
    for (final edge in flow['edges']) {
      if (edge is! Map ||
          edge['from'] is! String ||
          edge['to'] is! String ||
          (edge.containsKey('label') && edge['label'] is! String)) {
        return false;
      }
    }
    if (flow['variables'] != null && flow['variables'] is! Map) return false;
    if ((flow['variables'] as Map? ?? {}).values.any((v) => v is! Map)) {
      return false;
    }
    final target = value['target'] as Map;
    if (target['launchTargets'] is! Map ||
        (target['launchTargets'] as Map).values.any((v) => v is! String)) {
      return false;
    }
    if (target['platform'] is! String ||
        (target['allowedOrigins'] != null &&
            (target['allowedOrigins'] is! List ||
                (target['allowedOrigins'] as List).any((v) => v is! String)))) {
      return false;
    }
    for (final locator in (value['selectors']['selectors'] as Map).values) {
      if (locator is! Map) return false;
      for (final platform in ['web', 'android', 'ios']) {
        final item = locator[platform];
        if (item != null &&
            (item is! Map ||
                item['value'] is! String ||
                item['strategy'] is! String)) {
          return false;
        }
      }
    }
    if (value['testCase'] != null && value['testCase'] is! Map) return false;
    for (final key in ['id', 'name', 'expected']) {
      if (value['testCase']?[key] != null &&
          value['testCase'][key] is! String) {
        return false;
      }
    }
    final metadata = flow['metadata'];
    if (metadata != null && metadata is! Map) return false;
    final presentation = metadata?['presentation'];
    if (presentation != null && presentation is! Map) return false;
    final positions = presentation?['positions'];
    if (positions != null && positions is! Map) return false;
    return true;
  }

  Future<void> initialize() async {
    try {
      final loaded = await _catalog.load();
      if (_disposed) return;
      _contract = loaded;
      notifyListeners();
    } catch (_) {
      if (!_disposed) {
        error = '공개 엔진 편집 계약을 읽을 수 없습니다.';
        notifyListeners();
      }
    }
  }

  void load(Map<String, dynamic> value) {
    if (!_renderable(value)) {
      error = '화면에 표시할 수 없는 Flow 구조입니다. 이전 초안을 유지합니다.';
      notifyListeners();
      return;
    }
    _draft = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
    revision++;
    _loadedSource = jsonEncode(_draft);
    _undo.clear();
    _redo.clear();
    error = null;
    notifyListeners();
  }

  String? _loadedSource;
  bool get isDirty => _draft != null && jsonEncode(_draft) != _loadedSource;
  void markClean() {
    _loadedSource = jsonEncode(_draft);
  }

  void clear() {
    revision++;
    _draft = null;
    _loadedSource = null;
    _undo.clear();
    _redo.clear();
    error = null;
    notifyListeners();
  }

  void create() {
    if (_contract != null) load(_contract!['example'] as Map<String, dynamic>);
  }

  void edit(void Function(Map<String, dynamic>) action) {
    if (_draft == null) return;
    final before = jsonEncode(_draft);
    final next = jsonDecode(before) as Map<String, dynamic>;
    try {
      action(next);
      if (!_renderable(next)) {
        throw const FormatException('Invalid editor structure');
      }
      if (jsonEncode(next) == before) return;
      _undo.add(before);
      if (_undo.length > 100) _undo.removeAt(0);
      _redo.clear();
      _draft = next;
      revision++;
      error = null;
    } catch (_) {
      error = '설정 형식이 잘못되었습니다. 기존 Flow를 유지합니다.';
    }
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _redo.add(jsonEncode(_draft));
    _draft = jsonDecode(_undo.removeLast()) as Map<String, dynamic>;
    revision++;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(jsonEncode(_draft));
    _draft = jsonDecode(_redo.removeLast()) as Map<String, dynamic>;
    revision++;
    notifyListeners();
  }

  void addNode(String type) {
    if (!nodeTypes.contains(type)) return;
    edit((b) {
      final nodes = b['flow']['nodes'] as List;
      var i = 1;
      while (nodes.any((n) => n['id'] == 'node$i')) {
        i++;
      }
      final n = <String, dynamic>{'id': 'node$i', 'type': type};
      if (type == 'action' || type == 'assertion') {
        n['action'] = actionsFor(type).first;
        n['params'] = <String, dynamic>{};
      }
      if (type == 'branch') {
        n['condition'] = {
          'variable': (b['flow']['variables'] as Map?)?.keys.firstOrNull ?? '',
          'operator': 'equals',
          'value': true,
        };
      }
      nodes.add(n);
    });
  }

  void removeNode(String id) => edit((b) {
    (b['flow']['nodes'] as List).removeWhere((n) => n['id'] == id);
    (b['flow']['edges'] as List).removeWhere(
      (e) => e['from'] == id || e['to'] == id,
    );
  });
  void updateNode(String id, Map<String, dynamic> node) => edit((b) {
    if (node['id'] != id) {
      throw const FormatException('Node ID cannot be renamed');
    }
    final nodes = b['flow']['nodes'] as List;
    nodes[nodes.indexWhere((n) => n['id'] == id)] = node;
  });
  void connect(String from, String to, String label) => edit((b) {
    final nodes = b['flow']['nodes'] as List;
    final a = nodes.where((n) => n['id'] == from).firstOrNull,
        bNode = nodes.where((n) => n['id'] == to).firstOrNull;
    if (a == null ||
        bNode == null ||
        from == to ||
        a['type'] == 'end' ||
        bNode['type'] == 'start' ||
        (a['type'] == 'branch'
            ? !['true', 'false'].contains(label)
            : label.isNotEmpty)) {
      throw const FormatException('Invalid port direction');
    }
    final edges = b['flow']['edges'] as List;
    edges.removeWhere((e) => e['from'] == from && (e['label'] ?? '') == label);
    edges.add({'from': from, 'to': to, if (label.isNotEmpty) 'label': label});
  });
  void removeEdge(int index) => edit((b) {
    (b['flow']['edges'] as List).removeAt(index);
  });
  void move(String id, double x, double y) => edit((b) {
    final metadata = b['flow']['metadata'] ??= <String, dynamic>{};
    final presentation = metadata['presentation'] ??= <String, dynamic>{};
    final positions = presentation['positions'] ??= <String, dynamic>{};
    positions[id] = {'x': x, 'y': y};
  });
  void settings(Map<String, dynamic> settings) => edit((b) {
    for (final key in ['id', 'name', 'selectors', 'target', 'testCase']) {
      if (settings.containsKey(key)) {
        b[key] = settings[key];
      } else if (key == 'testCase') {
        b.remove(key);
      }
    }
    if (settings.containsKey('flow')) {
      final flow = settings['flow'] as Map;
      for (final key in ['id', 'name', 'entryNode', 'variables', 'metadata']) {
        if (flow.containsKey(key)) b['flow'][key] = flow[key];
      }
    }
  });
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
