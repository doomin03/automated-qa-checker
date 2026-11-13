import 'desktop_runtime.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/workbench/views/run_panel.dart';
import 'package:automated_qa_desktop/features/run_review/view_models/run_view_model.dart';

void main() {
  testWidgets(
    'public CLI capability picker separates installed web from unverified native',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late String node;
      final root = Directory.current.parent.parent.path;
      await tester.runAsync(() async {
        node = (await Process.run('node', [
          '-p',
          'process.execPath',
        ])).stdout.toString().trim();
      });
      late RunViewModel vm;
      await tester.pumpWidget(
        AppProviders(
          child: Builder(
            builder: (context) {
              vm = context.read<RunViewModel>();
              return MaterialApp(home: Scaffold(body: const RunPanel()));
            },
          ),
        ),
      );
      for (final entry in {
        'engine-node': node,
        'engine-cli':
            '${desktopPackageRoot(root)}/packages/cli/aqa.mjs',
        'engine-report': '$root/artifacts/flutter-capability-ui',
      }.entries) {
        await tester.ensureVisible(find.byKey(Key(entry.key)));
        await tester.enterText(find.byKey(Key(entry.key)), entry.value);
      }
      await tester.ensureVisible(find.text('실행 대상·지원 기능 확인'));
      await tester.tap(find.text('실행 대상·지원 기능 확인'));
      await tester.pumpAndSettle();
      Future<void> inspect() async {
        await tester.ensureVisible(find.byKey(const Key('capability-inspect')));
        await tester.runAsync(() async {
          await tester.tap(find.byKey(const Key('capability-inspect')));
          for (var i = 0; i < 500 && vm.busy; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
          expect(vm.busy, false);
        });
        await tester.pumpAndSettle();
        expect(vm.error, isNull);
      }

      await inspect();
      expect(find.text('chromium-headless'), findsOneWidget);
      expect(vm.capabilities!['platforms'], ['web']);
      expect(vm.events, isEmpty);
      await tester.tap(find.byKey(const Key('capability-platform')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('android').last);
      await tester.pumpAndSettle();
      await inspect();
      expect(vm.capabilities!['targets'], isEmpty);
      expect(vm.capabilities!['diagnostics']['nativeConfigured'], false);
      expect(vm.capabilities!['diagnostics']['connectionVerified'], false);
      expect(find.textContaining('실제 기기 연결 미검증'), findsOneWidget);
      expect(vm.events, isEmpty);
      expect(vm.status, 'not_started');
      await tester.runAsync(() async {
        final file = File(
          '$root/artifacts/flutter-capability-ui/verification.json',
        );
        await file.parent.create(recursive: true);
        await file.writeAsString(
          jsonEncode({
            'actualPublicCli': true,
            'webTarget': 'chromium-headless',
            'nativeConfigured': false,
            'nativeConnectionVerified': false,
            'automaticExecution': false,
          }),
        );
      });
      await tester.pumpWidget(const SizedBox());
    },
  );
}
