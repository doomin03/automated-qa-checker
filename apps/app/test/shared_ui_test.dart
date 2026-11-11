import 'desktop_runtime.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/features/scenario_editor/view_models/scenario_editor_view_model.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:api_client_dart/platform_client.dart';
import 'package:automated_qa_desktop/features/run_review/view_models/run_view_model.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/view_models/shared_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/views/shared_panel.dart';

void main() {
  testWidgets(
    'Desktop shared form receives actual Registry XML without executing',
    (tester) async {
      final previous = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previous);
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Process server;
      late String origin, cache, xml, root;
      late String firstVersion, secondVersion;
      late SharedViewModel vm;
      late RunViewModel run;
      final tokens = {
        for (final id in ['author', 'reviewer', 'tester'])
          id: '$id-${DateTime.now().microsecondsSinceEpoch}-ui-test-identity',
      };
      await tester.runAsync(() async {
        root = Directory.current.parent.parent.path;
        final node = (await Process.run('where.exe', [
          'node.exe',
        ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
        final cli =
                '${desktopPackageRoot(root)}/packages/cli/aqa.mjs',
            dir = await Directory('$root/artifacts/flutter-shared-ui')
                .create(recursive: true),
            data = await dir.createTemp('server-');
        cache = '${data.path}/cache';
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
        server = await Process.start(
          node,
          ['$root/apps/server/dist/src/main.js'],
          workingDirectory: root,
          environment: {
            'NODE_ENV': 'test',
            'HOST': '127.0.0.1',
            'PORT': '0',
            'QA_AUTH_MODE': 'test',
            'QA_DATA_DIR': data.path,
            'QA_ENGINE_CLI': cli,
            'QA_ENGINE_MANIFEST': '$root/apps/app/assets/desktop-engine-runtime.json',
            'QA_LOCAL_IDENTITIES_JSON': jsonEncode(identities),
          },
          runInShell: false,
        );
        server.stderr.drain<void>();
        final ready = Completer<String>();
        server.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((l) {
              if (l.startsWith('{"event":"listening"')) {
                ready.complete(jsonDecode(l)['url']);
              }
            });
        origin = await ready.future.timeout(const Duration(seconds: 30));
        xml = (await Process.run(node, [
          cli,
          'template',
          '--format',
          'xml',
        ])).stdout.toString();
        final admin = PlatformClient(origin, tokens['author']!),
            reviewer = PlatformClient(origin, tokens['reviewer']!);
        try {
          final d = await admin.createDraft(
            'demo',
            DraftInput(
              packageId: 'shared-ui',
              title: 'UI',
              xml: xml,
              dependencies: [],
            ),
          );
          await reviewer.reviewDraft('demo', d.id);
          final first = await admin.publishDraft(
            'demo',
            d.id,
            '1.0.0',
            'first',
          );
          firstVersion = first.id;
          final next = await admin.createDraft(
            'demo',
            DraftInput(
              packageId: 'shared-ui',
              title: 'Second immutable member',
              xml: xml,
              dependencies: [],
            ),
          );
          await reviewer.reviewDraft('demo', next.id);
          final second = await admin.publishDraft(
            'demo',
            next.id,
            '1.1.0',
            'second',
          );
          secondVersion = second.id;
          final suite = await admin.createSuiteDraft(
            'demo',
            SuiteDraftInput(
              packageId: 'desktop-suite',
              title: 'Desktop ordered members',
              stopOnFailure: true,
              cases: [
                SuiteCase(
                  caseId: 'first',
                  versionId: first.id,
                  sha256: first.sha256,
                ),
                SuiteCase(
                  caseId: 'second',
                  versionId: second.id,
                  sha256: second.sha256,
                ),
              ],
            ),
          );
          await reviewer.reviewSuiteDraft('demo', suite.id);
          await admin.publishSuiteDraft(
            'demo',
            suite.id,
            '1.0.0',
            'suite-first',
          );
        } finally {
          admin.close();
          reviewer.close();
        }
      });
      addTearDown(() => server.kill());

      await tester.pumpWidget(
        AppProviders(
          child: Builder(
            builder: (context) {
              vm = context.read<SharedViewModel>();
              run = context.read<RunViewModel>();
              return const MaterialApp(
                home: Scaffold(
                  body: SingleChildScrollView(child: SharedPanel()),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('공용 XML · 서버 진행 공유 (선택)'));
      await tester.pumpAndSettle();
      for (final entry in {
        'shared-origin': origin,
        'shared-token': tokens['tester']!,
        'shared-project': 'demo',
        'shared-cache': cache,
      }.entries) {
        await tester.enterText(find.byKey(Key(entry.key)), entry.value);
      }
      Future<void> click(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.runAsync(() async {
          await tester.tap(find.text(label));
          await Future<void>.delayed(const Duration(milliseconds: 20));
          while (vm.busy) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        });
        await tester.pumpAndSettle();
      }

      await click('공유 연결');
      expect(vm.connected, true, reason: vm.message);
      await click(
        'shared-ui · 1.0.0 · ${vm.versions.firstWhere((v) => v['version'] == '1.0.0')['sha256']}',
      );
      await click('이 버전 고정·초안으로 수신 (실행 안 함)');
      expect(
        tester
            .element(find.byType(SharedPanel))
            .read<ScenarioEditorViewModel>()
            .draft
            .content,
        xml,
      );
      expect(run.events, isEmpty);
      expect(run.status, 'not_started');
      expect(vm.autoPublish, false);
      await click('공용 Suite · 개별 case 수신');
      await click('Suite 목록 가져오기');
      await click('Suite desktop-suite · 1.0.0');
      expect(
        (vm.selectedSuite!['cases'] as List).map((v) => v['caseId']).toList(),
        ['first', 'second'],
      );
      expect(run.events, isEmpty);
      await click('선택 Suite 버전 고정 (실행 안 함)');
      expect(vm.suitePinned, true, reason: vm.message);
      for (final entry in {
        'first': firstVersion,
        'second': secondVersion,
      }.entries) {
        await click('Suite case ${entry.key} · ${entry.value}');
        await click('이 버전 고정·초안으로 수신 (실행 안 함)');
        expect(vm.repository.receivedVersion!['id'], entry.value);
        expect(
          tester
              .element(find.byType(SharedPanel))
              .read<ScenarioEditorViewModel>()
              .draft
              .content,
          xml,
        );
        expect(run.events, isEmpty);
      }
      await tester.runAsync(() async {
        final proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
            http = HttpClient();
        final seen = Completer<void>(), release = Completer<void>();
        var hold = false, pins = 0;
        proxy.listen((request) async {
          try {
            if (request.uri.path.endsWith('/pins')) pins++;
            if (hold && request.uri.path.contains('/versions/')) {
              if (!seen.isCompleted) seen.complete();
              await release.future;
            }
            final forwarded = await http.openUrl(
              request.method,
              Uri.parse(origin).resolve(request.uri.toString()),
            );
            request.headers.forEach((k, values) {
              if (!['host', 'content-length'].contains(k)) {
                forwarded.headers.set(k, values);
              }
            });
            await forwarded.addStream(request);
            final response = await forwarded.close();
            request.response.statusCode = response.statusCode;
            response.headers.forEach((k, v) {
              if (![
                'transfer-encoding',
                'content-length',
                'connection',
              ].contains(k)) {
                request.response.headers.set(k, v);
              }
            });
            await request.response.addStream(response);
            await request.response.close();
          } catch (_) {
            await request.response.close();
          }
        });
        try {
          await vm.repository.connect(
            'http://127.0.0.1:${proxy.port}',
            tokens['tester']!,
            'demo',
            cache,
          );
          final old = await vm.repository.preview(firstVersion);
          hold = true;
          final pending = vm.repository
              .accept(old)
              .then<Object?>((_) => null, onError: (Object error) => error);
          await seen.future.timeout(const Duration(seconds: 5));
          await vm.repository.connect(origin, tokens['tester']!, 'demo', cache);
          release.complete();
          expect(await pending, isNotNull);
          expect(pins, 0);
          expect(vm.repository.receivedVersion!['id'], secondVersion);
        } finally {
          if (!release.isCompleted) release.complete();
          http.close(force: true);
          await proxy.close(force: true);
        }
      });
      await tester.runAsync(
        () => File('$root/artifacts/flutter-shared-ui/verification.json')
            .writeAsString(
              jsonEncode({
                'actualRegistryUi': true,
                'receivedXml': true,
                'automaticExecution': false,
                'offlinePinWritten': true,
                'suiteOrderedCases': 2,
                'suiteCaseVersionIds': [firstVersion, secondVersion],
                'suiteAutomaticExecution': false,
                'connectionChangedDuringReceivePreservedOldPin': true,
              }),
            ),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
