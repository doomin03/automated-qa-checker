import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/desktop_workspace_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/terminal_workbench_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/xml_block_workbench_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/views/terminal_dock.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/models/terminal_profile.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'multi_terminal_test.dart' show RecordingTerminal;
import 'terminal_workspace_test.dart'
    show DelayedCompiler, GatedDocuments, FileCatalog, FakeDefaults;

class EnvironmentDocuments extends GatedDocuments {
  EnvironmentDocuments(super.compiler);
  Completer<void>? gate, finished;
  @override
  Future<String> describeEnvironment(Directory session) async {
    await gate?.future;
    try {
      return await super.describeEnvironment(session);
    } finally {
      if (finished?.isCompleted == false) finished!.complete();
    }
  }
}

void main() {
  testWidgets(
    'guide dialog copies exact instruction, routes unsubmitted input and fences late epochs',
    (tester) async {
      final folder = Directory.systemTemp.createTempSync('qa-guide-dialog-');
      final engine = DelayedCompiler();
      final documents = EnvironmentDocuments(DelayedCompiler());
      final services = <RecordingTerminal>[];
      late DesktopWorkspaceViewModel desktop;
      late TerminalWorkbenchViewModel pool;
      late XmlBlockWorkbenchViewModel blocks;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      try {
        await tester.pumpWidget(
          AppProviders(
            engineService: engine,
            liveDocuments: documents,
            blueprintCatalog: FileCatalog(),
            workspaceFileService: WorkspaceFileService(directory: folder),
            desktopDefaultsService: FakeDefaults(),
            terminalServiceFactory: () {
              final service = RecordingTerminal();
              services.add(service);
              return service;
            },
            child: Builder(
              builder: (context) {
                desktop = context.read<DesktopWorkspaceViewModel>();
                pool = context.read<TerminalWorkbenchViewModel>();
                blocks = context.read<XmlBlockWorkbenchViewModel>();
                return const MaterialApp(
                  home: Scaffold(
                    body: Column(
                      children: [
                        Expanded(child: Text('Guide UI fixture')),
                        TerminalDock(maxHeight: 360),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.runAsync(() async {
          await desktop.initialize();
          await desktop.createProject('Guide');
          await desktop.createQa('QA');
          while (blocks.busy) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          blocks.setEnabled(false);
          (documents.compiler as DelayedCompiler).blueprint =
              engine.blueprint = jsonDecode(desktop.work.source);
          for (final provider in ['codex', 'claude']) {
            await pool.add(
              TerminalProfile(
                provider,
                'Fixture $provider',
                Platform.resolvedExecutable,
                readiness: 'available',
              ),
              writer: provider == 'codex',
            );
          }
        });
        await tester.pumpAndSettle();
        await tester.tap(find.text('터미널 열기'));
        await tester.pumpAndSettle();
        final a = pool.sessions[0], b = pool.sessions[1];
        final source = desktop.work.source;
        pool.select(a.id);
        await tester.pumpAndSettle();

        Future<void> openEnvironment() async {
          await tester.runAsync(() async {
            documents.finished = Completer<void>();
            await tester.tap(find.text('작성 환경'));
            await documents.finished!.future.timeout(const Duration(seconds: 5));
            await Future<void>.delayed(const Duration(milliseconds: 20));
          });
          await tester.pumpAndSettle();
        }

        await openEnvironment();
        expect(find.textContaining('별도 확인 필요'), findsOneWidget);
        await tester.tap(find.text('호출 안내 복사'));
        await tester.pumpAndSettle();
        expect(copied, [a.skillInvocation]);
        expect(copied.single, isNot(contains('\n')));
        expect(copied.single, isNot(contains('\r')));
        expect(services.every((s) => s.inputs.isEmpty), true);
        // Selecting B while A's dialog is open must not redirect A's instruction.
        pool.select(b.id);
        await tester.pumpAndSettle();
        await tester.tap(find.text('입력에 넣기 · 미제출'));
        await tester.pumpAndSettle();
        expect(services[0].inputs, [a.skillInvocation]);
        expect(services[1].inputs, isEmpty);
        expect(services[0].inputs.single, isNot(contains('\r')));

        // A valid open dialog becomes stale if its writer epoch changes.
        pool.select(a.id);
        await tester.pumpAndSettle();
        await openEnvironment();
        pool.revokeWriter();
        await tester.pumpAndSettle();
        await tester.tap(find.text('입력에 넣기 · 미제출'));
        await tester.pumpAndSettle();
        expect(services[0].inputs, [a.skillInvocation]);
        expect(services[1].inputs, isEmpty);

        // An epoch change while guide IO is pending invalidates the inspection.
        await tester.runAsync(() async {
          documents.gate = Completer<void>();
          documents.finished = Completer<void>();
          await tester.tap(find.text('작성 환경'));
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        final beforeEpoch = a.inputEpoch;
        expect(pool.grantWriter(a.id), true);
        expect(a.inputEpoch, greaterThan(beforeEpoch));
        await tester.runAsync(() async {
          documents.gate!.complete();
          await documents.finished!.future.timeout(const Duration(seconds: 5));
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        await tester.pumpAndSettle();
        expect(find.textContaining('작성 환경 확인 실패'), findsOneWidget);
        final input = tester.widget<TextButton>(
          find.widgetWithText(TextButton, '입력에 넣기 · 미제출'),
        );
        expect(input.onPressed, isNull);
        expect(services[0].inputs, [a.skillInvocation]);
        expect(services[1].inputs, isEmpty);
        expect(engine.runs, 0);
        expect(desktop.work.source, source);
        await tester.tap(find.text('닫기'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      } finally {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
        await tester.runAsync(pool.closeAll);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        engine.dispose();
        documents.dispose();
        await tester.runAsync(() => folder.delete(recursive: true));
      }
    },
  );
}
