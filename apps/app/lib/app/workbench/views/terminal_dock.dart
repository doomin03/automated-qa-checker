import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm2/xterm.dart';

import '../view_models/terminal_workbench_view_model.dart';

class TerminalDock extends StatefulWidget {
  const TerminalDock({super.key});
  @override
  State<TerminalDock> createState() => _TerminalDockState();
}

class _TerminalDockState extends State<TerminalDock> {
  final _focus = FocusNode();
  final _controller = TerminalController();
  bool _open = false;
  double _height = 180;
  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TerminalWorkbenchViewModel>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.resizeUpDown,
          child: GestureDetector(
            onVerticalDragUpdate: (e) => setState(
              () => _height = (_height - e.delta.dy).clamp(
                100,
                MediaQuery.sizeOf(context).height * .45,
              ),
            ),
            child: Container(height: 6, color: const Color(0xff3a4552)),
          ),
        ),
        SizedBox(
          height: 34,
          child: Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _open = !_open),
                child: Text(_open ? '터미널 접기' : '터미널 열기'),
              ),
              TextButton(
                key: const Key('terminal-start'),
                onPressed: vm.canStart
                    ? () async {
                        setState(() => _open = true);
                        await WidgetsBinding.instance.endOfFrame;
                        if (!mounted) return;
                        await vm.start();
                        if (mounted) _focus.requestFocus();
                      }
                    : null,
                child: const Text('Codex 시작'),
              ),
              TextButton(
                onPressed: vm.active ? () => vm.input('\x03') : null,
                child: const Text('Ctrl+C'),
              ),
              TextButton(
                key: const Key('terminal-close'),
                onPressed: vm.active ? vm.close : null,
                child: const Text('종료'),
              ),
              TextButton(
                onPressed: vm.session == null ? null : vm.updateContext,
                child: const Text('선택 문맥 갱신'),
              ),
              const Spacer(),
              Text(
                '${vm.service.state} · ${vm.state}',
                key: const Key('terminal-status'),
              ),
            ],
          ),
        ),
        if (_open) ...[
          if (vm.session == null)
            const Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                'QA 전용 폴더에서 실제 CLI를 시작합니다. 파일 편집은 자동 반영되며, 실행은 앱의 실행 버튼을 사용하세요.',
                style: TextStyle(fontSize: 11),
              ),
            ),
          if (vm.session != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      vm.session!.path,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: () => vm.refresh(force: true),
                    child: const Text('파일 다시 읽기'),
                  ),
                  TextButton(
                    onPressed: vm.desktop.busy ? null : vm.saveGui,
                    child: const Text('GUI → 파일 저장'),
                  ),
                ],
              ),
            ),
          if (vm.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                vm.error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          if (vm.state == 'conflict')
            Wrap(
              children: [
                TextButton(
                  onPressed: () => vm.acceptFile('xml'),
                  child: const Text('XML 수용 · GUI 사본 보존'),
                ),
                TextButton(
                  onPressed: () => vm.acceptFile('json'),
                  child: const Text('JSON 수용 · GUI 사본 보존'),
                ),
                TextButton(
                  onPressed: vm.saveGui,
                  child: const Text('GUI 유지 → 파일 교체'),
                ),
                TextButton(
                  onPressed: vm.canUndo ? vm.undo : null,
                  child: const Text('직전 동기화 되돌리기'),
                ),
              ],
            ),
          SizedBox(
            height: _height,
            child: TerminalView(
              vm.terminal,
              key: const Key('interactive-terminal'),
              controller: _controller,
              focusNode: _focus,
              autofocus: false,
              readOnly: vm.service.state != 'running',
              textStyle: const TerminalStyle(fontSize: 13),
              onPaste: () async {
                final text = (await Clipboard.getData(Clipboard.kTextPlain))
                    ?.text;
                if (text != null) vm.input(text);
              },
              onCopy: (text) => Clipboard.setData(ClipboardData(text: text)),
            ),
          ),
        ],
      ],
    );
  }
}
