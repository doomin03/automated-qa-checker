import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../features/run_review/view_models/run_view_model.dart';
import '../../../features/run_review/view_models/engine_settings_view_model.dart';
import '../../../features/scenario_editor/view_models/scenario_editor_view_model.dart';
import '../../../features/scenario_editor/view_models/flow_editor_view_model.dart';
import '../../../features/design_baselines/view_models/design_view_model.dart';
import '../../../features/design_baselines/models/reference_input.dart';
import '../../../features/shared_scenarios/view_models/shared_view_model.dart';
import '../../../features/organization_login/view_models/organization_view_model.dart';

class WorkbenchStamp {
  const WorkbenchStamp(this.documentRevision, this.settingsRevision);
  final int documentRevision, settingsRevision;
}

/// Application commands compose features without duplicating their state.
class WorkbenchViewModel extends ChangeNotifier {
  WorkbenchViewModel({
    required this.editor,
    required this.settings,
    required this.run,
    required this.design,
    required this.flow,
    required this.shared,
    required this.auth,
  }) {
    settings.addListener(_settingsChanged);
    for (final source in _sources) {
      source.addListener(_changed);
    }
  }
  final ScenarioEditorViewModel editor;
  final EngineSettingsViewModel settings;
  final RunViewModel run;
  final DesignViewModel design;
  final FlowEditorViewModel flow;
  final SharedViewModel shared;
  final OrganizationViewModel auth;
  bool _disposed = false, _applying = false;
  int _generation = 0;
  String? message;
  List<ChangeNotifier> get _sources => [
    editor,
    run,
    design,
    flow,
    shared,
    auth,
  ];
  bool get busy => _applying || run.busy || design.busy || editor.isBusy;
  String get source => editor.draft.content;
  WorkbenchStamp get stamp =>
      WorkbenchStamp(editor.revision, settings.revision);
  bool _current(WorkbenchStamp stamp) =>
      !_disposed &&
      editor.revision == stamp.documentRevision &&
      settings.revision == stamp.settingsRevision;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _settingsChanged() {
    run.clearCapabilities();
    run.invalidateValidation();
    _changed();
  }

  bool get canUsePlan =>
      run.plan != null &&
      run.matchesSource(source) &&
      run.matchesSettings(settings.execution);
  List<String> get selectorIds => List<String>.from(
    run.plan?['blueprint']?['selectors']?['selectors']?.keys ?? [],
  );

  Future<void> validate() async {
    if (!_disposed && !busy) await run.validate(settings.execution, source);
  }

  Future<void> execute() async {
    if (!_disposed && !busy) await run.run(settings.execution, source);
  }

  Future<void> cancel() => run.cancel();
  Future<void> inspectCapabilities() async {
    if (!_disposed && !busy) {
      await run.inspectCapabilities(settings.execution, settings.platform);
    }
  }

  Future<void> exportXml() =>
      _apply(() => run.exportXml(settings.execution, source));
  Future<void> expandAuthoring({String? document, WorkbenchStamp? ticket}) =>
      _apply(
        () => run.expandAuthoring(settings.execution, document ?? source),
        ticket: ticket,
      );
  Future<void> expandPreset(
    Map<String, dynamic> selection,
    WorkbenchStamp ticket,
  ) => _apply(
    () => run.expandPreset(
      settings.execution,
      selection['id'],
      selection['version'],
      selection['bindings'],
    ),
    ticket: ticket,
  );
  Future<void> attachReference(ReferenceInput input, WorkbenchStamp ticket) =>
      _apply(
        () => design.attach(settings.execution, source, input),
        ticket: ticket,
      );
  Future<void> receive() => _apply(shared.accept);
  Future<void> openOffline(String folder, String origin, String project) =>
      _apply(() => shared.offline(folder, origin, project));
  Future<void> _apply(
    Future<String?> Function() operation, {
    WorkbenchStamp? ticket,
  }) async {
    if (_disposed || busy) return;
    final captured = ticket ?? stamp;
    if (!_current(captured)) {
      message = '문서 또는 설정이 바뀌어 이전 입력을 적용하지 않았습니다.';
      _changed();
      return;
    }
    final generation = ++_generation;
    _applying = true;
    message = null;
    _changed();
    try {
      final result = await operation();
      if (_disposed || generation != _generation) return;
      if (!_current(captured)) {
        message = '문서 또는 설정이 바뀌어 이전 결과를 적용하지 않았습니다.';
        return;
      }
      if (result != null) editor.edit(result);
    } catch (_) {
      if (!_disposed) message = '작업을 완료하지 못했습니다. 초안은 유지됩니다.';
    } finally {
      if (!_disposed && generation == _generation) {
        _applying = false;
        _changed();
      }
    }
  }

  void loadSourceIntoFlow() {
    if (_disposed || busy) return;
    try {
      flow.load(jsonDecode(source) as Map<String, dynamic>);
      message = null;
    } catch (_) {
      message = 'XML은 먼저 검증한 뒤 계획에서 불러오세요.';
    }
    _changed();
  }

  void loadPlanIntoFlow() {
    if (!_disposed && !busy && canUsePlan) {
      flow.load(run.plan!['blueprint'] as Map<String, dynamic>);
    }
  }

  void applyFlow() {
    if (!_disposed && !busy && flow.blueprint != null) editor.edit(flow.source);
  }

  Future<void> login(String origin) async {
    shared.disconnect();
    await auth.login(origin);
  }

  Future<void> logout() async {
    shared.disconnect();
    await auth.logout();
  }

  Future<void> connectShared(
    String origin,
    String localToken,
    String project,
    String folder,
  ) async {
    if (_disposed || auth.busy) return;
    await shared.connect(
      origin,
      auth.identity == null ? localToken : auth.credentialFor(origin),
      project,
      folder,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    settings.removeListener(_settingsChanged);
    for (final source in _sources) {
      source.removeListener(_changed);
    }
    super.dispose();
  }
}
