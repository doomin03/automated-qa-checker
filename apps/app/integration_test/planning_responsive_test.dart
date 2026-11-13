import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:api_client_dart/platform_client.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/desktop_workspace_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/project_home_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/xml_block_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/project_workspace/models/workspace.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/services/terminal_service.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/terminal_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/ai_authoring/models/ai_request.dart';

class FixturePty extends TerminalService {
  FixturePty(this.node, this.script);
  final String node, script;
  @override
  Future<void> start(String executable, List<String> args, String directory) =>
      super.start(node, [script], directory);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('adaptive project journey, server context and alpha8 local execution', (
    tester,
  ) async {
    const root = String.fromEnvironment('QA_REPO');
    final output = await Directory('$root/artifacts/planning-responsive/native')
        .create(recursive: true);
    final session = await output.createTemp('run-');
    final installation = jsonDecode(
      await File('$root/apps/app/assets/desktop-installation.json')
          .readAsString(),
    );
    final manifest = jsonDecode(
      await File('$root/apps/app/assets/desktop-engine-runtime.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    final engine = LocalEngineCliService(loadManifest: () async => manifest);
    final settings = EngineSettings(
      nodePath: installation['nodePath'],
      cliPath: installation['cliPath'],
      reportRoot: '${session.path}/reports',
    );
    final ptyScript = File('${session.path}/pty-fixture.cjs');
    await ptyScript.writeAsString(r'''
const fs=require('node:fs'),readline=require('node:readline');
console.log('PTY FIXTURE - not an AI model. Type edit.');
readline.createInterface({input:process.stdin}).on('line',line=>{
 if(line.trim()==='edit'){
  const source=fs.readFileSync('scenario.xml','utf8').replaceAll('id="end"','id="end_terminal"').replaceAll('to="end"','to="end_terminal"');
  fs.writeFileSync('scenario.xml',source); console.log('Fixture XML edited.');
 }
});
''');
    final pty = FixturePty(installation['nodePath'], ptyScript.path);
    late TerminalWorkbenchViewModel terminal;
    final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    target.listen((r) async {
      r.response.headers.contentType = ContentType.html;
      r.response.write(
        '<input data-testid="username"><button data-testid="submit" onclick="document.querySelector(\'[data-testid=greeting]\').textContent=\'Welcome \'+document.querySelector(\'input\').value">Go</button><h1 data-testid="greeting"></h1>',
      );
      await r.response.close();
    });
    final contract = jsonDecode(
      await File('$root/apps/app/assets/desktop-engine-contract.json')
          .readAsString(),
    );
    final blueprint = contract['example'] as Map<String, dynamic>,
        url = 'http://127.0.0.1:${target.port}';
    blueprint['target']['allowedOrigins'] = [url];
    for (final key in (blueprint['target']['launchTargets'] as Map).keys) {
      blueprint['target']['launchTargets'][key] = url;
    }
    final xml = await engine.exportXml(settings, jsonEncode(blueprint));
    final workspace = WorkspaceFileService(
      directory: Directory('${session.path}/workspace'),
    );
    final p1 = '1' * 32, p2 = '2' * 32, p3 = '3' * 32;
    await workspace.write(
      Workspace(
        projects: [
          QaProject(
            id: p1,
            name: '사용자 웹',
            documents: [
              QaDocument(
                id: 'a' * 32,
                name: '가입 및 로그인 흐름',
                source: xml,
                updatedAt: '2026-11-11T03:20:00Z',
              ),
              QaDocument(
                id: 'b' * 32,
                name: '검색 결과와 상세 화면',
                source: xml,
                updatedAt: '2026-11-10T08:30:00Z',
              ),
            ],
          ),
          QaProject(
            id: p2,
            name: 'Windows 사용자 앱과 여러 테스트 환경을 함께 확인하는 프로젝트',
            documents: [
              QaDocument(id: 'c' * 32, name: '파일 가져오기와 실행 결과 확인', source: xml),
            ],
          ),
          QaProject(id: p3, name: '릴리즈 점검'),
        ],
      ),
    );
    final tokens = {
      for (final id in ['author', 'reviewer', 'tester', 'viewer'])
        id: '$id-${DateTime.now().microsecondsSinceEpoch}-home-local-fixture',
    };
    final identities = {
      'users': [
        for (final id in tokens.keys)
          {'id': id, 'token': tokens[id], 'active': true},
      ],
      'projects': [
        {'id': 'demo', 'name': '공용 웹 품질 점검'},
        {'id': 'empty', 'name': '게시 준비 중인 프로젝트'},
      ],
      'memberships': [
        for (final id in tokens.keys)
          for (final project in ['demo', 'empty'])
            {
              'userId': id,
              'projectId': project,
              'role': id == 'viewer'
                  ? 'viewer'
                  : id == 'tester'
                  ? 'qa_tester'
                  : 'qa_manager',
            },
      ],
    };
    Process? server;
    final evidence = <String, dynamic>{
      'session': session.path,
      'serverEngine': '0.1.0-alpha.6',
      'desktopEngine': manifest['engineVersion'],
      'screenshots': [],
      'nativeViewports': [],
    };
    late DesktopWorkspaceViewModel desktop;
    late ProjectHomeViewModel home;
    late XmlBlockWorkbenchViewModel blocks;
    final boundary = GlobalKey();
    Future<void> resize(Size logicalSize) async {
      final ratio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
      final resized = await Process.run('powershell.exe', [
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
        '${(logicalSize.width * ratio).round()}',
        '-ClientHeight',
        '${(logicalSize.height * ratio).round()}',
      ], runInShell: false);
      expect(resized.exitCode, 0, reason: '${resized.stderr}');
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final actual = MediaQuery.of(
          tester.element(find.byType(Scaffold).first),
        ).size;
        if ((actual.width - logicalSize.width).abs() < 1 &&
            (actual.height - logicalSize.height).abs() < 1) {
          break;
        }
      }
      final media = MediaQuery.of(tester.element(find.byType(Scaffold).first));
      expect(media.size.width, closeTo(logicalSize.width, 1));
      expect(media.size.height, closeTo(logicalSize.height, 1));
      (evidence['nativeViewports'] as List).add({
        'requestedLogical': [logicalSize.width, logicalSize.height],
        'mediaQuerySize': [media.size.width, media.size.height],
        'textScale14': media.textScaler.scale(14) / 14,
        'devicePixelRatio': media.devicePixelRatio,
        'window': jsonDecode(resized.stdout as String),
      });
    }

    Future<void> wait(bool Function() ready) async {
      final end = DateTime.now().add(const Duration(seconds: 100));
      while (!ready() && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        ready(),
        true,
        reason: '${home.error} / ${desktop.error} / ${desktop.work.run.error}',
      );
      await tester.pump(const Duration(milliseconds: 200));
    }

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final media = MediaQuery.of(tester.element(find.byType(Scaffold).first));
      await File('${session.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      (evidence['screenshots'] as List).add({
        'file': '$name.png',
        'width': image.width,
        'height': image.height,
        'mediaQuerySize': [media.size.width, media.size.height],
        'textScale14': media.textScaler.scale(14) / 14,
        'devicePixelRatio': media.devicePixelRatio,
      });
      image.dispose();
    }

    Widget app() => AppProviders(
      engineService: engine,
      terminalService: pty,
      workspaceFileService: workspace,
      child: Builder(
        builder: (context) {
          desktop = context.read<DesktopWorkspaceViewModel>();
          home = context.read<ProjectHomeViewModel>();
          blocks = context.read<XmlBlockWorkbenchViewModel>();
          terminal = context.read<TerminalWorkbenchViewModel>();
          return RepaintBoundary(key: boundary, child: const QaApp());
        },
      ),
    );
    try {
      await tester.pumpWidget(app());
      await wait(() => desktop.initialized);
      await resize(const Size(1440, 900));
      desktop.work.settings.update(settings);
      await tester.pumpAndSettle();
      await shot('01-projects-1440');
      await tester.tap(find.byKey(Key('home-project-$p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('home-qa-${'a' * 32}')));
      await tester.pumpAndSettle();
      await shot('02-project-qa');
      server = await Process.start(
        installation['nodePath'],
        [
          '--input-type=module',
          '-e',
          "import {bootstrap} from '${Uri.file('$root/apps/server/dist/src/main.js')}'; await bootstrap();",
        ],
        workingDirectory: root,
        runInShell: false,
        environment: {
          'NODE_ENV': 'test',
          'HOST': '127.0.0.1',
          'PORT': '0',
          'QA_AUTH_MODE': 'test',
          'QA_DATA_DIR': '${session.path}/server',
          'QA_ENGINE_CLI':
              '$root/.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs',
          'QA_ENGINE_MANIFEST': '$root/apps/app/assets/engine-runtime.json',
          'QA_LOCAL_IDENTITIES_JSON': jsonEncode(identities),
        },
      );
      final ready = Completer<String>();
      final serverLog = File('${session.path}/server.log').openWrite();
      serverLog.writeln(
        'Explicit existing bootstrap; PID ${server.pid}; server alpha.6 manifest; node ${installation['nodePath']}',
      );
      server.stderr.transform(utf8.decoder).listen(serverLog.write);
      server.exitCode.then((code) {
        serverLog.writeln('exit $code');
        if (!ready.isCompleted) {
          ready.completeError(
            StateError('Server exited $code; see server.log'),
          );
        }
      });
      server.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            serverLog.writeln(line);
            if (line.startsWith('{"event":"listening"') && !ready.isCompleted) {
              ready.complete(jsonDecode(line)['url']);
            }
          });
      final origin = await ready.future.timeout(const Duration(seconds: 45));
      await serverLog.flush();
      final author = PlatformClient(origin, tokens['author']!),
          reviewer = PlatformClient(origin, tokens['reviewer']!);
      late VersionResponse version;
      try {
        for (final package in [
          'login-smoke',
          'account-settings',
          'checkout-critical',
        ]) {
          final draft = await author.createDraft(
            'demo',
            DraftInput(
              packageId: package,
              title: '공용 QA $package',
              xml: xml,
              dependencies: [],
            ),
          );
          await reviewer.reviewDraft('demo', draft.id);
          final published = await author.publishDraft(
            'demo',
            draft.id,
            '1.0.0',
            'home-$package',
          );
          if (package == 'login-smoke') version = published;
        }
        final draft = await author.createSuiteDraft(
          'demo',
          SuiteDraftInput(
            packageId: 'release-readiness',
            title: '릴리즈 기본 점검',
            stopOnFailure: true,
            cases: [
              SuiteCase(
                caseId: 'login',
                versionId: version.id,
                sha256: version.sha256,
              ),
            ],
          ),
        );
        await reviewer.reviewSuiteDraft('demo', draft.id);
        await author.publishSuiteDraft('demo', draft.id, '1.0.0', 'home-suite');
      } finally {
        author.close();
        reviewer.close();
      }
      home.navigate('available');
      await tester.pump();
      await home.discover(origin, token: tokens['tester']!);
      await home.connectProject('demo');
      await tester.pumpAndSettle();
      expect(home.shared.connected, true);
      expect(home.shared.versions.length, 3);
      expect(home.shared.projectContext?.engine.engineVersion, '0.1.0-alpha.6');
      expect(home.shared.canPublish, false);
      evidence['serverContext'] = home.shared.projectContext!.toJson();
      await tester.tap(find.byKey(Key('home-version-${version.id}')));
      await wait(() => !home.busy && home.shared.preview != null);
      await shot('03-receive-1440');
      await resize(const Size(1024, 768));
      await tester.pumpAndSettle();
      await shot('04-receive-1024');
      await resize(const Size(800, 600));
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('compact-detail')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('home-receive')));
      await shot('04b-receive-detail-800-text150');
      await tester.tap(find.text('목록'));
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await resize(const Size(1024, 768));
      await tester.tap(find.text('릴리즈 기본 점검').first);
      await wait(() => !home.busy && home.shared.selectedSuite != null);
      await tester.tap(find.text('Suite 버전 고정').first);
      await wait(() => !home.busy && home.shared.suitePinned);
      await home.shared.loadSuitePins();
      expect(home.shared.suitePins.length, 1);
      await home.shared.openSuitePin(home.shared.suitePins.single);
      await tester.tap(find.text('QA login').first);
      await wait(() => !home.busy && home.shared.preview != null);
      await tester.tap(find.byKey(const Key('home-receive')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('home-receive-name')),
        '서버에서 받은 로그인 점검',
      );
      await tester.tap(find.byKey(const Key('home-receive-confirm')));
      await wait(
        () =>
            desktop.workspace.qa?.name == '서버에서 받은 로그인 점검' &&
            !blocks.busy &&
            !home.busy,
      );
      final qaId = desktop.workspace.qaId!;
      expect(blocks.enabled, false);
      expect(desktop.work.source, xml);
      expect(desktop.work.run.plan, isNull);
      expect(home.receipt(p1, qaId)!.versionId, version.id);
      expect(home.receipt(p1, qaId)!.suite?['packageId'], 'release-readiness');
      await shot('05-received-editor');
      await desktop.validate();
      expect(desktop.work.run.error, isNull);
      expect(
        home.shared.repository.versionFor(desktop.work.run.plan!),
        version.id,
      );
      await desktop.execute();
      await wait(() => !desktop.work.run.busy);
      expect(desktop.work.run.result!['outcome'], 'passed');
      expect(home.shared.autoPublish, false);
      home.shared.enablePublishing(true);
      expect(home.shared.autoPublish, false);
      expect(home.shared.publishStatus, contains('호환'));
      expect(desktop.work.run.result!['outcome'], 'passed');
      evidence['result'] = desktop.work.run.result;
      evidence['reportDirectory'] = desktop.work.run.reportDirectory;
      evidence['versionId'] = version.id;
      evidence['qaId'] = qaId;
      await desktop.save();
      await tester.pumpAndSettle();
      desktop.work.editor.edit('$xml\n');
      await tester.pump();
      await tester.tap(find.text('홈').first);
      await tester.pumpAndSettle();
      expect(find.text('저장하지 않은 문서 또는 프롬프트'), findsOneWidget);
      await tester.tap(find.text('취소').last);
      await tester.pumpAndSettle();
      expect(desktop.workspace.qaId, qaId);
      await tester.tap(find.text('홈').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('변경 버리기').last);
      await tester.pumpAndSettle();
      expect(desktop.workspace.qaId, isNull);
      home.navigate('received');
      home.chooseLocalQa(qaId);
      await tester.pumpAndSettle();
      await shot('06-received-copies-1024');
      await resize(const Size(1440, 900));
      await tester.pumpAndSettle();
      await shot('07-received-copies-1440');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await wait(() => desktop.initialized);
      await home.refreshReceipts();
      desktop.select(p1, qaId);
      await wait(() => !blocks.busy);
      expect(blocks.enabled, false);
      expect(desktop.work.source, xml);
      expect(home.receipt(p1, qaId)!.versionId, version.id);
      final saved = jsonDecode(await workspace.file.readAsString());
      expect(saved['version'], 1);
      expect(
        (saved['projects'][0]['documents'].last as Map).containsKey('receipt'),
        false,
      );
      expect(tester.takeException(), isNull);
      await resize(const Size(800, 600));
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('XML 원문'));
      await tester.tap(find.text('XML 원문'));
      await tester.pumpAndSettle();
      await shot('08-editor-800-text150');
      final source = tester.widget<TextField>(
        find.byKey(const Key('workspace-source')),
      );
      source.controller!.selection = const TextSelection(
        baseOffset: 8,
        extentOffset: 24,
      );
      await tester.tap(find.byKey(const Key('workspace-source')));
      source.controller!.selection = const TextSelection(
        baseOffset: 8,
        extentOffset: 24,
      );
      await resize(const Size(1440, 900));
      await tester.pumpAndSettle();
      expect(
        identical(
          source.controller,
          tester
              .widget<TextField>(find.byKey(const Key('workspace-source')))
              .controller,
        ),
        true,
      );
      expect(source.controller!.selection.extentOffset, 24);
      desktop.ai.configure(AiSettings(executable: installation['nodePath']));
      await resize(const Size(800, 600));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('terminal-start')).first);
      await wait(() => pty.state == 'running');
      final pid = pty.pid;
      terminal.input('edit\r');
      await wait(
        () =>
            desktop.work.source.contains('end_terminal') &&
            desktop.work.flow.nodes.any((n) => n['id'] == 'end_terminal'),
      );
      await shot('09-pty-fixture-800-text150');
      await tester.tap(find.text('작업실로'));
      await tester.pumpAndSettle();
      expect(pty.pid, pid);
      await resize(const Size(1440, 900));
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.pumpAndSettle();
      await tester.tap(find.text('직접 문서 / Flow'));
      await tester.pumpAndSettle();
      await shot('10-file-update-flow-1440');
      expect(pty.pid, pid);
      await terminal.close();
      await wait(() => !pty.active);
      expect(pty.cleanupUnknown, false);
      evidence['terminalFixture'] = {
        'pid': pid,
        'node': 'end_terminal',
        'closed': true,
        'realAiModel': false,
        'scope': 'actual native PTY fixture edit; app polling + public alpha8 plan + GUI',
      };
      final libraryFile = File('${session.path}/responsive-login.xml');
      await libraryFile.writeAsString(xml);
      expect(await blocks.importFile(libraryFile.path), true);
      blocks.setEnabled(true);
      await tester.pumpAndSettle();
      await tester.tap(find.text('responsive-login.xml').first);
      await tester.pumpAndSettle();
      expect(blocks.instances.length, 1);
      await resize(const Size(800, 600));
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('studio-properties')));
      await tester.pumpAndSettle();
      await shot('11-file-block-properties-800-text150');
      await tester.tap(find.text('닫기').last);
      await tester.pumpAndSettle();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await resize(const Size(1440, 900));
      await tester.tap(find.byKey(const Key('workspace-validate')));
      await wait(
        () => !blocks.busy && !desktop.work.run.busy && desktop.work.canUsePlan,
      );
      final priorRun = desktop.work.run.result?['runId'];
      await tester.tap(find.byKey(const Key('workspace-run')));
      await wait(
        () =>
            !desktop.work.run.busy &&
            desktop.work.run.result != null &&
            desktop.work.run.result!['runId'] != priorRun,
      );
      expect(desktop.work.run.result!['outcome'], 'passed');
      expect(desktop.work.run.images, isNotEmpty);
      await shot('12-file-block-result-1440');
      evidence['fileBlockResult'] = desktop.work.run.result;
      evidence['fileBlockReportDirectory'] = desktop.work.run.reportDirectory;
      evidence['status'] = 'passed';
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      engine.dispose();
      pty.dispose();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      server?.kill();
      await target.close(force: true);
      await File('${session.path}/verification.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(evidence));
    }
    expect(tester.takeException(), isNull);
    await File('${output.path}/latest.json').writeAsString(
      jsonEncode({'session': session.path, 'status': evidence['status']}),
    );
  }, timeout: const Timeout(Duration(minutes: 9)));
}
