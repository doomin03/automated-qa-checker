import 'desktop_runtime.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:api_client_dart/platform_client.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/repositories/engine_repository.dart';
import 'package:automated_qa_desktop/features/run_review/view_models/run_view_model.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/services/shared_file_service.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/repositories/shared_repository.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/view_models/shared_view_model.dart';

void main() {
  test('actual Desktop Registry receive, Engine run, separate progress/evidence upload and restart recovery', () async {
    final root = Directory.current.parent.parent.path,
        node = (await Process.run('where.exe', [
          'node.exe',
        ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
    final cli = '${desktopPackageRoot(root)}/packages/cli/aqa.mjs';
    final dir = await Directory('$root/artifacts/flutter-shared')
            .create(recursive: true),
        data = await dir.createTemp('server-');
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var targetCalls = 0;
    target.listen((r) async {
      targetCalls++;
      r.response.headers.contentType = ContentType.html;
      r.response.write('<h1 data-testid="greeting">Ready</h1>');
      await r.response.close();
    });
    final tokens = {
      for (final id in ['author', 'reviewer', 'tester'])
        id: '$id-${DateTime.now().microsecondsSinceEpoch}-local-test-identity',
    };
    final identities = {
      'users': [
        for (final id in tokens.keys)
          {'id': id, 'token': tokens[id], 'active': true},
      ],
      'projects': [
        {'id': 'demo', 'name': 'Demo'},
      ],
      'memberships': [
        for (final id in tokens.keys)
          {
            'userId': id,
            'projectId': 'demo',
            'role': id == 'tester' ? 'qa_tester' : 'qa_manager',
          },
      ],
    };
    Process? server;
    Future<String> start([int port = 0]) async {
      server = await Process.start(
        node,
        ['$root/apps/server/dist/src/main.js'],
        environment: {
          'NODE_ENV': 'test',
          'HOST': '127.0.0.1',
          'PORT': '$port',
          'QA_AUTH_MODE': 'test',
          'QA_DATA_DIR': data.path,
          'QA_ENGINE_CLI': cli,
          'QA_ENGINE_MANIFEST':
              '$root/apps/app/assets/desktop-engine-runtime.json',
          'QA_LOCAL_IDENTITIES_JSON': jsonEncode(identities),
        },
        workingDirectory: root,
        runInShell: false,
      );
      server!.stderr.drain<void>();
      final ready = Completer<String>();
      server!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((l) {
            if (l.startsWith('{"event":"listening"') && !ready.isCompleted) {
              ready.complete(jsonDecode(l)['url']);
            }
          });
      return ready.future.timeout(const Duration(seconds: 30));
    }

    final origin = await start();
    final admin = PlatformClient(origin, tokens['author']!),
        reviewer = PlatformClient(origin, tokens['reviewer']!),
        reader = PlatformClient(origin, tokens['tester']!);
    final manifest = jsonDecode(
      await File('$root/apps/app/assets/desktop-engine-runtime.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    final service = LocalEngineCliService(loadManifest: () async => manifest);
    final run = RunViewModel(EngineRepository(service)),
        repo = SharedRepository(SharedFileService());
    final shared = SharedViewModel(repo, run);
    try {
      final b = jsonDecode(
        await File('$cli/../../../examples/login.qa.json').absolute
            .readAsString(),
      );
      final url = 'http://127.0.0.1:${target.port}';
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
          'id': 'check',
          'type': 'assertion',
          'action': 'assertText',
          'params': {'selector': 'greeting', 'expected': 'Ready'},
        },
        {
          'id': 'proof',
          'type': 'action',
          'action': 'screenshot',
          'params': {'required': true},
        },
        {'id': 'end', 'type': 'end'},
      ];
      b['flow']['edges'] = [
        for (final pair in [
          ['start', 'open'],
          ['open', 'check'],
          ['check', 'proof'],
          ['proof', 'end'],
        ])
          {'from': pair[0], 'to': pair[1]},
      ];
      final settings = EngineSettings(
        nodePath: node,
        cliPath: cli,
        reportRoot: '${dir.path}/reports',
      );
      final xml = await service.exportXml(settings, jsonEncode(b));
      final draft = await admin.createDraft(
        'demo',
        DraftInput(
          packageId: 'shared-scenario',
          title: 'Shared',
          xml: xml,
          dependencies: [],
        ),
      );
      await reviewer.reviewDraft('demo', draft.id);
      final v = await admin.publishDraft('demo', draft.id, '1.0.0', 'first');
      await shared.connect(
        origin,
        tokens['tester']!,
        'demo',
        '${dir.path}/cache',
      );
      expect(shared.connected, true, reason: shared.message);
      await shared.select(v.id);
      final received = await shared.accept();
      expect(received, xml);
      expect(targetCalls, 0);
      expect(await shared.offline('${dir.path}/cache', origin, 'demo'), xml);
      await expectLater(
        repo.connect(
          origin,
          tokens['tester']!,
          'not-member',
          '${dir.path}/cache',
        ),
        throwsFormatException,
      );
      expect((await repo.client.me()).userId, 'tester');
      expect(repo.project, 'demo');
      await repo.files.cache(
        '${dir.path}/cache',
        'http://127.0.0.1:1',
        'demo',
        v.toJson(),
      );
      await shared.offline('${dir.path}/cache', 'http://127.0.0.1:1', 'demo');
      expect(await shared.accept(), isNull);
      await shared.offline('${dir.path}/cache', origin, 'demo');
      shared.enablePublishing(true);
      await run.validate(settings, received!);
      await run.run(settings, received);
      expect(run.status, 'passed', reason: run.error);
      Future<void> published() async {
        final end = DateTime.now().add(const Duration(seconds: 60));
        while (!shared.publishStatus.contains('증거 verified') &&
            !shared.publishStatus.startsWith('failed') &&
            DateTime.now().isBefore(end)) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        expect(shared.publishStatus, contains('증거 verified'));
      }

      await published();
      final remote = (await reader.runs('demo')).items.single;
      expect(remote.reportedOutcome, 'passed');
      expect(remote.versionId, v.id);
      expect(remote.artifacts.single.uploaded, true);
      server!.kill();
      await server!.exitCode;
      b['name'] = 'Edited after Registry receive';
      final edited = await service.exportXml(settings, jsonEncode(b));
      await run.validate(settings, edited);
      expect(repo.versionFor(run.plan!), isNull);
      await run.run(settings, edited);
      expect(run.status, 'passed', reason: run.error);
      // PlatformClient has a 30-second connection/response timeout; a stopped
      // server does not promise a synchronous refused connection on Windows.
      final failedDeadline = DateTime.now().add(const Duration(seconds: 35));
      while (!shared.publishStatus.startsWith('failed') &&
          DateTime.now().isBefore(failedDeadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(shared.publishStatus, startsWith('failed'));
      final second = run.reportDirectory!;
      await start(Uri.parse(origin).port);
      await shared.restoreReport(second);
      await published();
      expect((await reader.runs('demo')).items.length, 2);
      expect(
        (await reader.runs('demo')).items
            .where((r) => r.engineRunId == run.result!['runId'])
            .single
            .versionId,
        isNull,
      );
      await shared.connect(
        origin,
        tokens['tester']!,
        'demo',
        '${dir.path}/cache',
      );
      expect(shared.autoPublish, false);
      await File('${dir.path}/verification.json').writeAsString(
        jsonEncode({
          'engineVersion': run.plan!['engineVersion'],
          'firstServerRun': remote.id,
          'resultDirectory': second,
          'localOutcome': run.status,
          'networkFailureDidNotChangeOutcome': true,
          'durableReportReupload': true,
          'registryReceiveDidNotExecute': true,
          'evidence': 'verified',
        }),
      );
    } finally {
      shared.dispose();
      run.dispose();
      repo.dispose();
      service.dispose();
      admin.close();
      reviewer.close();
      reader.close();
      server?.kill();
      await target.close(force: true);
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
