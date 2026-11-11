import 'package:flutter/foundation.dart';

import '../../../../core/errors/draft_file_exception.dart';
import '../models/scenario_draft.dart';
import '../repositories/scenario_repository.dart';

class ScenarioEditorViewModel extends ChangeNotifier {
  ScenarioEditorViewModel(this._repository);
  final ScenarioRepository _repository;
  ScenarioDraft _draft = const ScenarioDraft();
  String _savedContent = '';
  int _revision = 0;
  int get revision => _revision;
  String? _error;
  String? _notice;
  bool _busy = false;
  bool _disposed = false;
  ScenarioDraft get draft => _draft;
  bool get isDirty => _draft.content != _savedContent;
  bool get isBusy => _busy;
  String? get error => _error;
  String? get notice => _notice;

  /// A workspace identity change invalidates pending commands even for equal text.
  void loadWorkspaceDocument(String source) {
    if (_disposed || _busy) return;
    _draft = ScenarioDraft(content: source);
    _savedContent = source;
    _revision++;
    _error = null;
    _notice = null;
    notifyListeners();
  }

  void markWorkspaceSaved(String source) {
    if (_disposed) return;
    _savedContent = source;
    notifyListeners();
  }

  void edit(String content) {
    if (_disposed || _busy || content == _draft.content) return;
    _draft = _draft.withContent(content);
    _revision++;
    _error = null;
    _notice = null;
    notifyListeners();
  }

  Future<bool> open(String path) => _perform(
    () => _repository.open(path),
    '파일을 열었습니다. 검증·계획을 확인한 후 명시적으로 실행하세요.',
  );
  Future<bool> save(String path) => _perform(
    () => _repository.save(path, _draft),
    '파일을 저장했습니다. 테스트를 검증하거나 실행한 결과가 아닙니다.',
  );

  Future<bool> _perform(
    Future<ScenarioDraft> Function() operation,
    String success,
  ) async {
    if (_disposed || _busy) return false;
    _busy = true;
    _error = null;
    _notice = null;
    notifyListeners();
    try {
      final result = await operation();
      if (_disposed) return false;
      _draft = result;
      _revision++;
      _savedContent = result.content;
      _notice = success;
      return true;
    } on DraftFileException catch (error) {
      if (!_disposed) _error = error.message;
      return false;
    } catch (_) {
      if (!_disposed) _error = '파일 작업 중 오류가 발생했습니다. 초안은 유지됩니다.';
      return false;
    } finally {
      if (!_disposed) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
