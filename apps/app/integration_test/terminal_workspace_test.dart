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
import 'package:automated_qa_desktop/app/workbench/view_models/terminal_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';

void main(){
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Windows Blueprint and actual interactive Codex first frame',(tester)async{
    const root=String.fromEnvironment('QA_REPO');
    final parent=await Directory('$root/artifacts/windows-terminal').create(recursive:true);
    final output=await parent.createTemp('run-');
    late DesktopWorkspaceViewModel desktop;
    late TerminalWorkbenchViewModel terminal;
    final boundary=GlobalKey();
    Future<void> until(bool Function() predicate)async{final end=DateTime.now().add(const Duration(seconds:90));while(!predicate()&&DateTime.now().isBefore(end)){await tester.pump(const Duration(milliseconds:100));}expect(predicate(),true,reason:terminal.error);}
    Future<void> capture(String name)async{await tester.pump(const Duration(milliseconds:500));final image=await(boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();final bytes=await image.toByteData(format:ui.ImageByteFormat.png);await File('${output.path}/$name.png').writeAsBytes(bytes!.buffer.asUint8List());image.dispose();}
    try {
      await tester.pumpWidget(AppProviders(workspaceFileService:WorkspaceFileService(directory:Directory('${output.path}/workspace')),child:Builder(builder:(context){desktop=context.read<DesktopWorkspaceViewModel>();terminal=context.read<TerminalWorkbenchViewModel>();return RepaintBoundary(key:boundary,child:const QaApp());})));
      tester.view.physicalSize=const Size(1440,900);tester.view.devicePixelRatio=1;
      addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
      await until(()=>desktop.initialized);
      await desktop.createProject('QA Blueprint'); await desktop.createQa('로그인 시나리오');
      await until(()=>desktop.work.flow.blueprint!=null);
      await capture('01-blueprint');
      await tester.tap(find.byKey(const Key('blueprint-node-name')));
      await tester.pump(const Duration(milliseconds:500));
      await tester.tap(find.byKey(const Key('terminal-start')));
      await until(()=>terminal.service.state=='running'||terminal.error!=null);
      expect(terminal.service.state,'running',reason:terminal.error);
      await tester.pump(const Duration(seconds:5));
      if(terminal.terminal.buffer.getText().contains('Skip')){terminal.input('\x1b');await tester.pump(const Duration(seconds:3));}
      await capture('02-interactive-codex');
      await File('${output.path}/session.txt').writeAsString(terminal.session!.path);
      await terminal.close();
      expect(terminal.service.cleanupUnknown,false);
    } finally {await terminal.close();await tester.pumpWidget(const SizedBox.shrink());}
  },timeout:const Timeout(Duration(minutes:4)));
}
