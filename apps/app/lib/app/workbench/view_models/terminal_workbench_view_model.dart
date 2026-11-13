import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xterm2/xterm.dart';
import '../../../features/interactive_terminal/services/terminal_service.dart';
import '../../../features/interactive_terminal/services/terminal_profile_service.dart';
import '../../../features/interactive_terminal/models/terminal_profile.dart';
import '../../../features/interactive_terminal/repositories/live_document_repository.dart';
import 'desktop_workspace_view_model.dart';
import 'terminal_session_view_model.dart';
import 'xml_block_workbench_view_model.dart';

/// Application-scoped pool. A hidden view never stops its native session.
class TerminalWorkbenchViewModel extends ChangeNotifier {
  TerminalWorkbenchViewModel(this.desktop, this._firstService, this.documents, {
    TerminalService Function()? serviceFactory, TerminalProfileService? profiles,
    this.composition,
  }) : _serviceFactory = serviceFactory ?? TerminalService.new,
       profiles = profiles ?? TerminalProfileService() {
    _preview = _make(TerminalService(), preview: true);
    desktop.addListener(_desktopChanged);
    _lastMode = composition?.enabled ?? false;
    _lastCompositionRevision = composition?.revision ?? 0;
    composition?.addListener(_compositionChanged);
    _lastIdentity = identity;
  }
  final DesktopWorkspaceViewModel desktop;
  final TerminalService _firstService;
  final TerminalService Function() _serviceFactory;
  final LiveDocumentRepository documents;
  final TerminalProfileService profiles;
  final XmlBlockWorkbenchViewModel? composition;
  bool _lastMode = false;
  int _lastCompositionRevision = 0, _modeEpoch = 0;
  late final TerminalSessionViewModel _preview;
  final List<TerminalSessionViewModel> _sessions = [];
  final Map<String, String> _writers = {}, _lastSelected = {};
  final Map<String, int> _epochs = {};
  final Set<String> _barriers = {};
  String? selectedId, secondaryId, poolError;
  String _lastIdentity = '';
  int _serial = 0;
  bool _disposed = false, _adding = false, split = false, _firstUsed = false;
  String get identity => '${desktop.workspace.projectId}/${desktop.workspace.qaId}';
  List<TerminalSessionViewModel> get sessions => List.unmodifiable(_sessions);
  List<TerminalSessionViewModel> get currentSessions => _sessions.where((s) => s.qaIdentity == identity).toList();
  TerminalSessionViewModel get selected => _sessions.where((s) => s.id == selectedId).firstOrNull ?? _preview;
  TerminalSessionViewModel? get secondary => _sessions.where((s) => s.id == secondaryId && s.id != selectedId).firstOrNull;
  bool get active => _sessions.any((s) => s.active);
  bool get canStart => !_adding && !_disposed && _sessions.length < 8 && !desktop.busy && desktop.workspace.qa != null;
  TerminalService get service => selected.service;
  Terminal get terminal => selected.terminal;
  Directory? get session => selected.session;
  String? get qaIdentity => selected.qaIdentity;
  String? get error => poolError ?? selected.error;
  String get state => selected.state;
  bool get canUndo => selected.canUndo;
  String? writerFor(String qa) => _writers[qa];
  bool isWriter(TerminalSessionViewModel item) => _writers[item.qaIdentity] == item.id && !_barriers.contains(item.qaIdentity);
  TerminalSessionViewModel _make(TerminalService service, {bool preview = false}) {
    final id = 'terminal-${++_serial}';
    late TerminalSessionViewModel item;
    item = TerminalSessionViewModel(desktop, service, documents,
      id: id, isWriter: () => isWriter(item),
      writerEpoch: () => _epochs[item.qaIdentity] ?? 0, previewEnabled: preview,
      canEditDocument: () => composition?.enabled != true,
      documentModeRevision: () => _modeEpoch);
    item.addListener(_sessionChanged);
    return item;
  }
  void _sessionChanged() {
    if (_disposed) return;
    _preview.previewEnabled = currentSessions.isEmpty;
    for (final item in _sessions) {
      final qa = item.qaIdentity;
      if (qa != null && _writers[qa] == item.id && item.service.cleanupUnknown && _barriers.add(qa)) {
        _epochs[qa] = (_epochs[qa] ?? 0) + 1;
      }
    }
    desktop.setRunBlock('terminal', _barriers.contains(identity) || _sessions.any((s) => s.preventsRun));
    notifyListeners();
  }
  void _compositionChanged() {
    if (_disposed || (_lastMode == composition!.enabled && _lastCompositionRevision == composition!.revision)) return;
    _lastMode = composition!.enabled;
    _lastCompositionRevision = composition!.revision;
    ++_modeEpoch;
    for (final item in {..._sessions, _preview}) { item.invalidateDocumentMode(); }
    _sessionChanged();
  }
  void _desktopChanged() {
    if (_disposed) return;
    if (_lastIdentity != identity) {
      _lastSelected[_lastIdentity] = selectedId ?? '';
      _lastIdentity = identity;
      selectedId = _lastSelected[identity];
      if (!currentSessions.any((s) => s.id == selectedId)) selectedId = currentSessions.firstOrNull?.id;
      secondaryId = null;
    }
    final valid = {for (final p in desktop.workspace.workspace.projects) for (final q in p.documents) '${p.id}/${q.id}'};
    for (final qa in _writers.keys.toList()) {
      if (!valid.contains(qa)) { _writers.remove(qa); _epochs[qa] = (_epochs[qa] ?? 0) + 1; }
    }
    _sessionChanged();
  }
  Future<TerminalProfile> inspect(String provider, {String? executable}) => profiles.inspect(provider, executable: executable);
  Future<void> add(TerminalProfile profile, {bool writer = false}) async {
    if (!canStart || !profile.available) return;
    _adding = true;
    poolError = null;
    final qa = identity, item = _make(_serviceFactory());
    item.provider = profile.id;
    item.displayName = '${profile.label} ${_sessions.length + 1}';
    item.qaIdentity = qa;
    _sessions.add(item);
    selectedId = item.id;
    if (writer && !_writers.containsKey(qa) && !_barriers.contains(qa)) {
      _writers[qa] = item.id;
      _epochs[qa] = (_epochs[qa] ?? 0) + 1;
    }
    _sessionChanged();
    try {
      await item.start(executablePath: profile.executable, providerId: profile.id, arguments: profile.arguments);
    } finally { _adding = false; _sessionChanged(); }
  }
  /// Existing explicit Codex entry also selects the initial writer.
  Future<void> start() async {
    if (!canStart) return;
    _adding = true;
    final item = _make(_firstUsed ? _serviceFactory() : _firstService);
    _firstUsed = true;
    item.previewEnabled = false;
    item.qaIdentity = identity;
    item.displayName = 'Codex ${_sessions.length + 1}';
    _sessions.add(item);
    selectedId = item.id;
    if (!_writers.containsKey(identity) && !_barriers.contains(identity)) {
      _writers[identity] = item.id;
      _epochs[identity] = (_epochs[identity] ?? 0) + 1;
    }
    try { await item.start(); } finally { _adding = false; _sessionChanged(); }
  }
  void select(String id) {
    if (!_sessions.any((s) => s.id == id)) return;
    if (secondaryId == id) secondaryId = selectedId;
    selectedId = id; poolError = null; _sessionChanged();
  }
  void rename(String id, String name) {
    final item = _sessions.where((s) => s.id == id).firstOrNull;
    if (item == null || name.trim().isEmpty || name.length > 80) return;
    item.displayName = name.trim(); _sessionChanged();
  }
  bool grantWriter(String id) {
    final next = _sessions.where((s) => s.id == id).firstOrNull;
    if (next == null || next.qaIdentity != identity || next.closing || next.service.cleanupUnknown || next.service.state == 'closing' || next.session == null) return false;
    final qa = next.qaIdentity!;
    final old = _sessions.where((s) => s.id == _writers[qa]).firstOrNull;
    if (_barriers.contains(qa) || old?.closing == true || old?.service.state == 'closing' || old?.service.cleanupUnknown == true || desktop.work.run.running) return false;
    _epochs[qa] = (_epochs[qa] ?? 0) + 1;
    _writers[qa] = next.id;
    old?.invalidateOwnership(); next.invalidateOwnership();
    unawaited(next.refresh(force: true)); _sessionChanged(); return true;
  }
  void revokeWriter() {
    final current = _sessions.where((s) => s.id == _writers[identity]).firstOrNull;
    if (current?.closing == true || current?.service.cleanupUnknown == true) return;
    final old = _writers.remove(identity);
    _epochs[identity] = (_epochs[identity] ?? 0) + 1;
    _sessions.where((s) => s.id == old).firstOrNull?.invalidateOwnership();
    _sessionChanged();
  }
  void toggleSplit() {
    split = !split;
    secondaryId ??= currentSessions.where((s) => s.id != selectedId).firstOrNull?.id;
    _sessionChanged();
  }
  void input(String text) => selected.input(text);
  Future<void> updateContext() => selected.updateContext();
  Future<void> refresh({bool force = false}) => selected.refresh(force: force);
  Future<void> saveGui() => selected.saveGui();
  Future<void> acceptFile(String ext) => selected.acceptFile(ext);
  void undo() => selected.undo();
  Future<void> close() => selected.close();
  Future<void> detach() async { if (!selected.active) await selected.detach(); }
  Future<void> closeAll() async { await Future.wait(_sessions.map((s) => s.close())); }
  Future<void> remove(String id) async {
    final item = _sessions.where((s) => s.id == id).firstOrNull;
    if (item == null || item.active || item.service.cleanupUnknown) return;
    if (_writers[item.qaIdentity] == id) {
      _writers.remove(item.qaIdentity);
      _epochs[item.qaIdentity!] = (_epochs[item.qaIdentity] ?? 0) + 1;
    }
    item.removeListener(_sessionChanged);
    await item.detach();
    item.dispose();
    if (!identical(item.service, _firstService)) item.service.dispose();
    _sessions.remove(item); selectedId = currentSessions.firstOrNull?.id;
    if (secondaryId == id) secondaryId = null;
    _sessionChanged();
  }
  @override
  void dispose() {
    _disposed = true; desktop.removeListener(_desktopChanged);
    composition?.removeListener(_compositionChanged);
    desktop.setRunBlock('terminal', false);
    for (final item in {..._sessions, _preview}) {
      item.removeListener(_sessionChanged); item.dispose();
      if (!identical(item.service, _firstService)) item.service.dispose();
    }
    super.dispose();
  }
}
