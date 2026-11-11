import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/ai_request.dart';

abstract interface class AiCliService {
  Future<String> diagnose(AiSettings settings);
  Future<AiAnswer> generate(
    AiSettings settings,
    Directory sessionRoot,
    String prompt,
    void Function(String) onProgress,
  );
  Future<void> cancel();
  void dispose();
}

/// Runs only a fixed definition-authoring adapter. No user shell command text.
class LocalAiCliService implements AiCliService {
  LocalAiCliService({
    this.deadline = const Duration(seconds: 180),
    this.closeBudget = const Duration(seconds: 7),
    this.maxStdout = 4 * 1024 * 1024,
    this.maxStderr = 1024 * 1024,
    this.startProcess,
  });
  final Duration deadline, closeBudget;
  final int maxStdout, maxStderr;
  final Future<Process> Function(
    String executable,
    List<String> arguments,
    Directory cwd,
  )?
  startProcess;
  Process? _process;
  bool _busy = false, _cancelled = false, _disposed = false;
  bool _operationBusy = false, _cleanupUnknown = false;
  int _epoch = 0;
  Future<void>? _stopping;
  static const schema = {
    'type': 'object',
    'properties': {
      'summary': {'type': 'string'},
      'xml': {'type': 'string'},
    },
    'required': ['summary', 'xml'],
    'additionalProperties': false,
  };
  static List<String> arguments(Directory session) => [
    '-a',
    'never',
    'exec',
    '--ignore-user-config',
    '--ignore-rules',
    '--ephemeral',
    '--skip-git-repo-check',
    '--sandbox',
    'read-only',
    '--disable',
    'shell_tool',
    '--disable',
    'apps',
    '--disable',
    'hooks',
    '--disable',
    'multi_agent',
    '--disable',
    'remote_plugin',
    '-c',
    'agents.enabled=false',
    '-c',
    'web_search="disabled"',
    '--json',
    '--color',
    'never',
    '--output-schema',
    '${session.path}${Platform.pathSeparator}schema.json',
    '--output-last-message',
    '${session.path}${Platform.pathSeparator}answer.json',
    '-',
  ];
  Future<void> _check(AiSettings settings) async {
    if (_disposed) throw const AiFailure('AI 연결이 종료되었습니다.');
    if (settings.provider != 'codex') {
      throw const AiFailure(
        'Claude는 이 앱에서 아직 실제 연결을 인수하지 않았습니다. 설치·로그인 후 지원 adapter 검증이 필요합니다.',
      );
    }
    if (!File(settings.executable).isAbsolute ||
        !await File(settings.executable).exists()) {
      throw const AiFailure('설치된 Codex CLI 실행 파일의 절대 경로를 지정하세요.');
    }
  }

  Future<T> _operation<T>(Future<T> Function(int) action) async {
    if (_operationBusy || _disposed || _cleanupUnknown) {
      throw const AiFailure('AI 작업 중이거나 이전 프로세스 정리가 확인되지 않았습니다. 연결을 다시 확인하세요.');
    }
    _operationBusy = true;
    _cancelled = false;
    _stopping = null;
    final token = ++_epoch;
    try {
      return await action(token);
    } finally {
      _operationBusy = false;
    }
  }

  void _guard(int token) {
    if (_disposed || _cancelled || token != _epoch) {
      throw const AiFailure('AI 생성이 취소되었습니다.');
    }
  }

  @override
  Future<String> diagnose(AiSettings settings) => _operation((token) async {
    await _check(settings);
    _guard(token);
    final version = await _command(
      settings,
      ['--version'],
      Directory.systemTemp,
      '',
      (_) {},
      structured: false,
      budget: const Duration(seconds: 15),
    );
    _guard(token);
    if (!version.trim().startsWith('codex-cli ')) {
      throw const AiFailure('지원되는 Codex CLI가 아닙니다.');
    }
    final auth = await _command(
      settings,
      ['login', 'status'],
      Directory.systemTemp,
      '',
      (_) {},
      structured: false,
      budget: const Duration(seconds: 15),
    );
    _guard(token);
    return '${version.trim()} · ${auth.toLowerCase().contains('logged in') ? '기존 CLI 로그인 확인' : '로그인 상태는 CLI에서 확인하세요'}';
  });
  @override
  Future<AiAnswer> generate(
    AiSettings settings,
    Directory sessionRoot,
    String prompt,
    void Function(String) onProgress,
  ) => _operation((token) async {
    await _check(settings);
    _guard(token);
    if (utf8.encode(prompt).length > 2 * 1024 * 1024) {
      throw const AiFailure('AI 요청이 2 MiB 제한을 초과했습니다.');
    }
    await sessionRoot.create(recursive: true);
    _guard(token);
    final session = await sessionRoot.createTemp('request-');
    _guard(token);
    await File('${session.path}${Platform.pathSeparator}schema.json')
        .writeAsString(jsonEncode(schema), flush: true);
    _guard(token);
    await _command(settings, arguments(session), session, prompt, onProgress);
    _guard(token);
    final answer = File('${session.path}${Platform.pathSeparator}answer.json');
    if (await FileSystemEntity.type(answer.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const AiFailure('AI 최종 응답 파일이 없습니다.');
    }
    _guard(token);
    final handle = await answer.open();
    late List<int> bytes;
    try {
      bytes = await handle.read(2 * 1024 * 1024 + 1);
    } finally {
      await handle.close();
    }
    _guard(token);
    if (bytes.length > 2 * 1024 * 1024) throw const AiFailure('AI 응답이 너무 큽니다.');
    dynamic value;
    try {
      value = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const AiFailure('AI가 올바른 구조 응답을 반환하지 않았습니다.');
    }
    if (value is! Map ||
        value.length != 2 ||
        value['summary'] is! String ||
        value['xml'] is! String ||
        utf8.encode(value['xml']).length > 1024 * 1024 ||
        !value['xml'].trimLeft().startsWith('<')) {
      throw const AiFailure('AI 응답은 summary와 1 MiB 이하의 전체 XML이어야 합니다.');
    }
    final candidate = File(
      '${session.path}${Platform.pathSeparator}candidate.xml',
    );
    await candidate.create(exclusive: true);
    _guard(token);
    await candidate.writeAsString(value['xml'], flush: true);
    _guard(token);
    return AiAnswer(value['summary'], value['xml'], session.path);
  });
  Future<String> _command(
    AiSettings settings,
    List<String> args,
    Directory cwd,
    String input,
    void Function(String) progress, {
    bool structured = true,
    Duration? budget,
  }) async {
    if (_busy || _disposed) throw const AiFailure('다른 AI 요청이 진행 중입니다.');
    _busy = true;
    Process? child;
    StreamSubscription<List<int>>? out, err;
    Timer? timer;
    String? failure;
    final output = <int>[], errors = <int>[];
    final doneOut = Completer<void>(),
        doneErr = Completer<void>(),
        aborted = Completer<void>();
    final lines = StringBuffer();
    var total = 0, errorTotal = 0, terminal = false;
    void stop(String reason) {
      failure ??= reason;
      if (!aborted.isCompleted) aborted.complete();
      unawaited(cancel());
    }

    void eventLine(String line) {
      if (line.trim().isEmpty) return;
      try {
        final event = jsonDecode(line);
        final type = event['type'];
        if (type == 'turn.failed' || type == 'error') {
          stop('AI 요청이 실패했습니다. CLI 인증/모델 가용성을 확인하세요.');
          return;
        }
        final item = event['item'];
        if (item is Map &&
            !['agent_message', 'reasoning'].contains(item['type'])) {
          stop('정의 생성 중 도구 이벤트가 발생하여 후보를 거절했습니다.');
          return;
        }
        if (type == 'turn.completed') terminal = true;
        if ([
          'thread.started',
          'turn.started',
          'item.started',
          'item.completed',
          'turn.completed',
        ].contains(type)) {
          progress(type.toString());
        }
      } catch (_) {
        stop('AI 진행 응답이 올바른 JSONL이 아닙니다.');
      }
    }

    // Chunk boundaries may split UTF-8; JSONL decoding happens on full lines below.
    final pending = <int>[];
    try {
      child = await (startProcess != null
          ? startProcess!(settings.executable, args, cwd)
          : Process.start(
              settings.executable,
              args,
              workingDirectory: cwd.path,
              runInShell: false,
              mode: ProcessStartMode.normal,
            ));
      _process = child;
      if (_cancelled || _disposed) {
        _stopping = null;
        stop('AI 생성이 취소되었습니다.');
      }
      out = child.stdout.listen(
        (bytes) {
          total += bytes.length;
          if (total > maxStdout) {
            stop('AI 표준 출력 제한을 초과했습니다.');
            return;
          }
          if (structured) {
            pending.addAll(bytes);
            int newline;
            while ((newline = pending.indexOf(10)) >= 0) {
              final line = pending.sublist(0, newline);
              pending.removeRange(0, newline + 1);
              try {
                eventLine(utf8.decode(line));
              } catch (_) {
                stop('AI 출력 인코딩 오류');
              }
            }
          } else {
            output.addAll(bytes);
          }
        },
        onError: (_) {
          stop('AI 출력 읽기 실패');
          if (!doneOut.isCompleted) doneOut.complete();
        },
        onDone: () {
          if (!doneOut.isCompleted) doneOut.complete();
        },
      );
      err = child.stderr.listen(
        (bytes) {
          errorTotal += bytes.length;
          if (errorTotal > maxStderr) {
            stop('AI 진단 출력 제한을 초과했습니다.');
            return;
          }
          if (!structured) errors.addAll(bytes);
        },
        onError: (_) {
          if (!doneErr.isCompleted) doneErr.complete();
        },
        onDone: () {
          if (!doneErr.isCompleted) doneErr.complete();
        },
      );
      timer = Timer(budget ?? deadline, () => stop('AI 생성 시간 제한을 초과했습니다.'));
      child.stdin.add(utf8.encode(input));
      unawaited(child.stdin.close().catchError((_) {}));
      final exit = child.exitCode;
      final complete = Future.wait([exit, doneOut.future, doneErr.future]);
      await Future.any([complete, aborted.future]);
      if (failure != null || _cancelled || _disposed) {
        await cancel();
        try {
          await complete.timeout(closeBudget);
        } on TimeoutException {
          _cleanupUnknown = true;
          failure =
              '${failure ?? 'AI 생성이 취소되었습니다.'} 프로세스/출력 파이프 정리 미확인: 앱을 다시 열기 전에 소유 CLI 작업을 확인하세요.';
        }
      } else {
        await complete;
      }
      if (failure != null) {
        throw AiFailure(failure!, cleanupUnknown: _cleanupUnknown);
      }
      if (_cancelled || _disposed) throw const AiFailure('AI 생성이 취소되었습니다.');
      if (await exit != 0) {
        throw const AiFailure('AI CLI가 실패했습니다. 외부 CLI 로그인·모델·지원 옵션을 확인하세요.');
      }
      if (structured) {
        if (pending.isNotEmpty) eventLine(utf8.decode(pending));
        if (failure != null || !terminal) {
          throw const AiFailure('AI 요청의 정상 완료가 확인되지 않았습니다.');
        }
      }
      lines.write(utf8.decode(output));
      lines.write(utf8.decode(errors));
      return lines.toString();
    } on ProcessException {
      throw const AiFailure('AI CLI를 시작할 수 없습니다. 실행 경로를 확인하세요.');
    } finally {
      timer?.cancel();
      await out?.cancel();
      await err?.cancel();
      _process = null;
      _busy = false;
    }
  }

  @override
  Future<void> cancel() {
    _epoch++;
    _cancelled = true;
    return _stopping ??= _terminate();
  }

  Future<void> _terminate() async {
    final child = _process;
    if (child == null) return;
    // Codex exec has no public stdin cancellation protocol. Stop only our tree.
    if (Platform.isWindows) {
      Process? killer;
      try {
        killer = await Process.start(
          '${Platform.environment['SystemRoot'] ?? r'C:\Windows'}\\System32\\taskkill.exe',
          ['/PID', '${child.pid}', '/T', '/F'],
          runInShell: false,
        );
        unawaited(killer.stdout.drain<void>());
        unawaited(killer.stderr.drain<void>());
        await killer.exitCode.timeout(const Duration(seconds: 5));
      } catch (_) {
        killer?.kill();
        child.kill();
      }
    } else {
      child.kill();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(cancel());
  }
}
