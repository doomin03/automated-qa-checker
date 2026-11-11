import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/desktop_workspace_view_model.dart';
import '../view_models/canvas_layout_view_model.dart';
import '../../../features/scenario_editor/views/flow_forms.dart';

class BlueprintWorkspace extends StatefulWidget {
  const BlueprintWorkspace({super.key});
  @override
  State<BlueprintWorkspace> createState() => _BlueprintWorkspaceState();
}

class _BlueprintWorkspaceState extends State<BlueprintWorkspace> {
  final _transform = TransformationController();
  final _viewport = GlobalKey();
  String? _dragging, _wireFrom, _wireLabel;
  Offset? _wireEnd;
  final Map<String, Offset> _drag = {};
  bool _properties = true, _runSnapshot = false;
  String? _fitIdentity;
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _fit(Size canvas, Size viewport) {
    final scale = math
        .min(viewport.width / canvas.width, viewport.height / canvas.height)
        .clamp(.02, 1.0);
    _transform.value = Matrix4.identity()..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = context.watch<DesktopWorkspaceViewModel>(),
        layout = context.watch<CanvasLayoutViewModel>();
    final flow = desktop.work.flow, run = desktop.work.run;
    final b = _runSnapshot
        ? (run.plan?['blueprint'] as Map<String, dynamic>?)
        : flow.blueprint;
    final nodes = List<Map<String, dynamic>>.from(b?['flow']['nodes'] ?? []),
        edges = List<Map<String, dynamic>>.from(b?['flow']['edges'] ?? []);
    final positions = {
      for (var i = 0; i < nodes.length; i++)
        nodes[i]['id'] as String:
            _drag[nodes[i]['id']] ?? layout.position(b!, nodes[i]['id'], i),
    };
    final size = Size(
      positions.values.fold<double>(1100, (v, p) => math.max(v, p.dx + 260)),
      positions.values.fold<double>(650, (v, p) => math.max(v, p.dy + 180)),
    );
    final fitIdentity =
        '${desktop.workspace.qaId}/${nodes.map((n) => n['id']).join('/')}';
    if (nodes.isNotEmpty && _fitIdentity != fitIdentity) {
      _fitIdentity = fitIdentity;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final box = _viewport.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) _fit(size, box.size);
      });
    }
    final selected = nodes
        .where((n) => n['id'] == desktop.selectedNode)
        .firstOrNull;
    final matches =
        b != null && jsonEncode(b) == jsonEncode(run.plan?['blueprint']);
    final states = <String, String>{};
    if (matches) {
      for (final e in run.events) {
        if (e['type'] == 'step.started') states[e['nodeId']] = 'running';
        if (e['type'] == 'step.finished') states[e['nodeId']] = e['outcome'];
      }
      for (final id in run.result?['unvisitedNodes'] ?? []) {
        states[id] = 'unrun';
      }
    }
    final readonly = _runSnapshot || run.running;
    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xff181c22),
        visualDensity: VisualDensity.compact,
      ),
      child: Builder(
        builder: (context) => Column(
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  PopupMenuButton<String>(
                    tooltip: '블록 추가',
                    enabled: !readonly,
                    onSelected: (type) => flow.addNode(type),
                    itemBuilder: (_) => [
                      for (final type in flow.nodeTypes)
                        PopupMenuItem(value: type, child: Text('+ $type')),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('+ 블록'),
                    ),
                  ),
                  TextButton(
                    onPressed: readonly ? null : desktop.applyFlow,
                    child: Text(flow.isDirty ? 'Flow 적용 *' : 'Flow 적용'),
                  ),
                  TextButton(
                    onPressed: readonly || !flow.canUndo ? null : flow.undo,
                    child: const Text('되돌리기'),
                  ),
                  TextButton(
                    onPressed: () {
                      final box =
                          _viewport.currentContext?.findRenderObject()
                              as RenderBox?;
                      if (box != null) _fit(size, box.size);
                    },
                    child: const Text('전체 보기'),
                  ),
                  if (run.plan != null)
                    TextButton(
                      onPressed: () =>
                          setState(() => _runSnapshot = !_runSnapshot),
                      child: Text(_runSnapshot ? '편집 보기' : '실행 snapshot'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _properties = !_properties),
                    child: const Text('속성'),
                  ),
                ],
              ),
            ),
            if (flow.error != null || layout.error != null)
              Text(
                flow.error ?? layout.error!,
                style: const TextStyle(color: Colors.orange),
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ClipRect(
                      key: _viewport,
                      child: ColoredBox(
                        color: const Color(0xff161a20),
                        child: b == null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('문서를 검증하면 Blueprint가 표시됩니다.'),
                                    TextButton(
                                      onPressed: desktop.busy
                                          ? null
                                          : desktop.validate,
                                      child: const Text('검증하여 그래프 열기'),
                                    ),
                                  ],
                                ),
                              )
                            : InteractiveViewer(
                                key: const Key('blueprint-viewport'),
                                transformationController: _transform,
                                constrained: false,
                                minScale: .02,
                                maxScale: 2.5,
                                boundaryMargin: const EdgeInsets.all(500),
                                panEnabled:
                                    _dragging == null && _wireFrom == null,
                                scaleEnabled:
                                    _dragging == null && _wireFrom == null,
                                child: SizedBox(
                                  key: const Key('blueprint-canvas'),
                                  width: size.width,
                                  height: size.height,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: _BlueprintPainter(
                                            positions,
                                            edges,
                                            nodes,
                                            _wireFrom,
                                            _wireLabel,
                                            _wireEnd,
                                          ),
                                        ),
                                      ),
                                      for (final node in nodes)
                                        Positioned(
                                          left: positions[node['id']]!.dx,
                                          top: positions[node['id']]!.dy,
                                          child: Container(
                                            width: 200,
                                            height: 112,
                                            decoration: BoxDecoration(
                                              color: const Color(0xff262d37),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                color:
                                                    desktop.selectedNode ==
                                                        node['id']
                                                    ? const Color(0xff70b7ff)
                                                    : const Color(0xff536171),
                                                width:
                                                    desktop.selectedNode ==
                                                        node['id']
                                                    ? 2
                                                    : 1,
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                GestureDetector(
                                                  key: Key(
                                                    'blueprint-node-${node['id']}',
                                                  ),
                                                  onTap: () => desktop
                                                      .selectNode(node['id']),
                                                  onPanStart: readonly
                                                      ? null
                                                      : (_) {
                                                          desktop.selectNode(
                                                            node['id'],
                                                          );
                                                          setState(
                                                            () => _dragging =
                                                                node['id'],
                                                          );
                                                        },
                                                  onPanUpdate: readonly
                                                      ? null
                                                      : (e) {
                                                          setState(
                                                            () => _drag[node['id']] =
                                                                positions[node['id']]! +
                                                                e.delta,
                                                          );
                                                        },
                                                  onPanEnd: readonly
                                                      ? null
                                                      : (_) {
                                                          final point = _drag
                                                              .remove(
                                                                node['id'],
                                                              );
                                                          if (point != null) {
                                                            layout.move(
                                                              node['id'],
                                                              point,
                                                            );
                                                          }
                                                          setState(
                                                            () => _dragging =
                                                                null,
                                                          );
                                                        },
                                                  child: Container(
                                                    height: 32,
                                                    width: 200,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          node['type'] ==
                                                              'branch'
                                                          ? const Color(
                                                              0xff775c31,
                                                            )
                                                          : node['type'] ==
                                                                'assertion'
                                                          ? const Color(
                                                              0xff405774,
                                                            )
                                                          : const Color(
                                                              0xff384c61,
                                                            ),
                                                      borderRadius:
                                                          const BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${node['type']} · ${node['id']}',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      if (node['type'] !=
                                                          'start')
                                                        DragTarget<String>(
                                                          onWillAcceptWithDetails:
                                                              (d) =>
                                                                  !readonly &&
                                                                  d.data !=
                                                                      node['id'],
                                                          onAcceptWithDetails:
                                                              (d) {
                                                                flow.connect(
                                                                  d.data,
                                                                  node['id'],
                                                                  _wireLabel ??
                                                                      '',
                                                                );
                                                                setState(() {
                                                                  _wireFrom =
                                                                      null;
                                                                  _wireEnd =
                                                                      null;
                                                                });
                                                              },
                                                          builder:
                                                              (
                                                                context,
                                                                c,
                                                                r,
                                                              ) => Container(
                                                                key: Key(
                                                                  'pin-in-${node['id']}',
                                                                ),
                                                                width: 24,
                                                                height: 60,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Icon(
                                                                  Icons.circle,
                                                                  size: 12,
                                                                  color:
                                                                      c.isEmpty
                                                                      ? Colors
                                                                            .white70
                                                                      : Colors
                                                                            .lightBlue,
                                                                ),
                                                              ),
                                                        ),
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                6,
                                                              ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                '${node['action'] ?? node['condition']?['variable'] ?? node['type']}',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              const SizedBox(
                                                                height: 8,
                                                              ),
                                                              Text(
                                                                states[node['id']] ??
                                                                    '미실행',
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color:
                                                                      states[node['id']] ==
                                                                          'passed'
                                                                      ? Colors
                                                                            .lightGreen
                                                                      : states[node['id']] == 'failed'
                                                                      ? Colors
                                                                            .redAccent
                                                                      : states[node['id']] == 'running'
                                                                      ? Colors
                                                                            .amber
                                                                      : Colors
                                                                            .white54,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      if (node['type'] != 'end')
                                                        Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            for (final label
                                                                in node['type'] ==
                                                                        'branch'
                                                                    ? [
                                                                        'true',
                                                                        'false',
                                                                      ]
                                                                    : [''])
                                                              Draggable<String>(
                                                                data:
                                                                    node['id'],
                                                                maxSimultaneousDrags:
                                                                    readonly
                                                                    ? 0
                                                                    : 1,
                                                                feedback: const Icon(
                                                                  Icons.circle,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .lightBlue,
                                                                ),
                                                                onDragStarted:
                                                                    () => setState(() {
                                                                      _wireFrom =
                                                                          node['id'];
                                                                      _wireLabel =
                                                                          label;
                                                                    }),
                                                                onDragUpdate: (d) {
                                                                  final box =
                                                                      _viewport
                                                                              .currentContext
                                                                              ?.findRenderObject()
                                                                          as RenderBox?;
                                                                  if (box !=
                                                                      null) {
                                                                    setState(
                                                                      () => _wireEnd = _transform.toScene(
                                                                        box.globalToLocal(
                                                                          d.globalPosition,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                },
                                                                onDragEnd: (_) =>
                                                                    setState(() {
                                                                      _wireFrom =
                                                                          null;
                                                                      _wireEnd =
                                                                          null;
                                                                    }),
                                                                child: Container(
                                                                  key: Key(
                                                                    'pin-out-${node['id']}-$label',
                                                                  ),
                                                                  height: 30,
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            5,
                                                                      ),
                                                                  child: Row(
                                                                    children: [
                                                                      if (label
                                                                          .isNotEmpty)
                                                                        Text(
                                                                          label,
                                                                          style: const TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                          ),
                                                                        ),
                                                                      const SizedBox(
                                                                        width:
                                                                            4,
                                                                      ),
                                                                      const Icon(
                                                                        Icons
                                                                            .circle,
                                                                        size:
                                                                            12,
                                                                        color: Colors
                                                                            .lightBlue,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (_properties)
                    SizedBox(
                      width: 270,
                      child: Material(
                        color: const Color(0xff20252c),
                        child: selected == null
                            ? SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('블록을 선택하여 속성을 편집하세요.'),
                                      const SizedBox(height: 16),
                                      Text(
                                        '${nodes.length} blocks · ${edges.length} connections',
                                      ),
                                      if (b != null)
                                        TextButton(
                                          onPressed: readonly
                                              ? null
                                              : () async {
                                                  final result =
                                                      await showDialog<
                                                        Map<String, dynamic>
                                                      >(
                                                        context: context,
                                                        builder: (_) => TargetForm(
                                                          blueprint: b,
                                                          strategies: flow
                                                              .locatorStrategies,
                                                          platformStrategies: flow
                                                              .platformStrategies,
                                                        ),
                                                      );
                                                  if (result != null &&
                                                      mounted) {
                                                    flow.settings(result);
                                                  }
                                                },
                                          child: const Text('대상 / 선택자 설정'),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: AbsorbPointer(
                                      absorbing: readonly,
                                      child: NodeForm(
                                        key: ValueKey(
                                          '${desktop.workspace.qaId}/${selected['id']}/${jsonEncode(selected)}',
                                        ),
                                        node: selected,
                                        editor: flow,
                                        onSaved: (n) =>
                                            flow.updateNode(selected['id'], n),
                                      ),
                                    ),
                                  ),
                                  if (!readonly)
                                    TextButton(
                                      onPressed: () =>
                                          flow.removeNode(selected['id']),
                                      child: const Text('블록 삭제'),
                                    ),
                                  SizedBox(
                                    height: 90,
                                    child: ListView(
                                      children: [
                                        for (var i = 0; i < edges.length; i++)
                                          if (edges[i]['from'] ==
                                                  selected['id'] ||
                                              edges[i]['to'] == selected['id'])
                                            ListTile(
                                              dense: true,
                                              title: Text(
                                                '${edges[i]['from']} → ${edges[i]['to']} ${edges[i]['label'] ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                              trailing: readonly
                                                  ? null
                                                  : IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                        size: 14,
                                                      ),
                                                      onPressed: () =>
                                                          flow.removeEdge(i),
                                                    ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  _BlueprintPainter(
    this.positions,
    this.edges,
    this.nodes,
    this.from,
    this.label,
    this.pointer,
  );
  final Map<String, Offset> positions;
  final List<Map<String, dynamic>> edges, nodes;
  final String? from, label;
  final Offset? pointer;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xff252b33)
      ..strokeWidth = .7;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    void wire(String id, String? tag, Offset end) {
      final start = positions[id];
      if (start == null) return;
      final branch = nodes.any((n) => n['id'] == id && n['type'] == 'branch');
      final a = start + Offset(200, branch ? (tag == 'false' ? 86 : 56) : 72);
      final distance = math.max(70, (end.dx - a.dx).abs() * .5);
      final pen = Paint()
        ..color = tag == 'false'
            ? const Color(0xffc78e64)
            : const Color(0xff6f9fbe)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..cubicTo(
            a.dx + distance,
            a.dy,
            math.max(12, end.dx - distance),
            end.dy,
            end.dx,
            end.dy,
          ),
        pen,
      );
    }

    for (final edge in edges) {
      final end = positions[edge['to']];
      if (end != null) {
        wire(edge['from'], edge['label'], end + const Offset(0, 72));
      }
    }
    if (from != null && pointer != null) wire(from!, label, pointer!);
  }

  @override
  bool shouldRepaint(covariant _BlueprintPainter old) => true;
}
