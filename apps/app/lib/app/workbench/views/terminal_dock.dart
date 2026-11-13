import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm2/xterm.dart';

import '../../../features/interactive_terminal/models/terminal_profile.dart';
import '../view_models/terminal_workbench_view_model.dart';
import '../view_models/terminal_session_view_model.dart';
import 'adaptive_workbench.dart';
import 'terminal_readiness_dialog.dart';
import '../../../features/interactive_terminal/view_models/terminal_readiness_view_model.dart';

class _SessionScrollController extends ScrollController {
  double? _detachedOffset;
  bool _disposed = false;
  @override
  void detach(ScrollPosition position) {
    _detachedOffset = position.pixels;
    super.detach(position);
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    final offset = _detachedOffset;
    if (offset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed &&
            positions.contains(position) &&
            position.hasContentDimensions) {
          position.jumpTo(
            offset.clamp(position.minScrollExtent, position.maxScrollExtent),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _PaneHandles {
  _PaneHandles({TerminalController? controller, ScrollController? scroll})
    : controller = controller ?? TerminalController(),
      scroll = scroll ?? _SessionScrollController(),
      ownsController = controller == null,
      ownsScroll = scroll == null;
  final TerminalController controller;
  final ScrollController scroll;
  final focus = FocusNode();
  final bool ownsController, ownsScroll;
  void dispose() {
    focus.dispose();
    if (ownsController) controller.dispose();
    if (ownsScroll) scroll.dispose();
  }
}

class TerminalDock extends StatefulWidget {
  const TerminalDock({
    this.collapsed = false,
    this.onOpen,
    this.maxHeight = 280,
    this.inDialog = false,
    this.controller,
    this.scrollController,
    this.onOpenQa,
    this.onDirectDocument,
    super.key,
  }) : _shared = null;
  const TerminalDock._dialog(
    this._shared, {
    required this.maxHeight,
    this.onOpenQa,
    this.onDirectDocument,
  }) : inDialog = true,
       collapsed = false,
       onOpen = null,
       controller = null,
       scrollController = null;
  final bool collapsed, inDialog;
  final VoidCallback? onOpen;
  final Future<void> Function(String identity)? onOpenQa;
  final Future<void> Function()? onDirectDocument;
  final double maxHeight;
  final TerminalController? controller;
  final ScrollController? scrollController;
  final Map<String, _PaneHandles>? _shared;
  @override
  State<TerminalDock> createState() => _TerminalDockState();
}

class _TerminalDockState extends State<TerminalDock> {
  late final _handles = widget._shared ?? <String, _PaneHandles>{};
  bool _open = false, _maximized = false, _dialogOpen = false;
  double _height = 240;
  @override
  void initState() {
    super.initState();
    _open = widget.inDialog;
  }

  @override
  void dispose() {
    if (widget._shared == null) {
      for (final h in _handles.values) {
        h.dispose();
      }
    }
    super.dispose();
  }

  _PaneHandles _handle(String id) => _handles.putIfAbsent(
    id,
    () => _PaneHandles(
      controller: _handles.isEmpty ? widget.controller : null,
      scroll: _handles.isEmpty ? widget.scrollController : null,
    ),
  );
  Future<void> _showPanel() async {
    if (_dialogOpen) return;
    setState(() {
      _open = false;
      _dialogOpen = true;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: WorkbenchDialogBody(
          width: 1200,
          height: 720,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('터미널 · 닫아도 세션은 유지됩니다'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('작업실로'),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => TerminalDock._dialog(
                    _handles,
                    maxHeight: c.maxHeight - workbenchLineHeight(context) - 6,
                    onOpenQa: widget.onOpenQa,
                    onDirectDocument: widget.onDirectDocument,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() => _dialogOpen = false);
  }

  void _openDock(bool compact) {
    widget.onOpen?.call();
    if (compact) {
      _showPanel();
    } else {
      setState(() => _open = true);
    }
  }

  Future<void> _add(TerminalWorkbenchViewModel vm, bool compact) async {
    final readiness = context.read<TerminalReadinessViewModel>();
    await readiness.selectProvider(readiness.provider);
    if (!mounted) return;
    final selection = await showDialog<(TerminalProfile, bool)>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: readiness,
        child: const TerminalReadinessDialog(),
      ),
    );
    if (selection == null || !mounted) return;
    _openDock(compact);
    await WidgetsBinding.instance.endOfFrame;
    await vm.add(selection.$1, writer: selection.$2);
  }

  Future<void> _rename(TerminalWorkbenchViewModel vm) async {
    final item = vm.selected,
        text = TextEditingController(text: vm.selected.displayName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('세션 이름'),
        content: TextField(controller: text, maxLength: 80, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.text),
            child: const Text('적용'),
          ),
        ],
      ),
    );
    text.dispose();
    if (value != null) vm.rename(item.id, value);
  }

  Future<void> _environment(TerminalSessionViewModel item) async {
    final ticket = item.inputEpoch;
    String summary;
    var verified = true;
    try {
      summary = await item.authoringEnvironment();
    } catch (e) {
      verified = false;
      summary = '작성 환경 확인 실패: $e';
    }
    if (!mounted) return;
    final instruction = item.skillInvocation;
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('${item.displayName} · 작성 환경'),
        content: WorkbenchDialogBody(
          width: 620,
          height: 380,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(summary),
                const SizedBox(height: 12),
                if (item.provider == 'codex' || item.provider == 'claude') ...[
                  const Text('아래 문장을 입력한 뒤 구체적인 변경 요청을 덧붙여 직접 제출하세요.'),
                  SelectableText(instruction),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (item.provider == 'codex' || item.provider == 'claude') ...[
            TextButton(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: instruction)),
              child: const Text('호출 안내 복사'),
            ),
            TextButton(
              onPressed: !verified
                  ? null
                  : () {
                      if (ticket == item.inputEpoch &&
                          item.service.state == 'running') {
                        item.input(instruction);
                      }
                      Navigator.pop(dialog);
                    },
              child: const Text('입력에 넣기 · 미제출'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _resize(double delta) => setState(() {
    _maximized = false;
    _height = (_height + delta).clamp(160, 800);
  });
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TerminalWorkbenchViewModel>();
    final compact = !widget.inDialog && MediaQuery.sizeOf(context).height < 700;
    final open = _open && !widget.collapsed && !compact && !_dialogOpen;
    final selected = vm.selected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _resize(24);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _resize(-24);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.home) {
              setState(() {
                _height = 160;
                _maximized = false;
              });
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.end) {
              setState(() => _maximized = true);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Semantics(
            label: '터미널 높이 조절',
            value: '${_height.round()}',
            focusable: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: GestureDetector(
                onVerticalDragUpdate: (event) => _resize(-event.delta.dy),
                child: Container(
                  key: const Key('terminal-resize'),
                  height: 6,
                  color: const Color(0xff414141),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: workbenchLineHeight(context),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TextButton(
                  onPressed: widget.inDialog
                      ? null
                      : () {
                          if (open) {
                            setState(() => _open = false);
                          } else {
                            _openDock(compact);
                          }
                        },
                  child: Text(open ? '터미널 접기' : '터미널 열기'),
                ),
                TextButton(
                  key: const Key('terminal-add'),
                  onPressed: vm.canStart ? () => _add(vm, compact) : null,
                  child: const Text('새 세션'),
                ),
                TextButton(
                  onPressed: vm.sessions.length > 1 ? vm.toggleSplit : null,
                  child: Text(vm.split ? '분할 해제' : '분할'),
                ),
                TextButton(
                  onPressed: widget.inDialog ? null : _showPanel,
                  child: const Text('확대'),
                ),
                TextButton(
                  onPressed: selected.session == null
                      ? null
                      : () => _rename(vm),
                  child: const Text('이름'),
                ),
                TextButton(
                  onPressed: selected.active
                      ? () => selected.input('\x03')
                      : null,
                  child: const Text('Ctrl+C'),
                ),
                TextButton(
                  key: const Key('terminal-close'),
                  onPressed: selected.active ? selected.close : null,
                  child: const Text('선택 종료'),
                ),
                TextButton(
                  onPressed:
                      selected.session != null &&
                          !selected.active &&
                          !selected.service.cleanupUnknown
                      ? () => vm.remove(selected.id)
                      : null,
                  child: const Text('목록에서 제거'),
                ),
                Text(
                  '${vm.sessions.length}/8 · ${_stateLabel(selected.service.state)}',
                  key: const Key('terminal-status'),
                ),
              ],
            ),
          ),
        ),
        if (open)
          SizedBox(
            height: widget.inDialog
                ? widget.maxHeight.clamp(100, 900)
                : (_maximized ? widget.maxHeight : _height).clamp(
                    100,
                    widget.maxHeight.clamp(100, 900),
                  ),
            child: Column(
              children: [
                SizedBox(
                  height: workbenchLineHeight(context),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final item in vm.sessions)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ChoiceChip(
                              selected: selected.id == item.id,
                              label: Text(
                                '${item.displayName}${vm.isWriter(item) ? ' · 작성' : ' · 검토'}${item.qaIdentity == vm.identity ? '' : ' · 다른 QA'}',
                              ),
                              onSelected: (_) => vm.select(item.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      final second = vm.split && bounds.maxWidth >= 720
                          ? vm.secondary
                          : null;
                      return Row(
                        children: [
                          Expanded(
                            key: ValueKey('split-${selected.id}'),
                            child: _pane(vm, selected),
                          ),
                          if (second != null) ...[
                            const VerticalDivider(width: 1),
                            Expanded(
                              key: ValueKey('split-${second.id}'),
                              child: _pane(vm, second),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _pane(TerminalWorkbenchViewModel vm, TerminalSessionViewModel item) {
    final h = _handle(item.id), current = item.qaIdentity == vm.identity;
    return Column(
      key: ValueKey('pane-${item.id}'),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 90),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (item.session == null)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('새 세션에서 프로그램을 선택하세요. 세션별 QA 사본을 사용합니다.'),
                  ),
                if (item.session != null) ...[
                  Tooltip(
                    message: item.session!.path,
                    child: Text(
                      '${item.displayName} · ${_stateLabel(item.state)} · ${item.session!.path}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (!current)
                        TextButton(
                          onPressed: widget.onOpenQa == null
                              ? null
                              : () => widget.onOpenQa!(item.qaIdentity!),
                          child: const Text('시작 QA로 이동'),
                        ),
                      TextButton(
                        onPressed: current
                            ? () => vm.grantWriter(item.id)
                            : null,
                        child: Text(
                          vm.isWriter(item) ? '작성 권한 재지정' : '작성 권한 받기',
                        ),
                      ),
                      if (vm.isWriter(item))
                        TextButton(
                          onPressed: vm.revokeWriter,
                          child: const Text('작성 해제'),
                        ),
                      TextButton(
                        onPressed: current ? item.updateContext : null,
                        child: const Text('문맥 갱신'),
                      ),
                      TextButton(
                        onPressed: () => _environment(item),
                        child: const Text('작성 환경'),
                      ),
                      TextButton(
                        onPressed: current
                            ? () => item.refresh(force: true)
                            : null,
                        child: const Text('파일 다시 읽기'),
                      ),
                      TextButton(
                        onPressed:
                            current &&
                                vm.isWriter(item) &&
                                item.canEditDocument()
                            ? item.saveGui
                            : null,
                        child: const Text('GUI → 파일 저장'),
                      ),
                      if (current && !item.canEditDocument())
                        TextButton(
                          onPressed: widget.onDirectDocument,
                          child: const Text('직접 문서로 전환'),
                        ),
                      if (item.state == 'conflict' && vm.isWriter(item)) ...[
                        TextButton(
                          onPressed: () => item.acceptFile('xml'),
                          child: const Text('XML 수용 · 사본 보존'),
                        ),
                        TextButton(
                          onPressed: () => item.acceptFile('json'),
                          child: const Text('JSON 수용 · 사본 보존'),
                        ),
                      ],
                      TextButton(
                        onPressed: item.canUndo ? item.undo : null,
                        child: const Text('반영 되돌리기'),
                      ),
                    ],
                  ),
                  if (item.error != null)
                    Text(
                      item.error!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: TerminalView(
            item.terminal,
            key: ValueKey('interactive-terminal-${item.id}'),
            controller: h.controller,
            scrollController: h.scroll,
            focusNode: h.focus,
            readOnly: item.service.state != 'running',
            textStyle: const TerminalStyle(fontSize: 13),
            onPaste: () async {
              final ticket = item.inputEpoch;
              final text = (await Clipboard.getData(Clipboard.kTextPlain))
                  ?.text;
              if (mounted &&
                  ticket == item.inputEpoch &&
                  item.service.state == 'running' &&
                  text != null) {
                item.input(text);
              }
            },
            onCopy: (text) => Clipboard.setData(ClipboardData(text: text)),
          ),
        ),
      ],
    );
  }

  String _stateLabel(String state) => switch (state) {
    'idle' => '대기',
    'preparing' => '준비 중',
    'compiling' => '검증 중',
    'synced' => '반영됨',
    'review_ready' => '검토 준비',
    'composition_review' => '합성 보호 · 검토 후보',
    'needs_validation' => '재검증 필요',
    'conflict' => '충돌 확인 필요',
    'stale' => '이전 변경 폐기',
    'writing' => '파일 쓰는 중',
    'waiting_run' => 'QA 실행 종료 대기',
    'invalid' => '유효하지 않은 파일',
    'running' => '실행 중',
    'starting' => '시작 중',
    'closing' => '종료 중',
    'closed' => '종료됨',
    'cleanup_unknown' => '정리 확인 필요',
    'error' => '오류',
    _ => state,
  };
}
