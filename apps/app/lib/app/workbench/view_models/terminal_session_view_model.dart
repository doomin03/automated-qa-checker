import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:xterm2/xterm.dart';

import '../../../features/interactive_terminal/services/terminal_service.dart';
import '../../../features/interactive_terminal/repositories/live_document_repository.dart';
import 'desktop_workspace_view_model.dart';

/// Coordinates the session and accepted document; does not duplicate Flow/run state.
class TerminalSessionViewModel extends ChangeNotifier {
  TerminalSessionViewModel(
    this.desktop,
    this.service,
    this.documents, {
    required this.id,
    required this.isWriter,
    required this.writerEpoch,
    bool Function()? canEditDocument,
    int Function()? documentModeRevision,
    this.previewEnabled = false,
  }) : canEditDocument = canEditDocument ?? (() => true),
       documentModeRevision = documentModeRevision ?? (() => 0) {
    terminal.onOutput = input;
    terminal.onResize = (w, h, _, _) => service.resize(w, h);
    service.onOutput = terminal.write;
    service.onState = (_) => _notify();
    _seenIdentity = identity;
    desktop.addListener(_desktopChanged);
  }
  final String id;
  final bool Function() isWriter;
  final int Function() writerEpoch;
  final bool Function() canEditDocument;
  final int Function() documentModeRevision;
  bool previewEnabled;
  String provider = 'codex', displayName = 'Codex';
  String? environmentVersion;
  late String _seenIdentity;
  final DesktopWorkspaceViewModel desktop;
  final TerminalService service;
  final LiveDocumentRepository documents;
  final Terminal terminal = Terminal(maxLines: 10000);
  Directory? session;
  String? qaIdentity, error;
  String state = 'idle', format = 'xml';
  bool _disposed = false,
      _scanning = false,
      _writing = false,
      _preparing = false;
  Timer? _poll;
  StreamSubscription<FileSystemEvent>? _watcher;
  Timer? _debounce;
  Timer? _preview;
  String? _previewIdentity;
  int _previewRevision = -1;
  int _generation = 0, _syncedRevision = -1, _settingsRevision = -1;
  final Map<String, String?> _hashes = {};
  String? _undoSource;
  int? _undoRevision;
  int? _undoEpoch;
  bool _ownershipSyncRequired = false;
  bool closing = false;
  Future<void>? _closeFuture;
  bool _previewBusy = false, _previewPending = false;
  int get inputEpoch => _generation;
  LiveDocument? conflict;
  bool get active => _preparing || service.active;
  bool get canStart =>
      !_preparing &&
      !active &&
      !service.cleanupUnknown &&
      !desktop.busy &&
      desktop.workspace.qa != null;
  bool get preventsRun =>
      canEditDocument() &&
      session != null &&
      identity == qaIdentity &&
      isWriter() &&
      (service.cleanupUnknown || !['synced', 'idle', 'closed'].contains(state));
  bool get canUndo =>
      canEditDocument() &&
      identity == qaIdentity &&
      isWriter() &&
      !closing &&
      !service.cleanupUnknown &&
      _undoEpoch == writerEpoch() &&
      _undoSource != null &&
      desktop.work.editor.revision == _undoRevision &&
      !desktop.busy;
  String get identity =>
      '${desktop.workspace.projectId}/${desktop.workspace.qaId}';
  void _notify() {
    if (!_disposed) {
      // Pool aggregates the blockers for all sessions.
      notifyListeners();
    }
  }

  String get contextText =>
      '''# QA 작업 문맥
프로젝트: ${desktop.workspace.project?.name}
QA: ${desktop.workspace.qa?.name}
선택 node: ${desktop.selectedNode ?? '전체 흐름'}
인접 edge: ${jsonEncode(desktop.work.flow.edges.where((e) => e['from'] == desktop.selectedNode || e['to'] == desktop.selectedNode).toList())}
프로젝트 지침: ${desktop.workspace.instructions}
QA 지속 요청: ${desktop.workspace.prompt}

scenario.xml 또는 scenario.json의 정의만 편집하세요. 앱은 유효한 변경을 자동으로 그래프에 반영합니다.
QA 실행은 앱에서 사용자가 명시합니다. 임의 테스트 실행/원본 workspace 변경은 요청하지 않습니다.
한 번에 하나의 형식을 편집하고, 기존 node ID/target/selectors/variables와 요청 밖 내용을 보존하세요.
공개 계약은 engine-contract.json의 schema/example을 참고하세요.
''';
  void _desktopChanged() {
    // Selection alone is not a document generation change.
    if (_seenIdentity != identity) {
      _seenIdentity = identity;
      ++_generation;
      _undoSource = null;
      if (session != null) state = 'needs_validation';
    }
    if (session != null &&
        desktop.work.settings.revision != _settingsRevision) {
      _settingsRevision = desktop.work.settings.revision;
      ++_generation;
      state = 'needs_validation';
      _hashes.clear();
    }
    if (previewEnabled &&
        session == null &&
        desktop.workspace.qa != null &&
        !desktop.work.flow.isDirty &&
        (_previewIdentity != identity ||
            _previewRevision != desktop.work.editor.revision)) {
      _previewIdentity = identity;
      _previewRevision = desktop.work.editor.revision;
      _preview?.cancel();
      _preview = Timer(
        const Duration(milliseconds: 350),
        () => unawaited(previewCurrent()),
      );
    }
    _notify();
  }

  Future<void> previewCurrent() async {
    if (_previewBusy) {
      _previewPending = true;
      return;
    }
    if (_disposed ||
        !previewEnabled ||
        !canEditDocument() ||
        session != null ||
        desktop.work.flow.isDirty ||
        desktop.busy) {
      return;
    }
    final revision = desktop.work.editor.revision,
        id = identity,
        setting = desktop.work.settings.revision,
        source = desktop.work.source,
        flowRevision = desktop.work.flow.revision;
    if (source.trim().isEmpty) return;
    _previewBusy = true;
    final ticket = _generation, modeRevision = documentModeRevision();
    try {
      final result = await documents.compile(
        desktop.work.settings.execution,
        LiveDocument('preview', source),
      );
      if (!_disposed &&
          ticket == _generation &&
          canEditDocument() &&
          modeRevision == documentModeRevision() &&
          previewEnabled &&
          session == null &&
          identity == id &&
          desktop.work.editor.revision == revision &&
          desktop.work.settings.revision == setting &&
          desktop.work.flow.revision == flowRevision &&
          !desktop.work.flow.isDirty) {
        desktop.work.flow.load(
          result.plan['blueprint'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      if (!_disposed &&
          identity == id &&
          desktop.work.editor.revision == revision) {
        error = '$e';
        _notify();
      }
    } finally {
      _previewBusy = false;
      if (_previewPending && !_disposed) {
        _previewPending = false;
        unawaited(previewCurrent());
      }
    }
  }

  Future<void> start({
    String? executablePath,
    String providerId = 'codex',
    List<String> Function(String)? arguments,
  }) async {
    if (!canStart) return;
    if (providerId == 'codex' &&
        executablePath == null &&
        desktop.ai.settings.provider != 'codex') {
      error = '현재 실제 터미널 인수 대상은 설치된 Codex입니다.';
      _notify();
      return;
    }
    if (canEditDocument() && desktop.work.flow.isDirty) desktop.applyFlow();
    final capturedIdentity = identity, revision = desktop.work.editor.revision;
    final ticket = ++_generation;
    _preparing = true;
    state = 'preparing';
    error = null;
    _notify();
    try {
      provider = providerId;
      final executable = executablePath ?? desktop.ai.settings.executable;
      if (!File(executable).isAbsolute || !await File(executable).exists()) {
        throw const FormatException('설정에서 Codex 실행 파일을 지정하세요.');
      }
      if (_disposed || ticket != _generation) return;
      _poll?.cancel();
      _debounce?.cancel();
      await _watcher?.cancel();
      if (_disposed || ticket != _generation) return;
      final epoch = ticket;
      final created = await documents.createSession(
        desktop.workspace.repository.directory,
        desktop.workspace.projectId!,
        desktop.workspace.qaId!,
        desktop.work.source,
        contextText,
      );
      if (_disposed ||
          identity != capturedIdentity ||
          desktop.work.editor.revision != revision ||
          epoch != _generation) {
        return;
      }
      session = created;
      qaIdentity = identity;
      _syncedRevision = revision;
      _settingsRevision = desktop.work.settings.revision;
      format = desktop.work.source.trimLeft().startsWith('<') ? 'xml' : 'json';
      await documents.writeAuxiliary(
        created,
        'engine-contract.json',
        jsonEncode(desktop.contract),
      );
      await documents.prepareEnvironment(
        created,
        provider,
        desktop.contract,
        authoringContract: desktop.authoringContract,
      );
      environmentVersion = LiveDocumentRepository.guideVersion;
      if (_disposed || epoch != _generation) return;
      _hashes.clear();
      await refresh(force: true);
      if (_disposed || epoch != _generation) return;
      _watcher = created.watch().listen(
        (_) {
          _debounce?.cancel();
          _debounce = Timer(
            const Duration(milliseconds: 350),
            () => unawaited(refresh()),
          );
        },
        onError: (Object e) {
          error = '파일 감시 오류: 수동 새로고침을 사용하세요.';
          _notify();
        },
      );
      _poll = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(refresh()),
      );
      await service.start(
        executable,
        arguments?.call(created.path) ??
            [
              '--no-daemon',
              '--no-alt-screen',
              '-C',
              created.path,
              '-s',
              'workspace-write',
              '-a',
              'on-request',
            ],
        created.path,
      );
    } catch (e) {
      if (!_disposed && ticket == _generation) {
        error = '$e';
        state = 'error';
      }
    } finally {
      _preparing = false;
      _notify();
    }
  }

  void input(String text) {
    try {
      service.write(text);
    } catch (e) {
      error = '$e';
      _notify();
    }
  }

  Future<void> updateContext() async {
    if (session == null || identity != qaIdentity || _disposed) return;
    await documents.writeContext(session!, contextText);
    _notify();
  }

  Future<void> refresh({bool force = false, bool acceptFile = false}) async {
    final folder = session;
    if (folder == null ||
        identity != qaIdentity ||
        _scanning ||
        _writing ||
        _disposed ||
        closing ||
        service.cleanupUnknown ||
        service.state == 'closing') {
      return;
    }
    _scanning = true;
    final ownerEpoch = writerEpoch(), modeRevision = documentModeRevision();
    final ticket = _generation,
        id = identity,
        revision = desktop.work.editor.revision,
        flowRevision = desktop.work.flow.revision,
        setting = desktop.work.settings.revision;
    try {
      final files = <String, LiveDocument?>{};
      for (final ext in ['xml', 'json']) {
        files[ext] = await documents.read(folder, ext);
      }
      final changed = files.keys
          .where((k) => files[k]?.hash != _hashes[k])
          .toList();
      if (changed.isEmpty && !force) return;
      if (changed.length > 1 && files.values.every((f) => f != null)) {
        state = 'conflict';
        error = 'XML과 JSON이 함께 변경되었습니다. 수용할 형식을 선택하세요.';
        return;
      }
      final ext = changed.where((k) => files[k] != null).firstOrNull ?? format;
      final file = files[ext];
      if (file == null) {
        throw const FormatException('활성 QA 파일이 삭제되었습니다. 마지막 그래프를 유지합니다.');
      }
      if (canEditDocument() &&
          isWriter() &&
          _ownershipSyncRequired &&
          !acceptFile &&
          file.source != desktop.work.source) {
        conflict = file;
        state = 'conflict';
        error = '작성 권한이 변경되었습니다. 현재 GUI와 세션 사본의 적용 방향을 선택하세요.';
        return;
      }
      if (canEditDocument() &&
          isWriter() &&
          !acceptFile &&
          (desktop.work.editor.revision != _syncedRevision ||
              desktop.work.flow.isDirty)) {
        conflict = file;
        state = 'conflict';
        error = 'GUI와 터미널 파일이 함께 변경되었습니다.';
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if ((await documents.read(folder, ext))?.hash != file.hash) {
        state = 'writing';
        return;
      }
      state = 'compiling';
      _notify();
      final prepared = await documents.compile(
        desktop.work.settings.execution,
        file,
      );
      final finalFile = await documents.read(folder, ext);
      if (_disposed ||
          ownerEpoch != writerEpoch() ||
          modeRevision != documentModeRevision() ||
          closing ||
          service.cleanupUnknown ||
          service.state == 'closing' ||
          ticket != _generation ||
          id != identity ||
          identity != qaIdentity ||
          revision != desktop.work.editor.revision ||
          flowRevision != desktop.work.flow.revision ||
          setting != desktop.work.settings.revision ||
          finalFile?.hash != file.hash) {
        state = 'stale';
        return;
      }
      if (!isWriter() || !canEditDocument()) {
        state = canEditDocument() ? 'review_ready' : 'composition_review';
        conflict = file;
        error = null;
        for (final key in files.keys) {
          _hashes[key] = files[key]?.hash;
        }
        return;
      }
      if (desktop.work.run.running) {
        state = 'waiting_run';
        return;
      }
      if (desktop.work.source != file.source) {
        _undoSource = desktop.work.source;
        desktop.acceptExternalDocument(file.source, prepared.plan);
        _undoRevision = desktop.work.editor.revision;
        _undoEpoch = writerEpoch();
      } else {
        desktop.work.flow.load(
          prepared.plan['blueprint'] as Map<String, dynamic>,
        );
      }
      format = ext;
      _ownershipSyncRequired = false;
      _syncedRevision = desktop.work.editor.revision;
      for (final key in files.keys) {
        _hashes[key] = files[key]?.hash;
      }
      conflict = null;
      error = null;
      state = 'synced';
    } catch (e) {
      if (!_disposed && ticket == _generation) {
        error = '$e';
        state = 'invalid';
      }
    } finally {
      _scanning = false;
      _notify();
    }
  }

  Future<String> authoringEnvironment() async {
    final folder = session, ticket = _generation;
    if (folder == null || _disposed || closing) {
      throw StateError('세션이 준비되지 않았습니다.');
    }
    final summary = await documents.describeEnvironment(folder);
    if (_disposed || closing || ticket != _generation || session != folder) {
      throw StateError('세션이 변경되었습니다. 다시 확인하세요.');
    }
    return '고정 QA: $qaIdentity\n$summary';
  }

  String get skillInvocation => switch (provider) {
    'codex' => r'$qa-authoring QA-CONTEXT.md를 읽고 요청한 scenario.xml 또는 scenario.json 정의만 수정해 주세요. 테스트는 실행하지 마세요.',
    'claude' => '/qa-authoring QA-CONTEXT.md를 읽고 요청한 scenario.xml 또는 scenario.json 정의만 수정해 주세요. 테스트는 실행하지 마세요.',
    _ => '이 셸에는 AI skill 호출을 제공하지 않습니다.',
  };

  Future<void> acceptFile(String ext) async {
    final folder = session, ticket = _generation, id = identity;
    final revision = desktop.work.editor.revision,
        flowRevision = desktop.work.flow.revision;
    if (folder == null ||
        !canEditDocument() ||
        !isWriter() ||
        closing ||
        service.cleanupUnknown ||
        id != qaIdentity ||
        desktop.work.run.running ||
        _scanning ||
        _writing ||
        _disposed) {
      return;
    }
    try {
      // Preserve both source versions before choosing one format.
      await documents.preserveCopy(
        folder,
        desktop.work.flow.isDirty
            ? desktop.work.flow.source
            : desktop.work.source,
      );
      if (_disposed ||
          ticket != _generation ||
          identity != id ||
          revision != desktop.work.editor.revision ||
          flowRevision != desktop.work.flow.revision ||
          qaIdentity != id) {
        return;
      }
      format = ext;
      final hashes = <String, String?>{};
      for (final key in ['xml', 'json']) {
        hashes[key] = (await documents.read(folder, key))?.hash;
      }
      if (_disposed ||
          ticket != _generation ||
          identity != id ||
          revision != desktop.work.editor.revision ||
          flowRevision != desktop.work.flow.revision ||
          qaIdentity != id) {
        return;
      }
      _hashes.addAll(hashes);
      _hashes[ext] = null;
      await refresh(force: true, acceptFile: true);
    } catch (e) {
      if (!_disposed && ticket == _generation && identity == id) {
        error = '$e';
        state = 'conflict';
        _notify();
      }
    }
  }

  Future<void> saveGui() async {
    final folder = session, id = identity;
    if (folder == null ||
        !canEditDocument() ||
        !isWriter() ||
        closing ||
        service.cleanupUnknown ||
        id != qaIdentity ||
        _disposed ||
        _scanning ||
        _writing ||
        desktop.busy) {
      return;
    }
    _writing = true;
    ++_generation;
    final ticket = _generation;
    try {
      if (desktop.work.flow.isDirty) desktop.applyFlow();
      final revision = desktop.work.editor.revision,
          flowRevision = desktop.work.flow.revision,
          setting = desktop.work.settings.revision;
      final current = await documents.read(folder, format);
      final raw = desktop.work.source;
      final prepared = await documents.compile(
        desktop.work.settings.execution,
        LiveDocument('gui', raw),
      );
      final source = format == 'xml'
          ? await documents.exportXml(desktop.work.settings.execution, raw)
          : const JsonEncoder.withIndent('  ')
                .convert(prepared.plan['blueprint']);
      if (_disposed ||
          ticket != _generation ||
          id != identity ||
          qaIdentity != id ||
          revision != desktop.work.editor.revision ||
          flowRevision != desktop.work.flow.revision ||
          setting != desktop.work.settings.revision) {
        throw const FormatException('저장 중 GUI가 변경되었습니다.');
      }
      if (current != null) await documents.preserveCopy(folder, current.source);
      if (_disposed ||
          ticket != _generation ||
          id != identity ||
          qaIdentity != id ||
          revision != desktop.work.editor.revision ||
          flowRevision != desktop.work.flow.revision ||
          setting != desktop.work.settings.revision) {
        return;
      }
      await documents.replace(folder, format, source, current?.hash);
      if (_disposed ||
          ticket != _generation ||
          id != identity ||
          qaIdentity != id) {
        return;
      }
      _syncedRevision = revision;
      _hashes[format] = null;
    } catch (e) {
      error = '$e';
      state = 'conflict';
    } finally {
      _writing = false;
      _notify();
    }
    await refresh(force: true);
  }

  void undo() {
    if (!canUndo) return;
    desktop.work.editor.edit(_undoSource!);
    desktop.work.run.invalidateValidation();
    _undoSource = null;
    state = 'conflict';
    error = '되돌린 GUI와 파일을 확인한 뒤 저장 방향을 선택하세요.';
    _notify();
  }

  Future<void> close() =>
      _closeFuture ??= _close().whenComplete(() => _closeFuture = null);

  Future<void> _close() async {
    closing = true;
    ++_generation;
    _notify();
    _poll?.cancel();
    _debounce?.cancel();
    try {
      await _watcher?.cancel();
      await service.close();
    } finally {
      closing = false;
      _notify();
    }
  }

  void invalidateOwnership() {
    ++_generation;
    conflict = null;
    _undoSource = null;
    _ownershipSyncRequired = true;
    if (session != null) state = 'needs_validation';
    _notify();
  }

  void invalidateDocumentMode() {
    ++_generation;
    _undoSource = null;
    _hashes.clear();
    if (session != null) {
      state = canEditDocument() ? 'needs_validation' : 'composition_review';
    }
    _notify();
  }

  Future<void> detach() async {
    ++_generation;
    _poll?.cancel();
    _debounce?.cancel();
    await _watcher?.cancel();
    session = null;
    qaIdentity = null;
    _hashes.clear();
    conflict = null;
    state = 'idle';
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _poll?.cancel();
    _debounce?.cancel();
    _preview?.cancel();
    unawaited(_watcher?.cancel());
    desktop.removeListener(_desktopChanged);
    service.onOutput = null;
    service.onState = null;
    terminal.onOutput = null;
    super.dispose();
  }
}
