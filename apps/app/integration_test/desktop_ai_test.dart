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
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Windows project QA real Codex proposal explicit apply and actual Engine results',
    (tester) async {
      const root = String.fromEnvironment('QA_REPO');
      if (root.isEmpty) throw StateError('QA_REPO is required');
      final output = await Directory('$root/artifacts/windows-desktop-ai')
          .create(recursive: true);
      final session = await output.createTemp('run-');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.headers.contentType = ContentType.html;
        request.response.write(
          '<input data-testid="username"><button data-testid="submit" onclick="document.querySelector(\'[data-testid=greeting]\').textContent=\'Welcome \'+document.querySelector(\'input\').value">Go</button><h1 data-testid="greeting"></h1>',
        );
        await request.response.close();
      });
      final origin = 'http://127.0.0.1:${server.port}';
      final receipt = jsonDecode(
        await File('$root/apps/app/assets/desktop-installation.json')
            .readAsString(),
      );
      final manifest = jsonDecode(
        await File('$root/apps/app/assets/desktop-engine-runtime.json')
            .readAsString(),
      ) as Map<String, dynamic>;
      final contract = jsonDecode(
        await File('$root/apps/app/assets/desktop-engine-contract.json')
            .readAsString(),
      );
      final blueprint = contract['example'] as Map<String, dynamic>;
      blueprint['target']['allowedOrigins'] = [origin];
      for (final key in (blueprint['target']['launchTargets'] as Map).keys) {
        blueprint['target']['launchTargets'][key] = origin;
      }
      final service = LocalEngineCliService(loadManifest: () async => manifest);
      final settings = EngineSettings(
        nodePath: receipt['nodePath'],
        cliPath: receipt['cliPath'],
        reportRoot: '${session.path}/reports',
      );
      final xml = await service.exportXml(settings, jsonEncode(blueprint));
      final input = File('${session.path}/input.xml');
      await input.writeAsString(xml);
      late DesktopWorkspaceViewModel vm;
      final evidence = <String, dynamic>{
        'session': session.path,
        'engineVersion': manifest['engineVersion'],
        'archiveSha256': manifest['sha256'],
        'actualAi': true,
        'uiPath': 'project->QA->import->prompt->generate->preview->apply->validate->run->PNG',
      };
      final boundaryKey = GlobalKey();
      Future<void> pumpUntil(bool Function() ready, {int seconds = 180}) async {
        final limit = DateTime.now().add(Duration(seconds: seconds));
        while (!ready() && DateTime.now().isBefore(limit)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          ready(),
          isTrue,
          reason:
              'UI deadline: AI ${vm.ai.status} ${vm.ai.error}; QA ${vm.work.run.status} ${vm.work.run.error}; storage ${vm.workspace.error}',
        );
        await tester.pump(const Duration(milliseconds: 200));
      }

      Future<void> capture(String name) async {
        await tester.pump(const Duration(milliseconds: 300));
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${session.path}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }

      Future<void> dialogInput(String text) async {
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('workspace-dialog-input')),
          text,
        );
        await tester.tap(find.text('확인'));
        await tester.pump(const Duration(milliseconds: 400));
      }

      try {
        await tester.pumpWidget(
          AppProviders(
            engineService: service,
            workspaceFileService: WorkspaceFileService(
              directory: Directory('${session.path}/workspace'),
            ),
            child: Builder(
              builder: (context) {
                vm = context.read<DesktopWorkspaceViewModel>();
                return RepaintBoundary(key: boundaryKey, child: const QaApp());
              },
            ),
          ),
        );
        await pumpUntil(() => vm.initialized);
        // Assert actual install receipt initializes fields; only reports are test-isolated.
        expect(vm.work.settings.value.nodePath, settings.nodePath);
        expect(vm.work.settings.value.cliPath, settings.cliPath);
        vm.work.settings.update(settings);
        await capture('01-projects');
        await tester.tap(find.text('프로젝트 만들기'));
        await dialogInput('내일 테스트');
        await pumpUntil(
          () => !vm.workspace.busy && vm.workspace.project != null,
        );
        await tester.tap(find.text('QA 만들기'));
        await dialogInput('로컬 로그인');
        await pumpUntil(() => !vm.workspace.busy && vm.workspace.qa != null);
        await tester.tap(find.text('가져오기'));
        await dialogInput(input.path);
        await pumpUntil(() => !vm.work.editor.isBusy && vm.work.source == xml);
        await tester.tap(find.text('프로젝트 지침 · QA 요청'));
        await tester.pumpAndSettle();
        final instruction = find.widgetWithText(TextField, '프로젝트 공통 지침');
        await tester.enterText(instruction, '원본 대상과 기존 동작을 보존하고 QA 정의만 작성합니다.');
        await tester.enterText(
          find.widgetWithText(TextField, '이 QA의 지속 요청'),
          '로그인 결과와 증거를 검토합니다.',
        );
        await tester.tap(find.text('프로젝트 지침 · QA 요청'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byKey(const Key('ai-request')),
            matching: find.byType(TextField),
          ),
          '기존 모든 노드와 target, selectors, variables를 그대로 보존하세요. end로 들어가는 유일 edge에 action screenshot 노드 id=ai_evidence를 하나 삽입하세요. params는 {"required":true}입니다. 나머지 변경 없이 전체 XML을 반환하세요.',
        );
        await capture('02-request');
        await tester.tap(find.byKey(const Key('ai-generate')));
        await pumpUntil(() => !vm.ai.busy);
        expect(vm.ai.status, 'review', reason: vm.ai.error);
        expect(
          vm.work.run.events,
          isEmpty,
          reason: 'AI creation must not execute QA',
        );
        evidence['aiSession'] = vm.ai.proposal!.answer.sessionDirectory;
        evidence['changes'] = vm.ai.proposal!.changes;
        await tester.ensureVisible(find.text('변경 미리보기'));
        await tester.tap(find.text('변경 미리보기'));
        await tester.pumpAndSettle();
        await capture('03-proposal');
        await tester.tap(find.byKey(const Key('ai-apply')));
        await tester.pumpAndSettle();
        expect(vm.work.source, contains('ai_evidence'));
        await tester.tap(find.text('저장').first);
        await pumpUntil(() => !vm.workspace.busy && !vm.dirty);
        await tester.tap(find.byKey(const Key('workspace-validate')));
        await pumpUntil(() => !vm.work.run.busy);
        expect(vm.work.canUsePlan, isTrue, reason: vm.work.run.error);
        await tester.tap(find.byKey(const Key('workspace-run')));
        await pumpUntil(() => !vm.work.run.busy && !vm.workspace.busy);
        expect(
          vm.work.run.result?['outcome'],
          'passed',
          reason: vm.work.run.error,
        );
        expect(vm.work.run.images, isNotEmpty);
        evidence['pass'] = vm.work.run.reportDirectory;
        final imageTitle = find.textContaining('검증된 PNG').first;
        await tester.ensureVisible(imageTitle);
        await tester.tap(imageTitle);
        await tester.pumpAndSettle();
        await capture('04-passed-png');
        await tester.tap(find.text('결과 접기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('블록 / Flow'));
        await tester.pumpAndSettle();
        final startBlock = find.byKey(const Key('flow-node-start'));
        await tester.ensureVisible(startBlock);
        await tester.tap(startBlock);
        await tester.pumpAndSettle();
        expect(vm.selectedNode, 'start');
        expect(
          find.descendant(
            of: startBlock,
            matching: find.textContaining('passed'),
          ),
          findsOneWidget,
        );
        await capture('06-flow-passed');
        evidence['flowSelectionAndPassedBadge'] = true;
        await tester.tap(find.text('XML / JSON'));
        await tester.pumpAndSettle();
        final failed = jsonDecode(
          jsonEncode(vm.work.run.plan!['blueprint']),
        ) as Map<String, dynamic>;
        final node = (failed['flow']['nodes'] as List).firstWhere(
          (n) => n['action'] == 'assertText',
        );
        node['params']['expected'] = 'INTENTIONAL_MISMATCH';
        node['timeoutMs'] = 800;
        await tester.enterText(
          find.byKey(const Key('workspace-source')),
          jsonEncode(failed),
        );
        await tester.tap(find.byKey(const Key('workspace-validate')));
        await pumpUntil(() => !vm.work.run.busy);
        await tester.tap(find.byKey(const Key('workspace-run')));
        await pumpUntil(() => !vm.work.run.busy && !vm.workspace.busy);
        expect(vm.work.run.result?['outcome'], 'failed');
        evidence['fail'] = vm.work.run.reportDirectory;
        await capture('05-failed');
        node['timeoutMs'] = 30000;
        await tester.enterText(
          find.byKey(const Key('workspace-source')),
          jsonEncode(failed),
        );
        await tester.tap(find.byKey(const Key('workspace-validate')));
        await pumpUntil(() => !vm.work.run.busy);
        await tester.tap(find.byKey(const Key('workspace-run')));
        await pumpUntil(
          () => vm.work.run.events.any(
            (e) => e['type'] == 'step.started' && e['nodeId'] == node['id'],
          ),
        );
        await tester.tap(find.text('취소').first);
        await pumpUntil(() => !vm.work.run.busy && !vm.workspace.busy);
        expect(vm.work.run.result?['outcome'], 'cancelled');
        evidence['cancel'] = vm.work.run.reportDirectory;
        final saved = await WorkspaceFileService(
          directory: Directory('${session.path}/workspace'),
        ).read();
        expect(
          saved.projects.single.documents.single.lastRun?.outcome,
          'cancelled',
        );
        expect(saved.projects.single.instructions, isNotEmpty);
        evidence['persistedLastRun'] = saved
            .projects
            .single
            .documents
            .single
            .lastRun!
            .toJson();
        final savedSource = saved.projects.single.documents.single.source;
        final previousScope = vm;
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          AppProviders(
            engineService: service,
            workspaceFileService: WorkspaceFileService(
              directory: Directory('${session.path}/workspace'),
            ),
            child: Builder(
              builder: (context) {
                vm = context.read<DesktopWorkspaceViewModel>();
                return RepaintBoundary(key: boundaryKey, child: const QaApp());
              },
            ),
          ),
        );
        await pumpUntil(() => vm.initialized);
        expect(identical(vm, previousScope), isFalse);
        await tester.tap(find.text('내일 테스트').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('로컬 로그인').first);
        await tester.pumpAndSettle();
        expect(vm.work.source, savedSource);
        expect(vm.workspace.instructions, saved.projects.single.instructions);
        expect(
          vm.workspace.prompt,
          saved.projects.single.documents.single.prompt,
        );
        expect(vm.workspace.qa!.lastRun!.outcome, 'cancelled');
        expect(vm.ai.request, isEmpty);
        await capture('07-restored');
        evidence['newProviderScopeRestore'] = true;
        evidence['status'] = 'passed';
        expect(tester.takeException(), isNull);
      } finally {
        await File(
          '${session.path}/verification.json',
        ).writeAsString(const JsonEncoder.withIndent('  ').convert(evidence));
        await File('${output.path}/latest.json').writeAsString(
          jsonEncode({
            'session': session.path,
            'status': evidence['status'] ?? 'failed',
          }),
        );
        await tester.pumpWidget(const SizedBox());
        service.dispose();
        await server.close(force: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
