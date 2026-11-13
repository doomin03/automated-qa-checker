import 'desktop_runtime.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/view_models/run_view_model.dart';
import 'package:automated_qa_desktop/features/scenario_editor/view_models/flow_editor_view_model.dart';

void main() {
  testWidgets(
    'user enters XML, validates and runs actual CLI through Provider UI',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late String source;
      late String cancelSource;
      late String node;
      late String cli;
      late String reports;
      late LocalEngineCliService service;
      late HttpServer server;
      var requests = 0;
      await tester.runAsync(() async {
        final root = Directory.current.parent.parent.path;
        final packageRoot =
            desktopPackageRoot(root);
        node = (await Process.run('where.exe', [
          'node.exe',
        ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
        cli = '$packageRoot/packages/cli/aqa.mjs';
        reports = '$root/artifacts/flutter-ui-engine';
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((request) async {
          requests++;
          request.response.headers.contentType = ContentType.html;
          request.response.write(
            '<input data-testid="username"><h1 data-testid="greeting">Ready</h1>',
          );
          await request.response.close();
        });
        final b = jsonDecode(
          await File('$packageRoot/examples/login.qa.json').readAsString(),
        ) as Map<String, dynamic>;
        final origin = 'http://127.0.0.1:${server.port}';
        b['target']['launchTargets']['login'] = origin;
        b['target']['allowedOrigins'] = [origin];
        b['flow']['nodes'] = [
          {'id': 'start', 'type': 'start'},
          {
            'id': 'open',
            'type': 'action',
            'action': 'launch',
            'params': {'target': 'login'},
          },
          {
            'id': 'home',
            'type': 'assertion',
            'action': 'assertText',
            'params': {'selector': 'greeting', 'expected': 'Ready'},
          },
          {'id': 'end', 'type': 'end'},
        ];
        b['flow']['edges'] = [
          {'from': 'start', 'to': 'open'},
          {'from': 'open', 'to': 'home'},
          {'from': 'home', 'to': 'end'},
        ];
        await Directory(reports).create(recursive: true);
        final input = File('$reports/source.json');
        await input.writeAsString(jsonEncode(b));
        final exported = await Process.run(node, [
          cli,
          'export',
          input.path,
          '--format',
          'xml',
        ]);
        expect(exported.exitCode, 0);
        source = exported.stdout.toString();
        b['flow']['nodes'][2]['params']['expected'] = 'Never appears';
        b['flow']['nodes'][2]['timeoutMs'] = 30000;
        b['selectors']['selectors']['greeting']['web']['value'] =
            'never-visible-cancel-fixture';
        cancelSource = jsonEncode(b);
        final manifest = jsonDecode(
          await File('assets/desktop-engine-runtime.json').readAsString(),
        ) as Map<String, dynamic>;
        service = LocalEngineCliService(loadManifest: () async => manifest);
      });
      addTearDown(() => server.close(force: true));
      late RunViewModel vm;
      late FlowEditorViewModel flow;
      await tester.pumpWidget(
        AppProviders(
          engineService: service,
          child: Builder(
            builder: (context) {
              vm = context.read<RunViewModel>();
              flow = context.read<FlowEditorViewModel>();
              return const QaApp(legacyEditor: true);
            },
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('scenario-source')), source);
      await tester.enterText(find.byKey(const Key('engine-node')), node);
      await tester.enterText(find.byKey(const Key('engine-cli')), cli);
      await tester.enterText(find.byKey(const Key('engine-report')), reports);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('engine-validate')));
        while (vm.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pump();
      expect(vm.status, 'validated', reason: vm.error);
      expect(requests, 0);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('engine-run')));
        while (vm.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pump();
      expect(vm.status, 'passed', reason: vm.error);
      expect(find.byKey(const Key('engine-result')), findsOneWidget);
      expect(requests, greaterThan(0));
      await tester.tap(find.text('블록 / Flow'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('검증 계획에서 불러오기'));
      await tester.pumpAndSettle();
      final nodeStatus = find.descendant(
        of: find.byKey(const Key('flow-node-home')),
        matching: find.byType(Text),
      );
      expect(tester.widget<Text>(nodeStatus).data, contains('passed'));
      flow.move('start', 100, 100);
      await tester.pumpAndSettle();
      expect(find.textContaining('편집 Flow가 실행 snapshot과 다릅니다'), findsOneWidget);
      expect(tester.widget<Text>(nodeStatus).data, contains('편집'));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(nodeStatus).data, contains('passed'));
      expect(find.text('Flow를 원문에 적용'), findsNothing);
      await tester.runAsync(() async {
        await File('$reports/ui-verification.json').writeAsString(
          jsonEncode({
            'outcome': vm.status,
            'reportDirectory': vm.reportDirectory,
            'path':
                'Flutter widget user input -> actual installed CLI -> result',
          }),
        );
      });
      await tester.tap(find.text('XML / JSON'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('디자인 기준 / Appium 로컬 설정'));
      await tester.tap(find.text('디자인 기준 / Appium 로컬 설정'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('검증한 대상에 UX 팩 매핑'));
      await tester.runAsync(() async {
        await tester.tap(find.text('검증한 대상에 UX 팩 매핑'));
      });
      await tester.pumpAndSettle();
      final presetDropdown = find.byType(DropdownButton<String>);
      if (tester.widget<DropdownButton<String>>(presetDropdown).value !=
          'web-input') {
        await tester.tap(presetDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('web-input').last);
        await tester.pumpAndSettle();
      }
      for (final entry in {
        'id': 'ui-input-pack',
        'launch': 'login',
        'selector': 'username',
        'value': 'UI typed value',
      }.entries) {
        await tester.ensureVisible(find.byKey(Key('preset-${entry.key}')));
        await tester.enterText(
          find.byKey(Key('preset-${entry.key}')),
          entry.value,
        );
      }
      final beforePreset = requests;
      await tester.runAsync(() async {
        await tester.tap(find.text('팩 XML 만들기 (미실행)'));
        while (vm.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();
      expect(vm.error, isNull);
      expect(requests, beforePreset);
      await tester.ensureVisible(find.text('디자인 기준 / Appium 로컬 설정'));
      await tester.tap(find.text('디자인 기준 / Appium 로컬 설정'));
      await tester.pumpAndSettle();
      for (final key in ['engine-validate', 'engine-run']) {
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.runAsync(() async {
          await tester.tap(find.byKey(Key(key)));
          while (vm.busy) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        });
        await tester.pumpAndSettle();
      }
      expect(vm.status, 'passed', reason: vm.error);
      final presetReport = vm.reportDirectory;
      await tester.enterText(
        find.byKey(const Key('scenario-source')),
        cancelSource,
      );
      await tester.ensureVisible(find.byKey(const Key('engine-validate')));
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('engine-validate')));
        while (vm.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('engine-run')));
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('engine-run')));
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!vm.events.any(
              (e) => e['type'] == 'step.started' && e['nodeId'] == 'home',
            ) &&
            vm.busy &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pump();
      expect(vm.running, true);
      await tester.ensureVisible(find.byKey(const Key('engine-cancel')));
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('engine-cancel')));
        while (vm.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();
      expect(vm.status, 'cancelled', reason: vm.error);
      expect(vm.result?['outcome'], 'cancelled');
      await tester.runAsync(
        () => File('$reports/ui-preset-cancel-verification.json').writeAsString(
          jsonEncode({
            'presetReport': presetReport,
            'cancelReport': vm.reportDirectory,
            'presetMappedWithoutCode': true,
            'presetDidNotAutoRun': true,
            'actualCancelButton': true,
            'terminalOutcome': vm.result?['outcome'],
          }),
        ),
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
