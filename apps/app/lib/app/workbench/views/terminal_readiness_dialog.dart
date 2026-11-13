import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../features/interactive_terminal/view_models/terminal_readiness_view_model.dart';
import 'adaptive_workbench.dart';

class TerminalReadinessDialog extends StatefulWidget {
  const TerminalReadinessDialog({super.key});
  @override
  State<TerminalReadinessDialog> createState() =>
      _TerminalReadinessDialogState();
}

class _TerminalReadinessDialogState extends State<TerminalReadinessDialog> {
  final path = TextEditingController();
  bool writer = false;
  @override
  void dispose() {
    path.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TerminalReadinessViewModel>();
    if (path.text != vm.path) {
      path.value = TextEditingValue(
        text: vm.path,
        selection: TextSelection.collapsed(offset: vm.path.length),
      );
    }
    return AlertDialog(
      title: const Text('새 터미널'),
      content: WorkbenchDialogBody(
        width: 560,
        height: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: vm.provider,
                decoration: const InputDecoration(labelText: '프로그램'),
                items: const [
                  DropdownMenuItem(value: 'codex', child: Text('Codex')),
                  DropdownMenuItem(value: 'claude', child: Text('Claude')),
                  DropdownMenuItem(
                    value: 'powershell',
                    child: Text('PowerShell'),
                  ),
                  DropdownMenuItem(value: 'cmd', child: Text('명령 프롬프트')),
                ],
                onChanged: (value) {
                  if (value != null) vm.selectProvider(value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: path,
                decoration: const InputDecoration(
                  labelText: '실행 파일 (비우면 설치 경로 탐색)',
                ),
                onChanged: vm.changePath,
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: vm.busy ? null : vm.chooseExecutable,
                    child: const Text('파일 선택'),
                  ),
                  TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (dialog) => AlertDialog(
                        title: const Text('설치 안내'),
                        content: SingleChildScrollView(
                          child: SelectableText(vm.installationGuide),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Clipboard.setData(
                              ClipboardData(text: vm.installationGuide),
                            ),
                            child: const Text('안내 복사'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialog),
                            child: const Text('닫기'),
                          ),
                        ],
                      ),
                    ),
                    child: const Text('설치 안내'),
                  ),
                  TextButton(
                    onPressed: vm.busy ? null : vm.forget,
                    child: const Text('저장 경로 지우기'),
                  ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: vm.remember,
                onChanged: vm.busy ? null : (value) => vm.setRemember(value!),
                title: const Text('이 경로 기억'),
                subtitle: const Text('이 PC의 앱 설정에 경로만 저장 · 다음 시작 전 다시 진단'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: writer,
                onChanged: (value) => setState(() => writer = value!),
                title: const Text('이 QA의 자동 반영 작성자로 시작'),
                subtitle: const Text('기존 작성자가 있으면 검토 사본으로 시작'),
              ),
              Text(vm.readinessLabel),
              if (vm.profile != null) Text(vm.profile!.detail),
              if (vm.error != null)
                Text(vm.error!, style: const TextStyle(color: Colors.orange)),
              const SizedBox(height: 8),
              const Text(
                '로그인·신뢰·권한 화면은 실제 터미널에서 확인합니다. 경로 기억을 끄면 저장 없이 현재 경로를 사용할 수 있습니다.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: vm.busy ? null : vm.inspect,
          child: Text(vm.busy ? '확인 중' : '준비 확인'),
        ),
        FilledButton(
          key: const Key('terminal-start'),
          onPressed: vm.busy || vm.profile?.available != true
              ? null
              : () async {
                  final selected = await vm.accept();
                  if (context.mounted && selected != null) {
                    Navigator.pop(context, (selected, writer));
                  }
                },
          child: const Text('시작'),
        ),
      ],
    );
  }
}
