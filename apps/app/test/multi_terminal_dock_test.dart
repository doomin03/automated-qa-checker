import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xterm2/xterm.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/desktop_workspace_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/terminal_workbench_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/xml_block_workbench_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/views/terminal_dock.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/models/terminal_profile.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'terminal_workspace_test.dart' show DelayedCompiler,GatedDocuments,FileCatalog,FakeDefaults;
import 'multi_terminal_test.dart' show RecordingTerminal;

void main() {
  testWidgets('two dock controllers, pending paste, resize and bounded modal retain sessions', (tester) async {
    final folder=Directory.systemTemp.createTempSync('qa-docks-');
    final engine=DelayedCompiler(), documents=GatedDocuments(DelayedCompiler());
    final services=<RecordingTerminal>[];
    late DesktopWorkspaceViewModel desktop;
    late TerminalWorkbenchViewModel pool;
    late XmlBlockWorkbenchViewModel blocks;
    tester.view.devicePixelRatio=1;
    tester.view.physicalSize=const Size(1440,900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(AppProviders(engineService:engine,liveDocuments:documents,blueprintCatalog:FileCatalog(),
      workspaceFileService:WorkspaceFileService(directory:folder),desktopDefaultsService:FakeDefaults(),
      terminalServiceFactory:(){final value=RecordingTerminal();services.add(value);return value;},
      child:Builder(builder:(context){
        desktop=context.read<DesktopWorkspaceViewModel>();pool=context.read<TerminalWorkbenchViewModel>();blocks=context.read<XmlBlockWorkbenchViewModel>();
        return const MaterialApp(home:Scaffold(body:Column(children:[Expanded(child:Center(child:Text('Editor preserved'))),TerminalDock(maxHeight:360)])));
      })));
    await tester.runAsync(()async{
      await desktop.initialize();await desktop.createProject('Dock');await desktop.createQa('A');
      while(blocks.busy){await Future<void>.delayed(const Duration(milliseconds:10));}
      blocks.setEnabled(false);
      (documents.compiler as DelayedCompiler).blueprint=engine.blueprint=jsonDecode(desktop.work.source);
      final profile=TerminalProfile('cmd','명령 프롬프트',Platform.resolvedExecutable,readiness:'available');
      await pool.add(profile,writer:true);await pool.add(profile);
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('터미널 열기'));await tester.pumpAndSettle();
    final a=pool.sessions[0],b=pool.sessions[1];
    pool.select(a.id);pool.toggleSplit();await tester.pumpAndSettle();
    expect(find.byType(TerminalView),findsNWidgets(2));
    final av=tester.widget<TerminalView>(find.byKey(ValueKey('interactive-terminal-${a.id}')));
    final bv=tester.widget<TerminalView>(find.byKey(ValueKey('interactive-terminal-${b.id}')));
    expect(av.controller,isNot(same(bv.controller)));
    expect(av.scrollController,isNot(same(bv.scrollController)));
    a.terminal.write(List.generate(80,(i)=>'A line $i\r\n').join());
    await tester.pumpAndSettle();
    av.scrollController!.jumpTo(0);await tester.pump();
    final offset=av.scrollController!.offset;
    final clipboard=Completer<Object?>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,(call)async{
      if(call.method=='Clipboard.getData')return clipboard.future;
      return null;
    });
    final pasted=av.onPaste!();
    pool.select(b.id);await tester.pump();
    clipboard.complete({'text':'한글 pending paste'});await pasted;
    expect(services[0].inputs,['한글 pending paste']);expect(services[1].inputs,isEmpty);
    debugPrint('scroll after paste ${av.scrollController!.offset}');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,null);
    final before=tester.getSize(find.byKey(ValueKey('pane-${b.id}'))).height;
    final resizeFocus=Focus.of(tester.element(find.byKey(const Key('terminal-resize'))));
    resizeFocus.requestFocus();await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);await tester.pump();
    expect(tester.getSize(find.byKey(ValueKey('pane-${b.id}'))).height,greaterThan(before));
    for(final shape in [(const Size(1024,768),1.25),(const Size(800,600),1.5),(const Size(1280,500),1.0)]){
      tester.view.physicalSize=shape.$1;tester.platformDispatcher.textScaleFactorTestValue=shape.$2;
      await tester.pumpAndSettle();
      debugPrint('scroll at ${shape.$1}: ${av.scrollController!.hasClients ? av.scrollController!.offset : 'detached'}');
      if(shape.$1.height<700){
        await tester.tap(find.text('터미널 열기').first);await tester.pumpAndSettle();
        expect(find.byType(TerminalView),findsNWidgets(shape.$1.width >= 1000 ? 2 : 1));
        final visible=tester.widget<TerminalView>(find.byKey(ValueKey('interactive-terminal-${b.id}')));
        expect(visible.controller,same(bv.controller));
        await tester.tap(find.text('작업실로'));await tester.pumpAndSettle();
        debugPrint('scroll after panel ${av.scrollController!.hasClients ? av.scrollController!.offset : 'detached'}');
      }
      expect(tester.takeException(),isNull);
      expect(services.every((s)=>s.alive),true);
    }
    tester.view.physicalSize=const Size(1440,900);tester.platformDispatcher.textScaleFactorTestValue=1;
    await tester.pumpAndSettle();
    await tester.tap(find.text('터미널 열기').first);await tester.pumpAndSettle();
    final again=tester.widget<TerminalView>(find.byKey(ValueKey('interactive-terminal-${a.id}')));
    expect(again.controller,same(av.controller));expect(again.scrollController,same(av.scrollController));
    expect(again.scrollController!.offset,offset);
    // The compact icon toolbar must still operate the selected real session.
    expect(find.byTooltip('새 세션'), findsOneWidget);
    expect(find.byTooltip('선택 종료'), findsOneWidget);
    await tester.tap(find.byTooltip('세션 메뉴'));await tester.pumpAndSettle();
    await tester.tap(find.text('Ctrl+C'));await tester.pumpAndSettle();
    expect(services[1].inputs, contains('\x03'));
    expect(services[0].inputs, isNot(contains('\x03')));
    await tester.tap(find.byKey(const Key('terminal-toggle')));await tester.pumpAndSettle();
    expect(find.byType(TerminalView), findsNothing);
    expect(services.every((s)=>s.alive), true);
    await tester.tap(find.byKey(const Key('terminal-toggle')));await tester.pumpAndSettle();
    expect(tester.widget<TerminalView>(find.byKey(ValueKey('interactive-terminal-${b.id}'))).controller, same(bv.controller));
    await tester.runAsync(pool.closeAll);
    await tester.pumpWidget(const SizedBox());await tester.pump();
    engine.dispose();documents.dispose();await tester.runAsync(()=>folder.delete(recursive:true));
  });
}
