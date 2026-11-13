import 'dart:async';
import 'dart:io';

import 'dart_runtime.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/ai_authoring/models/ai_request.dart';
import 'package:automated_qa_desktop/features/ai_authoring/services/ai_cli_service.dart';

void main() {
  final dart = testDartExecutable();
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('qa-ai-transport-');
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });
  test('diagnosis checks supported CLI, missing provider/path and auth failure without exposing credentials', () async {
    for (final authenticated in [true, false]) {
      final service = LocalAiCliService(startProcess: (exe, args, cwd) => Process.start(dart, ['test/fixtures/ai_cli_fixture.dart', args.singleOrNull == '--version' ? 'diagnose' : authenticated ? 'auth-ok' : 'auth-fail', cwd.path]));
      if (authenticated) { expect(await service.diagnose(AiSettings(executable: dart)), contains('기존 CLI 로그인 확인')); }
      else { await expectLater(service.diagnose(AiSettings(executable: dart)), throwsA(isA<AiFailure>())); }
      await expectLater(service.diagnose(AiSettings(provider: 'claude', executable: dart)), throwsA(isA<AiFailure>()));
      await expectLater(service.diagnose(const AiSettings(executable: 'missing.exe')), throwsA(isA<AiFailure>()));
      service.dispose();
    }
  });
  test('immediate cancel starts no process and fixed arguments do not embed prompt', () async {
    var spawned = 0;
    final service = LocalAiCliService(
      startProcess: (exe, args, cwd) {
        spawned++;
        return Process.start(dart, [
          'test/fixtures/ai_cli_fixture.dart',
          'success',
          cwd.path,
        ]);
      },
    );
    final future = service.generate(
      AiSettings(executable: dart),
      dir,
      'user request',
      (_) {},
    );
    final assertion = expectLater(future, throwsA(isA<AiFailure>()));
    await service.cancel();
    await assertion;
    expect(spawned, 0);
    final args = LocalAiCliService.arguments(dir);
    expect(args.take(3), ['-a', 'never', 'exec']);
    expect(
      args,
      containsAll([
        '--ignore-user-config',
        '--ignore-rules',
        '--ephemeral',
        'read-only',
        'shell_tool',
        'apps',
        'hooks',
        'multi_agent',
        'remote_plugin',
      ]),
    );
    service.dispose();
  });
  test('actual child structured response, failure, tool, malformed and capped output', () async {
    for (final mode in ['success', 'failure', 'tool', 'invalid', 'overflow']) {
      final service = LocalAiCliService(
        maxStdout: 12000,
        startProcess: (exe, args, cwd) => Process.start(dart, [
          'test/fixtures/ai_cli_fixture.dart',
          mode,
          cwd.path,
        ]),
      );
      final request = service.generate(
        AiSettings(executable: dart),
        dir,
        'no commands',
        (_) {},
      );
      if (mode == 'success') {
        final answer = await request;
        expect(answer.xml, '<blueprint />');
        expect(
          File('${answer.sessionDirectory}/candidate.xml').existsSync(),
          isTrue,
        );
      } else {
        await expectLater(request, throwsA(isA<AiFailure>()));
      }
      service.dispose();
    }
  });
  test(
    'timeout and explicit cancellation stop owned child within finite budget',
    () async {
      for (final explicit in [true, false]) {
        Process? process;
        final started = Completer<void>();
        final service = LocalAiCliService(
          deadline: const Duration(milliseconds: 700),
          closeBudget: const Duration(seconds: 2),
          startProcess: (exe, args, cwd) async {
            process = await Process.start(dart, [
              'test/fixtures/ai_cli_fixture.dart',
              'hang',
              cwd.path,
            ]);
            started.complete();
            return process!;
          },
        );
        final watch = Stopwatch()..start();
        final future = service.generate(
          AiSettings(executable: dart),
          dir,
          'request',
          (_) {},
        );
        final assertion = expectLater(future, throwsA(isA<AiFailure>()));
        await started.future;
        if (explicit) await service.cancel();
        await assertion;
        await process!.exitCode.timeout(const Duration(seconds: 3));
        expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
        service.dispose();
      }
    },
  );
}
