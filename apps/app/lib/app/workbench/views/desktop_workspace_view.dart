import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../view_models/desktop_workspace_view_model.dart';
import '../view_models/terminal_workbench_view_model.dart';
import 'terminal_dock.dart';
import 'document_template_dialog.dart';
import '../view_models/document_template_view_model.dart';
import 'adaptive_workbench.dart';
import 'blueprint_workspace.dart';
import 'xml_block_studio.dart';
import '../view_models/xml_block_workbench_view_model.dart';
import '../../../core/widgets/model_text_field.dart';
import '../../../features/ai_authoring/models/ai_request.dart';
import '../../../features/scenario_editor/views/flow_forms.dart';
import '../../../features/run_review/views/run_results.dart';
import '../../../features/run_review/views/engine_settings_fields.dart';
import 'run_panel.dart';
import 'project_home.dart';
import '../view_models/project_home_view_model.dart';

class DesktopWorkspaceView extends StatefulWidget {
  const DesktopWorkspaceView({super.key});
  @override
  State<DesktopWorkspaceView> createState() => _DesktopWorkspaceViewState();
}

class _DesktopWorkspaceViewState extends State<DesktopWorkspaceView> {
  bool _flow = true, _navigation = false, _assistant = false, _results = false;
  bool get _inlineResults =>
      _results && MediaQuery.sizeOf(context).height >= 700;

  void _showResults({bool toggle = true}) {
    if (MediaQuery.sizeOf(context).height >= 700) {
      setState(() => _results = toggle ? !_results : true);
      return;
    }
    setState(() => _results = false);
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: WorkbenchDialogBody(
          width: 1000,
          height: 650,
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('실행 로그 / 결과'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('결과 닫기'),
                  ),
                ],
              ),
              Expanded(
                child:
                    Consumer2<
                      DesktopWorkspaceViewModel,
                      XmlBlockWorkbenchViewModel
                    >(
                      builder: (context, vm, blocks, _) =>
                          _resultBody(vm, blocks),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _compiledPreview = false;
  bool get _composition => context.read<XmlBlockWorkbenchViewModel>().enabled;
  set _composition(bool value) =>
      context.read<XmlBlockWorkbenchViewModel>().setEnabled(value);
  AppLifecycleListener? _lifecycle;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DesktopWorkspaceViewModel>().initialize();
    });
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async {
        if (!await _leave() || !mounted) return AppExitResponse.cancel;
        final terminals = context.read<TerminalWorkbenchViewModel>();
        if (terminals.active) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('앱 종료'),
              content: const Text('이 앱의 모든 터미널 세션을 종료하고 작업실을 닫습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('모두 종료'),
                ),
              ],
            ),
          );
          if (confirmed != true) return AppExitResponse.cancel;
        }
        await terminals.closeAll();
        if (terminals.sessions.any((s) => s.service.cleanupUnknown)) {
          return AppExitResponse.cancel;
        }
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<bool> _leave() async {
    final vm = context.read<DesktopWorkspaceViewModel>();
    final blocks = context.read<XmlBlockWorkbenchViewModel>();
    if (blocks.busy || vm.busy || context.read<ProjectHomeViewModel>().busy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('진행 중인 작업을 완료하거나 취소한 뒤 이동하세요.')),
      );
      return false;
    }
    if (blocks.dirty) {
      final save = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('XML 블록 조합 저장'),
          content: const Text('현재 조합과 라이브러리를 저장하고 이동합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('현재 문서 유지'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text('변경 버리기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('저장 후 이동'),
            ),
          ],
        ),
      );
      if (save == null || save == 'cancel') return false;
      if (save == 'save' && !await blocks.save()) return false;
      if (!mounted) return false;
    }
    // Sessions retain their QA/cwd identity while the user navigates.
    if (vm.busy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('진행 중인 작업을 취소하거나 완료한 뒤 이동하세요.')),
      );
      return false;
    }
    if (!vm.dirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장하지 않은 문서 또는 프롬프트'),
        content: const Text('변경 내용을 저장하고 이동할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('변경 버리기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('저장 후 이동'),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    return choice == 'discard' || (choice == 'save' && await vm.save());
  }

  Future<String?> _input(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          key: const Key('workspace-dialog-input'),
          controller: controller,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    return value;
  }

  Future<void> _create(bool project) async {
    if (!await _leave() || !mounted) return;
    final name = await _input(project ? '새 프로젝트' : '새 QA');
    if (!mounted || name == null) return;
    final vm = context.read<DesktopWorkspaceViewModel>();
    if (project) {
      await vm.createProject(name);
    } else {
      await vm.createQa(name);
    }
  }

  Future<void> _templateQa() async {
    if (!await _leave() || !mounted) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const DocumentTemplateDialog(),
    );
    if (!mounted) return;
    context.read<DocumentTemplateViewModel>().clear();
    if (created == true) {
      final blocks = context.read<XmlBlockWorkbenchViewModel>();
      while (blocks.busy && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      if (mounted) {
        blocks.setEnabled(false);
        setState(() => _flow = true);
      }
    }
  }

  Future<void> _select(String? project, String? qa) async {
    if (!await _leave() || !mounted) return;
    context.read<DesktopWorkspaceViewModel>().select(project, qa);
    if (mounted) setState(() => _compiledPreview = false);
  }

  Future<void> _settings() => showDialog<void>(
    context: context,
    builder: (context) => Consumer<DesktopWorkspaceViewModel>(
      builder: (context, vm, _) => FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(
          requestFocusCallback:
              (node, {alignment, alignmentPolicy, duration, curve}) {
                // Tab wrap must reveal controls above a long, scrolled settings form.
                FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
                  node,
                  alignment: 0.5,
                  alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
                );
              },
        ),
        child: AlertDialog(
          title: const Text('실행 환경 · AI CLI'),
          content: WorkbenchDialogBody(
            width: 760,
            height: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('설치된 CLI의 기존 로그인을 사용합니다. 앱은 API 키를 저장하지 않습니다.'),
                  DropdownButton<String>(
                    value: vm.ai.settings.provider,
                    items: const [
                      DropdownMenuItem(
                        value: 'codex',
                        child: Text('OpenAI Codex CLI'),
                      ),
                      DropdownMenuItem(
                        value: 'claude',
                        child: Text('Claude CLI · 실제 연결 미인수'),
                      ),
                    ],
                    onChanged: vm.busy
                        ? null
                        : (v) => vm.ai.configure(
                            AiSettings(
                              provider: v!,
                              executable: vm.ai.settings.executable,
                            ),
                          ),
                  ),
                  ModelTextField(
                    value: vm.ai.settings.executable,
                    onChanged: (v) => vm.ai.configure(
                      AiSettings(
                        provider: vm.ai.settings.provider,
                        executable: v,
                      ),
                    ),
                    enabled: !vm.busy,
                    decoration: const InputDecoration(
                      labelText: 'AI CLI 실행 파일 절대 경로',
                    ),
                  ),
                  TextButton(
                    onPressed: vm.busy ? null : vm.ai.diagnose,
                    child: const Text('CLI 설치·로그인 진단'),
                  ),
                  Text(vm.ai.diagnosis),
                  if (vm.ai.error != null) Text(vm.ai.error!),
                  const Divider(),
                  const Text('앱 전용 Engine · 기본 경로는 설치 receipt에서 설정됩니다.'),
                  EngineSettingsFields(enabled: !vm.busy),
                  EngineSettingsFields(enabled: !vm.busy, advanced: true),
                  const Text(
                    '결과 공유에는 연결된 서버와 실행 환경의 버전 호환이 필요합니다. 공유 실패는 로컬 결과를 바꾸지 않습니다.',
                  ),
                  Text(vm.workspace.repository.directory),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: vm.busy
                  ? null
                  : () async {
                      await vm.save();
                      if (context.mounted && vm.workspace.error == null) {
                        Navigator.pop(context);
                      }
                    },
              child: const Text('설정·작업 저장'),
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> _preview() async {
    final vm = context.read<DesktopWorkspaceViewModel>();
    final p = vm.ai.proposal;
    if (p == null) return;
    var acknowledged = vm.ai.scope == AiScope.whole;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('전체 후보 XML · 적용 전 검토'),
          content: WorkbenchDialogBody(
            width: 1050,
            height: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.answer.summary),
                  Text(
                    '원본 ${p.original.plan['blueprintSnapshotHash']}\n후보 ${p.candidate.plan['blueprintSnapshotHash']}',
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      children: p.changes.map((v) => Text(v)).toList(),
                    ),
                  ),
                  if (vm.ai.scope != AiScope.whole)
                    CheckboxListTile(
                      value: acknowledged,
                      onChanged: (v) => setDialog(() => acknowledged = v!),
                      title: const Text('선택 범위 밖의 변경까지 전체 diff를 확인했습니다.'),
                    ),
                  SizedBox(
                    height: 260,
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: SelectableText(p.source),
                          ),
                        ),
                        const VerticalDivider(),
                        Expanded(
                          child: SingleChildScrollView(
                            child: SelectableText(p.answer.xml),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
            FilledButton(
              key: const Key('ai-apply'),
              onPressed: !acknowledged
                  ? null
                  : () {
                      final applied = vm.applyProposal();
                      if (applied) {
                        Navigator.pop(context);
                      } else {
                        setDialog(() {});
                      }
                    },
              child: const Text('검토한 XML 적용 · 실행하지 않음'),
            ),
            if (vm.error != null) Text(vm.error!),
          ],
        ),
      ),
    );
  }

  Widget _ai(DesktopWorkspaceViewModel vm) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI 작성 · ${vm.ai.settings.provider}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            vm.ai.diagnosis.isEmpty
                ? '기존 CLI 인증 사용 · 설정에서 진단'
                : vm.ai.diagnosis,
          ),
          Text('선택: ${vm.selectedNode ?? '없음'}'),
          ExpansionTile(
            title: const Text('프로젝트 지침 · QA 요청'),
            children: [
              const Text('저장을 누르면 프로젝트 지침과 QA의 지속 요청을 보관합니다.'),
              ModelTextField(
                value: vm.workspace.instructions,
                enabled: !vm.busy,
                onChanged: vm.workspace.editInstructions,
                decoration: const InputDecoration(labelText: '프로젝트 공통 지침'),
              ),
              ModelTextField(
                value: vm.workspace.prompt,
                enabled: !vm.busy,
                onChanged: vm.workspace.editPrompt,
                decoration: const InputDecoration(labelText: '이 QA의 지속 요청'),
              ),
            ],
          ),
          DropdownButton<AiScope>(
            isExpanded: true,
            value: vm.ai.scope,
            items: AiScope.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: vm.busy ? null : (v) => vm.ai.setScope(v!),
          ),
          SizedBox(
            height: 130,
            child: ModelTextField(
              key: const Key('ai-request'),
              value: vm.ai.request,
              enabled: !vm.busy,
              expands: true,
              onChanged: vm.ai.editRequest,
              decoration: const InputDecoration(
                labelText: '이번 변경 요청 · 일회성',
                hintText: '선택 블록 뒤에 화면 캡처를 추가해 주세요.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('이번 변경 요청은 QA를 바꾸면 초기화됩니다.'),
          const Text('프로젝트 지침·QA 요청·전체 XML을 선택한 CLI로 보냅니다.'),
          Wrap(
            spacing: 6,
            children: [
              FilledButton(
                key: const Key('ai-generate'),
                onPressed: vm.busy || vm.ai.request.trim().isEmpty
                    ? null
                    : vm.generate,
                child: const Text('후보 생성'),
              ),
              TextButton(
                onPressed: vm.ai.busy ? vm.ai.cancel : null,
                child: const Text('생성 취소'),
              ),
            ],
          ),
          Text('AI: ${vm.ai.status}', key: const Key('ai-status')),
          if (vm.ai.error != null)
            Text(
              vm.ai.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          for (final event in vm.ai.progress.skip(
            (vm.ai.progress.length - 6).clamp(0, 100),
          ))
            Text(event),
          if (vm.ai.proposal != null) ...[
            Text(vm.ai.proposal!.answer.summary),
            for (final change in vm.ai.proposal!.changes.take(8)) Text(change),
            FilledButton(
              onPressed: vm.ai.status == 'review' && !vm.busy ? _preview : null,
              child: const Text('변경 미리보기'),
            ),
            TextButton(onPressed: vm.ai.dismiss, child: const Text('제안 버리기')),
          ],
          TextButton(
            onPressed: vm.canUndoAi ? vm.undoAi : null,
            child: const Text('AI 적용 되돌리기'),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DesktopWorkspaceViewModel>();
    final blocks = context.watch<XmlBlockWorkbenchViewModel>();
    final home = context.watch<ProjectHomeViewModel>();
    context.watch<TerminalWorkbenchViewModel>();
    final ws = vm.workspace;
    final compact =
        MediaQuery.sizeOf(context).width < 1100 ||
        MediaQuery.textScalerOf(context).scale(13) > 16;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) => Column(
            children: [
              Container(
                height: workbenchLineHeight(context),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Text(
                      'QA',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 14),
                    PopupMenuButton<String>(
                      tooltip: '파일',
                      onSelected: (value) {
                        if (value == 'project') _select(null, null);
                        if (value == 'settings') _settings();
                        if (value == 'import') _importBlock();
                        if (value == 'import-path') _importBlock(usePath: true);
                        if (value == 'template') _templateQa();
                        if (value == 'direct-path') {
                          _openDirectFile(usePath: true);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'template',
                          enabled: ws.projectId != null && !vm.busy,
                          child: const Text('템플릿으로 새 QA'),
                        ),
                        const PopupMenuItem(
                          value: 'project',
                          child: Text('프로젝트 열기'),
                        ),
                        const PopupMenuItem(
                          value: 'import',
                          child: Text('XML 블록 가져오기'),
                        ),
                        const PopupMenuItem(
                          value: 'import-path',
                          child: Text('XML 블록 경로 입력'),
                        ),
                        const PopupMenuItem(
                          value: 'direct-path',
                          child: Text('직접 XML 경로 입력'),
                        ),
                        const PopupMenuItem(
                          value: 'settings',
                          child: Text('실행 환경 / 연결'),
                        ),
                      ],
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('파일'),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: '편집',
                      onSelected: (value) {
                        final blocks = context
                            .read<XmlBlockWorkbenchViewModel>();
                        if (value == 'undo') blocks.undo();
                        if (value == 'redo') blocks.redo();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'undo',
                          child: Text('실행 취소'),
                        ),
                        const PopupMenuItem(
                          value: 'redo',
                          child: Text('다시 실행'),
                        ),
                      ],
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('편집'),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: '보기',
                      onSelected: (value) {
                        if (value == 'navigation') {
                          _openNavigation(compact);
                        }
                        if (value == 'results') {
                          _showResults();
                        }
                        if (value == 'assistant') _openAssistant(compact);
                        if (value == 'settings') _settings();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'navigation',
                          child: Text('프로젝트 탐색'),
                        ),
                        const PopupMenuItem(
                          value: 'results',
                          child: Text('출력 / 결과'),
                        ),
                        const PopupMenuItem(
                          value: 'assistant',
                          child: Text('AI 작성 도구'),
                        ),
                        const PopupMenuItem(
                          value: 'settings',
                          child: Text('실행 환경 / 연결'),
                        ),
                      ],
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('보기'),
                      ),
                    ),
                    const VerticalDivider(),
                    TextButton(
                      onPressed: home.busy ? null : () => _select(null, null),
                      child: const Text('홈'),
                    ),
                    if (ws.project != null && !compact)
                      TextButton(
                        onPressed: () => _select(ws.projectId, null),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(
                            ws.project!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    if (ws.qa != null)
                      Expanded(
                        child: Text(
                          ' / ${ws.qa!.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    if (!compact)
                      TextButton(
                        onPressed: _settings,
                        child: const Text('실행 환경 / 연결'),
                      ),
                    TextButton(
                      onPressed: () => _openNavigation(compact),
                      child: const Text('탐색'),
                    ),
                    if (ws.qa != null && !compact)
                      TextButton(
                        onPressed: () => _openAssistant(compact),
                        child: const Text('AI 작성 도구'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (ws.error != null || vm.error != null)
                MaterialBanner(
                  content: Text(ws.error ?? vm.error!),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() {
                        vm.error = null;
                        ws.error = null;
                      }),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              if (!vm.initialized)
                const Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(6),
                      child: Text('실행 환경 확인 중 · 첫 파일 검증에는 시간이 걸릴 수 있습니다.'),
                    ),
                    LinearProgressIndicator(),
                  ],
                ),
              Expanded(
                child: ws.qa == null
                    ? ProjectHome(
                        onCreate: _create,
                        onOpen: _select,
                        onReceived: () {
                          if (mounted) {
                            setState(() {
                              _flow = false;
                              _compiledPreview = false;
                            });
                          }
                        },
                      )
                    : Row(
                        children: [
                          if (_navigation && !compact)
                            SizedBox(
                              width: 170,
                              child: ListView(
                                children: [
                                  ListTile(
                                    title: Text(ws.project!.name),
                                    dense: true,
                                  ),
                                  for (final q in ws.project!.documents)
                                    ListTile(
                                      dense: true,
                                      selected: q.id == ws.qaId,
                                      title: Text(q.name),
                                      onTap: () => _select(ws.projectId, q.id),
                                    ),
                                  TextButton(
                                    onPressed: vm.busy
                                        ? null
                                        : () => _create(false),
                                    child: const Text('+ QA'),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            key: const ValueKey('workbench-editor'),
                            child: _editor(vm),
                          ),
                          if (_assistant && !compact) ...[
                            const VerticalDivider(width: 1),
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width < 1200
                                  ? 290
                                  : 330,
                              child: _ai(vm),
                            ),
                          ],
                        ],
                      ),
              ),
              if (ws.qa != null)
                TerminalDock(
                  onDirectDocument: _directDocument,
                  onOpenQa: (identity) async {
                    final ids = identity.split('/');
                    if (ids.length == 2) await _select(ids[0], ids[1]);
                  },
                  collapsed: _inlineResults,
                  onOpen: () => setState(() => _results = false),
                  maxHeight:
                      (bounds.maxHeight -
                              workbenchLineHeight(context) * 7 -
                              180)
                          .clamp(100, 260),
                ),
              Container(
                height: workbenchLineHeight(context, 26),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(vm.dirty || blocks.dirty ? '저장하지 않은 변경' : '저장됨'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        vm.workspace.qa?.name ?? '프로젝트 선택',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      {
                            'not_started': '실행 전',
                            'validating': '검증 중',
                            'validated': '검증 완료',
                            'running': '실행 중',
                            'passed': '통과',
                            'failed': '실패',
                            'cancelled': '취소됨',
                            'cancelling': '취소 요청 중',
                            'error': '오류',
                            'completed': '실행 완료',
                          }[vm.work.run.status] ??
                          vm.work.run.status,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNavigation(bool compact) {
    if (!compact) {
      setState(() => _navigation = !_navigation);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: WorkbenchDialogBody(
          width: 420,
          child: Consumer<DesktopWorkspaceViewModel>(
            builder: (context, vm, _) => Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('프로젝트 탐색'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _select(null, null);
                        },
                        child: const Text('모든 프로젝트'),
                      ),
                      for (final q in vm.workspace.project?.documents ?? [])
                        ListTile(
                          title: Text(q.name),
                          selected: q.id == vm.workspace.qaId,
                          onTap: vm.busy
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _select(vm.workspace.projectId, q.id);
                                },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAssistant(bool compact) {
    if (!compact) {
      setState(() => _assistant = !_assistant);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: WorkbenchDialogBody(
          width: 500,
          child: Consumer<DesktopWorkspaceViewModel>(
            builder: (context, vm, _) => Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('AI 작성 도구'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
                Expanded(child: _ai(vm)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importBlock({bool usePath = false}) async {
    final vm = context.read<DesktopWorkspaceViewModel>();
    if (vm.workspace.qa == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('프로젝트에서 QA 문서를 먼저 여세요.')));
      return;
    }
    final blocks = context.read<XmlBlockWorkbenchViewModel>(),
        owner = context.read<XmlBlockWorkbenchViewModel>().identity;
    final path = usePath
        ? await _input('라이브러리에 가져올 XML 파일 경로')
        : await blocks.chooseFile();
    if (path != null && mounted && owner == blocks.identity) {
      if (await blocks.importFile(path) && mounted) {
        setState(() => _composition = true);
      }
    }
  }

  Future<void> _openDirectFile({bool usePath = false}) async {
    final vm = context.read<DesktopWorkspaceViewModel>(),
        blocks = context.read<XmlBlockWorkbenchViewModel>(),
        owner = context.read<XmlBlockWorkbenchViewModel>().identity;
    final path = usePath
        ? await _input('가져올 XML / JSON 절대 경로')
        : await blocks.chooseFile(allowJson: true);
    if (path == null || !mounted || owner != blocks.identity) return;
    if (!await _leave() || !mounted || owner != blocks.identity) return;
    await vm.importFile(path);
    if (mounted && owner == blocks.identity && vm.work.editor.error == null) {
      blocks.setEnabled(false);
      setState(() {
        _flow = true;
        _compiledPreview = false;
      });
    }
  }

  Future<void> _validateDocument() async {
    final vm = context.read<DesktopWorkspaceViewModel>(),
        blocks = context.read<XmlBlockWorkbenchViewModel>();
    if (_composition) {
      blocks.setEnabled(true);
      if (!await blocks.compile()) return;
    }
    await vm.validate();
  }

  Future<void> _saveDocument() async {
    final vm = context.read<DesktopWorkspaceViewModel>(),
        blocks = context.read<XmlBlockWorkbenchViewModel>();
    if (vm.busy || blocks.busy) return;
    if (await blocks.save()) await vm.save();
  }

  Future<void> _directDocument() async {
    final blocks = context.read<XmlBlockWorkbenchViewModel>();
    if (blocks.busy) return;
    if (blocks.enabled) {
      final accept = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('직접 XML 문서로 전환'),
          content: const Text(
            '현재 실행 XML을 독립 문서로 편집합니다. 라이브러리 원본과 바깥 조합은 바뀌지 않습니다. 다시 조합하면 이 직접 편집 내용은 합성 결과로 교체됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('조합 유지'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('직접 문서 편집'),
            ),
          ],
        ),
      );
      if (accept != true || !mounted) return;
    }
    blocks.setEnabled(false);
    setState(() {
      _flow = true;
      _compiledPreview = false;
    });
  }

  Widget _editor(DesktopWorkspaceViewModel vm) {
    final blocks = context.watch<XmlBlockWorkbenchViewModel>();
    return LayoutBuilder(
      builder: (context, bounds) => Column(
        children: [
          Container(
            width: double.infinity,
            height: workbenchLineHeight(context),
            color: const Color(0xff323232),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton(
                    onPressed: vm.busy || blocks.busy ? null : _saveDocument,
                    child: const Text('저장'),
                  ),
                  TextButton(
                    onPressed: vm.busy
                        ? null
                        : () async {
                            final name = await _input(
                              'QA 이름',
                              initial: vm.workspace.qa!.name,
                            );
                            if (name != null) await vm.save(qaName: name);
                          },
                    child: const Text('문서 이름'),
                  ),
                  TextButton(
                    onPressed: vm.busy ? null : _openDirectFile,
                    child: const Text('XML 직접 열기'),
                  ),
                  TextButton(
                    onPressed: vm.busy
                        ? null
                        : () async {
                            final path = await _input(
                              '내보낼 XML / JSON 경로 · 기존 파일 교체',
                            );
                            if (path != null) {
                              if (_composition) {
                                await blocks.export(path);
                              } else {
                                await vm.work.editor.save(path);
                              }
                            }
                          },
                    child: const Text('내보내기'),
                  ),
                  OutlinedButton(
                    key: const Key('workspace-validate'),
                    onPressed: vm.busy || blocks.busy
                        ? null
                        : _validateDocument,
                    child: const Text('검증'),
                  ),
                  FilledButton(
                    key: const Key('workspace-run'),
                    onPressed:
                        vm.busy ||
                            blocks.busy ||
                            (_composition && !blocks.current) ||
                            vm.externalRunBlocked ||
                            !vm.work.canUsePlan
                        ? null
                        : () async {
                            _showResults(toggle: false);
                            final composed = _composition;
                            if (composed) blocks.captureRunMap();
                            await vm.execute();
                            if (composed) blocks.finishRunMap();
                          },
                    child: const Text('실행'),
                  ),
                  TextButton(
                    onPressed: vm.work.run.running ? vm.work.cancel : null,
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 12),
                  if (blocks.busy)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
          Container(
            height: workbenchLineHeight(context),
            decoration: const BoxDecoration(
              color: Color(0xff292929),
              border: Border(bottom: BorderSide(color: Color(0xff505050))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      blocks.setEnabled(true);
                      setState(() => _compiledPreview = false);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: _composition && !_compiledPreview
                          ? const Color(0xff414141)
                          : null,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Text(
                        '${vm.workspace.qa?.name ?? '문서'}${blocks.dirty ? ' *' : ''} / XML 블록',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: vm.busy || blocks.busy ? null : _directDocument,
                    style: TextButton.styleFrom(
                      backgroundColor: !_composition && _flow
                          ? const Color(0xff414141)
                          : null,
                    ),
                    child: const Text('직접 문서 / Flow'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_composition) {
                        setState(() => _compiledPreview = true);
                      } else {
                        if (vm.work.flow.isDirty) vm.applyFlow();
                        setState(() => _flow = false);
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor:
                          (_composition && _compiledPreview) ||
                              (!_composition && !_flow)
                          ? const Color(0xff414141)
                          : null,
                    ),
                    child: Text(_composition ? '생성 XML' : 'XML 원문'),
                  ),
                  if (_composition)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        blocks.current ? '조합됨' : '조합 전',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xffbcbcbc),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AbsorbPointer(
              absorbing: vm.work.run.running || vm.ai.busy,
              child: Padding(
                padding: EdgeInsets.zero,
                child: _composition
                    ? (_compiledPreview
                          ? Container(
                              color: const Color(0xff1c1c1c),
                              width: double.infinity,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: SelectableText(
                                  blocks.compiledXml ??
                                      '현재 조합을 검증하면 생성 XML이 표시됩니다.',
                                  style: const TextStyle(
                                    fontFamily: 'Consolas',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                          : XmlBlockStudio(
                              importXml: _importBlock,
                              save: _saveDocument,
                            ))
                    : _flow
                    ? const BlueprintWorkspace()
                    : _XmlSource(
                        source: vm.work.source,
                        edit: vm.work.editor.edit,
                        selected: vm.selectNode,
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TextButton(
                  onPressed: _showResults,
                  child: Text(_inlineResults ? '결과 접기' : '실행 로그 / 결과'),
                ),
                if (vm.selectedNode != null)
                  TextButton(
                    onPressed: vm.busy
                        ? null
                        : () async {
                            final node = vm.work.flow.nodes
                                .where((n) => n['id'] == vm.selectedNode)
                                .firstOrNull;
                            if (node == null) return;
                            final result =
                                await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (_) => NodeForm(
                                    node: node,
                                    editor: vm.work.flow,
                                  ),
                                );
                            if (result != null) {
                              vm.work.flow.updateNode(vm.selectedNode!, result);
                            }
                          },
                    child: Text('속성: ${vm.selectedNode}'),
                  ),
                TextButton(
                  onPressed: vm.busy
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('실행·디자인·공유 고급 기능'),
                            content: WorkbenchDialogBody(
                              width: 850,
                              height: 650,
                              child: RunPanel(
                                openReceivedHome: () async {
                                  final home = context
                                      .read<ProjectHomeViewModel>();
                                  Navigator.pop(context);
                                  await _select(null, null);
                                  if (mounted && vm.workspace.qa == null) {
                                    home.navigate('available');
                                  }
                                },
                                execute: vm.execute,
                                validate: vm.validate,
                                blocked: vm.ai.busy,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('닫기'),
                              ),
                            ],
                          ),
                        ),
                  child: const Text('고급 기능'),
                ),
              ],
            ),
          ),
          if (_inlineResults)
            SizedBox(
              height: (bounds.maxHeight - 220).clamp(80, 200),
              child: _resultBody(vm, blocks),
            ),
        ],
      ),
    );
  }

  Widget _resultBody(
    DesktopWorkspaceViewModel vm,
    XmlBlockWorkbenchViewModel blocks,
  ) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultSummary(vm, blocks),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('진단 상세', style: TextStyle(fontSize: 12)),
            children: [
              if (vm.resultOwner != null)
                SelectableText(
                  '실행 소속: ${vm.resultOwner}\nSnapshot: ${vm.resultSnapshot ?? '준비 중'}',
                ),
              RunResults(source: vm.work.source),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _resultSummary(
    DesktopWorkspaceViewModel vm,
    XmlBlockWorkbenchViewModel blocks,
  ) {
    final run = vm.work.run, failure = vm.work.run.result?['failure'] as Map?;
    final node = failure?['nodeId'] as String?,
        mapping = blocks.currentRunMapping(node);
    final filename = mapping?['sourceFile']
        ?.replaceAll('\\', '/')
        .split('/')
        .last;
    final label =
        {
          'passed': '통과',
          'failed': '실패',
          'cancelled': '취소됨',
          'cancel_requested': '취소 요청 중',
          'blocked': '차단됨',
          'infra_error': '실행 환경 오류',
          'running': '실행 중',
          'starting': '실행 준비 중',
          'validated': '검증 완료',
          'validating': '검증 중',
          'not_started': '실행 전',
          'validation_error': '검증 오류',
          'validation_stale': '다시 검증 필요',
        }[run.status] ??
        (run.running ? '실행 중' : '실행 전');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 16),
            Text(
              vm.resultOwner?.split(' (').first ??
                  vm.workspace.qa?.name ??
                  '현재 문서',
              style: const TextStyle(fontSize: 12),
            ),
            if (filename != null) ...[
              const SizedBox(width: 16),
              Text(filename, style: const TextStyle(fontSize: 12)),
            ],
            if (node != null && mapping != null)
              TextButton(
                onPressed: () {
                  blocks.focusGenerated(node);
                  setState(() => _composition = true);
                },
                child: const Text('원인 블록 보기'),
              ),
            if (run.images.isNotEmpty)
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('실행 화면 증거'),
                    content: WorkbenchDialogBody(
                      width: 850,
                      height: 500,
                      child: Image.memory(
                        run.images.first.bytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('닫기'),
                      ),
                    ],
                  ),
                ),
                child: Text('PNG ${run.images.length}개'),
              ),
            if (run.reportDirectory != null)
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: run.reportDirectory!),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('결과 폴더 경로를 복사했습니다.')),
                    );
                  }
                },
                child: const Text('결과 폴더 경로 복사'),
              ),
          ],
        ),
        if (failure != null)
          Text(
            '${failure['code'] ?? ''} · ${failure['message'] ?? ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        if (run.error != null)
          Text(
            run.error!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        if (run.images.isEmpty && run.result != null)
          const Text('수집된 화면 증거 없음', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _XmlSource extends StatefulWidget {
  const _XmlSource({
    required this.source,
    required this.edit,
    required this.selected,
  });
  final String source;
  final ValueChanged<String> edit;
  final ValueChanged<String?> selected;
  @override
  State<_XmlSource> createState() => _XmlSourceState();
}

class _XmlSourceState extends State<_XmlSource> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.source,
  );
  bool _syncing = false;
  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  void _changed() {
    if (_syncing) return;
    widget.edit(_controller.text);
    final offset = _controller.selection.baseOffset;
    if (offset < 0) return;
    String? selected;
    for (final match in RegExp(
      r'<node\s[^>]*\bid="([^"]+)"[^>]*>[\s\S]*?</node>|<node\s[^>]*\bid="([^"]+)"[^>]*/>',
    ).allMatches(_controller.text)) {
      if (offset >= match.start && offset <= match.end) {
        selected = match.group(1) ?? match.group(2);
        break;
      }
    }
    widget.selected(selected);
  }

  @override
  void didUpdateWidget(covariant _XmlSource oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.source) {
      _syncing = true;
      _controller.value = TextEditingValue(
        text: widget.source,
        selection: TextSelection.collapsed(
          offset: _controller.selection.baseOffset.clamp(
            0,
            widget.source.length,
          ),
        ),
      );
      _syncing = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    key: const Key('workspace-source'),
    controller: _controller,
    expands: true,
    maxLines: null,
    minLines: null,
    style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      labelText: '전체 QA 원문 · XML / JSON',
    ),
  );
}
