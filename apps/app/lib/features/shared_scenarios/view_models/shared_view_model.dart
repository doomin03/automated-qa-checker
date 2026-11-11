import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:api_client_dart/platform_client.dart';

import '../repositories/shared_repository.dart';
import '../../run_review/view_models/run_view_model.dart';

class _Publication {
  _Publication(this.plan, this.project, this.origin, this.versionId);
  final Map<String, dynamic> plan;
  final String project;
  final String origin;
  final String? versionId;
  List<Map<String, dynamic>> events = [];
  Map<String, dynamic>? result;
  String? directory, serverId;
  int sent = 0;
  bool finished = false;
}

class SharedViewModel extends ChangeNotifier {
  SharedViewModel(this.repository, this._run) {
    _run.addListener(_changed);
  }
  final SharedRepository repository;
  final RunViewModel _run;
  Map<String, dynamic>? get receivedVersion => repository.receivedVersion;
  bool get receivedVersionMatchesPlan =>
      repository.versionFor(_run.plan ?? {}) != null;
  final Map<String, _Publication> _publications = {};
  final Set<String> _completed = {};
  bool busy = false,
      connected = false,
      autoPublish = false,
      _disposed = false,
      _syncing = false;
  String message = '공유는 선택 기능입니다. 로컬 QA는 서버 없이 실행합니다.',
      publishStatus = 'not_requested';
  List<Map<String, dynamic>> versions = [];
  List<Map<String, dynamic>> suites = [];
  Map<String, dynamic>? selectedSuite;
  int? _suiteGeneration;
  bool suitePinned = false;
  String? suiteCursor;
  Map<String, dynamic>? preview;
  String? nextCursor, diff;
  String? _previewOrigin, _previewProject;
  String _error(Object e) => e is ApiFailure
      ? 'API ${e.status}: ${e.body.code}'
      : e is TransportFailure
      ? '공유 연결 오류: ${e.reason}'
      : e is FormatException
      ? e.message.toString()
      : '공유 계약/파일 오류';
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _action(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    _notify();
    try {
      await action();
    } catch (e) {
      message = _error(e);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> connect(
    String origin,
    String token,
    String project,
    String folder,
  ) => _action(() async {
    if (_syncing || _run.running) {
      throw const FormatException('실행/게시가 끝난 뒤 연결을 바꾸세요.');
    }
    connected = false;
    autoPublish = false;
    preview = null;
    versions = [];
    suites = [];
    selectedSuite = null;
    suitePinned = false;
    suiteCursor = null;
    final me = await repository.connect(origin, token, project, folder);
    connected = true;
    message =
        '${me.localMode ? '로컬 테스트 identity' : '인증 사용자'}: ${me.userId} · 프로젝트 $project';
    final page = await repository.versions();
    versions = page.items.map((v) => v.toJson()).toList();
    nextCursor = page.nextCursor;
  });
  Future<void> more() => _action(() async {
    final page = await repository.versions(cursor: nextCursor);
    versions.addAll(page.items.map((v) => v.toJson()));
    nextCursor = page.nextCursor;
  });
  Future<void> loadSuites({bool more = false}) => _action(() async {
    final generation = repository.connectionGeneration;
    final page = await repository.suites(cursor: more ? suiteCursor : null);
    if (generation != repository.connectionGeneration) {
      throw const FormatException('공유 연결이 바뀌었습니다.');
    }
    suites = more
        ? [...suites, ...page.items.map((s) => s.toJson())]
        : page.items.map((s) => s.toJson()).toList();
    suiteCursor = page.nextCursor;
  });
  Future<void> selectSuite(String id) => _action(() async {
    final value = await repository.suite(id);
    selectedSuite = value;
    _suiteGeneration = repository.connectionGeneration;
    suitePinned = false;
    message = 'Suite의 순서 있는 고정 case 목록을 받았습니다. 자동 실행하지 않습니다.';
  });
  Future<void> pinSelectedSuite() => _action(() async {
    if (selectedSuite == null ||
        _suiteGeneration != repository.connectionGeneration) {
      throw const FormatException('현재 연결에서 Suite를 다시 선택하세요.');
    }
    await repository.pinSuite(selectedSuite!);
    suitePinned = true;
    message = 'Suite 버전을 고정했습니다. case를 명시 선택하고 개별 검증·실행하세요.';
  });
  Future<void> selectSuiteCase(Map<String, dynamic> member) =>
      _action(() async {
        if (!suitePinned ||
            selectedSuite == null ||
            _suiteGeneration != repository.connectionGeneration) {
          throw const FormatException('현재 Suite 버전을 먼저 고정하세요.');
        }
        if (!(selectedSuite!['cases'] as List).any(
          (value) =>
              value['caseId'] == member['caseId'] &&
              value['versionId'] == member['versionId'] &&
              value['sha256'] == member['sha256'],
        )) {
          throw const FormatException('선택한 Suite의 case가 아닙니다.');
        }
        final value = await repository.preview(member['versionId']);
        if (value['sha256'] != member['sha256']) {
          throw const FormatException('Suite member의 고정 hash가 다릅니다.');
        }
        preview = value;
        _previewOrigin = repository.origin;
        _previewProject = repository.project;
        diff = await repository.diff(value);
        message =
            'Suite case ${member['caseId']}를 선택했습니다. 개별 XML 수신 버튼으로 초안에 적용하세요.';
      });
  void disconnect() {
    autoPublish = false;
    connected = false;
    selectedSuite = null;
    suitePinned = false;
    suites = [];
    suiteCursor = null;
    repository.disconnect();
    message = '서버 연결을 해제했습니다. 로컬 결과는 유지됩니다.';
    _notify();
  }

  Future<void> select(String id) => _action(() async {
    preview = await repository.preview(id);
    _previewOrigin = repository.origin;
    _previewProject = repository.project;
    diff = await repository.diff(preview!);
  });
  Future<String?> accept() async {
    String? xml;
    await _action(() async {
      if (preview == null) return;
      if (_previewOrigin != repository.origin ||
          _previewProject != repository.project) {
        throw const FormatException('선택 버전의 서버/프로젝트가 현재 연결과 다릅니다.');
      }
      await repository.accept(preview!);
      xml = preview!['xml'];
      message = '고정 XML을 받았습니다. 초안 적용 후 별도 검증·실행하세요.';
    });
    return xml;
  }

  Future<String?> offline(String folder, String origin, String project) async {
    String? xml;
    await _action(() async {
      final cached = await repository.offline(folder, origin, project);
      if (cached == null) throw const FormatException('저장된 고정 snapshot이 없습니다.');
      preview = cached;
      _previewOrigin = origin;
      _previewProject = project;
      xml = cached['xml'];
      message = '오프라인 고정 snapshot ${cached['version']} · 수신만으로 실행하지 않습니다.';
    });
    return xml;
  }

  void enablePublishing(bool enabled) {
    autoPublish = enabled;
    _notify();
    if (enabled) _changed();
  }

  void _changed() {
    if (_disposed ||
        !autoPublish ||
        !connected ||
        _run.events.isEmpty ||
        _run.plan == null) {
      return;
    }
    final start = _run.events.first;
    final key = '${start['runId']}.${start['attempt']}';
    if (_completed.contains(key)) return;
    if (!_publications.containsKey(key) && _publications.length >= 10) {
      publishStatus = 'failed: 미게시 실행이 많습니다. 기존 결과를 게시한 뒤 다시 시도하세요.';
      _notify();
      return;
    }
    final p = _publications.putIfAbsent(
      key,
      () => _Publication(
        jsonDecode(jsonEncode(_run.plan)) as Map<String, dynamic>,
        repository.project,
        repository.origin,
        repository.versionFor(_run.plan!),
      ),
    );
    p.events = _run.events.map((e) => Map<String, dynamic>.from(e)).toList();
    p.result = _run.result;
    p.directory = _run.reportDirectory;
    if (!publishStatus.startsWith('failed')) unawaited(_sync());
  }

  Future<void> retry() async {
    publishStatus = 'pending';
    await _sync();
  }

  Future<void> restoreReport(String folder) => _action(() async {
    if (!connected || _syncing) {
      throw const FormatException('공유 연결 후 게시가 끝났을 때 복구하세요.');
    }
    final saved = await repository.files.report(folder);
    final events = List<Map<String, dynamic>>.from(saved['events']);
    final first = events.first, key = '${first['runId']}.${first['attempt']}';
    if (_publications.length >= 10 && !_publications.containsKey(key)) {
      throw const FormatException('미게시 실행 한도 초과');
    }
    _publications[key] =
        _Publication(
            saved['plan'],
            repository.project,
            repository.origin,
            repository.versionFor(saved['plan']),
          )
          ..events = events
          ..result = saved['result']
          ..directory = folder;
    message = '저장된 실행 파일을 재게시합니다. 서버가 identity·schema·bytes를 다시 확인합니다.';
    await retry();
  });

  Future<void> _sync() async {
    if (_syncing || _disposed || !connected) return;
    _syncing = true;
    publishStatus = 'pending';
    _notify();
    try {
      for (final p in _publications.values.toList()) {
        if (p.finished) continue;
        if (p.project != repository.project || p.origin != repository.origin) {
          throw const FormatException('실행의 공유 서버/프로젝트가 현재 연결과 다릅니다.');
        }
        p.serverId ??= (await repository.createRun(
          p.plan,
          p.events.first,
          versionId: p.versionId,
        )).id;
        final pending = p.events.skip(p.sent).toList();
        if (pending.isNotEmpty) {
          await repository.append(p.serverId!, pending);
          p.sent += pending.length;
        }
        if (p.result != null &&
            p.directory != null &&
            p.sent == p.events.length) {
          final result = await repository.finish(
            p.serverId!,
            p.result!,
            p.directory!,
          );
          p.finished =
              result.evidenceStatus == RunResponseEvidenceStatusEnum.verified;
          if (!p.finished) {
            throw FormatException('서버 증거 상태: ${result.evidenceStatus}');
          }
          publishStatus =
              'server ${p.serverId} · 외부 outcome ${result.reportedOutcome} · 증거 ${result.evidenceStatus} · 업무 ${result.workStatus}';
        } else {
          publishStatus = 'server ${p.serverId} · 진행 ${p.sent}개 게시';
        }
      }
      _publications.removeWhere((key, p) {
        if (p.finished) _completed.add(key);
        return p.finished;
      });
      while (_completed.length > 100) {
        _completed.remove(_completed.first);
      }
    } catch (e) {
      publishStatus = 'failed: ${_error(e)}. 로컬 결과는 유지됩니다. 게시 재시도를 선택하세요.';
    } finally {
      _syncing = false;
      _notify();
      if (!_disposed &&
          !publishStatus.startsWith('failed') &&
          _publications.values.any(
            (p) =>
                p.sent < p.events.length || (p.result != null && !p.finished),
          )) {
        unawaited(_sync());
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _run.removeListener(_changed);

    super.dispose();
  }
}
