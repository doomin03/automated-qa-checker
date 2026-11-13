import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/workbench/views/blueprint_workspace.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/desktop_workspace_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/terminal_workbench_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/xml_block_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/repositories/live_document_repository.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/services/terminal_service.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/ai_authoring/models/ai_request.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/canvas_layout_view_model.dart';
import 'package:automated_qa_desktop/features/scenario_editor/repositories/canvas_layout_repository.dart';

import 'engine_bridge_test.dart' show IncompleteService;

import 'package:automated_qa_desktop/features/scenario_editor/repositories/blueprint_catalog.dart';

import 'package:automated_qa_desktop/features/project_workspace/services/desktop_defaults_service.dart';

class FileCatalog extends BlueprintCatalog {
  @override
  Future<Map<String, dynamic>> load() async => jsonDecode(
    File('assets/desktop-engine-contract.json').readAsStringSync(),
  );
}

class FakeDefaults extends DesktopDefaultsService {
  @override
  Future<Map<String, String>> load() async => {
    'nodePath': 'node',
    'cliPath': 'cli',
    'reportRoot': 'reports',
  };
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
      result: {'outcome': 'passed', 'unvisitedNodes': [], 'artifacts': []},
    );
  }
}

class IdleTerminal extends TerminalService {
  bool alive = false;
  @override
  bool get active => alive;
  @override
  Future<void> start(String exe, List<String> args, String cwd) async {
    alive = true;
    state = 'running';
    onState?.call(state);
  }

  @override
  Future<void> close() async {
    alive = false;
    state = 'closed';
    onState?.call(state);
  }
}

class DelayedCompiler extends WorkspaceEngine {
  Completer<void>? gate;
  @override
  Future<PreparedScenario> prepare(
    EngineSettings settings,
    String source,
  ) async {
    await gate?.future;
    return super.prepare(settings, source);
  }
}

class GatedDocuments extends LiveDocumentRepository {
  GatedDocuments(super.compiler);
  Completer<void>? copyGate, readGate;
  int reads = 0, blockRead = -1;
  @override
  Future<LiveDocument?> read(Directory session, String format) async {
    final value = await super.read(session, format);
    if (++reads == blockRead) await readGate?.future;
    return value;
  }

  @override
  Future<void> preserveCopy(Directory session, String source) async {
    await super.preserveCopy(session, source);
    await copyGate?.future;
  }
}

class GatedLayout extends CanvasLayoutRepository {
  Completer<Map<String, dynamic>>? gate;
  Map<String, dynamic>? saved;
  @override
  Future<Map<String, dynamic>> read(String root, String identity) async =>
      await gate?.future ?? {};
  @override
  Future<void> write(
    String root,
    String identity,
    Map<String, dynamic> positions,
  ) async {
    saved = jsonDecode(jsonEncode(positions));
  }
}

void main() {
  testWidgets(
    'terminal files auto-apply, invalid preserve, conflicts, stale revisions and QA boundaries',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync('qa-live-');
      final engine = DelayedCompiler(), service = IdleTerminal();
      final repository = GatedDocuments(engine);
      late DesktopWorkspaceViewModel desktop;
      late TerminalWorkbenchViewModel terminal;
      late XmlBlockWorkbenchViewModel blocks;
      await tester.pumpWidget(
        AppProviders(
          engineService: engine,
          blueprintCatalog: FileCatalog(),
          liveDocuments: repository,
          terminalService: service,
          workspaceFileService: WorkspaceFileService(directory: directory),
          desktopDefaultsService: FakeDefaults(),
          child: Builder(
            builder: (context) {
              desktop = context.read<DesktopWorkspaceViewModel>();
              terminal = context.read<TerminalWorkbenchViewModel>();
              blocks = context.read<XmlBlockWorkbenchViewModel>();
              return const MaterialApp(home: SizedBox());
            },
          ),
        ),
      );
      unawaited(desktop.initialize());
      for (var i = 0; i < 150 && !desktop.initialized; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      expect(desktop.initialized, true);
      await tester.runAsync(() async {
        await desktop.createProject('A');
        await desktop.createQa('QA-A');
        while (blocks.busy) { await Future<void>.delayed(const Duration(milliseconds: 10)); }
        blocks.setEnabled(false);
        engine.blueprint = jsonDecode(desktop.work.source);
        desktop.ai.configure(
          AiSettings(executable: Platform.resolvedExecutable),
        );
        await terminal.start();
        expect(terminal.state, 'synced');
        final file = File('${terminal.session!.path}/scenario.json');
        final first = jsonDecode(desktop.work.source) as Map<String, dynamic>;
        first['name'] = '외부수정';
        await file.writeAsString(jsonEncode(first));
        await terminal.refresh();
        expect(jsonDecode(desktop.work.source)['name'], '외부수정');
        expect(engine.runs, 0);
        final valid = desktop.work.flow.source;
        await file.writeAsString('{partial');
        await terminal.refresh();
        expect(terminal.state, 'invalid');
        expect(desktop.work.flow.source, valid);
        expect(desktop.externalRunBlocked, true);
        await file.writeAsString(jsonEncode({...first, 'name': 'restored'}));
        await terminal.refresh();
        expect(terminal.state, 'synced');
        desktop.work.editor.edit(jsonEncode({...first, 'name': 'GUI'}));
        await file.writeAsString(jsonEncode({...first, 'name': 'FILE'}));
        await terminal.refresh();
        expect(terminal.state, 'conflict');
        expect(jsonDecode(desktop.work.source)['name'], 'GUI');
        await terminal.acceptFile('json');
        expect(jsonDecode(desktop.work.source)['name'], 'FILE');
        expect(
          terminal.session!.listSync().whereType<Directory>().any(
            (d) => d.path.contains('gui-copy'),
          ),
          true,
        );
        desktop.work.editor.edit(jsonEncode({...first, 'name': 'after'}));
        terminal.undo();
        expect(jsonDecode(desktop.work.source)['name'], 'after');
        await terminal.saveGui();
        expect(terminal.state, 'synced');
        final gate = Completer<void>();
        engine.gate = gate;
        await file.writeAsString(jsonEncode({...first, 'name': 'slow'}));
        final pending = terminal.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        final before = desktop.work.source;
        desktop.work.editor.edit('$before ');
        desktop.work.editor.edit(before);
        gate.complete();
        await pending;
        engine.gate = null;
        expect(terminal.state, 'stale');
        expect(desktop.work.source, before);
        // A final file read is asynchronous: edits during it invalidate the plan.
        await terminal.acceptFile('json');
        repository.reads = 0;
        repository.blockRead = 4;
        repository.readGate = Completer<void>();
        await file.writeAsString(jsonEncode({...first, 'name': 'final-read'}));
        final finalRead = terminal.refresh();
        while (repository.reads < 4) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        final stable = desktop.work.source;
        desktop.work.editor.edit('$stable ');
        repository.readGate!.complete();
        await finalRead;
        expect(desktop.work.source, '$stable ');
        expect(terminal.state, 'stale');
        repository.blockRead = -1;
        await terminal.acceptFile('json');
        // Flow-only edits also invalidate an outstanding compile, without source edits.
        engine.gate = Completer<void>();
        await file.writeAsString(jsonEncode({...first, 'name': 'flow-race'}));
        final flowRead = terminal.refresh();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        desktop.work.flow.addNode('action');
        final flowDraft = desktop.work.flow.source;
        engine.gate!.complete();
        await flowRead;
        engine.gate = null;
        expect(desktop.work.flow.source, flowDraft);
        // The live watcher may already recheck the rejected candidate and report
        // its remaining GUI conflict. Neither state may replace the Flow draft.
        expect(terminal.state, isIn(['stale', 'conflict']));
        await terminal.acceptFile('json');
        desktop.work.editor.edit(jsonEncode({...first, 'name': 'GUI-1'}));
        repository.copyGate = Completer<void>();
        final accepting = terminal.acceptFile('json');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final gui2 = jsonEncode({...first, 'name': 'GUI-2'});
        desktop.work.editor.edit(gui2);
        repository.copyGate!.complete();
        await accepting;
        repository.copyGate = null;
        expect(desktop.work.source, gui2);
        final layouts = GatedLayout(),
            layout = CanvasLayoutViewModel(desktop, GatedLayout());
        layout.dispose();
        final ownedLayout = CanvasLayoutViewModel(desktop, layouts);
        layouts.gate = Completer<Map<String, dynamic>>();
        await desktop.createQa('layout-race');
        ownedLayout.move('a', const Offset(44, 55));
        expect(ownedLayout.canUndo, false);
        expect(layouts.saved, isNull);
        layouts.gate!.complete({
          'a': {'x': 1, 'y': 2},
          'b': {'x': 300, 'y': 400},
        });
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(ownedLayout.positions['a']['x'], 44);
        expect(layouts.saved!['b']['x'], 300);
        ownedLayout.undo();
        expect(ownedLayout.positions['b']['x'], 300);
        ownedLayout.dispose();
        // Bypassing the UI navigation prompt must still never apply A's folder to B.
        await desktop.createQa('QA-B');
        final bSource = desktop.work.source;
        await terminal.refresh(force: true);
        expect(desktop.work.source, bSource);
        await terminal.close();
        await terminal.detach();
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      service.dispose();
      repository.dispose();
      directory.deleteSync(recursive: true);
    },
  );
  test(
    'session format, size, replacement and write-root checks preserve bytes',
    () async {
      final root = await Directory.systemTemp.createTemp('qa-session-');
      final repo = LiveDocumentRepository(WorkspaceEngine());
      try {
        final session = await repo.createSession(
          root.path,
          'p',
          'q',
          '<blueprint/>',
          'context',
        );
        await File('${session.path}/scenario.xml').writeAsString('{}');
        await expectLater(repo.read(session, 'xml'), throwsFormatException);
        await File('${session.path}/scenario.xml')
            .writeAsString('x' * (1024 * 1024 + 1));
        await expectLater(repo.read(session, 'xml'), throwsFormatException);
        await File('${session.path}/scenario.xml')
            .writeAsString('<blueprint/>');
        final original = await repo.read(session, 'xml');
        await expectLater(
          repo.replace(session, 'xml', '<changed/>', 'stale'),
          throwsFormatException,
        );
        expect((await repo.read(session, 'xml'))!.hash, original!.hash);
        final moved = await session.rename('${session.path}-moved');
        await expectLater(
          repo.writeContext(session, 'private'),
          throwsA(anything),
        );
        await expectLater(repo.preserveCopy(session, '{}'), throwsA(anything));
        expect(
          await File('${moved.path}/QA-CONTEXT.md').readAsString(),
          'context',
        );
      } finally {
        repo.dispose();
        await root.delete(recursive: true);
      }
    },
  );
  testWidgets('Blueprint zoom drag uses local coordinates and pin directions', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync('qa-blueprint-');
    final engine = WorkspaceEngine();
    late DesktopWorkspaceViewModel desktop;
    late CanvasLayoutViewModel layout;
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AppProviders(
        engineService: engine,
        desktopDefaultsService: FakeDefaults(),
        workspaceFileService: WorkspaceFileService(directory: root),
        child: Builder(
          builder: (context) {
            desktop = context.read<DesktopWorkspaceViewModel>();
            layout = context.read<CanvasLayoutViewModel>();
            return const MaterialApp(
              home: Scaffold(body: BlueprintWorkspace()),
            );
          },
        ),
      ),
    );
    await tester.runAsync(() async {
      await desktop.workspace.initialize();
      desktop.contract = jsonDecode(
        await File('assets/desktop-engine-contract.json').readAsString(),
      );
      await desktop.createProject('Canvas');
      await desktop.createQa('Graph');
      engine.blueprint = jsonDecode(desktop.work.source);
      desktop.work.flow.load(engine.blueprint);
    });
    await tester.pump();
    await tester.pump();
    final viewer = tester.widget<InteractiveViewer>(
      find.byKey(const Key('blueprint-viewport')),
    );
    viewer.transformationController!.value = Matrix4.identity()
      ..scaleByDouble(.5, .5, 1, 1);
    await tester.pump();
    final before = layout.position(desktop.work.flow.blueprint!, 'name', 2);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('blueprint-node-name'))),
    );
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    final after = layout.position(desktop.work.flow.blueprint!, 'name', 2);
    expect(after.dx - before.dx, closeTo(40, .1));
    expect(after.dy, before.dy);
    expect(find.byKey(const Key('pin-in-start')), findsNothing);
    final original = jsonEncode(desktop.work.flow.blueprint);
    desktop.work.flow.connect('end', 'start', '');
    expect(jsonEncode(desktop.work.flow.blueprint), original);
    for (
      var i = 0;
      i < 100 && !desktop.work.flow.nodeTypes.contains('branch');
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    expect(desktop.work.flow.nodeTypes, contains('branch'));
    desktop.work.flow.addNode('branch');
    await tester.pump();
    final branch = desktop.work.flow.nodes.last['id'];
    expect(find.byKey(Key('pin-out-$branch-true')), findsOneWidget);
    expect(find.byKey(Key('pin-out-$branch-false')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    root.deleteSync(recursive: true);
  });
}
