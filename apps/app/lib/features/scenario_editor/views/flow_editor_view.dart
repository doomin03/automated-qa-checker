import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/flow_editor_view_model.dart';
import '../../run_review/view_models/run_view_model.dart';
import 'flow_forms.dart';

class FlowEditorView extends StatefulWidget {
  const FlowEditorView({
    required this.loadSource,
    required this.loadPlan,
    required this.applyFlow,
    required this.canLoadPlan,
    this.onSelected,
    super.key,
  });
  final VoidCallback loadSource, loadPlan, applyFlow;
  final bool canLoadPlan;
  final ValueChanged<String?>? onSelected;
  @override
  State<FlowEditorView> createState() => _FlowEditorViewState();
}

class _FlowEditorViewState extends State<FlowEditorView> {
  String? _selected;
  String? _from;
  String? _to;
  String _label = '';
  String? _error;
  bool _showRun = false;
  final Map<String, Offset> _drag = {};
  final Map<String, Offset> _dragOrigins = {};
  Future<void> _nodeForm(
    FlowEditorViewModel vm,
    Map<String, dynamic> node,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => NodeForm(node: node, editor: vm),
    );
    if (mounted && result != null) vm.updateNode(node['id'], result);
  }

  Future<void> _targetForm(
    FlowEditorViewModel vm,
    Map<String, dynamic> blueprint,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => TargetForm(
        blueprint: blueprint,
        strategies: vm.locatorStrategies,
        platformStrategies: vm.platformStrategies,
      ),
    );
    if (mounted && result != null) vm.settings(result);
  }

  Future<void> _settings(
    String title,
    Map<String, dynamic> value,
    void Function(Map<String, dynamic>) apply,
  ) async {
    final controller = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(value),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 700,
          height: 400,
          child: TextField(
            key: const Key('flow-settings-json'),
            controller: controller,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('설정 적용'),
          ),
        ],
      ),
    );
    // Dialog route finishes its exit animation before its controller is released.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (!mounted || result == null) return;
    try {
      apply(jsonDecode(result) as Map<String, dynamic>);
      setState(() => _error = null);
    } catch (_) {
      setState(() => _error = '올바른 JSON 객체를 입력하세요.');
    }
  }

  Offset _position(Map<String, dynamic> b, String id, int index) {
    final raw = b['flow']['metadata']?['presentation']?['positions']?[id];
    return _drag[id] ??
        (raw is Map && raw['x'] is num && raw['y'] is num
            ? Offset(
                (raw['x'] as num).toDouble().clamp(0, 1000000),
                (raw['y'] as num).toDouble().clamp(0, 1000000),
              )
            : Offset(24 + (index % 5) * 280, 30 + (index ~/ 5) * 160));
  }

  @override
  Widget build(BuildContext context) => Consumer<FlowEditorViewModel>(
    builder: (context, vm, _) {
      final run = context.watch<RunViewModel>();
      final b = _showRun && run.plan != null
          ? run.plan!['blueprint'] as Map<String, dynamic>
          : vm.blueprint;
      final nodes = List<Map<String, dynamic>>.from(b?['flow']['nodes'] ?? []);
      final edges = List<Map<String, dynamic>>.from(b?['flow']['edges'] ?? []);
      final ids = nodes.map((n) => n['id'] as String).toList();
      final positions = {
        for (var i = 0; i < nodes.length; i++)
          nodes[i]['id'] as String: _position(b!, nodes[i]['id'], i),
      };
      final canvasWidth = positions.values.fold<double>(
        1600,
        (width, position) => math.max(width, position.dx + 180),
      );
      final canvasHeight = positions.values.fold<double>(
        1000,
        (height, position) => math.max(height, position.dy + 120),
      );
      final selected = nodes.where((n) => n['id'] == _selected).firstOrNull;
      final matches =
          b != null && jsonEncode(b) == jsonEncode(run.plan?['blueprint']);
      final states = {for (final id in ids) id: 'pending'};
      if (matches) {
        for (final event in run.events) {
          if (event['type'] == 'step.started') {
            states[event['nodeId']] = 'running';
          }
          if (event['type'] == 'step.finished') {
            states[event['nodeId']] = event['outcome'];
          }
        }
        if (run.result != null) {
          for (final id in run.result!['unvisitedNodes'] as List) {
            states[id] = 'unrun';
          }
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (run.plan != null)
            SwitchListTile(
              title: const Text('실행 snapshot 보기 (읽기 전용)'),
              value: _showRun,
              onChanged: (v) => setState(() {
                _showRun = v;
                _drag.clear();
                _dragOrigins.clear();
              }),
            ),
          if (run.events.isNotEmpty && !matches)
            const Text(
              '편집 Flow가 실행 snapshot과 다릅니다. 실행 snapshot 보기에서 진행을 확인하세요.',
            ),
          if (!_showRun)
            Wrap(
              spacing: 6,
              children: [
                TextButton(
                  onPressed: vm.nodeTypes.isEmpty ? null : () => vm.create(),
                  child: const Text('공개 예제로 새 Flow'),
                ),
                TextButton(
                  onPressed: widget.loadSource,
                  child: const Text('JSON 초안 불러오기'),
                ),
                TextButton(
                  onPressed: widget.canLoadPlan ? widget.loadPlan : null,
                  child: const Text('검증 계획에서 불러오기'),
                ),
                TextButton(
                  onPressed: b == null ? null : widget.applyFlow,
                  child: const Text('Flow를 원문에 적용'),
                ),
                IconButton(
                  tooltip: '되돌리기',
                  onPressed: vm.canUndo ? vm.undo : null,
                  icon: const Icon(Icons.undo),
                ),
                IconButton(
                  tooltip: '다시 실행',
                  onPressed: vm.canRedo ? vm.redo : null,
                  icon: const Icon(Icons.redo),
                ),
              ],
            ),
          if (_error != null || vm.error != null)
            Text(
              _error ?? vm.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (b != null) ...[
            if (!_showRun)
              Wrap(
                spacing: 6,
                children: [
                  for (final type in vm.nodeTypes)
                    OutlinedButton(
                      onPressed: () {
                        vm.addNode(type);
                        if (vm.nodes.isNotEmpty) _nodeForm(vm, vm.nodes.last);
                      },
                      child: Text('+ $type'),
                    ),
                  TextButton(
                    onPressed: () => _targetForm(vm, b),
                    child: const Text('대상·선택자·TC 설정'),
                  ),
                  if (selected != null)
                    TextButton(
                      onPressed: () => _nodeForm(vm, selected),
                      child: const Text('노드 설정'),
                    ),
                  if (selected != null)
                    TextButton(
                      onPressed: () => _settings(
                        '고급 노드 JSON',
                        selected,
                        (n) => vm.updateNode(_selected!, n),
                      ),
                      child: const Text('고급 JSON'),
                    ),
                  if (selected != null)
                    TextButton(
                      onPressed: () => vm.removeNode(_selected!),
                      child: const Text('노드 삭제'),
                    ),
                ],
              ),
            Text('공개 지원 액션: ${vm.actions.join(', ')}'),
            if (!_showRun)
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String>(
                    hint: const Text('from'),
                    value: ids.contains(_from) ? _from : null,
                    items: ids
                        .map(
                          (id) => DropdownMenuItem(value: id, child: Text(id)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _from = v),
                  ),
                  DropdownButton<String>(
                    hint: const Text('to'),
                    value: ids.contains(_to) ? _to : null,
                    items: ids
                        .map(
                          (id) => DropdownMenuItem(value: id, child: Text(id)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _to = v),
                  ),
                  DropdownButton<String>(
                    value: _label,
                    items: ['', 'true', 'false']
                        .map(
                          (label) => DropdownMenuItem(
                            value: label,
                            child: Text(label.isEmpty ? '일반 연결' : label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _label = v!),
                  ),
                  TextButton(
                    onPressed: ids.contains(_from) && ids.contains(_to)
                        ? () => vm.connect(_from!, _to!, _label)
                        : null,
                    child: const Text('연결 추가'),
                  ),
                ],
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: _drag.isNotEmpty
                    ? const NeverScrollableScrollPhysics()
                    : null,
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  physics: _drag.isNotEmpty
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  child: SizedBox(
                    key: const Key('flow-canvas'),
                    width: canvasWidth,
                    height: canvasHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _EdgesPainter(edges, positions),
                          ),
                        ),
                        for (final node in nodes)
                          Positioned(
                            left: positions[node['id']]!.dx,
                            top: positions[node['id']]!.dy,
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              key: Key('flow-node-${node['id']}'),
                              onPointerDown: (event) => setState(() {
                                _selected = node['id'];
                                widget.onSelected?.call(_selected);
                                if (!_showRun) {
                                  _drag[node['id']] = positions[node['id']]!;
                                  _dragOrigins[node['id']] =
                                      positions[node['id']]!;
                                }
                              }),
                              onPointerMove: _showRun
                                  ? null
                                  : (event) => setState(
                                      () => _drag[node['id']] = Offset(
                                        (positions[node['id']]!.dx +
                                                event.delta.dx)
                                            .clamp(0, canvasWidth - 150),
                                        (positions[node['id']]!.dy +
                                                event.delta.dy)
                                            .clamp(0, canvasHeight - 100),
                                      ),
                                    ),
                              onPointerUp: (_) {
                                final pos = _drag.remove(node['id']);
                                final origin = _dragOrigins.remove(node['id']);
                                if (pos != null && pos != origin) {
                                  vm.move(node['id'], pos.dx, pos.dy);
                                }
                              },
                              onPointerCancel: (_) => setState(() {
                                _drag.remove(node['id']);
                                _dragOrigins.remove(node['id']);
                              }),
                              child: Container(
                                width: 140,
                                height: 80,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      matches && states[node['id']] == 'failed'
                                      ? Colors.red.shade100
                                      : matches &&
                                            states[node['id']] == 'passed'
                                      ? Colors.green.shade100
                                      : matches &&
                                            states[node['id']] == 'running'
                                      ? Colors.amber.shade100
                                      : _selected == node['id']
                                      ? Colors.lightBlue.shade100
                                      : Colors.grey.shade100,
                                  border: Border.all(),
                                ),
                                child: Text(
                                  '${node['id']}\n${node['type']} ${node['action'] ?? ''}\n${matches ? states[node['id']] : '편집'}',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < edges.length; i++)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: InputChip(
                        label: Text(
                          '${edges[i]['from']} → ${edges[i]['to']} ${edges[i]['label'] ?? ''}',
                        ),
                        onDeleted: _showRun ? null : () => vm.removeEdge(i),
                      ),
                    ),
                ],
              ),
            ),
          ] else
            const Expanded(
              child: Center(child: Text('예제로 생성하거나 검증한 XML의 실행계획을 불러오세요.')),
            ),
        ],
      );
    },
  );
}

class _EdgesPainter extends CustomPainter {
  _EdgesPainter(this.edges, this.positions);
  final List<Map<String, dynamic>> edges;
  final Map<String, Offset> positions;
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 2;
    for (final edge in edges) {
      final from = positions[edge['from']], to = positions[edge['to']];
      if (from == null || to == null) continue;
      final a = from + const Offset(140, 40), b = to + const Offset(0, 40);
      canvas.drawLine(a, b, pen);
      final direction = (a - b);
      final length = direction.distance;
      if (length > 0) {
        final unit = direction / length;
        final normal = Offset(-unit.dy, unit.dx);
        canvas.drawLine(b, b + unit * 12 + normal * 5, pen);
        canvas.drawLine(b, b + unit * 12 - normal * 5, pen);
      }
      final text = TextPainter(
        text: TextSpan(
          text: edge['label'] ?? '',
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, (a + b) / 2);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter oldDelegate) => true;
}
