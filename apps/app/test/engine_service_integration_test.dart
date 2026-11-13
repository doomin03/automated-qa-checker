import 'desktop_runtime.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';

/// Default pin remains unchanged; an explicitly verified external candidate may
/// supply its root+manifest through the test process environment.
void main() {
  test('public package completes real cancellation while UI delivery is paused', () async {
    final repo = Directory.current.parent.parent.path;
    final package =
        Platform.environment['AQA_TEST_ENGINE_ROOT'] ??
        desktopPackageRoot(repo);
    final manifestPath =
        Platform.environment['AQA_TEST_ENGINE_MANIFEST'] ??
        'assets/desktop-engine-runtime.json';
    final manifest = jsonDecode(
      await File(manifestPath).readAsString(),
    ) as Map<String, dynamic>;
    final isolated =
        Platform.environment['AQA_TEST_ENGINE_ROOT'] != null ||
        Platform.environment['AQA_TEST_ENGINE_MANIFEST'] != null;
    if (isolated) {
      final expectedVersion = Platform.environment['AQA_TEST_ENGINE_VERSION'];
      final expectedSha = Platform.environment['AQA_TEST_ENGINE_SHA'];
      expect(expectedVersion, matches(r'^0\.1\.0-alpha\.[1-9][0-9]*$'));
      expect(expectedSha, matches(r'^[a-f0-9]{64}$'));
      expect(manifest['engineVersion'], expectedVersion);
      expect(manifest['sha256'], expectedSha);
    }
    final node = (await Process.run('where.exe', [
      'node.exe',
    ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write('<h1 data-testid="entry">Ready</h1>');
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final b = jsonDecode(
      await File('$package/examples/login.qa.json').readAsString(),
    ) as Map<String, dynamic>;
    final url = 'http://127.0.0.1:${server.port}';
    b['target']['launchTargets']['login'] = url;
    b['target']['allowedOrigins'] = [url];
    b['flow']['nodes'] = [
      {'id': 'start', 'type': 'start'},
      {
        'id': 'open',
        'type': 'action',
        'action': 'launch',
        'params': {'target': 'login'},
      },
      {
        'id': 'wait',
        'type': 'action',
        'action': 'waitFor',
        'timeoutMs': 30000,
        'params': {'selector': 'greeting'},
      },
      {'id': 'end', 'type': 'end'},
    ];
    b['flow']['edges'] = [
      {'from': 'start', 'to': 'open'},
      {'from': 'open', 'to': 'wait'},
      {'from': 'wait', 'to': 'end'},
    ];
    final out = await Directory(
      isolated
          ? '$repo/artifacts/engine-refactor/${manifest['engineVersion']}/${manifest['sha256']}'
          : '$repo/artifacts/service-audit/public-${manifest['engineVersion']}',
    ).create(recursive: true);
    final svc = LocalEngineCliService(loadManifest: () async => manifest);
    addTearDown(svc.dispose);
    final settings = EngineSettings(
      nodePath: node,
      cliPath: '$package/packages/cli/aqa.mjs',
      reportRoot: out.path,
    );
    final watch = Stopwatch()..start();
    final prepared = await svc.prepare(settings, jsonEncode(b));
    final prepareMs = watch.elapsedMilliseconds;
    watch.reset();
    final paused = Completer<void>(), done = Completer<void>();
    String? runId;
    EngineUpdate? result;
    Object? failure;
    late StreamSubscription<EngineUpdate> sub;
    sub = svc
        .run(prepared)
        .listen(
          (update) {
            runId ??= update.event?['runId'] as String?;
            if (update.event?['type'] == 'step.started' &&
                update.event?['nodeId'] == 'wait' &&
                !paused.isCompleted) {
              sub.pause();
              paused.complete();
            }
            if (update.result != null) result = update;
          },
          onError: (Object error) {
            failure = error;
          },
          onDone: () => done.complete(),
        );
    await paused.future.timeout(const Duration(seconds: 20));
    final runUntilPauseMs = watch.elapsedMilliseconds;
    watch.reset();
    await svc.cancel();
    await svc.cancel();
    final persisted = File('${prepared.reportRoot}/$runId/result.json');
    for (var i = 0; i < 120 && !await persisted.exists(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(
      await persisted.exists(),
      isTrue,
      reason: 'Engine cleanup/result must progress without UI delivery',
    );
    final disk = jsonDecode(await persisted.readAsString());
    expect(disk['outcome'], 'cancelled');
    final cancelToDiskMs = watch.elapsedMilliseconds;
    sub.resume();
    await done.future.timeout(const Duration(seconds: 10));
    expect(failure, isNull);
    expect(result?.result?['outcome'], 'cancelled');
    await File('${out.path}/paused-cancel.json').writeAsString(
      jsonEncode({
        'engineVersion': manifest['engineVersion'],
        'prepareMs': prepareMs,
        'runUntilPauseMs': runUntilPauseMs,
        'cancelToDiskMs': cancelToDiskMs,
        'resultWhileUiPaused': true,
        'outcome': result!.result!['outcome'],
        'reportDirectory': result!.reportDirectory,
      }),
    );
  }, timeout: const Timeout(Duration(seconds: 90)));
}
