import 'dart:async';
import 'dart:io';

import '../models/engine_execution.dart';

/// Transport budgets, separate from the Engine's execution/cleanup deadlines.
class CliProcessPolicy {
  const CliProcessPolicy({
    this.commandTimeout = const Duration(seconds: 30),
    this.runTimeout = const Duration(minutes: 2),
    this.cancelGrace = const Duration(seconds: 10),
    this.cleanupTimeout = const Duration(seconds: 2),
    this.maxStdout = 16 * 1024 * 1024,
    this.maxStderr = 2 * 1024 * 1024,
  });
  final Duration commandTimeout, runTimeout, cancelGrace, cleanupTimeout;
  final int maxStdout, maxStderr;
}

/// Owns pipe subscriptions independently of the UI stream. Total accepted bytes
/// bound the queued data even when the UI pauses; diagnostics are never retained.
class CliProcess {
  CliProcess._(this.process, this.policy, Duration timeout, this.gracefulStop) {
    _output.onCancel = () => stop();
    _stdout = process.stdout.listen(
      (bytes) {
        if (_stopping != null || _finished) return;
        _stdoutBytes += bytes.length;
        if (_stdoutBytes > policy.maxStdout) {
          unawaited(stop(const EngineException('엔진 stdout 출력 제한을 초과했습니다.')));
        } else {
          _output.add(bytes);
        }
      },
      onError: (Object _) {
        unawaited(stop(const EngineException('엔진 stdout을 읽을 수 없습니다.')));
      },
      onDone: () {
        _outClosed = true;
        _completeIfClosed();
      },
    );
    _stderr = process.stderr.listen(
      (bytes) {
        if (_stopping != null || _finished) return;
        _stderrBytes += bytes.length;
        if (_stderrBytes > policy.maxStderr) {
          unawaited(stop(const EngineException('엔진 stderr 출력 제한을 초과했습니다.')));
        }
      },
      onError: (Object _) {
        unawaited(stop(const EngineException('엔진 stderr를 읽을 수 없습니다.')));
      },
      onDone: () {
        _errClosed = true;
        _completeIfClosed();
      },
    );
    process.exitCode.then((value) {
      exitCode = value;
      _completeIfClosed();
    });
    _deadline = Timer(timeout, () {
      unawaited(stop(const EngineException('엔진 응답 시간이 초과되었습니다.')));
    });
  }

  static Future<CliProcess> start(
    String executable,
    List<String> arguments, {
    required CliProcessPolicy policy,
    required Duration timeout,
    bool gracefulStop = false,
    Map<String, String>? environment,
  }) async {
    try {
      final process = await Process.start(
        executable,
        arguments,
        runInShell: false,
        environment: environment,
      );
      return CliProcess._(process, policy, timeout, gracefulStop);
    } on ProcessException {
      throw const EngineException('엔진 프로세스를 시작할 수 없습니다. 실행 경로를 확인하세요.');
    }
  }

  final Process process;
  final CliProcessPolicy policy;
  final bool gracefulStop;
  final _output = StreamController<List<int>>();
  final _done = Completer<void>();
  late final StreamSubscription<List<int>> _stdout, _stderr;
  Timer? _deadline, _cancelDeadline;
  Future<void>? _stopping;
  Future<void>? _forcing;
  Stopwatch? _cancelWatch;
  bool _outClosed = false, _errClosed = false, _finished = false;
  bool _cancelSent = false;
  int _stdoutBytes = 0, _stderrBytes = 0;
  int? exitCode;
  EngineException? failure;
  Stream<List<int>> get stdout => _output.stream;
  Future<void> get done => _done.future;

  void _completeIfClosed() {
    if (exitCode != null && _outClosed && _errClosed) _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _deadline?.cancel();
    _cancelDeadline?.cancel();
    // Do not await this: a paused UI is allowed to consume the queue later.
    unawaited(_output.close());
    _done.complete();
  }

  void check() {
    if (failure != null) throw failure!;
  }

  Future<void> cancel({required bool controlStdin}) async {
    if (_finished || _cancelSent) return;
    _cancelSent = true;
    _cancelWatch = Stopwatch()..start();
    _cancelDeadline = Timer(policy.cancelGrace, () {
      unawaited(
        _force(
          const EngineException(
            'infra_error: 취소 후 엔진이 종료되지 않았습니다. 강제 종료는 정상 취소가 아닙니다.',
          ),
        ),
      );
    });
    if (!controlStdin) {
      await _force(const EngineException('infra_error: 정상 취소 제어를 지원하지 않습니다.'));
      return;
    }
    try {
      process.stdin.writeln('{"type":"cancel"}');
      await process.stdin.flush().timeout(policy.cleanupTimeout);
    } catch (_) {
      // A concurrently completed process still needs terminal/result validation.
      if (!_finished) {
        await _force(
          const EngineException('infra_error: 엔진 취소 요청을 전달하지 못했습니다.'),
        );
      }
    }
  }

  Future<void> stop([EngineException? error]) {
    if (_finished) return Future<void>.value();
    failure ??= error;
    return _stopping ??= _stop();
  }

  Future<void> _stop() async {
    _deadline?.cancel();
    if (gracefulStop) {
      await cancel(controlStdin: true);
      if (_finished) return;
      final remaining = policy.cancelGrace - _cancelWatch!.elapsed;
      if (remaining > Duration.zero) {
        try {
          await done.timeout(remaining);
          return;
        } on TimeoutException {
          // The original cancellation budget is never restarted.
        }
      }
    }
    await _force();
  }

  Future<void> _force([EngineException? error]) {
    if (_finished) return Future<void>.value();
    if (_forcing != null) return _forcing!;
    failure = EngineException(
      '${failure?.message ?? error?.message ?? 'infra_error: 강제 종료했습니다.'} '
      '하위 프로세스/장치 정리 상태는 확인되지 않았습니다.',
    );
    return _forcing ??= _forceStop();
  }

  Future<void> _forceStop() async {
    _deadline?.cancel();
    _cancelDeadline?.cancel();
    process.kill();
    try {
      await Future.wait<void>([
        process.exitCode.then((code) {
          exitCode = code;
        }),
        _stdout.cancel(),
        _stderr.cancel(),
      ]).timeout(policy.cleanupTimeout);
    } on TimeoutException {
      failure ??= const EngineException('infra_error: 엔진 종료 정리를 확인할 수 없습니다.');
    } catch (_) {
      failure ??= const EngineException('infra_error: 엔진 종료 정리에 실패했습니다.');
    } finally {
      _finish();
    }
  }
}
