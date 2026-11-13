import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/desktop_workspace_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/xml_block_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/run_review/services/portable_runtime_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'portable runtime defaults in real Windows UI and explicit QA run',
    (tester) async {
      const repo = String.fromEnvironment('QA_REPO');
      const bundle = String.fromEnvironment('QA_PORTABLE_ROOT');
      final expectedRoot = bundle.isEmpty
          ? File(Platform.resolvedExecutable).parent.path.replaceAll('\\', '/')
          : bundle;
      final root = await Directory('$repo/artifacts/portable-runtime/native')
          .create(recursive: true);
      final out = await root.createTemp('run-');
      final runtime = PortableRuntimeService(
        executableDirectory: bundle.isEmpty ? null : bundle,
        required: true,
      );
      final boundary = GlobalKey();
      late DesktopWorkspaceViewModel desktop;
      late XmlBlockWorkbenchViewModel blocks;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requests = 0;
      server.listen((request) async {
        requests++;
        request.response.headers.contentType = ContentType.html;
        request.response.write('<h1 data-testid="greeting">Ready</h1>');
        await request.response.close();
      });
      Future<void> wait(bool Function() predicate) async {
        final end = DateTime.now().add(const Duration(seconds: 90));
        while (!predicate() && DateTime.now().isBefore(end)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          predicate(),
          isTrue,
          reason: desktop.error ?? desktop.work.run.error,
        );
        await tester.pump(const Duration(milliseconds: 100));
      }

      Future<void> shot(String name) async {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${out.path}/$name.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      }

      try {
        await tester.pumpWidget(
          AppProviders(
            portableRuntime: runtime,
            workspaceFileService: WorkspaceFileService(
              directory: Directory('${out.path}/workspace'),
            ),
            child: Builder(
              builder: (context) {
                desktop = context.read<DesktopWorkspaceViewModel>();
                blocks = context.read<XmlBlockWorkbenchViewModel>();
                return RepaintBoundary(key: boundary, child: const QaApp());
              },
            ),
          ),
        );
        await tester.pump();
        await shot('01-preparing');
        await wait(() => desktop.initialized);
        expect(desktop.error, isNull);
        expect(
          desktop.work.settings.execution.cliPath.replaceAll('\\', '/'),
          startsWith(expectedRoot),
        );
        expect(desktop.work.settings.usesAutomaticRuntime, isTrue);
        final initialNodeMs = runtime.lastNodeVerificationMs;
        await tester.tap(find.byTooltip('파일'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('실행 환경 / 연결').last);
        await tester.pumpAndSettle();
        expect(find.text('기본 실행 환경 사용 중'), findsOneWidget);
        await shot('02-relative-settings');
        await tester.tap(find.text('닫기').last);
        await tester.pumpAndSettle();
        await desktop.createProject('이동형 실행 환경');
        final b = jsonDecode(
          jsonEncode(desktop.contract!['example']),
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
            'id': 'check',
            'type': 'assertion',
            'action': 'assertText',
            'params': {'selector': 'greeting', 'expected': 'Ready'},
          },
          {
            'id': 'capture',
            'type': 'action',
            'action': 'screenshot',
            'params': {},
          },
          {'id': 'end', 'type': 'end'},
        ];
        b['flow']['edges'] = [
          {'from': 'start', 'to': 'open'},
          {'from': 'open', 'to': 'check'},
          {'from': 'check', 'to': 'capture'},
          {'from': 'capture', 'to': 'end'},
        ];
        expect(
          await desktop.createQaFromSource('로컬 웹 실행', jsonEncode(b)),
          isTrue,
        );
        await wait(() => !blocks.busy);
        blocks.setEnabled(false);
        await tester.pumpAndSettle();
        expect(requests, 0);
        await tester.tap(find.byKey(const Key('workspace-validate')));
        await wait(() => desktop.work.canUsePlan);
        expect(requests, 0);
        await tester.tap(find.byKey(const Key('workspace-run')));
        await wait(
          () => !desktop.work.run.running && desktop.work.run.result != null,
        );
        expect(desktop.work.run.result!['outcome'], 'passed');
        expect(desktop.work.run.images, isNotEmpty);
        await shot('03-explicit-pass');
        await tester.tap(find.text('PNG 1개').last);
        await tester.pumpAndSettle();
        expect(find.text('실행 화면 증거'), findsOneWidget);
        final evidenceImage = find.descendant(
          of: find.byType(AlertDialog).last,
          matching: find.byType(Image),
        );
        expect(evidenceImage, findsOneWidget);
        expect(tester.widget<Image>(evidenceImage).image, isA<MemoryImage>());
        expect(tester.getSize(evidenceImage).height, greaterThan(100));
        await shot('04-visible-png');
        await tester.tap(find.text('닫기').last);
        await tester.pumpAndSettle();
        expect(await desktop.save(), isTrue);
        final evidence = {
          'bundle': expectedRoot,
          'executableRelative': bundle.isEmpty,
          'node': desktop.work.settings.value.nodePath,
          'cli': desktop.work.settings.value.cliPath,
          'automatic': desktop.work.settings.usesAutomaticRuntime,
          'evidenceImageVisible': true,
          'initialNodeVerificationMs': initialNodeMs,
          'report': desktop.work.run.reportDirectory,
          'result': desktop.work.run.result,
          'pid': pid,
          'executable': Platform.resolvedExecutable,
          'kind': bundle.isEmpty
              ? 'sanitized assets; native UI resolves executable-relative runtime; final Release launch separate'
              : 'native UI with injected relocated runtime; final portable Release startup separate',
        };
        await File(
          '${out.path}/verification.json',
        ).writeAsString(const JsonEncoder.withIndent('  ').convert(evidence));
        await File('${root.path}/latest.json')
            .writeAsString(jsonEncode({'directory': out.path}));
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await server.close(force: true);
      }
    },
  );
}
