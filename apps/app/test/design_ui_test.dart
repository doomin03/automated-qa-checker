import 'desktop_runtime.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/features/design_baselines/view_models/design_view_model.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/view_models/run_view_model.dart';
import 'package:automated_qa_desktop/features/scenario_editor/repositories/blueprint_catalog.dart';

class UiCatalog extends BlueprintCatalog {
  UiCatalog(this.value);
  final Map<String, dynamic> value;
  @override
  Future<Map<String, dynamic>> load() async => value;
}

void main() {
  testWidgets('reference form -> actual visual run -> verified PNG rendered', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late HttpServer server;
    late String root, node, resources, source, browserVersion;
    late LocalEngineCliService service;
    late UiCatalog catalog;
    await tester.runAsync(() async {
      root = Directory.current.parent.parent.path;
      node = (await Process.run('where.exe', [
        'node.exe',
      ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
      resources = '$root/artifacts/design-ui-reference';
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((r) async {
        r.response.headers.contentType = ContentType.html;
        r.response.write(
          '<style>body{margin:0;background:white}input{box-sizing:border-box;width:100px;height:30px;position:absolute;left:20px;top:20px}</style><input data-testid="entry">',
        );
        await r.response.close();
      });
      final origin = 'http://127.0.0.1:${server.port}';
      final captured = await Process.run(node, [
        '$root/tests/create-design-fixture.mjs',
        origin,
        resources,
      ]);
      expect(captured.exitCode, 0);
      browserVersion = jsonDecode(captured.stdout.toString())['browserVersion'];
      final bundle = jsonDecode(
        await File('assets/engine-contract.json').readAsString(),
      ) as Map<String, dynamic>;
      catalog = UiCatalog(bundle);
      final b =
          jsonDecode(jsonEncode(bundle['example'])) as Map<String, dynamic>;
      b.remove('testCase');
      b['target']['launchTargets'] = {'page': origin};
      b['target']['allowedOrigins'] = [origin];
      b['selectors']['selectors'] = {
        'entry': {
          'web': {'strategy': 'testId', 'value': 'entry'},
        },
      };
      b['flow']['nodes'] = [
        {'id': 'start', 'type': 'start'},
        {
          'id': 'open',
          'type': 'action',
          'action': 'launch',
          'params': {'target': 'page'},
        },
        {'id': 'end', 'type': 'end'},
      ];
      b['flow']['edges'] = [
        {'from': 'start', 'to': 'open'},
        {'from': 'open', 'to': 'end'},
      ];
      source = jsonEncode(b);
      final manifest = jsonDecode(
        await File('assets/desktop-engine-runtime.json').readAsString(),
      ) as Map<String, dynamic>;
      service = LocalEngineCliService(loadManifest: () async => manifest);
    });
    addTearDown(() => server.close(force: true));
    late RunViewModel run;
    late DesignViewModel design;
    await tester.pumpWidget(
      AppProviders(
        engineService: service,
        blueprintCatalog: catalog,
        child: Builder(
          builder: (context) {
            run = context.read<RunViewModel>();
            design = context.read<DesignViewModel>();
            return const QaApp(legacyEditor: true);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> fill(String key, String value) async {
      final f = find.byKey(Key(key));
      await tester.ensureVisible(f);
      await tester.enterText(f, value);
    }

    await fill('scenario-source', source);
    await fill('engine-node', node);
    await fill(
      'engine-cli',
      '${desktopPackageRoot(root)}/packages/cli/aqa.mjs',
    );
    await fill('engine-report', '$root/artifacts/flutter-design-ui');
    await tester.tap(find.text('디자인 기준 / Appium 로컬 설정'));
    await tester.pumpAndSettle();
    await fill('engine-reference-root', resources);
    await tester.ensureVisible(find.text('PNG·수치 기준 연결'));
    await tester.runAsync(() async {
      await tester.tap(find.text('PNG·수치 기준 연결'));
    });
    await tester.pumpAndSettle();
    await fill('design-id', 'ui-baseline-v1');
    await fill('design-png', 'baseline.png');
    await fill('design-rules', 'measurements.json');
    await fill('design-width', '320');
    await fill('design-height', '200');
    await fill('design-browserVersion', browserVersion);
    await fill('design-ready', 'entry');
    await tester.tap(find.text('기준을 새 XML에 연결'));
    await tester.pumpAndSettle();
    expect(find.text('새 디자인 기준 버전'), findsNothing);
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (design.summary == null &&
          design.error == null &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();
    expect(design.error, isNull);
    expect(design.summary, contains('미실행'));
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('scenario-source')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      contains('<references>'),
    );
    // Collapse the reference details so validation/run controls remain visible.
    await tester.ensureVisible(find.text('디자인 기준 / Appium 로컬 설정'));
    await tester.tap(find.text('디자인 기준 / Appium 로컬 설정'));
    await tester.pumpAndSettle();
    for (final key in ['engine-validate', 'engine-run']) {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.runAsync(() async {
        await tester.tap(find.byKey(Key(key)));
        while (run.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();
    }
    expect(run.status, 'passed', reason: run.error);
    expect(run.checks.length, 2);
    expect(run.images, isNotEmpty);
    final title = find.text('검증된 PNG · ${run.images.first.path}');
    await tester.ensureVisible(title);
    await tester.tap(title);
    await tester.pumpAndSettle();
    final image = find.byKey(Key('evidence-image-${run.images.first.path}'));
    expect(image, findsOneWidget);
    expect(tester.widget<Image>(image).image, isA<MemoryImage>());
    await tester.runAsync(() async {
      await File('$root/artifacts/flutter-design-ui/ui-verification.json')
          .writeAsString(
            jsonEncode({
              'outcome': run.status,
              'reportDirectory': run.reportDirectory,
              'referenceInputUi': true,
              'verifiedPngRendered': true,
              'checkReports': run.checks.length,
            }),
          );
    });
  }, timeout: const Timeout(Duration(minutes: 3)));
}
