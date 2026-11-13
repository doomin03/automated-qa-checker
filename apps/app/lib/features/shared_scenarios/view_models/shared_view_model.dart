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
  SharedViewModel(this.repository, this._run, {this.loadLocalRuntime}) {
    _run.addListener(_changed);
  }
  final SharedRepository repository;
  final RunViewModel _run;
  final Future<Map<String, dynamic>> Function()? loadLocalRuntime;
  ProjectContextResponse? projectContext;
  Map<String, dynamic>? localRuntime;
  String? contextError;
  List<Map<String, dynamic>> suitePins = [];
  String? pinCursor;
  int _actionEpoch = 0;
  int _contextGeneration = 0;
  bool allows(String action) =>
      !_disposed &&
      connected &&
      _contextGeneration == repository.connectionGeneration &&
      projectContext?.projectId == repository.project &&
      projectContext?.allowedActions.any((a) => a.value == action) == true;
  String? get incompatibility {
    final server = projectContext?.engine;
    if (server == null) return contextError ?? '서버 실행 계약을 확인하지 못했습니다.';
    final local = localRuntime;
    if (local == null ||
        local['engineVersion'] is! String ||
        local['contractVersion'] is! String ||
        local['bundleSha256'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(local['bundleSha256'] as String)) {
      return '로컬 Engine 계약을 확인하지 못했습니다. 로컬 편집·실행은 유지됩니다.';
    }
    if (local['engineVersion'] != server.engineVersion ||
        local['contractVersion'] != server.contractVersion ||
        local['bundleSha256'] != server.contractSha256) {
      return '공유 호환되지 않음 · 앱 ${local['engineVersion']} / 서버 ${server.engineVersion}. 로컬 실행과 결과는 유지됩니다.';
    }
    return null;
  }

  bool get canPublish => allows('publishRuns') && incompatibility == null;
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

  void Function() _checkpoint() {
    final epoch = _actionEpoch, generation = repository.connectionGeneration;
    return () {
      if (_disposed ||
          epoch != _actionEpoch ||
          generation != repository.connectionGeneration) {
        throw const FormatException('공유 연결 요청이 변경되었습니다.');
      }
    };
  }

  void _require(String action) {
    if (!allows(action)) {
      throw FormatException(contextError ?? '프로젝트 권한을 다시 확인하세요.');
    }
  }

  void _permissionFailure(Object error) {
    if (error is ApiFailure && [401, 403].contains(error.status)) {
      projectContext = null;
      autoPublish = false;
      contextError = '프로젝트 권한이 변경되었습니다. 다시 연결하세요.';
    }
  }

  void reportServerError(Object error) {
    if (_disposed) return;
    _permissionFailure(error);
    _notify();
  }

  Future<void> _action(Future<void> Function() action) async {
    if (busy || _disposed) return;
    final epoch = ++_actionEpoch;
    busy = true;
    _notify();
    try {
      await action();
    } catch (e) {
      if (!_disposed && epoch == _actionEpoch) {
        _permissionFailure(e);
        message = _error(e);
      }
    } finally {
      if (!_disposed && epoch == _actionEpoch) {
        busy = false;
        _notify();
      }
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
    suitePins = [];
    pinCursor = null;
    projectContext = null;
    contextError = null;
    localRuntime = null;
    nextCursor = null;
    diff = null;
    final epoch = _actionEpoch;
    final me = await repository.connect(origin, token, project, folder);
    if (_disposed || epoch != _actionEpoch) return;
    final generation = repository.connectionGeneration;
    final current = _checkpoint();
    connected = true;
    message =
        '${me.localMode ? '로컬 테스트 identity' : '인증 사용자'}: ${me.userId} · 프로젝트 $project';
    try {
      final value = await repository.context();
      current();
      projectContext = value;
      _contextGeneration = generation;
    } catch (e) {
      if (_disposed ||
          epoch != _actionEpoch ||
          generation != repository.connectionGeneration) {
        return;
      }
      contextError = '프로젝트 권한/실행 계약 확인 실패: ${_error(e)}';
      return;
    }
    try {
      final local = await loadLocalRuntime?.call();
      current();
      localRuntime = local;
    } catch (_) {
      current();
      localRuntime = null;
    }
    _require('readPublished');
    final page = await repository.versions();
    current();
    versions = page.items.map((v) => v.toJson()).toList();
    nextCursor = page.nextCursor;
  });
  Future<void> more() => _action(() async {
    _require('readPublished');
    if (nextCursor == null) return;
    final current = _checkpoint();
    final page = await repository.versions(cursor: nextCursor);
    current();
    versions.addAll(page.items.map((v) => v.toJson()));
    nextCursor = page.nextCursor;
  });
  Future<void> loadSuites({bool more = false}) => _action(() async {
    _require('readPublished');
    if (more && suiteCursor == null) return;
    final current = _checkpoint();
    final generation = repository.connectionGeneration;
    final page = await repository.suites(cursor: more ? suiteCursor : null);
    current();
    if (generation != repository.connectionGeneration) {
      throw const FormatException('공유 연결이 바뀌었습니다.');
    }
    suites = more
        ? [...suites, ...page.items.map((s) => s.toJson())]
        : page.items.map((s) => s.toJson()).toList();
    suiteCursor = page.nextCursor;
  });
  Future<void> loadSuitePins({bool more = false}) => _action(() async {
    _require('readPublished');
    if (more && pinCursor == null) return;
    final current = _checkpoint();
    final generation = repository.connectionGeneration;
    final page = await repository.suitePins(cursor: more ? pinCursor : null);
    current();
    if (_disposed || generation != repository.connectionGeneration) return;
    suitePins = [
      ...(more ? suitePins : <Map<String, dynamic>>[]),
      ...page.items.map((p) => p.toJson()),
    ];
    pinCursor = page.nextCursor;
  });
  Future<void> openSuitePin(Map<String, dynamic> pin) => _action(() async {
    _require('readPublished');
    final current = _checkpoint();
    final selection = Map<String, dynamic>.from(pin);
    selectedSuite = null;
    suitePinned = false;
    preview = null;
    final value = await repository.suite(selection['versionId']);
    current();
    if (value['id'] != selection['versionId'] ||
        value['packageId'] != selection['packageId'] ||
        value['sha256'] != selection['sha256']) {
      throw const FormatException('저장된 Suite pin과 서버 원본이 다릅니다.');
    }
    selectedSuite = value;
    _suiteGeneration = repository.connectionGeneration;
    suitePinned = true;
    message = '고정한 Suite를 다시 열었습니다. case를 선택해 개별 수신하세요.';
  });
  Future<void> selectSuite(String id) => _action(() async {
    _require('readPublished');
    final current = _checkpoint();
    selectedSuite = null;
    suitePinned = false;
    preview = null;
    final value = await repository.suite(id);
    current();
    selectedSuite = value;
    _suiteGeneration = repository.connectionGeneration;
    suitePinned = false;
    message = 'Suite의 순서 있는 고정 case 목록을 받았습니다. 자동 실행하지 않습니다.';
  });
  Future<void> pinSelectedSuite() => _action(() async {
    final current = _checkpoint();
    if (!allows('pinVersions')) throw const FormatException('버전 고정 권한을 확인하세요.');
    if (selectedSuite == null ||
        _suiteGeneration != repository.connectionGeneration) {
      throw const FormatException('현재 연결에서 Suite를 다시 선택하세요.');
    }
    await repository.pinSuite(selectedSuite!);
    current();
    suitePinned = true;
    message = 'Suite 버전을 고정했습니다. case를 명시 선택하고 개별 검증·실행하세요.';
  });
  Future<void> selectSuiteCase(Map<String, dynamic> member) =>
      _action(() async {
        _require('readPublished');
        final current = _checkpoint();
        preview = null;
        diff = null;
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
        current();
        if (value['sha256'] != member['sha256']) {
          throw const FormatException('Suite member의 고정 hash가 다릅니다.');
        }
        final nextDiff = await repository.diff(value);
        current();
        preview = value;
        _previewOrigin = repository.origin;
        _previewProject = repository.project;
        diff = nextDiff;
        message =
            'Suite case ${member['caseId']}를 선택했습니다. 개별 XML 수신 버튼으로 초안에 적용하세요.';
      });
  void disconnect() {
    _actionEpoch++;
    busy = false;
    autoPublish = false;
    connected = false;
    selectedSuite = null;
    suitePinned = false;
    suites = [];
    suiteCursor = null;
    projectContext = null;
    contextError = null;
    suitePins = [];
    pinCursor = null;
    preview = null;
    versions = [];
    nextCursor = null;
    diff = null;
    localRuntime = null;
    repository.disconnect();
    message = '서버 연결을 해제했습니다. 로컬 결과는 유지됩니다.';
    _notify();
  }

  Future<void> select(String id) => _action(() async {
    _require('readPublished');
    final current = _checkpoint();
    preview = null;
    final value = await repository.preview(id);
    current();
    final nextDiff = await repository.diff(value);
    current();
    preview = value;
    _previewOrigin = repository.origin;
    _previewProject = repository.project;
    diff = nextDiff;
  });
  Future<String?> accept() async {
    String? xml;
    await _action(() async {
      _require('pinVersions');
      final current = _checkpoint();
      if (preview == null) return;
      if (_previewOrigin != repository.origin ||
          _previewProject != repository.project) {
        throw const FormatException('선택 버전의 서버/프로젝트가 현재 연결과 다릅니다.');
      }
      await repository.accept(preview!);
      current();
      xml = preview!['xml'];
      message = '고정 XML을 받았습니다. 초안 적용 후 별도 검증·실행하세요.';
    });
    return xml;
  }

  Future<String?> offline(String folder, String origin, String project) async {
    String? xml;
    await _action(() async {
      final current = _checkpoint();
      final cached = await repository.offline(folder, origin, project);
      current();
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
    if (enabled && !canPublish) {
      autoPublish = false;
      publishStatus = incompatibility ?? '실행 게시 권한이 없습니다.';
      _notify();
      return;
    }
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
    final current = _checkpoint();
    if (!connected || _syncing) {
      throw const FormatException('공유 연결 후 게시가 끝났을 때 복구하세요.');
    }
    final saved = await repository.files.report(folder);
    current();
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
    final generation = repository.connectionGeneration;
    void current() {
      if (_disposed ||
          !connected ||
          generation != repository.connectionGeneration) {
        throw const FormatException('실행 게시 연결이 변경되었습니다.');
      }
    }

    _syncing = true;
    publishStatus = 'pending';
    _notify();
    try {
      if (!allows('publishRuns') || incompatibility != null) {
        throw FormatException(incompatibility ?? '실행 게시 권한이 없습니다.');
      }
      for (final p in _publications.values.toList()) {
        if (p.finished) continue;
        if (p.project != repository.project || p.origin != repository.origin) {
          throw const FormatException('실행의 공유 서버/프로젝트가 현재 연결과 다릅니다.');
        }
        if (p.plan['engineVersion'] != projectContext!.engine.engineVersion) {
          throw const FormatException('저장된 실행의 Engine 버전이 서버와 다릅니다.');
        }
        p.serverId ??= (await repository.createRun(
          p.plan,
          p.events.first,
          versionId: p.versionId,
        )).id;
        current();
        final pending = p.events.skip(p.sent).toList();
        if (pending.isNotEmpty) {
          await repository.append(p.serverId!, pending);
          current();
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
          current();
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
      if (!_disposed && generation == repository.connectionGeneration) {
        _permissionFailure(e);
        publishStatus = 'failed: ${_error(e)}. 로컬 결과는 유지됩니다. 게시 재시도를 선택하세요.';
      }
    } finally {
      _syncing = false;
      _notify();
      if (!_disposed &&
          connected &&
          generation == repository.connectionGeneration &&
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
    _actionEpoch++;
    _run.removeListener(_changed);

    super.dispose();
  }
}
