import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/desktop_workspace_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/xml_block_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/desktop_defaults_service.dart';
import 'package:automated_qa_desktop/features/ai_authoring/models/ai_request.dart';
import 'package:automated_qa_desktop/features/ai_authoring/services/ai_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';

import 'engine_bridge_test.dart' show IncompleteService;

class FakeDefaults extends DesktopDefaultsService {
  @override
  Future<Map<String, String>> load() async => {
    'nodePath': 'node',
    'cliPath': 'cli',
    'reportRoot': 'reports',
  };
}

class FakeAuthor implements AiCliService {
  Completer<AiAnswer>? pending;
  Map<String, dynamic>? payload;
  int requests = 0, disposals = 0;
  @override
  Future<String> diagnose(AiSettings settings) async => 'fixture';
  @override
  Future<AiAnswer> generate(
    AiSettings settings,
    Directory sessions,
    String prompt,
    void Function(String) progress,
  ) {
    requests++;
    payload = jsonDecode(prompt) as Map<String, dynamic>;
    return pending!.future;
  }

  @override
  Future<void> cancel() async {}
  @override
  void dispose() {
    disposals++;
  }
}

class WorkspaceEngine extends IncompleteService {
  late Map<String, dynamic> blueprint;
  @override
  Future<PreparedScenario> prepare(
    EngineSettings settings,
    String source,
  ) async {
    if (source == '<invalid />') {
      throw const EngineException('INVALID_DOCUMENT fixture');
    }
    return PreparedScenario(
      settings: settings,
      inputPath: 'fixture',
      reportRoot: settings.reportRoot,
      plan: {
        'blueprint': source.startsWith('{') ? jsonDecode(source) : blueprint,
        'blueprintSnapshotHash': source,
        'nodeOrder': ['start', 'end'],
        'requiredActions': [],
      },
    );
  }

  @override
  Future<String> exportXml(EngineSettings settings, String source) async =>
      '<blueprint />';
  @override
  Stream<EngineUpdate> run(PreparedScenario scenario) async* {
    runs++;
    yield EngineUpdate(
      result: {
        'runId': 'fixture-run',
        'outcome': 'passed',
        'unvisitedNodes': [],
        'artifacts': [],
      },
    );
  }
}

void main() {
  testWidgets(
    'new workspace navigation, prompt dirty, Flow identity, AI stale/apply/undo and result ownership',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('qa-ui-workspace-');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final engine = WorkspaceEngine();
      final ai = FakeAuthor();
      Future<void> waitFor(bool Function() ready) async {
        for (var i = 0; i < 150 && !ready(); i++) {
          await tester.pump(const Duration(milliseconds: 30));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
        }
        expect(ready(), isTrue);
      }

      late DesktopWorkspaceViewModel vm;
      late XmlBlockWorkbenchViewModel blocks;
      await tester.pumpWidget(
        AppProviders(
          engineService: engine,
          aiService: ai,
          workspaceFileService: WorkspaceFileService(directory: dir),
          desktopDefaultsService: FakeDefaults(),
          child: Builder(
            builder: (context) {
              vm = context.read<DesktopWorkspaceViewModel>();
              blocks = context.read<XmlBlockWorkbenchViewModel>();
              return const QaApp();
            },
          ),
        ),
      );
      for (var i = 0; i < 100 && !vm.initialized; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      expect(vm.initialized, isTrue);
      debugPrint('workspace test: initialized');
      await tester.pumpAndSettle();
      expect(find.text('새 프로젝트'), findsOneWidget);
      await tester.tap(find.text('새 프로젝트'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('workspace-dialog-input')),
        'Project',
      );
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pumpAndSettle();
      await waitFor(() => vm.workspace.project != null && !vm.workspace.busy);
      debugPrint('workspace test: project created');
      await tester.runAsync(() => vm.createQa('A'));
      await waitFor(() => !blocks.busy);
      blocks.setEnabled(false);
      await tester.pumpAndSettle();
      debugPrint('workspace test: QA created');
      engine.blueprint = vm.contract!['example'];
      final qaA = vm.workspace.qaId!;
      await vm.validate();
      await tester.pumpAndSettle();
      debugPrint('workspace test: validated');
      vm.work.flow.move('start', 400, 200);
      expect(vm.dirty, isTrue);
      await tester.runAsync(() => vm.save());
      await tester.pumpAndSettle();
      expect(
        vm.work.flow.blueprint,
        isNotNull,
        reason: 'save notify must not clear graph',
      );
      await tester.runAsync(() => vm.createQa('B'));
      await waitFor(() => !blocks.busy);
      blocks.setEnabled(false);
      await tester.pumpAndSettle();
      expect(vm.work.flow.blueprint, isNull);
      vm.work.applyFlow();
      expect(vm.work.source, vm.workspace.qa!.source);
      vm.workspace.editInstructions('shared instructions');
      expect(vm.dirty, isTrue);
      await tester.runAsync(() => vm.save());
      await tester.pumpAndSettle();
      vm.select(vm.workspace.projectId, qaA);
      await waitFor(() => !blocks.busy);
      blocks.setEnabled(false);
      await tester.pumpAndSettle();
      ai.pending = Completer<AiAnswer>();
      vm.ai.editRequest('add screenshot');
      final first = vm.generate();
      await tester.pump();
      await tester.pump();
      final original = vm.work.source;
      vm.work.editor.edit('$original ');
      vm.work.editor.edit(original);
      ai.pending!.complete(
        const AiAnswer('candidate', '<candidate />', 'fixture'),
      );
      await first;
      await tester.pumpAndSettle();
      expect(vm.ai.status, 'stale');
      expect(vm.applyProposal(), isFalse);
      expect(engine.runs, 0);
      for (final scope in AiScope.values) {
        vm.selectNode('start');
        vm.ai.setScope(scope);
        ai.pending = Completer<AiAnswer>();
        final request = vm.generate();
        await tester.pump();
        await tester.pump();
        ai.pending!.complete(
          const AiAnswer('candidate', '<candidate />', 'fixture'),
        );
        await request;
        await tester.pumpAndSettle();
        expect(vm.ai.status, 'review');
        expect(ai.payload!['scope'], scope.name);
        expect(ai.payload!['selectedNodeId'], 'start');
        expect(ai.payload!['originalXml'], isNotEmpty);
        vm.ai.dismiss();
        expect(vm.work.source, original);
        expect(engine.runs, 0);
      }
      ai.pending = Completer<AiAnswer>();
      final invalid = vm.generate();
      await tester.pump();
      await tester.pump();
      ai.pending!.complete(const AiAnswer('invalid', '<invalid />', 'fixture'));
      await invalid;
      expect(vm.ai.status, 'failed');
      expect(vm.ai.proposal, isNull);
      for (final mutate in <void Function()>[
        () => vm.selectNode('end'),
        () => vm.ai.editRequest('changed request'),
        () => vm.workspace.editPrompt('changed persistent prompt'),
      ]) {
        vm.ai.setScope(AiScope.whole);
        vm.selectNode('start');
        ai.pending = Completer<AiAnswer>();
        final stale = vm.generate();
        await tester.pump();
        await tester.pump();
        mutate();
        ai.pending!.complete(
          const AiAnswer('candidate', '<candidate />', 'fixture'),
        );
        await stale;
        expect(vm.ai.status, 'stale');
        expect(vm.applyProposal(), isFalse);
      }
      ai.pending = Completer<AiAnswer>();
      final second = vm.generate();
      await tester.pump();
      await tester.pump();
      ai.pending!.complete(
        const AiAnswer('candidate', '<candidate />', 'fixture'),
      );
      await second;
      await tester.pumpAndSettle();
      expect(vm.ai.status, 'review');
      expect(vm.applyProposal(), isTrue);
      expect(engine.runs, 0);
      vm.work.editor.edit('<later />');
      expect(vm.canUndoAi, isFalse);
      vm.undoAi();
      expect(vm.work.source, '<later />');
      await vm.validate();
      await vm.execute();
      await tester.pumpAndSettle();
      blocks.compiledHash = vm.resultSnapshot;
      blocks.sourceMap = {
        'node': {'instanceId': 'instance_1', 'sourceFile': 'source.xml'},
      };
      blocks.captureRunMap();
      blocks.finishRunMap();
      expect(blocks.currentRunMapping('node')?['sourceFile'], 'source.xml');
      blocks.mappedRunId = 'previous-composition-run';
      expect(
        blocks.currentRunMapping('node'),
        isNull,
        reason: 'a later direct run must not display the earlier composition file or focus button',
      );
      final owner = vm.resultOwner;
      vm.select(
        vm.workspace.projectId,
        vm.workspace.project!.documents.last.id,
      );
      await waitFor(() => !blocks.busy);
      blocks.setEnabled(false);
      await vm.execute();
      expect(
        vm.ai.request,
        isEmpty,
        reason: 'one-off request must not leak across QAs',
      );
      expect(vm.resultOwner, owner);
      expect(engine.runs, 1);
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(ai.disposals, 0, reason: 'borrowed dependency');
    },
  );
}
