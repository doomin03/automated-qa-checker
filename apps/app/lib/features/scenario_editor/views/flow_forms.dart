import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../view_models/flow_editor_view_model.dart';

class NodeForm extends StatefulWidget {
  const NodeForm({
    required this.node,
    required this.editor,
    this.onSaved,
    super.key,
  });
  final Map<String, dynamic> node;
  final FlowEditorViewModel editor;
  final ValueChanged<Map<String, dynamic>>? onSaved;
  @override
  State<NodeForm> createState() => _NodeFormState();
}

class _NodeFormState extends State<NodeForm> {
  final Map<String, TextEditingController> _fields = {};
  late String? _action = widget.node['action'];
  late String _operator = widget.node['condition']?['operator'] ?? 'equals';
  late String _valueType = widget.node['condition']?['value'] is bool
      ? 'boolean'
      : widget.node['condition']?['value'] is num
      ? 'number'
      : widget.node['condition']?['value'] == null
      ? 'null'
      : 'string';
  late bool _sideEffects = widget.node['retry']?['allowSideEffects'] == true;
  String? _error;
  TextEditingController field(String key, dynamic initial) =>
      _fields.putIfAbsent(
        key,
        () => TextEditingController(
          text: initial is Map || initial is List
              ? jsonEncode(initial)
              : initial?.toString() ?? '',
        ),
      );
  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void save() {
    try {
      final n = Map<String, dynamic>.from(widget.node);
      final type = n['type'] as String;
      if (_action != null) {
        n['action'] = _action;
        final params = _action == widget.node['action']
            ? Map<String, dynamic>.from(widget.node['params'] ?? {})
            : <String, dynamic>{};
        final schemas = widget.editor.paramsFor(type, _action);
        for (final e in schemas.entries) {
          final text = field('param.${e.key}', null).text;
          if (text.isEmpty) {
            params.remove(e.key);
            continue;
          }
          final kind = e.value['type'];
          final original = widget.node['params']?[e.key];
          params[e.key] = original is Map || original is List
              ? jsonDecode(text)
              : kind == 'integer'
              ? int.parse(text)
              : kind == 'number'
              ? num.parse(text)
              : kind == 'boolean'
              ? (text == 'true'
                    ? true
                    : text == 'false'
                    ? false
                    : throw const FormatException())
              : text;
        }
        n['params'] = params;
      }
      final timeout = field('timeout', null).text;
      if (timeout.isEmpty) {
        n.remove('timeoutMs');
      } else {
        n['timeoutMs'] = int.parse(timeout);
      }
      final retry = field('retry', null).text;
      if (retry.isEmpty) {
        n.remove('retry');
      } else {
        n['retry'] = {
          'maxRetries': int.parse(retry),
          'allowSideEffects': _sideEffects,
        };
      }
      if (type == 'branch') {
        final raw = field('conditionValue', null).text;
        n['condition'] = {
          'variable': field('variable', null).text,
          'operator': _operator,
          'value': _valueType == 'number'
              ? num.parse(raw)
              : _valueType == 'boolean'
              ? (raw == 'true'
                    ? true
                    : raw == 'false'
                    ? false
                    : throw const FormatException())
              : _valueType == 'null'
              ? null
              : raw,
        };
      }
      if (widget.onSaved != null) {
        widget.onSaved!(n);
      } else {
        Navigator.pop(context, n);
      }
    } catch (_) {
      setState(() => _error = '수치와 boolean(true/false) 입력을 확인하세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.node;
    final type = n['type'] as String;
    final actions = widget.editor.actionsFor(type);
    final params = widget.editor.paramsFor(type, _action);
    final dialog = AlertDialog(
      title: Text('노드 ${n['id']} · $type'),
      content: SizedBox(
        width: 600,
        height: math.min(
          520,
          math.max(120, MediaQuery.sizeOf(context).height - 190),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ID는 연결 보존을 위해 고정됩니다. 최종 의미 검증은 엔진이 수행합니다.'),
              if (actions.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: actions.contains(_action) ? _action : null,
                  decoration: const InputDecoration(labelText: 'action'),
                  items: actions
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => setState(() => _action = v),
                ),
              if (_action != null && !actions.contains(_action))
                Text('미지원 action: $_action'),
              for (final e in params.entries)
                TextField(
                  key: Key('node-param-${e.key}'),
                  controller: field('param.${e.key}', n['params']?[e.key]),
                  decoration: InputDecoration(
                    labelText: e.key,
                    helperText: e.key == 'selector'
                        ? '등록된 selector: ${(widget.editor.blueprint?['selectors']['selectors'] as Map?)?.keys.join(', ') ?? ''}'
                        : e.key == 'target'
                        ? '등록된 target: ${(widget.editor.blueprint?['target']['launchTargets'] as Map?)?.keys.join(', ') ?? ''}: ${e.value['type']}'
                        : e.value['type']?.toString(),
                  ),
                ),
              if (type == 'branch') ...[
                TextField(
                  controller: field('variable', n['condition']?['variable']),
                  decoration: InputDecoration(
                    labelText: '분기 변수',
                    helperText:
                        '등록 변수: ${(widget.editor.blueprint?['flow']['variables'] as Map?)?.keys.join(', ') ?? ''}',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _operator,
                  items: ['equals', 'notEquals']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _operator = v!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _valueType,
                  decoration: const InputDecoration(labelText: '비교값 타입'),
                  items: ['string', 'number', 'boolean', 'null']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _valueType = v!),
                ),
                TextField(
                  controller: field('conditionValue', n['condition']?['value']),
                  decoration: const InputDecoration(labelText: '비교값'),
                ),
              ],
              TextField(
                controller: field('timeout', n['timeoutMs']),
                decoration: const InputDecoration(labelText: 'timeoutMs (선택)'),
              ),
              TextField(
                controller: field('retry', n['retry']?['maxRetries']),
                decoration: const InputDecoration(labelText: 'maxRetries (선택)'),
              ),
              CheckboxListTile(
                value: _sideEffects,
                onChanged: (v) => setState(() => _sideEffects = v!),
                title: const Text('부수효과 액션의 재시도 허용'),
              ),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: save, child: const Text('노드 적용')),
      ],
    );
    if (widget.onSaved == null) return dialog;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('속성 · ${n['id']}'),
        ),
        ((dialog.content! as SizedBox).child! as SingleChildScrollView).child!,
        Padding(
          padding: const EdgeInsets.all(8),
          child: FilledButton(onPressed: save, child: const Text('속성 적용')),
        ),
      ],
    );
  }
}

class _MappingRow {
  _MappingRow(
    String key,
    String value, [
    this.kind = 'testId',
    String extra = '',
  ]) : name = TextEditingController(text: key),
       content = TextEditingController(text: value),
       detail = TextEditingController(text: extra);
  final TextEditingController name, content, detail;
  String kind;
  void dispose() {
    name.dispose();
    content.dispose();
    detail.dispose();
  }
}

class TargetForm extends StatefulWidget {
  const TargetForm({
    required this.blueprint,
    required this.strategies,
    this.platformStrategies = const {},
    super.key,
  });
  final Map<String, dynamic> blueprint;
  final List<String> strategies;
  final Map<String, List<String>> platformStrategies;
  @override
  State<TargetForm> createState() => _TargetFormState();
}

class _TargetFormState extends State<TargetForm> {
  late String _platform = widget.blueprint['target']['platform'];
  late final Map<String, dynamic> _locators = Map<String, dynamic>.from(
    jsonDecode(jsonEncode(widget.blueprint['selectors']['selectors'])),
  );
  List<String> get _strategies =>
      widget.platformStrategies[_platform] ?? widget.strategies;
  void _selectPlatform(String value) {
    setState(() {
      _platform = value;
      _selectors.clear();
      for (final entry in _locators.entries) {
        final locator = entry.value[value];
        final row = _MappingRow(
          entry.key,
          locator?['value'] ?? '',
          locator?['strategy'] ?? _strategies.firstOrNull ?? '',
          locator?['name'] ?? '',
        );
        _selectors.add(row);
        _all.add(row);
      }
    });
  }

  final List<_MappingRow> _targets = [],
      _selectors = [],
      _variables = [],
      _all = [];
  late final _name = TextEditingController(
    text: widget.blueprint['name'] ?? '',
  );
  late final _entry = TextEditingController(
    text: widget.blueprint['flow']['entryNode'],
  );
  late final _origins = TextEditingController(
    text: (widget.blueprint['target']['allowedOrigins'] as List? ?? []).join(
      '\n',
    ),
  );
  late final _tcName = TextEditingController(
    text: widget.blueprint['testCase']?['name'] ?? '',
  );
  late final _tcExpected = TextEditingController(
    text: widget.blueprint['testCase']?['expected'] ?? '',
  );
  late final _tcId = TextEditingController(
    text: widget.blueprint['testCase']?['id'] ?? 'test-case',
  );
  late bool _tc = widget.blueprint.containsKey('testCase');
  String? _error;
  @override
  void initState() {
    super.initState();
    final b = widget.blueprint;
    for (final e in (b['target']['launchTargets'] as Map? ?? {}).entries) {
      _targets.add(_MappingRow(e.key, e.value));
    }
    for (final e in (b['selectors']['selectors'] as Map).entries) {
      final locator = e.value[_platform];
      _selectors.add(
        _MappingRow(
          e.key,
          locator?['value'] ?? '',
          locator?['strategy'] ?? _strategies.firstOrNull ?? '',
          locator?['name'] ?? '',
        ),
      );
    }
    for (final e in (b['flow']['variables'] as Map? ?? {}).entries) {
      final v = e.value;
      _variables.add(
        _MappingRow(
          e.key,
          (v['value'] ?? v['ref'] ?? '').toString(),
          v['from'] == 'secret'
              ? 'secretRef'
              : v['from'] == 'capture'
              ? 'publicCapture'
              : v['value'] is bool
              ? 'boolean'
              : v['value'] is num
              ? 'number'
              : v['value'] == null
              ? 'null'
              : 'string',
        ),
      );
    }
    _all.addAll([..._targets, ..._selectors, ..._variables]);
  }

  @override
  void dispose() {
    for (final r in _all) {
      r.dispose();
    }
    for (final c in [_name, _entry, _origins, _tcName, _tcExpected, _tcId]) {
      c.dispose();
    }
    super.dispose();
  }

  void _add(List<_MappingRow> rows, String kind) {
    final row = _MappingRow('', '', kind);
    setState(() {
      rows.add(row);
      _all.add(row);
    });
  }

  Map<String, dynamic> _map(
    List<_MappingRow> rows,
    dynamic Function(_MappingRow) convert,
  ) {
    final out = <String, dynamic>{};
    for (final r in rows) {
      if (!RegExp(r'^[A-Za-z][A-Za-z0-9_.-]{0,127}$').hasMatch(r.name.text) ||
          out.containsKey(r.name.text)) {
        throw const FormatException();
      }
      out[r.name.text] = convert(r);
    }
    return out;
  }

  void _save() {
    try {
      final b =
          jsonDecode(jsonEncode(widget.blueprint)) as Map<String, dynamic>;
      b['name'] = _name.text;
      b['flow']['entryNode'] = _entry.text;
      b['target']['launchTargets'] = _map(_targets, (r) => r.content.text);
      b['target']['platform'] = _platform;
      b['target']['allowedOrigins'] = _origins.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      b['selectors']['selectors'] = _map(
        _selectors,
        (r) => {
          ...?(_locators[r.name.text] as Map<String, dynamic>?),
          _platform: {
            'strategy': r.kind,
            'value': r.content.text,
            if (_platform == 'web' && r.detail.text.isNotEmpty)
              'name': r.detail.text,
          },
        },
      );
      b['flow']['variables'] = _map(
        _variables,
        (r) => r.kind == 'secretRef'
            ? {'from': 'secret', 'ref': r.content.text}
            : r.kind == 'publicCapture'
            ? {'from': 'capture', 'public': true}
            : {
                'from': 'literal',
                'value': r.kind == 'number'
                    ? num.parse(r.content.text)
                    : r.kind == 'boolean'
                    ? (r.content.text == 'true'
                          ? true
                          : r.content.text == 'false'
                          ? false
                          : throw const FormatException())
                    : r.kind == 'null'
                    ? null
                    : r.content.text,
              },
      );
      if (_tc) {
        b['testCase'] = {
          ...?(b['testCase'] as Map<String, dynamic>?),
          'schemaVersion': 'qa.testcase/v1',
          'id': _tcId.text,
          'name': _tcName.text,
          'flowRef': b['flow']['id'],
          'expected': _tcExpected.text,
          'prerequisites': b['testCase']?['prerequisites'] ?? [],
          'platforms': [_platform],
        };
      } else {
        b.remove('testCase');
      }
      Navigator.pop(context, b);
    } catch (_) {
      setState(() => _error = '별칭 중복·빈 ID·수치/boolean 입력을 확인하세요.');
    }
  }

  Widget _rows(
    String title,
    List<_MappingRow> rows,
    List<String> kinds,
    String defaultKind,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      for (final r in rows)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: r.name,
                decoration: const InputDecoration(labelText: '별칭'),
              ),
            ),
            if (kinds.isNotEmpty)
              DropdownButton<String>(
                value: kinds.contains(r.kind) ? r.kind : null,
                items: kinds
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => r.kind = v!),
              ),
            Expanded(
              flex: 2,
              child: TextField(
                controller: r.content,
                decoration: const InputDecoration(
                  labelText: '값 / URL / secretRef',
                ),
              ),
            ),
            if (identical(rows, _selectors))
              Expanded(
                child: TextField(
                  controller: r.detail,
                  decoration: const InputDecoration(
                    labelText: 'role name (선택)',
                  ),
                ),
              ),
            IconButton(
              tooltip: '행 삭제',
              onPressed: () => setState(() => rows.remove(r)),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      TextButton(
        onPressed: () => _add(rows, defaultKind),
        child: Text('$title 추가'),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('대상 · 선택자 · 변수 · TestCase'),
    content: SizedBox(
      width: 850,
      height: math.min(
        580,
        math.max(120, MediaQuery.sizeOf(context).height - 190),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '시나리오 이름'),
            ),
            TextField(
              controller: _entry,
              decoration: const InputDecoration(labelText: '시작 노드 ID'),
            ),
            DropdownButton<String>(
              value: widget.platformStrategies.containsKey(_platform)
                  ? _platform
                  : null,
              hint: Text('대상: $_platform'),
              items: widget.platformStrategies.keys
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (value) => _selectPlatform(value!),
            ),
            const Text(
              '대상 변경 시 해당 플랫폼의 선택자를 다시 입력하세요. web은 URL, android/ios는 설치된 앱 ID입니다. Appium 기기 설정은 실행 패널의 로컬 JSON 경로로 분리합니다.',
            ),
            _rows('실행 대상', _targets, [], 'url'),
            TextField(
              controller: _origins,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '허용 origin (한 줄씩)'),
            ),
            _rows(
              '선택자',
              _selectors,
              _strategies,
              _strategies.firstOrNull ?? '',
            ),
            _rows('변수', _variables, [
              'string',
              'number',
              'boolean',
              'null',
              'secretRef',
              'publicCapture',
            ], 'string'),
            const Text(
              'publicCapture는 공개 DOM 값임을 작성자가 명시하는 선언입니다. 모든 개인정보를 자동 판별하지 않습니다. secret 변수와 혼합할 수 없으며 실제 캡처값은 기록에 저장하지 않습니다.',
            ),
            CheckboxListTile(
              value: _tc,
              onChanged: (v) => setState(() => _tc = v!),
              title: const Text('TestCase 정의 포함'),
            ),
            if (_tc) ...[
              TextField(
                controller: _tcId,
                decoration: const InputDecoration(labelText: 'TestCase ID'),
              ),
              TextField(
                controller: _tcName,
                decoration: const InputDecoration(labelText: 'TestCase 이름'),
              ),
              TextField(
                controller: _tcExpected,
                decoration: const InputDecoration(labelText: '기대 결과'),
              ),
            ],
            if (_error != null) Text(_error!),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(onPressed: _save, child: const Text('설정 적용')),
    ],
  );
}
