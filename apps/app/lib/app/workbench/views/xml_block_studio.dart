import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../view_models/xml_block_workbench_view_model.dart';
import '../view_models/desktop_workspace_view_model.dart';
import '../../../features/xml_blocks/models/xml_block_document.dart';

class XmlBlockStudio extends StatefulWidget {
  const XmlBlockStudio({
    required this.importXml,
    required this.save,
    super.key,
  });
  final VoidCallback importXml;
  final VoidCallback save;
  @override
  State<XmlBlockStudio> createState() => _XmlBlockStudioState();
}

class _XmlBlockStudioState extends State<XmlBlockStudio> {
  final transform = TransformationController();
  final viewport = GlobalKey();
  final focus = FocusNode();
  final Map<String, Offset> dragPositions = {};
  String? dragging, wire, fittedIdentity;
  Offset? pointer;
  bool inspector = true;
  String tab = '속성';
  @override
  void dispose() {
    transform.dispose();
    focus.dispose();
    super.dispose();
  }

  void fit(Map<String, Offset> p) {
    final box = viewport.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || p.isEmpty) return;
    final x = p.values.map((v) => v.dx).reduce(math.min) - 36,
        y = p.values.map((v) => v.dy).reduce(math.min) - 36;
    final w = p.values.map((v) => v.dx + 230).reduce(math.max) + 36 - x,
        h = p.values.map((v) => v.dy + 125).reduce(math.max) + 36 - y;
    final s = math.min(box.size.width / w, box.size.height / h).clamp(.15, 1.0);
    transform.value = Matrix4.identity()
      ..translateByDouble(
        (box.size.width - w * s) / 2 - x * s,
        (box.size.height - h * s) / 2 - y * s,
        0,
        1,
      )
      ..scaleByDouble(s, s, 1, 1);
  }

  void inspect(XmlBlockAsset a) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${a.name} / 읽기 전용'),
        content: SizedBox(
          width: 850,
          height: 510,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'XML 원문'),
                    Tab(text: '내부 동작'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        child: SelectableText(
                          a.xml,
                          style: const TextStyle(
                            fontFamily: 'Consolas',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ListView(
                        children: [
                          for (final n in a.blueprint['flow']['nodes'])
                            ListTile(
                              dense: true,
                              title: Text(n['id']),
                              subtitle: Text(
                                '${n['type']} ${n['action'] ?? ''}',
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
        actions: [
          const Text(
            '원문 편집은 XML 직접 열기를 사용하세요.',
            style: TextStyle(fontSize: 12),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  void showLibrary(XmlBlockWorkbenchViewModel vm) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 400,
          height: 520,
          child: library(vm, dialog: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<XmlBlockWorkbenchViewModel>(),
        desktop = context.watch<DesktopWorkspaceViewModel>();
    final locked = vm.busy || desktop.work.run.running;
    final positions = {
      for (final n in vm.instances)
        n.id: dragPositions[n.id] ?? Offset(n.x, n.y),
    };
    final size = Size(
      positions.values.fold<double>(1000, (v, p) => math.max(v, p.dx + 300)),
      positions.values.fold<double>(600, (v, p) => math.max(v, p.dy + 200)),
    );
    final identity =
        '${vm.identity}/${vm.instances.map((n) => n.id).join(',')}';
    if (fittedIdentity != identity && positions.isNotEmpty) {
      fittedIdentity = identity;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) fit(positions);
      });
    }
    return Column(
      children: [
        Container(
          height: 32,
          color: const Color(0xff323232),
          child: Row(
            children: [
              TextButton(
                onPressed: () => showLibrary(vm),
                child: const Text('라이브러리'),
              ),
              TextButton(
                onPressed: () => fit(positions),
                child: const Text('전체 보기'),
              ),
              IconButton(
                tooltip: '축소',
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () {
                  transform.value = transform.value.clone()
                    ..scaleByDouble(.85, .85, 1, 1);
                },
              ),
              IconButton(
                tooltip: '확대',
                icon: const Icon(Icons.add, size: 16),
                onPressed: () {
                  transform.value = transform.value.clone()
                    ..scaleByDouble(1.18, 1.18, 1, 1);
                },
              ),
              const Spacer(),
              Text(
                '${vm.instances.length}개 파일 블록',
                style: const TextStyle(fontSize: 12),
              ),
              TextButton(
                onPressed: () => setState(() => inspector = !inspector),
                child: const Text('속성'),
              ),
            ],
          ),
        ),
        if (vm.error != null)
          Container(
            width: double.infinity,
            color: const Color(0xff473b32),
            padding: const EdgeInsets.all(8),
            child: Text(vm.error!, style: const TextStyle(fontSize: 12)),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) => Row(
              children: [
                tools(vm, locked, positions),
                if (c.maxWidth >= 1100)
                  SizedBox(
                    key: const Key('studio-library'),
                    width: 190,
                    child: library(vm),
                  ),
                Expanded(child: canvas(vm, locked, positions, size)),
                if (inspector && c.maxWidth >= 740)
                  SizedBox(
                    key: const Key('studio-inspector'),
                    width: 250,
                    child: properties(vm, locked),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget tools(
    XmlBlockWorkbenchViewModel vm,
    bool locked,
    Map<String, Offset> positions,
  ) => Container(
    width: 36,
    color: const Color(0xff292929),
    child: Column(
      children: [
        IconButton(
          tooltip: '선택 / 블록 이동',
          onPressed: () => focus.requestFocus(),
          icon: const Icon(Icons.near_me_outlined, size: 18),
        ),
        IconButton(
          tooltip: 'XML 가져오기',
          onPressed: locked ? null : widget.importXml,
          icon: const Icon(Icons.note_add_outlined, size: 18),
        ),
        IconButton(
          tooltip: '블록 삭제',
          onPressed: locked || vm.selected == null ? null : vm.removeSelected,
          icon: const Icon(Icons.delete_outline, size: 18),
        ),
        const Divider(),
        IconButton(
          tooltip: '전체 보기',
          onPressed: () => fit(positions),
          icon: const Icon(Icons.fit_screen, size: 18),
        ),
      ],
    ),
  );
  Widget library(
    XmlBlockWorkbenchViewModel vm, {
    bool dialog = false,
  }) => Material(
    color: const Color(0xff323232),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading('XML 라이브러리'),
        Padding(
          padding: const EdgeInsets.all(8),
          child: OutlinedButton(
            onPressed: vm.busy
                ? null
                : () {
                    if (dialog) Navigator.pop(context);
                    widget.importXml();
                  },
            child: const Text('XML 가져오기'),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final a in vm.assets)
                Draggable<String>(
                  data: a.id,
                  maxSimultaneousDrags: vm.busy ? 0 : 1,
                  feedback: Material(
                    color: const Color(0xff414141),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(a.name),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.description_outlined, size: 18),
                    title: Text(a.name, style: const TextStyle(fontSize: 12)),
                    subtitle: Text(
                      '${(a.blueprint['flow']['nodes'] as List).length}개 내부 동작',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () {
                      vm.add(a.id);
                      if (dialog) Navigator.pop(context);
                    },
                    onLongPress: () => inspect(a),
                  ),
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            '파일을 끌거나 클릭하여 배치',
            style: TextStyle(fontSize: 11, color: Color(0xffbcbcbc)),
          ),
        ),
        if (dialog)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
      ],
    ),
  );
  Widget canvas(
    XmlBlockWorkbenchViewModel vm,
    bool locked,
    Map<String, Offset> positions,
    Size size,
  ) {
    return Focus(
      key: const Key('studio-canvas-focus'),
      focusNode: focus,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent || locked) return KeyEventResult.ignored;
        final ctrl = HardwareKeyboard.instance.isControlPressed;
        if (ctrl && event.logicalKey == LogicalKeyboardKey.keyS) {
          widget.save();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.delete) {
          vm.removeSelected();
          return KeyEventResult.handled;
        }
        if (ctrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
          vm.undo();
          return KeyEventResult.handled;
        }
        if (ctrl && event.logicalKey == LogicalKeyboardKey.keyY) {
          vm.redo();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ClipRect(
        key: viewport,
        child: CustomPaint(
          painter: _ViewportGrid(),
          child: DragTarget<String>(
            onWillAcceptWithDetails: (_) => !locked,
            onAcceptWithDetails: (d) {
              final box =
                  viewport.currentContext!.findRenderObject() as RenderBox;
              final p = transform.toScene(box.globalToLocal(d.offset));
              vm.add(d.data, x: p.dx, y: p.dy);
            },
            builder: (context, candidates, rejected) {
              if (vm.instances.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_tree_outlined,
                        size: 40,
                        color: Color(0xff8ea8bd),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'XML 파일을 블록으로 배치',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '파일을 추가하고 실행 순서대로 연결하세요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xffbcbcbc),
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: widget.importXml,
                        child: const Text('XML 가져오기'),
                      ),
                    ],
                  ),
                );
              }
              return InteractiveViewer(
                key: const Key('xml-block-viewport'),
                transformationController: transform,
                constrained: false,
                minScale: .15,
                maxScale: 2.5,
                boundaryMargin: const EdgeInsets.all(600),
                panEnabled: dragging == null && wire == null,
                scaleEnabled: dragging == null && wire == null,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _BlockPainter(
                            positions,
                            vm.links,
                            wire,
                            pointer,
                          ),
                        ),
                      ),
                      for (final n in vm.instances)
                        Positioned(
                          left: positions[n.id]!.dx,
                          top: positions[n.id]!.dy,
                          child: node(vm, n, locked, positions),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget node(
    XmlBlockWorkbenchViewModel vm,
    XmlBlockInstance n,
    bool locked,
    Map<String, Offset> positions,
  ) {
    final a = vm.asset(n.assetId)!;
    return GestureDetector(
      onTap: () {
        focus.requestFocus();
        vm.select(n.id);
      },
      onDoubleTap: () => inspect(a),
      child: Container(
        key: Key('xml-block-${n.id}'),
        width: 230,
        height: 125,
        decoration: BoxDecoration(
          color: const Color(0xff323232),
          border: Border.all(
            color: vm.selected == n.id
                ? const Color(0xffc4d4df)
                : const Color(0xff646464),
            width: vm.selected == n.id ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          children: [
            GestureDetector(
              onPanStart: locked
                  ? null
                  : (d) {
                      focus.requestFocus();
                      vm.select(n.id);
                      setState(() => dragging = n.id);
                    },
              onPanUpdate: locked
                  ? null
                  : (d) {
                      setState(() {
                        dragPositions[n.id] =
                            (dragPositions[n.id] ?? positions[n.id]!) + d.delta;
                      });
                    },
              onPanEnd: locked
                  ? null
                  : (_) {
                      final p = dragPositions.remove(n.id) ?? positions[n.id]!;
                      vm.move(n.id, p.dx, p.dy);
                      setState(() => dragging = null);
                    },
              child: Container(
                height: 32,
                width: double.infinity,
                color: const Color(0xff4a5660),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  a.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Row(
                children: [
                  DragTarget<String>(
                    onWillAcceptWithDetails: (d) => !locked && d.data != n.id,
                    onAcceptWithDetails: (d) {
                      vm.connect(d.data, n.id);
                      setState(() {
                        wire = null;
                        pointer = null;
                      });
                    },
                    builder: (context, candidate, rejected) => Icon(
                      Icons.play_arrow_outlined,
                      key: Key('xml-pin-in-${n.id}'),
                      size: 21,
                      color: candidate.isEmpty
                          ? const Color(0xffdedede)
                          : Colors.white,
                    ),
                  ),
                  const Text('실행', style: TextStyle(fontSize: 11)),
                  const Spacer(),
                  const Text('완료', style: TextStyle(fontSize: 11)),
                  Draggable<String>(
                    data: n.id,
                    maxSimultaneousDrags: locked ? 0 : 1,
                    feedback: const SizedBox(width: 1, height: 1),
                    onDragStarted: () => setState(() => wire = n.id),
                    onDragUpdate: (d) {
                      final box =
                          viewport.currentContext!.findRenderObject()
                              as RenderBox;
                      setState(
                        () => pointer = transform.toScene(
                          box.globalToLocal(d.globalPosition),
                        ),
                      );
                    },
                    onDragEnd: (_) => setState(() {
                      wire = null;
                      pointer = null;
                    }),
                    child: Icon(
                      Icons.play_arrow_outlined,
                      key: Key('xml-pin-out-${n.id}'),
                      size: 21,
                      color: const Color(0xffdedede),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 13,
                    color: Color(0xffbcbcbc),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'XML / ${(a.blueprint['flow']['nodes'] as List).length}개 동작',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xffbcbcbc),
                      ),
                    ),
                  ),
                  Text(
                    n.id.replaceFirst('instance_', '#'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xffbcbcbc),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              height: 19,
              color: const Color(0xff292929),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                vm.current ? '조합 검증됨' : '조합 필요',
                style: const TextStyle(fontSize: 10, color: Color(0xffbcbcbc)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget properties(XmlBlockWorkbenchViewModel vm, bool locked) {
    final selected = vm.selectedInstance,
        a = selected == null ? null : vm.asset(selected.assetId);
    Widget body;
    if (tab == '이력') {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final h in vm.history.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(h, style: const TextStyle(fontSize: 12)),
            ),
        ],
      );
    } else if (tab == '구조') {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final n in vm.instances)
            TextButton(
              onPressed: () => vm.select(n.id),
              child: Text('${n.id}  ${vm.asset(n.assetId)?.name}'),
            ),
          const Divider(),
          for (final e in vm.links)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${e.from} → ${e.to}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                IconButton(
                  tooltip: '연결 삭제',
                  onPressed: locked ? null : () => vm.disconnect(e.from, e.to),
                  icon: const Icon(Icons.close, size: 15),
                ),
              ],
            ),
        ],
      );
    } else if (a == null) {
      body = const Text(
        '블록을 선택하세요.',
        style: TextStyle(fontSize: 12, color: Color(0xffbcbcbc)),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            a.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          property(
            '내부 동작',
            '${(a.blueprint['flow']['nodes'] as List).length}개 노드',
          ),
          property('실행 대상', a.blueprint['target']['platform']),
          property('인스턴스', selected!.id),
          Tooltip(
            message: a.path,
            child: Text(
              a.path,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontSize: 11, color: Color(0xffbcbcbc)),
            ),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('파일 상세', style: TextStyle(fontSize: 12)),
            children: [property('원문 해시', a.hash), property('원문 경로', a.path)],
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => inspect(a),
            child: const Text('블록 내용 확인'),
          ),
          const SizedBox(height: 10),
          const Text(
            '하나의 실행 세션으로 조합됩니다.',
            style: TextStyle(fontSize: 11, color: Color(0xffbcbcbc)),
          ),
          const Divider(),
          TextButton(
            onPressed: locked ? null : vm.removeSelected,
            child: const Text('블록 삭제'),
          ),
        ],
      );
    }
    return Material(
      color: const Color(0xff323232),
      child: Column(
        children: [
          Row(
            children: [
              for (final t in ['속성', '구조', '이력'])
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => tab = t),
                    style: TextButton.styleFrom(
                      backgroundColor: tab == t
                          ? const Color(0xff414141)
                          : Colors.transparent,
                    ),
                    child: Text(t),
                  ),
                ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: body,
            ),
          ),
        ],
      ),
    );
  }

  Widget heading(String value) => Container(
    height: 33,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xff505050))),
    ),
    child: Text(value, style: const TextStyle(fontSize: 13)),
  );
  Widget property(String name, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 11, color: Color(0xffbcbcbc)),
        ),
        const SizedBox(height: 3),
        SelectableText(value, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

class _BlockPainter extends CustomPainter {
  _BlockPainter(this.positions, this.edges, this.from, this.pointer);
  final Map<String, Offset> positions;
  final List<XmlBlockLink> edges;
  final String? from;
  final Offset? pointer;
  @override
  void paint(Canvas canvas, Size size) {
    void wire(Offset a, Offset b) {
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx + 90, a.dy, b.dx - 90, b.dy, b.dx, b.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xffc1c8ce)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    for (final e in edges) {
      final a = positions[e.from], b = positions[e.to];
      if (a != null && b != null) {
        wire(a + const Offset(210, 53), b + const Offset(20, 53));
      }
    }
    if (from != null && pointer != null && positions[from] != null) {
      wire(positions[from]! + const Offset(210, 53), pointer!);
    }
  }

  @override
  bool shouldRepaint(covariant _BlockPainter old) => true;
}

class _ViewportGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff1c1c1c),
    );
    final paint = Paint()
      ..color = const Color(0xff303030)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ViewportGrid old) => false;
}
