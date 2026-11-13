import 'package:flutter/foundation.dart';

import '../../../features/run_review/services/engine_cli_service.dart';
import 'desktop_workspace_view_model.dart';

class DocumentTemplateViewModel extends ChangeNotifier {
  DocumentTemplateViewModel(this.desktop, this.engine);
  final DesktopWorkspaceViewModel desktop;
  final EngineCliService engine;
  List<Map<String, dynamic>> catalog = [];
  Map<String, dynamic>? candidate;
  String? error;
  bool busy = false, _disposed = false;
  int _generation = 0;
  String? _owner;
  int? _documentRevision, _settingsRevision;
  String get identity =>
      '${desktop.workspace.projectId}/${desktop.workspace.qaId}';
  EngineDocumentAuthoring get api {
    if (engine is! EngineDocumentAuthoring) {
      throw StateError('UNSUPPORTED_CAPABILITY: 공개 작성 API 필요');
    }
    return engine as EngineDocumentAuthoring;
  }

  bool get current =>
      candidate != null &&
      _owner == identity &&
      _documentRevision == desktop.work.editor.revision &&
      _settingsRevision == desktop.work.settings.revision;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    error = null;
    candidate = null;
    final ticket = ++_generation;
    _notify();
    try {
      final value = await api.templates(desktop.work.settings.execution);
      if (!_disposed && ticket == _generation) {
        catalog = List<Map<String, dynamic>>.from(value['templates']);
      }
    } catch (e) {
      if (!_disposed && ticket == _generation) error = '$e';
    } finally {
      if (!_disposed && ticket == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> generate(
    Map<String, dynamic> template,
    Map<String, dynamic> bindings,
  ) async {
    if (busy || desktop.busy) return;
    final owner = identity,
        doc = desktop.work.editor.revision,
        settings = desktop.work.settings.revision,
        ticket = ++_generation;
    busy = true;
    error = null;
    candidate = null;
    _notify();
    try {
      final value = await api.createTemplate(
        desktop.work.settings.execution,
        template['id'],
        template['version'],
        template['sha256'],
        bindings,
      );
      if (_disposed || ticket != _generation) return;
      if (owner != identity ||
          doc != desktop.work.editor.revision ||
          settings != desktop.work.settings.revision) {
        throw StateError('문서 또는 설정이 바뀌어 생성 결과를 폐기했습니다.');
      }
      candidate = value;
      _owner = owner;
      _documentRevision = doc;
      _settingsRevision = settings;
    } catch (e) {
      if (!_disposed && ticket == _generation) error = '$e';
    } finally {
      if (!_disposed && ticket == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<bool> accept(String name) async {
    if (!current || busy || desktop.busy) {
      error = '현재 문서/설정으로 다시 생성하세요.';
      _notify();
      return false;
    }
    final source = candidate!['xml'] as String;
    candidate = null;
    final saved = await desktop.createQaFromSource(name, source);
    if (!saved) error = desktop.workspace.error ?? '새 QA 저장에 실패했습니다.';
    _notify();
    return saved;
  }

  void clear() {
    ++_generation;
    candidate = null;
    error = null;
    busy = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    super.dispose();
  }
}
