import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../features/project_workspace/view_models/workspace_view_model.dart';
import '../../../features/project_workspace/models/workspace.dart';
import '../../../features/project_workspace/services/desktop_defaults_service.dart';
import '../../../features/ai_authoring/view_models/ai_authoring_view_model.dart';
import '../../../features/ai_authoring/models/ai_request.dart';
import '../../../features/scenario_editor/repositories/blueprint_catalog.dart';
import 'workbench_view_model.dart';

class DesktopWorkspaceViewModel extends ChangeNotifier {
  DesktopWorkspaceViewModel(
    this.workspace,
    this.work,
    this.ai,
    this.catalog,
    this.defaults,
  ) {
    _seenDocumentRevision = work.editor.revision;
    _seenSettingsRevision = work.settings.revision;
    for (final source in _sources) {
      source.addListener(_changed);
    }
    work.editor.addListener(_invalidate);
    work.settings.addListener(_invalidate);
  }
  final WorkspaceViewModel workspace;
  final WorkbenchViewModel work;
  final AiAuthoringViewModel ai;
  final BlueprintCatalog catalog;
  final DesktopDefaultsService defaults;
  bool initialized = false,
      _disposed = false,
      _saving = false,
      _syncingFlow = false;
  final Set<String> _runBlocks = {};
  bool get externalRunBlocked => _runBlocks.isNotEmpty;
  // Existing terminal assignments affect only the terminal reason.
  set externalRunBlocked(bool value) => setRunBlock('terminal', value);
  void setRunBlock(String reason, bool blocked) {
    if (blocked) {
      _runBlocks.add(reason);
    } else {
      _runBlocks.remove(reason);
    }
  }

  Set<String> get runBlockReasons => Set.unmodifiable(_runBlocks);
  String? error, selectedNode, resultOwner, resultSnapshot;
  int selectionRevision = 0, _identityRevision = 0;
  int _seenDocumentRevision = 0, _seenSettingsRevision = 0;
  String? _undoSource;
  int? _undoRevision;
  Map<String, dynamic>? contract;
  Map<String, dynamic>? authoringContract;
  List<ChangeNotifier> get _sources => [workspace, work, ai];
  bool get busy => _saving || workspace.busy || work.busy || ai.busy;
  bool get dirty =>
      workspace.promptsDirty ||
      work.flow.isDirty ||
      (workspace.qa != null && work.source != workspace.qa!.source);
  bool get canUndoAi =>
      _undoSource != null && work.editor.revision == _undoRevision && !busy;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _invalidate() {
    if (_disposed) return;
    final documentChanged = _seenDocumentRevision != work.editor.revision;
    final settingsChanged = _seenSettingsRevision != work.settings.revision;
    _seenDocumentRevision = work.editor.revision;
    _seenSettingsRevision = work.settings.revision;
    if (!documentChanged && !settingsChanged) return;
    if (ai.proposal != null) ai.invalidate();
    if (documentChanged && !_syncingFlow && work.flow.blueprint != null) {
      work.flow.clear();
    }
  }

  Future<void> initialize() async {
    if (initialized || _disposed) return;
    await workspace.initialize();
    if (_disposed) return;
    try {
      contract = await catalog.load();
      authoringContract = await catalog.authoring();
      var initial = <String, String>{};
      try {
        initial = await defaults.load();
      } catch (failure) {
        error = '번들 실행 환경 검증 실패: $failure. 외부 실행 환경 설정을 선택할 수 있습니다.';
      }
      if (_disposed) return;
      final s = {...initial, ...workspace.workspace.settings};
      ai.configure(
        AiSettings(
          provider: s['aiProvider'] ?? 'codex',
          executable: s['aiExecutable'] ?? '',
        ),
      );
      work.settings.restore(initial, workspace.workspace.settings);
    } catch (_) {
      error = '앱 계약 또는 초기 연결 설정을 읽지 못했습니다.';
    }
    initialized = true;
    _changed();
  }

  void select(String? projectId, String? qaId) {
    if (busy || _disposed) return;
    workspace.select(projectId, qaId);
    work.shared.repository.activateDocument(
      qaId == null ? null : '$projectId/$qaId',
    );
    work.editor.loadWorkspaceDocument(workspace.qa?.source ?? '');
    _identityRevision++;
    selectNode(null);
    _undoSource = null;
    ai.resetContext();
    work.run.invalidateValidation();
    _changed();
  }

  void selectNode(String? id) {
    if (selectedNode == id) return;
    selectedNode = id;
    selectionRevision++;
    ai.invalidate();
    _changed();
  }

  Future<void> createProject(String name) async {
    if (busy) return;
    if (await workspace.createProject(name)) {
      work.shared.repository.activateDocument(null);
      work.editor.loadWorkspaceDocument('');
      _identityRevision++;
      ai.resetContext();
      selectNode(null);
    }
  }

  Future<void> createQa(String name) async {
    if (busy || contract == null) return;
    // Public example starts editable; its target is explicit and never auto-run.
    final source = const JsonEncoder.withIndent('  ')
        .convert(contract!['example']);
    await createQaFromSource(name, source);
  }

  Future<bool> createQaFromSource(String name, String source) async {
    if (busy || workspace.projectId == null) return false;
    if (await workspace.createQa(name, source)) {
      work.shared.repository.activateDocument(
        '${workspace.projectId}/${workspace.qaId}',
      );
      work.editor.loadWorkspaceDocument(source);
      _identityRevision++;
      ai.resetContext();
      selectNode(null);
      return true;
    }
    return false;
  }

  Map<String, String> get savedSettings => {
    ...work.settings.runtimeProvenance,
    'aiProvider': ai.settings.provider,
    'aiExecutable': ai.settings.executable,
    'nodePath': work.settings.value.nodePath,
    'cliPath': work.settings.value.cliPath,
    'reportRoot': work.settings.value.reportRoot,
    'referenceRoot': work.settings.value.referenceRoot,
    'appiumConfig': work.settings.value.appiumConfig,
  };
  Future<bool> save({String? projectName, String? qaName}) async {
    if (busy || _disposed) return false;
    if (work.flow.isDirty) applyFlow();
    _saving = true;
    _changed();
    final source = work.source;
    final saved = await workspace.save(
      source,
      projectName: projectName,
      qaName: qaName,
      settings: savedSettings,
    );
    if (!_disposed) {
      if (saved) work.editor.markWorkspaceSaved(source);
      _saving = false;
      _changed();
    }
    return saved;
  }

  AiStamp get stamp => AiStamp(
    workspace.projectId ?? '',
    workspace.qaId ?? '',
    work.editor.revision,
    selectionRevision + workspace.selectionRevision,
    workspace.promptRevision,
    work.settings.revision + ai.settingsRevision,
    _identityRevision,
  );
  bool _current(AiStamp value) => !_disposed && stamp == value;
  Future<void> generate() async {
    if (busy || workspace.qa == null || contract == null) return;
    if (work.flow.isDirty) applyFlow();
    await ai.generate(
      stamp: stamp,
      isCurrent: _current,
      engineSettings: work.settings.execution,
      sessions: Directory(
        '${workspace.repository.directory}${Platform.pathSeparator}sessions${Platform.pathSeparator}${workspace.projectId}',
      ),
      source: work.source,
      instructions: workspace.instructions,
      qaPrompt: workspace.prompt,
      selectedNode: selectedNode,
      contract: contract!,
    );
  }

  bool applyProposal() {
    final proposal = ai.proposal;
    if (busy ||
        proposal == null ||
        ai.status != 'review' ||
        !_current(proposal.stamp)) {
      error = '이전 문서/선택의 제안입니다. 다시 생성하세요.';
      _changed();
      return false;
    }
    _undoSource = work.source;
    work.editor.edit(proposal.answer.xml);
    _undoRevision = work.editor.revision;
    work.run.invalidateValidation();
    ai.dismiss();
    error = null;
    _changed();
    return true;
  }

  void undoAi() {
    if (!canUndoAi) {
      error = '적용 이후 편집이 있어 이전 제안을 되돌릴 수 없습니다.';
      _changed();
      return;
    }
    work.editor.edit(_undoSource!);
    _undoSource = null;
    work.run.invalidateValidation();
    ai.dismiss();
    _changed();
  }

  void applyFlow() {
    if (work.flow.blueprint == null || busy) return;
    _syncingFlow = true;
    try {
      work.applyFlow();
      work.flow.markClean();
    } finally {
      _syncingFlow = false;
    }
  }

  void acceptExternalDocument(String source, Map<String, dynamic> plan) {
    if (_disposed || work.run.running) return;
    _syncingFlow = true;
    try {
      work.editor.edit(source);
      work.flow.load(plan['blueprint'] as Map<String, dynamic>);
      work.run.invalidateValidation();
    } finally {
      _syncingFlow = false;
    }
    _changed();
  }

  Future<void> validate() async {
    if (!busy && workspace.qa != null) {
      if (work.flow.isDirty) applyFlow();
      await work.validate();
      if (!_disposed && work.canUsePlan) {
        work.loadPlanIntoFlow();
      }
    }
  }

  Future<void> execute() async {
    if (busy || externalRunBlocked || workspace.qa == null) return;
    if (work.flow.isDirty) applyFlow();
    if (!work.canUsePlan) {
      error = '현재 QA와 설정을 먼저 검증하세요.';
      _changed();
      return;
    }
    resultOwner =
        '${workspace.project!.name} / ${workspace.qa!.name} (${workspace.qaId})';
    resultSnapshot = work.run.plan?['blueprintSnapshotHash'] as String?;
    final projectId = workspace.projectId!, qaId = workspace.qaId!;
    _changed();
    await work.execute();
    final result = work.run.result;
    if (!_disposed && result != null && work.run.reportDirectory != null) {
      await workspace.recordRun(
        projectId,
        qaId,
        LastRun(
          runId: result['runId'],
          snapshotHash: resultSnapshot!,
          reportDirectory: work.run.reportDirectory!,
          outcome: result['outcome'],
        ),
      );
    }
  }

  Future<void> importFile(String path) async {
    if (!busy) {
      await work.editor.open(path);
      _identityRevision++;
      ai.dismiss();
      selectNode(null);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final source in _sources) {
      source.removeListener(_changed);
    }
    work.editor.removeListener(_invalidate);
    work.settings.removeListener(_invalidate);
    super.dispose();
  }
}
