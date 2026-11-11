import 'desktop_runtime.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/repositories/engine_repository.dart';
import 'package:automated_qa_desktop/features/run_review/view_models/run_view_model.dart';

void main() {
  test('actual pinned package validates without execution, runs PASS/FAIL and protects snapshot', () async {
    final repoRoot = Directory.current.parent.parent.path;
    final packageRoot =
        desktopPackageRoot(repoRoot);
    final node = (await Process.run('where.exe', [
      'node.exe',
    ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
    final output = await Directory('$repoRoot/artifacts/flutter-engine')
        .create(recursive: true);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<input data-testid="username"><button data-testid="submit" onclick="document.querySelector(\'[data-testid=greeting]\').textContent=\'Welcome \'+document.querySelector(\'input\').value">Go</button><h1 data-testid="greeting"></h1>',
      );
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final blueprint = jsonDecode(
      await File('$packageRoot/examples/login.qa.json').readAsString(),
    ) as Map<String, dynamic>;
    final origin = 'http://127.0.0.1:${server.port}';
    blueprint['target']['launchTargets']['login'] = origin;
    blueprint['target']['allowedOrigins'] = [origin];
    blueprint['flow']['metadata'] = {
      'presentation': {
        'numbers': [1.0, 1e20, -0.0, 1e-7],
      },
    };
    final manifest = jsonDecode(
      await File('assets/desktop-engine-runtime.json').readAsString(),
    ) as Map<String, dynamic>;
    final service = LocalEngineCliService(loadManifest: () async => manifest);
    addTearDown(service.dispose);
    final settings = EngineSettings(
      nodePath: node,
      cliPath: '$packageRoot/packages/cli/aqa.mjs',
      reportRoot: output.path,
    );
    final prepared = await service.prepare(settings, jsonEncode(blueprint));
    expect(requests, 0, reason: 'validate/plan must not launch the target');
    final passed = await service.run(prepared).toList();
    expect(passed.last.result?['outcome'], 'passed');
    expect(passed.last.result?['artifacts'], isNotEmpty);
    expect(
      File('${passed.last.reportDirectory}/events.jsonl').existsSync(),
      isTrue,
    );
    final nodes = blueprint['flow']['nodes'] as List;
    nodes.firstWhere((n) => n['id'] == 'home')['params']['expected'] =
        'intentional mismatch';
    final failed = await service
        .run(await service.prepare(settings, jsonEncode(blueprint)))
        .toList();
    expect(failed.last.result?['outcome'], 'failed');
    expect(failed.last.result?['failure']['nodeId'], 'home');
    nodes.firstWhere((n) => n['id'] == 'home')['timeoutMs'] = 30000;
    final cancelPlan = await service.prepare(settings, jsonEncode(blueprint));
    EngineUpdate? cancelledResult;
    await for (final update in service.run(cancelPlan)) {
      if (update.event?['type'] == 'step.started' &&
          update.event?['nodeId'] == 'home') {
        await service.cancel();
      }
      if (update.result != null) cancelledResult = update;
    }
    expect(cancelledResult?.result?['outcome'], 'cancelled');
    await File(prepared.inputPath).writeAsString('{}');
    await expectLater(
      service.run(prepared).toList(),
      throwsA(isA<EngineException>()),
    );
    final before = requests;
    await expectLater(
      service.prepare(settings, '<blueprint bad="true"/>'),
      throwsA(isA<EngineException>()),
    );
    expect(requests, before);
    final gate = Completer<Map<String, dynamic>>();
    final reached = Completer<void>();
    var waitAtVerify = false;
    final earlyCancel = LocalEngineCliService(
      loadManifest: () async {
        if (waitAtVerify) {
          reached.complete();
          return gate.future;
        }
        return manifest;
      },
    );
    addTearDown(earlyCancel.dispose);
    final earlyPrepared = await earlyCancel.prepare(
      settings,
      jsonEncode(blueprint),
    );
    waitAtVerify = true;
    final cancelled = earlyCancel.run(earlyPrepared).toList();
    final assertion = expectLater(
      cancelled,
      throwsA(
        isA<EngineException>().having(
          (e) => e.message,
          'message',
          startsWith('cancelled_before_start:'),
        ),
      ),
    );
    await reached.future;
    await earlyCancel.cancel();
    gate.complete(manifest);
    await assertion;
    expect(
      requests,
      before,
      reason: 'cancel before spawn must never launch browser',
    );
    final badManifest = Map<String, dynamic>.from(manifest)
      ..['engineVersion'] = '0.0.0';
    final mismatch = LocalEngineCliService(
      loadManifest: () async => badManifest,
    );
    addTearDown(mismatch.dispose);
    await expectLater(
      mismatch.prepare(settings, jsonEncode(blueprint)),
      throwsA(isA<EngineException>()),
    );
    await File('${output.path}/verification.json').writeAsString(
      jsonEncode({
        'engineVersion': manifest['engineVersion'],
        'pass': passed.last.reportDirectory,
        'fail': failed.last.reportDirectory,
        'nonExecutingValidation': true,
        'snapshotTamperRejected': true,
        'cancel': cancelledResult?.reportDirectory,
      }),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('event transport rejects gaps, cross-run identity and terminal after active node', () {
    final plan = <String, dynamic>{
      'blueprintSnapshotHash': 'sha256:test',
      'nodeOrder': ['start'],
    };
    Map<String, dynamic> event(int sequence, String type) => {
      'schemaVersion': 'qa.runEvent/v1',
      'runId': 'run_test',
      'attempt': 1,
      'sequence': sequence,
      'type': type,
      'blueprintSnapshotHash': 'sha256:test',
    };
    final gap = EventSequence(plan)..add(event(1, 'run.started'));
    expect(
      () => gap.add(event(3, 'step.started')..['nodeId'] = 'start'),
      throwsA(isA<EngineException>()),
    );
    final wrongRun = EventSequence(plan)..add(event(1, 'run.started'));
    expect(
      () => wrongRun.add(
        event(2, 'step.started')
          ..['runId'] = 'other'
          ..['nodeId'] = 'start',
      ),
      throwsA(isA<EngineException>()),
    );
    final active = EventSequence(plan)
      ..add(event(1, 'run.started'))
      ..add(event(2, 'step.started')..['nodeId'] = 'start');
    expect(
      () => active.add(event(3, 'run.finished')..['outcome'] = 'passed'),
      throwsA(isA<EngineException>()),
    );
  });

  test('view model requires current validation and never infers success from terminal only', () async {
    final service = IncompleteService();
    final vm = RunViewModel(EngineRepository(service));
    addTearDown(vm.dispose);
    const settings = EngineSettings(
      nodePath: 'node',
      cliPath: 'cli',
      reportRoot: 'report',
    );
    await vm.run(settings, 'source');
    expect(service.runs, 0);
    await vm.validate(settings, 'source');
    await vm.run(settings, 'changed');
    expect(service.runs, 0);
    await vm.run(settings, 'source');
    expect(vm.status, 'infra_error');
    expect(vm.result, isNull);
  });
}

class IncompleteService implements EngineCliService {
  @override
  Future<Map<String, dynamic>> capabilities(
    EngineSettings settings,
    String platform,
  ) async => throw UnimplementedError();
  @override
  Future<ExpandedAuthoring> expandAuthoring(
    EngineSettings settings,
    String source,
  ) async => throw UnimplementedError();
  @override
  Future<String> expandPreset(
    EngineSettings settings,
    String id,
    String version,
    Map<String, dynamic> bindings,
  ) async => throw UnimplementedError();
  int runs = 0;
  @override
  Future<PreparedScenario> prepare(
    EngineSettings settings,
    String source,
  ) async => PreparedScenario(
    settings: settings,
    inputPath: 'snapshot',
    reportRoot: 'report',
    plan: {},
  );
  @override
  Stream<EngineUpdate> run(PreparedScenario scenario) async* {
    runs++;
    yield const EngineUpdate(
      event: {'type': 'run.finished', 'outcome': 'passed'},
    );
  }

  @override
  Future<void> cancel() async {}
  @override
  Future<String> exportXml(EngineSettings settings, String source) async =>
      source;
  @override
  void dispose() {}
}
