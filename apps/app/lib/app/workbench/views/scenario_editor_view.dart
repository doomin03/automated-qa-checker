import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/scenario_editor/view_models/scenario_editor_view_model.dart';
import '../view_models/workbench_view_model.dart';
import '../../../core/widgets/model_text_field.dart';
import 'run_panel.dart';
import '../../../features/scenario_editor/views/flow_editor_view.dart';

class ScenarioEditorView extends StatefulWidget {
  const ScenarioEditorView({super.key});
  @override
  State<ScenarioEditorView> createState() => _ScenarioEditorViewState();
}

class _ScenarioEditorViewState extends State<ScenarioEditorView> {
  final _path = TextEditingController();
  bool _flow = false;

  @override
  void dispose() {
    _path.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final vm = context.read<ScenarioEditorViewModel>();
    if (vm.isDirty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('저장하지 않은 초안을 바꾸시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('파일 열기'),
            ),
          ],
        ),
      );
      if (!mounted || replace != true) return;
    }
    await vm.open(_path.text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Automated QA Desktop')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer<ScenarioEditorViewModel>(
        builder: (context, vm, child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '테스트 초안 · XML / Flow JSON',
              style: TextStyle(fontSize: 20),
            ),
            const Text('웹에서 받은 XML을 열거나 원하는 테스트 원문을 붙여넣으세요.'),
            const Text(
              '파일 수신·저장만으로 실행하지 않습니다. 공용 XML과 진행 공유는 선택한 서버 연결에서 사용합니다.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('file-path'),
              controller: _path,
              enabled: !vm.isBusy,
              decoration: const InputDecoration(
                labelText: 'XML 또는 JSON 파일 경로',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('XML / JSON'),
                  selected: !_flow,
                  onSelected: (_) => setState(() => _flow = false),
                ),
                ChoiceChip(
                  label: const Text('블록 / Flow'),
                  selected: _flow,
                  onSelected: (_) => setState(() => _flow = true),
                ),
                OutlinedButton(
                  onPressed: vm.isBusy ? null : _open,
                  child: const Text('파일 열기'),
                ),
                FilledButton(
                  onPressed: vm.isBusy ? null : () => vm.save(_path.text),
                  child: const Text('파일 저장'),
                ),
                Text(
                  vm.isBusy
                      ? '파일 작업 중'
                      : vm.isDirty
                      ? '저장하지 않은 변경'
                      : '변경 없음',
                  key: const Key('draft-status'),
                ),
              ],
            ),
            if (vm.error != null)
              Text(
                vm.error!,
                key: const Key('file-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (vm.notice != null)
              Text(vm.notice!, key: const Key('file-notice')),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _flow
                        ? FlowEditorView(
                            loadSource: context
                                .read<WorkbenchViewModel>()
                                .loadSourceIntoFlow,
                            loadPlan: context
                                .read<WorkbenchViewModel>()
                                .loadPlanIntoFlow,
                            applyFlow: context
                                .read<WorkbenchViewModel>()
                                .applyFlow,
                            canLoadPlan: context
                                .watch<WorkbenchViewModel>()
                                .canUsePlan,
                          )
                        : ModelTextField(
                            key: const Key('scenario-source'),
                            value: vm.draft.content,
                            enabled: !vm.isBusy,
                            expands: true,
                            onChanged: vm.edit,
                            decoration: const InputDecoration(
                              labelText: 'XML / Flow JSON 원문',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: const RunPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
