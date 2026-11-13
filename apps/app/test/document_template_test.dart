import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/desktop_workspace_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/document_template_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/views/document_template_dialog.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';

import 'engine_bridge_test.dart' show IncompleteService;
import 'terminal_workspace_test.dart' show FileCatalog, FakeDefaults;

class TemplateEngine extends IncompleteService
    implements EngineDocumentAuthoring {
  final definition = <String, dynamic>{
    'id': 'empty',
    'version': '1.0.0',
    'sha256': 'fixture',
    'description': 'fixture',
    'inputSchema': {},
  };
  Completer<Map<String, dynamic>>? pending;
  @override
  Future<Map<String, dynamic>> templates(EngineSettings settings) async => {
    'templates': [definition],
  };
  @override
  Future<Map<String, dynamic>> createTemplate(
    EngineSettings settings,
    String id,
    String version,
    String hash,
    Map<String, dynamic> bindings,
  ) => pending!.future;
  @override
  Future<Map<String, dynamic>> compose(
    EngineSettings settings,
    Map<String, dynamic> input,
  ) async => {};
}

void main() {
  testWidgets(
    'template form locks pending bindings and invalidates changed candidate; failed same-source save stays open',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dir = Directory.systemTemp.createTempSync('qa-template-ui-');
      var rejectSave = false;
      final files = WorkspaceFileService(
        directory: dir,
        beforeCommit: () async {
          if (rejectSave) {
            throw const FileSystemException('fixture save failed');
          }
        },
      );
      final engine = TemplateEngine();
      late DesktopWorkspaceViewModel desktop;
      late DocumentTemplateViewModel vm;
      late BuildContext host;
      await tester.pumpWidget(
        AppProviders(
          engineService: engine,
          blueprintCatalog: FileCatalog(),
          desktopDefaultsService: FakeDefaults(),
          workspaceFileService: files,
          child: Builder(
            builder: (context) {
              desktop = context.read<DesktopWorkspaceViewModel>();
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    host = context;
                    return const Scaffold(body: SizedBox());
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.runAsync(() async {
        await desktop.initialize();
        await desktop.createProject('templates');
        await desktop.createQa('same source');
      });
      final original = desktop.work.source, qa = desktop.workspace.qaId;
      vm = DocumentTemplateViewModel(desktop, engine);
      unawaited(
        showDialog<void>(
          context: host,
          builder: (_) => ChangeNotifierProvider.value(
            value: vm,
            child: const DocumentTemplateDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('empty · 1.0.0').last);
      await tester.pumpAndSettle();
      engine.pending = Completer<Map<String, dynamic>>();
      await tester.tap(find.byKey(const Key('template-generate')));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, '웹 시작 URL'))
            .enabled,
        false,
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, '문서 ID'))
            .enabled,
        false,
      );
      engine.pending!.complete({'xml': original});
      await tester.pumpAndSettle();
      expect(vm.current, true);
      await tester.enterText(
        find.widgetWithText(TextField, '웹 시작 URL'),
        'http://127.0.0.1:9999',
      );
      await tester.pump();
      expect(vm.candidate, isNull);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('template-accept')))
            .onPressed,
        isNull,
      );
      engine.pending = Completer<Map<String, dynamic>>();
      await tester.tap(find.byKey(const Key('template-generate')));
      await tester.pump();
      engine.pending!.complete({'xml': original});
      await tester.pumpAndSettle();
      rejectSave = true;
      await tester.runAsync(() async {
        expect(await vm.accept('must not exist'), false);
      });
      await tester.pump();
      expect(desktop.workspace.qaId, qa);
      expect(desktop.work.source, original);
      expect(vm.error, contains('fixture save failed'));
      expect(find.byType(DocumentTemplateDialog), findsOneWidget);
      Navigator.of(host).pop();
      await tester.pumpAndSettle();
      vm.dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.runAsync(() => dir.delete(recursive: true));
    },
  );
}
