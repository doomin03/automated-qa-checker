import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../models/terminal_profile.dart';

/// Probes executable availability, never credentials or a model completion.
class TerminalProfileService {
  TerminalProfileService({
    Future<Process> Function(String, List<String>)? spawn,
    this.probeTimeout = const Duration(seconds: 5),
  }) : _spawn = spawn ?? _start;
  final Future<Process> Function(String, List<String>) _spawn;
  final Duration probeTimeout;
  Future<String?> chooseExecutable() async => (await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: '프로그램', extensions: ['exe']),
    ],
  ))?.path;
  static Future<Process> _start(String executable, List<String> args) =>
      Process.start(executable, args, runInShell: false);
  Future<TerminalProfile> inspect(String id, {String? executable}) async {
    final label = {
      'codex': 'Codex',
      'claude': 'Claude',
      'powershell': 'PowerShell',
      'cmd': '명령 프롬프트',
    }[id];
    if (label == null) throw ArgumentError.value(id);
    final found = executable?.trim().isNotEmpty == true
        ? executable!.trim()
        : _find(id);
    // Dart's Windows cmd.exe dispatch requires the native executable spelling.
    final path = Platform.isWindows ? found?.replaceAll('/', '\\') : found;
    if (path == null || !File(path).isAbsolute || !await File(path).exists()) {
      return TerminalProfile(
        id,
        label,
        path ?? '',
        readiness: 'missing',
        detail: '실행 파일을 설정하세요.',
      );
    }
    Process? process;
    final output = StringBuffer();
    var size = 0;
    var outputError = false;
    final outDone = Completer<void>(), errDone = Completer<void>();
    StreamSubscription<String>? stdout, stderr;
    try {
      final args = switch (id) {
        'codex' => ['--help'],
        'claude' => ['--version'],
        'powershell' => [
          '-NoLogo',
          '-NoProfile',
          '-Command',
          r'$PSVersionTable.PSVersion.ToString()',
        ],
        _ => ['/D', '/C', 'ver'],
      };
      process = await _spawn(path, args);
      void append(String chunk) {
        size += utf8.encode(chunk).length;
        if (size <= 65536) {
          output.write(chunk);
        } else {
          process?.kill();
        }
      }

      final decoder = const Utf8Decoder(allowMalformed: true);
      stdout = process.stdout
          .transform(decoder)
          .listen(
            append,
            onError: (_) {
              outputError = true;
              process?.kill();
            },
            onDone: outDone.complete,
          );
      stderr = process.stderr
          .transform(decoder)
          .listen(
            append,
            onError: (_) {
              outputError = true;
              process?.kill();
            },
            onDone: errDone.complete,
          );
      final results = await Future.wait<Object?>([
        process.exitCode,
        outDone.future,
        errDone.future,
      ]).timeout(probeTimeout);
      final exit = results.first;
      if (exit != 0 || size > 65536 || outputError) {
        return TerminalProfile(
          id,
          label,
          path,
          readiness: 'failed',
          detail:
              '실행 파일 진단 실패 (exit=$exit, outputError=$outputError, bytes=$size)',
        );
      }
      if (id == 'codex' &&
          [
            '--no-daemon',
            '--no-alt-screen',
            '--sandbox',
            '--ask-for-approval',
          ].any((flag) => !output.toString().contains(flag))) {
        return TerminalProfile(
          id,
          label,
          path,
          readiness: 'unsupported',
          detail: '필수 터미널 옵션이 없는 Codex입니다.',
        );
      }
      return TerminalProfile(
        id,
        label,
        path,
        readiness: 'available',
        detail: '실행 파일 확인 · 로그인/모델 응답은 터미널에서 확인',
      );
    } catch (_) {
      process?.kill();
      if (process != null) {
        try {
          await process.exitCode.timeout(const Duration(seconds: 2));
        } catch (_) {
          return TerminalProfile(
            id,
            label,
            path,
            readiness: 'failed',
            detail: '진단 프로세스 종료 확인 실패',
          );
        }
      }
      return TerminalProfile(
        id,
        label,
        path,
        readiness: 'failed',
        detail: '실행 파일 진단 실패 또는 시간 제한',
      );
    } finally {
      await stdout?.cancel();
      await stderr?.cancel();
    }
  }

  String? _find(String id) {
    final name = id == 'powershell' ? 'powershell' : id;
    final candidates = <String>[
      if (id == 'cmd') '${Platform.environment['SystemRoot']}/System32/cmd.exe',
      if (id == 'powershell')
        '${Platform.environment['SystemRoot']}/System32/WindowsPowerShell/v1.0/powershell.exe',
      if (id == 'codex')
        '${Platform.environment['LOCALAPPDATA']}/Programs/OpenAI/Codex/bin/codex.exe',
      if (id == 'claude')
        '${Platform.environment['USERPROFILE']}/.local/bin/claude.exe',
      for (final dir in (Platform.environment['PATH'] ?? '').split(
        Platform.isWindows ? ';' : ':',
      ))
        '$dir/$name${Platform.isWindows ? '.exe' : ''}',
    ];
    return candidates
        .where((p) => File(p).isAbsolute && File(p).existsSync())
        .firstOrNull;
  }
}
