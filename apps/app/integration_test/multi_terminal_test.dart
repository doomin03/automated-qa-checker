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
import 'package:automated_qa_desktop/app/workbench/view_models/document_template_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/terminal_workbench_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/xml_block_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('two real native shells, writer file update and adaptive dock', (
    tester,
  ) async {
    const root = String.fromEnvironment('QA_REPO');
    final folder = await Directory('$root/artifacts/multi-terminal/native')
        .create(recursive: true);
    final out = await folder.createTemp('run-');
    final ws = WorkspaceFileService(
      directory: Directory('${out.path}/workspace'),
    );
    final boundary = GlobalKey();
    late DesktopWorkspaceViewModel desktop;
    late TerminalWorkbenchViewModel pool;
    late XmlBlockWorkbenchViewModel blocks;
    late DocumentTemplateViewModel templates;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var targetFails = false;
    server.listen((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<input data-testid="username"><button data-testid="submit" onclick="document.querySelector(\'[data-testid=greeting]\').textContent=\'${targetFails ? 'Mismatch' : 'Welcome '}\'+document.querySelector(\'input\').value">Go</button><h1 data-testid="greeting"></h1>',
      );
      await request.response.close();
    });
    final evidence = <String, dynamic>{
      'kind': 'actual PowerShell/cmd PTY, not an AI model',
      'screenshots': [],
      'viewports': [],
    };
    Future<void> wait(bool Function() ready) async {
      final end = DateTime.now().add(const Duration(seconds: 60));
      while (!ready() && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(ready(), true, reason: '${pool.error} / ${desktop.error}');
      await tester.pump(const Duration(milliseconds: 200));
    }

    Future<void> resize(Size size) async {
      final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
      final r = await Process.run('powershell.exe', [
        '-NoProfile',
        '-WindowStyle',
        'Hidden',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        '$root/apps/app/integration_test/fixtures/resize-owned-window.ps1',
        '-TargetProcessId',
        '$pid',
        '-ExpectedExecutable',
        Platform.resolvedExecutable,
        '-ClientWidth',
        '${(size.width * dpr).round()}',
        '-ClientHeight',
        '${(size.height * dpr).round()}',
      ]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      await wait(
        () =>
            (MediaQuery.sizeOf(tester.element(find.byType(Scaffold).first))
                        .width -
                    size.width)
                .abs() <
            1,
      );
      final media = MediaQuery.of(tester.element(find.byType(Scaffold).first));
      expect(media.size.height, closeTo(size.height, 1));
      (evidence['viewports'] as List).add({
        'size': [media.size.width, media.size.height],
        'dpr': media.devicePixelRatio,
        'window': jsonDecode(r.stdout as String),
      });
    }

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${out.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      (evidence['screenshots'] as List).add({
        'file': '$name.png',
        'width': image.width,
        'height': image.height,
      });
      image.dispose();
    }

    Future<void> add(String label, {bool writer = false}) async {
      final count = pool.sessions.length;
      await tester.tap(find.byKey(const Key('terminal-add')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      if (writer) {
        await tester.tap(find.widgetWithText(CheckboxListTile, '이 QA의 자동 반영 작성자로 시작'));
        await tester.pump();
      }
      await tester.tap(find.text('준비 확인'));
      await wait(
        () => find.text('실행 파일 확인됨').evaluate().isNotEmpty,
      );
      await tester.tap(find.byKey(const Key('terminal-start')));
      await wait(
        () =>
            pool.sessions.length == count + 1 &&
            pool.selected.service.state == 'running',
      );
    }

    try {
      await tester.pumpWidget(
        AppProviders(
          workspaceFileService: ws,
          child: Builder(
            builder: (context) {
              desktop = context.read<DesktopWorkspaceViewModel>();
              pool = context.read<TerminalWorkbenchViewModel>();
              blocks = context.read<XmlBlockWorkbenchViewModel>();
              templates = context.read<DocumentTemplateViewModel>();
              return RepaintBoundary(key: boundary, child: const QaApp());
            },
          ),
        ),
      );
      await wait(() => desktop.initialized);
      await resize(const Size(1440, 900));
      await desktop.createProject('터미널 작업실');
      await desktop.createQa('문서 A');
      final original = jsonDecode(desktop.work.source) as Map<String, dynamic>;
      original['name'] = 'Terminal fixture';
      desktop.work.editor.edit(jsonEncode(original));
      await desktop.save();
      await tester.pumpAndSettle();
      await tester.tap(find.text('직접 문서 / Flow'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('직접 문서 편집'));
      await tester.pumpAndSettle();
      await add('PowerShell', writer: true);
      final a = pool.selected, aPid = pool.service.pid;
      a.input("[IO.File]::WriteAllText('shell-ready.txt', ('A_'+'READY'))\r");
      await wait(() => File('${a.session!.path}/shell-ready.txt').existsSync());
      expect(
        await File('${a.session!.path}/shell-ready.txt').readAsString(),
        'A_READY',
      );
      await add('명령 프롬프트');
      final b = pool.selected, bPid = pool.service.pid;
      b.input('echo B_READY>shell-ready.txt\r');
      await wait(() => File('${b.session!.path}/shell-ready.txt').existsSync());
      expect(
        (await File(
          '${b.session!.path}/shell-ready.txt',
        ).readAsString()).trim(),
        'B_READY',
      );
      expect(aPid, isNot(bPid));
      expect(a.session!.path, isNot(b.session!.path));
      await tester.tap(find.text('분할'));
      await tester.pumpAndSettle();
      final paneKey = ValueKey('pane-${b.id}');
      final oldHeight = tester.getSize(find.byKey(paneKey)).height;
      await tester.drag(
        find.byKey(const Key('terminal-resize')),
        const Offset(0, 40),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(paneKey)).height, lessThan(oldHeight));
      final preferredHeight = tester.getSize(find.byKey(paneKey)).height;
      await tester.tap(find.text('확대').first);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(paneKey)).height,
        greaterThan(preferredHeight),
      );
      await tester.tap(find.text('작업실로'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('터미널 열기').first);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(paneKey)).height, preferredHeight);
      await shot('01-split-1440');
      a.input(
        "[IO.File]::WriteAllText('scenario.json', ([IO.File]::ReadAllText('scenario.json').Replace('Terminal fixture','PTY edit')))\r",
      );
      await wait(() => desktop.work.source.contains('PTY edit'));
      expect(a.state, 'synced');
      b.input('echo PENDING_INPUT');
      pool.select(a.id);
      await tester.pumpAndSettle();
      pool.select(b.id);
      await tester.pumpAndSettle();
      expect(b.terminal.buffer.getText(), contains('PENDING_INPUT'));
      b.input('\r');
      await resize(const Size(1024, 768));
      await shot('02-dock-1024');
      await tester.tap(find.text('터미널 접기').first);
      await tester.pumpAndSettle();
      expect(a.service.pid, aPid);
      expect(b.service.pid, bPid);
      await tester.tap(find.text('터미널 열기').first);
      await tester.pumpAndSettle();
      await resize(const Size(800, 600));
      await tester.tap(find.text('터미널 열기').first);
      await tester.pumpAndSettle();
      await shot('03-dialog-800');
      await tester.tap(find.text('작업실로'));
      await tester.pumpAndSettle();
      await resize(const Size(1440, 900));
      final p = desktop.workspace.projectId!, q = desktop.workspace.qaId!;
      await desktop.save();
      await desktop.createQa('문서 B');
      await tester.pumpAndSettle();
      expect(a.qaIdentity, '$p/$q');
      expect(a.service.pid, aPid);
      expect(b.service.pid, bPid);
      desktop.select(p, q);
      await tester.pumpAndSettle();
      await b.close();
      expect(a.service.state, 'running');
      a.input("Write-Output 'STILL_ALIVE'\r");
      await wait(() => a.terminal.buffer.getText().contains('STILL_ALIVE'));
      await shot('04-one-closed');
      evidence.addAll({
        'aPid': aPid,
        'bPid': bPid,
        'aDirectory': a.session!.path,
        'bDirectory': b.session!.path,
        'fileApplied': desktop.work.source.contains('PTY edit'),
      });
      await pool.closeAll();
      expect(pool.sessions.every((s) => !s.service.cleanupUnknown), true);
      evidence['cleanupConfirmed'] = true;
      // Start the installed Codex TUI; no trust, auth, configuration or model request.
      await add('Codex');
      final codex = pool.selected;
      await wait(
        () =>
            codex.terminal.buffer.getText().contains('Codex') ||
            codex.terminal.buffer.getText().contains('codex'),
      );
      await shot('05-codex-start');
      evidence['codex'] = {
        'started': true,
        'pid': codex.service.pid,
        'directory': codex.session!.path,
        'guide': await File('${codex.session!.path}/authoring-environment.json')
            .readAsString(),
        'modelEdit': false,
        'skillDiscoveryVerified': false,
      };
      await codex.close();
      if (find.text('터미널 접기').evaluate().isNotEmpty) {
        await tester.tap(find.text('터미널 접기').first);
        await tester.pumpAndSettle();
      }
      // Public template UI: generation/preview never runs QA.
      await desktop.save();
      await tester.tap(find.byTooltip('파일'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('템플릿으로 새 QA'));
      await tester.pumpAndSettle();
      await wait(
        () =>
            find.text('기술 템플릿').evaluate().isNotEmpty &&
            !find.text('생성·검증 중').evaluate().isNotEmpty,
      );
      await wait(() => templates.catalog.isNotEmpty && !templates.busy);
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('web-input-check · 1.0.0').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, '웹 시작 URL'),
        'http://127.0.0.1:${server.port}',
      );
      await tester.tap(find.byKey(const Key('template-generate')));
      await wait(
        () => find.text('검증된 생성 XML · 아직 저장하지 않음').evaluate().isNotEmpty,
      );
      await shot('06-template-preview');
      await tester.tap(find.byKey(const Key('template-accept')));
      await tester.pumpAndSettle();
      await wait(() => !blocks.busy && !blocks.enabled);
      expect(desktop.work.source, contains('new-qa'));
      await tester.tap(find.byKey(const Key('workspace-validate')));
      await wait(() => desktop.work.canUsePlan);
      await tester.tap(find.byKey(const Key('workspace-run')));
      await wait(
        () =>
            desktop.work.run.result?['outcome'] == 'passed' &&
            !desktop.work.run.running,
      );
      evidence['templatePass'] = desktop.work.run.reportDirectory;
      // Actual repeated file-block composition, namespace map, PASS/FAIL/cancel.
      final blueprint = jsonDecode(
        jsonEncode(desktop.contract!['example']),
      ) as Map<String, dynamic>;
      blueprint['target']['launchTargets']['login'] =
          'http://127.0.0.1:${server.port}';
      blueprint['target']['allowedOrigins'] = [
        'http://127.0.0.1:${server.port}',
      ];
      final cli = LocalEngineCliService();
      final xml = await cli.exportXml(
        desktop.work.settings.execution,
        jsonEncode(blueprint),
      );
      cli.dispose();
      final xmlFile = File('${out.path}/login.xml');
      await xmlFile.writeAsString(xml);
      await desktop.createQa('공개 합성 실행');
      await wait(() => !blocks.busy);
      expect(await blocks.importFile(xmlFile.path), true);
      blocks.add(blocks.assets.first.id);
      final first = blocks.instances.first.id;
      blocks.add(blocks.assets.first.id);
      final second = blocks.instances.last.id;
      blocks.connect(first, second);
      expect(await blocks.compile(), true, reason: blocks.error);
      expect(blocks.sourceMap.values.map((m) => m['instanceId']).toSet(), {
        first,
        second,
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workspace-validate')));
      await wait(() => desktop.work.canUsePlan);
      await tester.tap(find.byKey(const Key('workspace-run')));
      await wait(
        () =>
            desktop.work.run.result?['outcome'] == 'passed' &&
            !desktop.work.run.running,
      );
      evidence['compositionPass'] = desktop.work.run.reportDirectory;
      evidence['sourceMap'] = blocks.sourceMap;
      await shot('07-composition-pass');
      targetFails = true;
      await tester.tap(find.byKey(const Key('workspace-run')));
      await wait(
        () =>
            desktop.work.run.result?['outcome'] == 'failed' &&
            !desktop.work.run.running,
      );
      evidence['compositionFail'] = desktop.work.run.reportDirectory;
      await shot('08-composition-fail');
      await tester.tap(find.byKey(const Key('workspace-run')));
      await wait(
        () =>
            desktop.work.run.running &&
            desktop.work.run.events.any(
              (event) =>
                  event['type'] == 'step.started' &&
                  blocks.sourceMap[event['nodeId']]?['sourceNodeId'] == 'home',
            ),
      );
      await desktop.work.cancel();
      await wait(
        () => !desktop.work.run.running && desktop.work.run.result != null,
      );
      expect(desktop.work.run.result!['outcome'], 'cancelled');
      evidence['compositionCancel'] = desktop.work.run.reportDirectory;
      evidence['runtime'] = desktop.contract!['engineVersion'];
      await File('${out.path}/verification.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(evidence));
      await File('$root/artifacts/multi-terminal/native-latest.json')
          .writeAsString(jsonEncode({'directory': out.path}));
    } finally {
      await pool.closeAll();
      await server.close(force: true);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });
}
