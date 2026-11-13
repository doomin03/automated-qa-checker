import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_pty2/flutter_pty2.dart';

typedef PtyFactory = Future<PtySession> Function(PtySpawnOptions options);

/// Sole owner of the native session. Screen visibility never pauses its drain.
class TerminalService {
  TerminalService({
    PtyFactory? spawn,
    this.closeBudget = const Duration(seconds: 12),
  }) : _spawn = spawn ?? Pty.spawn;
  final PtyFactory _spawn;
  final Duration closeBudget;
  PtySession? _session;
  StreamSubscription<String>? _output;
  Future<void>? _starting, _closing;
  int _epoch = 0;
  bool _disposed = false, cleanupUnknown = false;
  PtySize _size = const PtySize(columns: 80, rows: 24);
  void Function(String)? onOutput;
  void Function(String)? onState;
  String state = 'idle';
  int? get pid => _session?.pid;
  bool get active => _session != null || _starting != null || _closing != null;
  void _state(String value) {
    state = cleanupUnknown ? 'cleanup_unknown' : value;
    onState?.call(state);
  }

  Future<void> start(
    String executable,
    List<String> args,
    String directory,
  ) async {
    if (_disposed || active || cleanupUnknown) {
      throw StateError('이전 터미널이 종료되지 않았습니다.');
    }
    final ticket = ++_epoch;
    final operation = _start(ticket, executable, args, directory);
    _starting = operation;
    try {
      await operation;
    } finally {
      if (identical(_starting, operation)) _starting = null;
    }
  }

  Future<void> _start(
    int ticket,
    String executable,
    List<String> args,
    String directory,
  ) async {
    _state('starting');
    try {
      final session = await _spawn(
        PtySpawnOptions(
          executable: executable,
          arguments: args,
          workingDirectory: directory,
          size: _size,
          inputBufferBytes: 65536,
          outputWindowBytes: 65536,
        ),
      );
      _session = session;
      _output = session.utf8Output().listen(
        (text) => onOutput?.call(text),
        onError: (Object error) {
          onOutput?.call('\r\n[PTY 출력 오류]\r\n');
        },
      );
      if (_disposed || ticket != _epoch) {
        await _closeSession(session);
        return;
      }
      _state('running');
      unawaited(_observe(session));
    } catch (_) {
      if (!cleanupUnknown) _state(ticket == _epoch ? 'failed' : 'closed');
      rethrow;
    }
  }

  Future<void> _observe(PtySession session) async {
    try {
      // A parent exiting must close its Job even if descendants hold output open.
      await session.processExit;
      try {
        await session.done.timeout(const Duration(seconds: 2));
      } catch (_) {
        /* close still owns the Job */
      }
      if (identical(_session, session)) await close();
    } catch (_) {
      if (identical(_session, session)) {
        cleanupUnknown = true;
        _state('cleanup_unknown');
      }
    }
  }

  void write(String text) {
    final bytes = Uint8List.fromList(utf8.encode(text));
    if (bytes.length > 32768) {
      throw StateError('한 번의 입력은 UTF-8 32 KiB 이하로 나누어 주세요.');
    }
    if (_session == null || state != 'running') {
      throw StateError('터미널이 실행 중이 아닙니다.');
    }
    if (_session!.input.tryWrite(bytes) != PtyWriteResult.accepted) {
      throw StateError('입력 큐가 가득 찼습니다. 잠시 후 다시 입력하세요.');
    }
  }

  void resize(int columns, int rows) {
    _size = PtySize(columns: columns.clamp(2, 500), rows: rows.clamp(2, 300));
    if (state == 'running') {
      _session?.resize(_size);
    }
  }

  Future<void> close() async {
    if (_closing != null) return _closing!;
    ++_epoch;
    final operation = _close();
    _closing = operation;
    try {
      await operation;
    } finally {
      if (identical(_closing, operation)) _closing = null;
    }
  }

  Future<void> _close() async {
    _state('closing');
    try {
      final pending = _starting;
      if (pending != null) {
        try {
          await pending.timeout(closeBudget);
        } catch (_) {
          if (_session == null) rethrow;
        }
      }
      final session = _session;
      if (session != null) await _closeSession(session);
      if (!cleanupUnknown) _state('closed');
    } catch (_) {
      cleanupUnknown = true;
      _state('cleanup_unknown');
    }
  }

  Future<void> _closeSession(PtySession session) async {
    try {
      await session.close().timeout(closeBudget);
      await _output?.cancel();
      if (identical(_session, session)) _session = null;
      if (!cleanupUnknown) _state('closed');
    } catch (_) {
      cleanupUnknown = true;
      _state('cleanup_unknown');
      rethrow;
    }
  }

  void dispose() {
    _disposed = true;
    onOutput = null;
    onState = null;
    unawaited(close());
  }
}
