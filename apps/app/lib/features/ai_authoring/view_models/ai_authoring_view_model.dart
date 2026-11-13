import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/ai_request.dart';
import '../repositories/ai_repository.dart';
import '../../run_review/models/engine_execution.dart';
import '../../run_review/repositories/engine_repository.dart';

class AiProposal {
  AiProposal({
    required this.answer,
    required this.original,
    required this.candidate,
    required this.source,
    required this.stamp,
  });
  final AiAnswer answer;
  final PreparedScenario original, candidate;
  final String source;
  final AiStamp stamp;
  List<String> get changes {
    final before = original.plan['blueprint'] as Map,
        after = candidate.plan['blueprint'] as Map;
    final messages = <String>[];
    final left = {for (final n in before['flow']['nodes']) n['id']: n};
    final right = {for (final n in after['flow']['nodes']) n['id']: n};
    for (final id in {...left.keys, ...right.keys}) {
      if (!left.containsKey(id)) {
        messages.add('노드 추가: $id');
      } else if (!right.containsKey(id)) {
        messages.add('노드 삭제: $id');
      } else if (!_same(left[id], right[id])) {
        messages.add('노드 변경: $id');
      }
    }
    for (final edge in before['flow']['edges']) {
      if (!(after['flow']['edges'] as List).any((e) => _same(e, edge))) {
        messages.add('연결 제거: ${jsonEncode(edge)}');
      }
    }
    for (final edge in after['flow']['edges']) {
      if (!(before['flow']['edges'] as List).any((e) => _same(e, edge))) {
        messages.add('연결 추가: ${jsonEncode(edge)}');
      }
    }
    for (final key in {
      ...before.keys,
      ...after.keys,
    }.where((k) => k != 'flow')) {
      if (!_same(before[key], after[key])) messages.add('$key 변경');
    }
    for (final key in {
      ...(before['flow'] as Map).keys,
      ...(after['flow'] as Map).keys,
    }.where((k) => k != 'nodes' && k != 'edges')) {
      if (!_same(before['flow'][key], after['flow'][key])) {
        messages.add('flow.$key 변경');
      }
    }
    return messages.isEmpty ? ['실행 의미 변경 없음 (원문 차이는 XML에서 확인)'] : messages;
  }

  static bool _same(dynamic a, dynamic b) =>
      jsonEncode(_sorted(a)) == jsonEncode(_sorted(b));
  static dynamic _sorted(dynamic v) => v is Map
      ? {
          for (final k in (v.keys.cast<String>().toList()..sort()))
            k: _sorted(v[k]),
        }
      : v is List
      ? v.map(_sorted).toList()
      : v;
}

class AiAuthoringViewModel extends ChangeNotifier {
  AiAuthoringViewModel(this.repository, this.engine);
  final AiRepository repository;
  final EngineRepository engine;
  AiSettings settings = const AiSettings();
  int settingsRevision = 0, generation = 0;
  String status = 'idle', diagnosis = '', request = '';
  String? error;
  AiScope scope = AiScope.whole;
  AiProposal? proposal;
  final List<String> progress = [];
  bool _disposed = false;
  bool get busy => ['diagnosing', 'generating', 'validating'].contains(status);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void configure(AiSettings value) {
    if (busy || _disposed) return;
    if (value.provider == settings.provider &&
        value.executable == settings.executable) {
      return;
    }
    settings = value;
    settingsRevision++;
    diagnosis = '';
    invalidate();
  }

  void setScope(AiScope value) {
    if (value == scope) return;
    scope = value;
    settingsRevision++;
    invalidate();
  }

  void editRequest(String value) {
    if (request == value) return;
    request = value;
    settingsRevision++;
    invalidate();
  }

  void invalidate() {
    if (proposal != null) status = 'stale';
    _notify();
  }

  Future<void> diagnose() async {
    if (busy || _disposed) return;
    final ticket = ++generation;
    status = 'diagnosing';
    error = null;
    _notify();
    try {
      final value = await repository.diagnose(settings);
      if (!_disposed && ticket == generation) {
        diagnosis = value;
        status = 'idle';
      }
    } catch (e) {
      if (!_disposed && e is AiFailure && e.cleanupUnknown) {
        error = '$e';
        status = 'cleanup_unknown';
      } else if (!_disposed && ticket == generation) {
        error = '$e';
        status = 'failed';
      }
    }
    _notify();
  }

  Future<void> generate({
    required AiStamp stamp,
    required bool Function(AiStamp) isCurrent,
    required EngineSettings engineSettings,
    required Directory sessions,
    required String source,
    required String instructions,
    required String qaPrompt,
    required String? selectedNode,
    required Map<String, dynamic> contract,
  }) async {
    if (busy || _disposed) return;
    final ticket = ++generation;
    proposal = null;
    error = null;
    progress.clear();
    status = 'validating';
    _notify();
    bool current() => !_disposed && ticket == generation && isCurrent(stamp);
    try {
      final original = await engine.validate(engineSettings, source);
      if (!current()) {
        if (!_disposed && ticket == generation) status = 'stale';
        return;
      }
      final xml = await engine.exportXml(engineSettings, source);
      if (!current()) {
        if (!_disposed && ticket == generation) status = 'stale';
        return;
      }
      final blueprint = original.plan['blueprint'];
      if (scope != AiScope.whole &&
          !(blueprint['flow']['nodes'] as List).any(
            (n) => n['id'] == selectedNode,
          )) {
        throw const AiFailure('현재 검증된 문서에서 블록을 선택하세요.');
      }
      final payload = {
        'task': 'Return summary and ONE complete qa.blueprint/v1 XML document only. Do not execute QA, commands, tools or edit files. Preserve unrelated nodes, edges, target, selectors, variables and metadata. Respect graph edges, not array order. No markdown fences. All changes are a proposal for human review.',
        'scope': scope.name,
        'selectedNodeId': selectedNode,
        'projectInstructions': instructions,
        'qaPrompt': qaPrompt,
        'request': request,
        'originalXml': xml,
        'publicExecutionSchema': contract['schema'],
      };
      status = 'generating';
      _notify();
      final answer = await repository.generate(
        settings,
        sessions,
        jsonEncode(payload),
        (event) {
          if (!current()) return;
          if (progress.length == 100) progress.removeAt(0);
          progress.add(event);
          _notify();
        },
      );
      if (!current()) {
        if (!_disposed && ticket == generation) status = 'stale';
        return;
      }
      status = 'validating';
      _notify();
      final candidate = await engine.validate(engineSettings, answer.xml);
      if (!current()) {
        if (!_disposed && ticket == generation) status = 'stale';
        return;
      }
      proposal = AiProposal(
        answer: answer,
        original: original,
        candidate: candidate,
        source: source,
        stamp: stamp,
      );
      status = 'review';
    } catch (e) {
      if (!_disposed && e is AiFailure && e.cleanupUnknown) {
        error = '$e';
        status = 'cleanup_unknown';
      } else if (!_disposed && ticket == generation) {
        error = '$e';
        status = isCurrent(stamp) ? 'failed' : 'stale';
      }
    } finally {
      _notify();
    }
  }

  Future<void> cancel() async {
    generation++;
    status = 'cancelled';
    proposal = null;
    _notify();
    await repository.cancel();
  }

  void dismiss() {
    proposal = null;
    status = 'idle';
    _notify();
  }

  /// A one-off edit request belongs to the selected QA, not the provider scope.
  void resetContext() {
    if (busy || _disposed) return;
    request = '';
    scope = AiScope.whole;
    settingsRevision++;
    proposal = null;
    progress.clear();
    if (status != 'cleanup_unknown') {
      status = 'idle';
      error = null;
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    generation++;
    super.dispose();
  }
}
