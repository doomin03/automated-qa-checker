import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/desktop_workspace_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/terminal_workbench_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/xml_block_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/models/terminal_profile.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/services/terminal_profile_service.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/repositories/live_document_repository.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'terminal_workspace_test.dart' show IdleTerminal, DelayedCompiler, GatedDocuments, FileCatalog, FakeDefaults;
import 'dart_runtime.dart';

class RecordingTerminal extends IdleTerminal {
  final inputs = <String>[];
  Completer<void>? closeGate;
  int closes = 0;
  @override
  void write(String text) => inputs.add(text);
  @override
  Future<void> close() async { closes++; await closeGate?.future; await super.close(); }
}

class CountedCompiler extends DelayedCompiler {
  int calls = 0;
  @override
  Future<PreparedScenario> prepare(EngineSettings settings, String source) {
    calls++;
    return super.prepare(settings, source);
  }
}

void main() {
  testWidgets('independent copies, live writer ABA, QA ownership, cleanup and close joins', (tester) async {
    final directory = Directory.systemTemp.createTempSync('qa-multiple-');
    final engine = DelayedCompiler(), docs = GatedDocuments(DelayedCompiler());
    final compiler = docs.compiler as DelayedCompiler;
    final services = <RecordingTerminal>[];
    late DesktopWorkspaceViewModel desktop;
    late TerminalWorkbenchViewModel pool;
    late XmlBlockWorkbenchViewModel blocks;
    await tester.pumpWidget(AppProviders(
      engineService: engine, blueprintCatalog: FileCatalog(), liveDocuments: docs,
      terminalServiceFactory: () { final s = RecordingTerminal(); services.add(s); return s; },
      workspaceFileService: WorkspaceFileService(directory: directory), desktopDefaultsService: FakeDefaults(),
      child: Builder(builder: (context) {
        desktop = context.read<DesktopWorkspaceViewModel>(); pool = context.read<TerminalWorkbenchViewModel>();
        blocks = context.read<XmlBlockWorkbenchViewModel>();
        return const MaterialApp(home: SizedBox());
      }),
    ));
    await tester.runAsync(() async {
      await desktop.initialize();
      await desktop.createProject('다중 작성'); await desktop.createQa('QA A');
      while (blocks.busy) { await Future<void>.delayed(const Duration(milliseconds: 10)); }
      blocks.setEnabled(false);
      compiler.blueprint = engine.blueprint = jsonDecode(desktop.work.source);
      final profile = TerminalProfile('cmd', 'cmd', Platform.resolvedExecutable, readiness: 'available');
      await pool.add(profile, writer: true);
      final a = pool.selected;
      await pool.add(profile);
      final b = pool.selected;
      expect(a.service, isNot(same(b.service))); expect(a.session!.path, isNot(b.session!.path));
      expect(pool.writerFor(pool.identity), a.id);
      services[0].onOutput?.call('A-output'); services[1].onOutput?.call('B-output');
      expect(a.terminal.buffer.getText(), contains('A-output'));
      expect(a.terminal.buffer.getText(), isNot(contains('B-output')));
      a.input('one'); b.input('two');
      expect(services[0].inputs, ['one']); expect(services[1].inputs, ['two']);
      final original = desktop.work.source;
      final changed = jsonEncode({...jsonDecode(original) as Map<String, dynamic>, 'name': 'late A'});
      await File('${a.session!.path}/scenario.json').writeAsString(changed);
      blocks.setEnabled(true);
      await a.refresh(force: true);
      expect(a.state, 'composition_review'); expect(desktop.work.source, original);
      await a.acceptFile('json'); await a.saveGui(); a.undo();
      expect(desktop.work.source, original);
      expect((await File('${a.session!.path}/scenario.json').readAsString()), changed);
      blocks.setEnabled(false);
      compiler.gate = Completer<void>();
      final pending = a.refresh(); await Future<void>.delayed(const Duration(milliseconds: 230));
      expect(pool.grantWriter(b.id), true); expect(services[0].alive, true);
      expect(pool.grantWriter(a.id), true);
      compiler.gate!.complete(); await pending; compiler.gate = null;
      await Future<void>.delayed(const Duration(milliseconds: 220));
      expect(desktop.work.source, original);
      await a.refresh(force: true);
      expect(a.state, 'conflict');
      await a.acceptFile('json'); expect(desktop.work.source, changed);
      expect(a.canUndo, true);
      final project = desktop.workspace.projectId!, qa = desktop.workspace.qaId!;
      await desktop.createQa('QA B');
      final qaB = desktop.work.source;
      a.undo(); await a.refresh(force: true);
      expect(desktop.work.source, qaB); expect(a.canUndo, false);
      expect(a.qaIdentity, '$project/$qa');
      desktop.select(project, qa);
      expect(pool.selected.id, b.id); // Selection and writer are independent.
      services[0].closeGate = Completer<void>();
      final close1 = a.close(); final close2 = a.close();
      expect(identical(close1, close2), true);
      expect(pool.grantWriter(b.id), false);
      var allClosed = false;
      final closing = pool.closeAll().then((_) => allClosed = true);
      await Future<void>.delayed(const Duration(milliseconds: 30)); expect(allClosed, false);
      services[0].closeGate!.complete(); await closing;
      expect(services[0].closes, 1);
      services[0].cleanupUnknown = true; services[0].onState?.call('cleanup_unknown');
      expect(pool.grantWriter(b.id), false);
      await File('${a.session!.path}/scenario.json').writeAsString(original);
      final beforeUnknown = desktop.work.source; await a.refresh(force: true);
      expect(desktop.work.source, beforeUnknown);
      expect(desktop.runBlockReasons, contains('terminal'));
      expect(File('${a.session!.path}/.agents/skills/qa-authoring/SKILL.md').existsSync(), false);
      expect(engine.runs, 0);
      // Retained closed entries count toward the bounded pool; explicit removal
      // releases the slot and never resurrects a preview runtime.
      for (var i=0;i<6;i++) {await pool.add(profile);}
      expect(pool.sessions,hasLength(8));expect(pool.canStart,false);
      await pool.add(profile);expect(pool.sessions,hasLength(8));
      await pool.remove(b.id);expect(pool.sessions.any((s)=>s.id==b.id),false);
      await pool.add(profile);expect(pool.sessions,hasLength(8));
    });
    await tester.pumpWidget(const SizedBox()); await tester.pump();
    docs.dispose(); engine.dispose();
    await tester.runAsync(() async { await directory.delete(recursive: true); });
  });

  test('provider probes separate executable readiness from authentication', () async {
    final service = TerminalProfileService();
    final missing = await service.inspect('claude', executable: 'C:/not-installed/claude.exe');
    expect(missing.readiness, 'missing');
    for (final id in ['powershell', 'cmd']) {
      final result = await service.inspect(id);
      expect(result.available, true, reason: '$id ${result.detail}');
      expect(result.ai, false);
    }
    final codex = await service.inspect('codex');
    if (codex.executable.isNotEmpty) expect(codex.available, true, reason: codex.detail);
  }, skip: !Platform.isWindows);

  testWidgets('preview coalesces edits and composition ABA rejects old candidates', (tester) async {
    final directory = Directory.systemTemp.createTempSync('qa-preview-');
    final engine = CountedCompiler(), docs = LiveDocumentRepository(CountedCompiler());
    final compiler = docs.compiler as CountedCompiler;
    late DesktopWorkspaceViewModel desktop;
    late TerminalWorkbenchViewModel pool;
    late XmlBlockWorkbenchViewModel blocks;
    await tester.pumpWidget(AppProviders(engineService: engine, blueprintCatalog: FileCatalog(),
      liveDocuments: docs, workspaceFileService: WorkspaceFileService(directory: directory), desktopDefaultsService: FakeDefaults(),
      child: Builder(builder: (context) {
        desktop = context.read<DesktopWorkspaceViewModel>(); pool = context.read<TerminalWorkbenchViewModel>();
        blocks = context.read<XmlBlockWorkbenchViewModel>();
        return const MaterialApp(home: SizedBox());
      })));
    await tester.runAsync(() async {
      await desktop.initialize(); await desktop.createProject('Preview'); await desktop.createQa('A');
      while (blocks.busy) { await Future<void>.delayed(const Duration(milliseconds: 10)); }
      blocks.setEnabled(false);
      final preview = pool.selected, original = desktop.work.source;
      compiler.blueprint = engine.blueprint = jsonDecode(original);
      compiler.gate = Completer<void>();
      final first = preview.previewCurrent();
      for (var i=0; i<20; i++) {
        desktop.work.editor.edit(jsonEncode({...jsonDecode(original) as Map<String,dynamic>, 'name':'revision-$i'}));
        await preview.previewCurrent();
      }
      expect(compiler.calls, 1);
      final gate = compiler.gate!; compiler.gate = null; gate.complete(); await first;
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(compiler.calls, 2);
      expect(desktop.work.flow.blueprint!['name'], 'revision-19');
      // A candidate started in direct mode cannot survive a mode ABA.
      compiler.gate = Completer<void>();
      desktop.work.editor.edit(jsonEncode({...jsonDecode(original) as Map<String,dynamic>, 'name':'stale mode'}));
      final before = desktop.work.flow.source;
      final candidate = preview.previewCurrent();
      blocks.setEnabled(true); blocks.setEnabled(false);
      final staleGate = compiler.gate!; compiler.gate = null; staleGate.complete(); await candidate;
      expect(desktop.work.flow.source, before);
      expect(engine.runs, 0);
    });
    await tester.pumpWidget(const SizedBox()); await tester.pump();
    docs.dispose(); engine.dispose();
    await tester.runAsync(() => directory.delete(recursive: true));
  });

  test('provider guides are isolated, hashed and never claim CLI discovery', () async {
    final root = await Directory.systemTemp.createTemp('qa-guides-');
    final engine = DelayedCompiler(), docs = LiveDocumentRepository(DelayedCompiler());
    final contract = await FileCatalog().load();
    try {
      for (final provider in ['codex','claude','powershell']) {
        final session = await docs.createSession(root.path,'p',provider,jsonEncode(contract['example']),'project instruction');
        await docs.writeAuxiliary(session,'engine-contract.json',jsonEncode(contract));
        await docs.prepareEnvironment(session,provider,contract);
        final manifest = jsonDecode(await File('${session.path}/authoring-environment.json').readAsString());
        expect(manifest['providerDiscoveryVerified'],false);
        expect(manifest['guidePrepared'],provider!='powershell');
        if (provider!='powershell') {
          final path='${session.path}/${provider=='codex'?'.agents':'.claude'}/skills/qa-authoring/SKILL.md';
          expect(await File(path).exists(),true);
          expect(manifest['guideSha256'],matches(RegExp(r'^[a-f0-9]{64}$')));
          final bytes=await File(path).readAsBytes();
          await expectLater(docs.prepareEnvironment(session,provider,contract),throwsFormatException);
          expect(await File(path).readAsBytes(),bytes);
        }
      }
    } finally { docs.dispose();engine.dispose();await root.delete(recursive:true); }
  });

  test('provider probe drains help tail, bounds output and terminates timed-out process', () async {
    final folder=await Directory.systemTemp.createTemp('qa-profile-');
    final dart=testDartExecutable();
    try {
      for(final mode in ['help','overflow','legacy-code-page','hang']) {
        Process? child;
        final service=TerminalProfileService(probeTimeout:const Duration(seconds:2),spawn:(exe,args)async{
          child=await Process.start(dart,['test/fixtures/terminal_profile_fixture.dart',mode,'${folder.path}/pid.txt']);
          return child!;
        });
        final result=await service.inspect(mode=='help'?'codex':'cmd',executable:dart);
        expect(result.available,mode=='help'||mode=='legacy-code-page',reason:result.detail);
        expect(child,isNotNull);
        await child!.exitCode.timeout(const Duration(seconds:2));
      }
    } finally {await folder.delete(recursive:true);}
  });
}
