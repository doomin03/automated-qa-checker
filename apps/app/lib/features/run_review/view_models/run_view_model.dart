import 'package:flutter/foundation.dart';

import '../models/engine_execution.dart';
import '../repositories/engine_repository.dart';

class RunViewModel extends ChangeNotifier {
  RunViewModel(this._repository);
  final EngineRepository _repository;
  PreparedScenario? _prepared;
  String? _validatedSource;
  bool _disposed = false;
  bool _busy = false;
  bool _running = false;
  String _status = 'not_started';
  String? _error;
  String? _reportDirectory;
  Map<String, dynamic>? _result;
  final List<Map<String, dynamic>> _events = [];
  List<EvidenceImage> _images = const [];
  List<Map<String, dynamic>> _checks = const [];
  ExpandedAuthoring? expansion;
  Map<String, dynamic>? capabilities;
  int _capabilityGeneration = 0;
  int _validationGeneration = 0;
  void invalidateValidation() {
    _validationGeneration++;
    _validatedSource = null;
    if (_status == 'validating' || _status == 'validated') {
      _status = 'validation_stale';
    }
    _notify();
  }

  bool matchesSettings(EngineSettings settings) =>
      _prepared?.settings == settings;
  Future<void> inspectCapabilities(
    EngineSettings settings,
    String platform,
  ) async {
    if (_disposed || _busy) return;
    _busy = true;
    _error = null;
    capabilities = null;
    final generation = ++_capabilityGeneration;
    _notify();
    try {
      final value = await _repository.capabilities(settings, platform);
      if (!_disposed && generation == _capabilityGeneration) {
        capabilities = value;
      }
    } catch (error) {
      if (!_disposed && generation == _capabilityGeneration) {
        _error = _message(error);
      }
    } finally {
      _busy = false;
      _notify();
    }
  }

  void clearCapabilities() {
    _capabilityGeneration++;
    capabilities = null;
    _notify();
  }

  String? iterationLabel(String node, String source) {
    final e = expansion;
    if (e == null ||
        e.xml != source ||
        e.sourceMap['blueprintSnapshotHash'] !=
            plan?['blueprintSnapshotHash']) {
      return null;
    }
    for (final m in e.sourceMap['nodes'] as List) {
      if (m['nodeId'] == node && m['iteration'] != null) {
        return '${m['sourceNodeId']} · ${m['iteration']}회차 · ${m['sourceStepId']}';
      }
    }
    return null;
  }

  Future<String?> expandAuthoring(
    EngineSettings settings,
    String source,
  ) async {
    if (_disposed || _busy) return null;
    _busy = true;
    _error = null;
    expansion = null;
    _notify();
    try {
      final value = await _repository.expandAuthoring(settings, source);
      if (_disposed) return null;
      expansion = value;
      return value.xml;
    } catch (e) {
      if (!_disposed) _error = _message(e);
      return null;
    } finally {
      _busy = false;
      _notify();
    }
  }

  List<EvidenceImage> get images => _images;
  List<Map<String, dynamic>> get checks => _checks;
  bool get busy => _busy;
  bool get running => _running;
  String get status => _status;
  String? get error => _error;
  String? get reportDirectory => _reportDirectory;
  Map<String, dynamic>? get result => _result;
  Map<String, dynamic>? get plan => _prepared?.plan;
  List<Map<String, dynamic>> get events => List.unmodifiable(_events);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool matchesSource(String source) => _validatedSource == source;
  Future<String?> expandPreset(
    EngineSettings settings,
    String id,
    String version,
    Map<String, dynamic> bindings,
  ) async {
    if (_disposed || _busy) return null;
    _busy = true;
    _error = null;
    _notify();
    try {
      return await _repository.expandPreset(settings, id, version, bindings);
    } catch (e) {
      if (!_disposed) _error = _message(e);
      return null;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<String?> exportXml(EngineSettings settings, String source) async {
    if (_disposed || _busy) return null;
    _busy = true;
    _error = null;
    _notify();
    try {
      return await _repository.exportXml(settings, source);
    } catch (error) {
      if (!_disposed) _error = _message(error);
      return null;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> validate(EngineSettings settings, String source) async {
    if (_disposed || _busy) return;
    _busy = true;
    _prepared = null;
    _validatedSource = null;
    _error = null;
    _result = null;
    _reportDirectory = null;
    _events.clear();
    _images = const [];
    _checks = const [];
    _status = 'validating';
    final generation = ++_validationGeneration;
    _notify();
    try {
      final prepared = await _repository.validate(settings, source);
      if (_disposed) return;
      if (generation != _validationGeneration) {
        _status = 'validation_stale';
        return;
      }
      _prepared = prepared;
      _validatedSource = source;
      _status = 'validated';
    } catch (error) {
      if (!_disposed && generation == _validationGeneration) {
        _status = 'validation_error';
        _error = _message(error);
      }
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> run(EngineSettings settings, String source) async {
    if (_disposed || _busy) return;
    final prepared = _prepared;
    if (prepared == null ||
        source != _validatedSource ||
        settings.nodePath != prepared.settings.nodePath ||
        settings.cliPath != prepared.settings.cliPath ||
        settings.reportRoot != prepared.settings.reportRoot ||
        settings.referenceRoot != prepared.settings.referenceRoot ||
        settings.appiumConfig != prepared.settings.appiumConfig) {
      _error = '현재 초안과 설정을 먼저 검증하세요.';
      _notify();
      return;
    }
    _busy = true;
    _running = true;
    _status = 'starting';
    _error = null;
    _result = null;
    _events.clear();
    _images = const [];
    _checks = const [];
    _notify();
    try {
      await for (final update in _repository.run(prepared)) {
        if (_disposed) break;
        if (update.event != null) {
          _events.add(update.event!);
          // Terminal events alone do not prove a valid persisted result.
          if (_status != 'cancel_requested') {
            _status = update.event!['type'] == 'run.finished'
                ? 'checking_result'
                : 'running';
          }
        }
        if (update.result != null) {
          _result = update.result;
          _images = update.images;
          _checks = update.checks;
          _reportDirectory = update.reportDirectory;
          _status = update.result!['outcome'] as String;
        }
        _notify();
      }
      if (!_disposed && _result == null) {
        throw const EngineException('infra_error: 확인된 결과가 없습니다.');
      }
    } catch (error) {
      if (!_disposed) {
        _status =
            error is EngineException &&
                error.message.startsWith('cancelled_before_start:')
            ? 'cancelled_before_start'
            : 'infra_error';
        _error = _message(error);
      }
    } finally {
      _busy = false;
      _running = false;
      _notify();
    }
  }

  Future<void> cancel() async {
    if (_disposed || !_running || _status == 'cancel_requested') return;
    _status = 'cancel_requested';
    _notify();
    try {
      await _repository.cancel();
    } catch (error) {
      if (!_disposed) {
        _error = _message(error);
        _notify();
      }
    }
  }

  String _message(Object error) => error is EngineException
      ? error.message
      : '엔진 통신/파일 형식 오류입니다. 경로와 배포판을 확인하세요.';
  @override
  void dispose() {
    _disposed = true;

    super.dispose();
  }
}
