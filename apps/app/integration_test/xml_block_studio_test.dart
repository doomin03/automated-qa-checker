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
import 'package:automated_qa_desktop/app/workbench/view_models/xml_block_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/scenario_editor/services/scenario_file_picker.dart';

class FixtureFilePicker implements ScenarioFilePicker {
  String? next;
  @override
  Future<String?> choose({bool allowJson = false}) async {
    final value = next;
    next = null;
    return value;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native XML file blocks compile and explicit Engine execution', (
    tester,
  ) async {
    const root = String.fromEnvironment('QA_REPO');
    final output = await Directory('$root/artifacts/xml-block-studio/native')
        .create(recursive: true);
    final session = await output.createTemp('run-');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) async {
      r.response.headers.contentType = ContentType.html;
      r.response.write(
        '<input data-testid="username"><button data-testid="submit" onclick="document.querySelector(\'[data-testid=greeting]\').textContent=\'Welcome \'+document.querySelector(\'input\').value">Go</button><h1 data-testid="greeting"></h1>',
      );
      await r.response.close();
    });
    final receipt = jsonDecode(
      await File('$root/apps/app/assets/desktop-installation.json')
          .readAsString(),
    );
    final contract = jsonDecode(
      await File('$root/apps/app/assets/desktop-engine-contract.json')
          .readAsString(),
    );
    final manifest = jsonDecode(
      await File('$root/apps/app/assets/desktop-engine-runtime.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    final engine = LocalEngineCliService(loadManifest: () async => manifest);
    final settings = EngineSettings(
      nodePath: receipt['nodePath'],
      cliPath: receipt['cliPath'],
      reportRoot: '${session.path}/reports',
    );
    final original = contract['example'] as Map<String, dynamic>;
    final origin = 'http://127.0.0.1:${server.port}';
    original['target']['allowedOrigins'] = [origin];
    for (final key in (original['target']['launchTargets'] as Map).keys) {
      original['target']['launchTargets'][key] = origin;
    }
    final files = <File>[];
    for (var i = 0; i < 3; i++) {
      final b = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
      b['id'] = 'block-${i + 1}';
      b['name'] = ['로그인', '환영 문구 확인', '화면 증거'][i];
      final xml = await engine.exportXml(settings, jsonEncode(b));
      final file = File(
        '${session.path}/${['login', 'greeting', 'evidence'][i]}.xml',
      );
      await file.writeAsString(xml);
      files.add(file);
    }
    late DesktopWorkspaceViewModel desktop;
    late XmlBlockWorkbenchViewModel blocks;
    final boundaryKey = GlobalKey();
    final picker = FixtureFilePicker();
    final evidence = <String, dynamic>{
      'session': session.path,
      'engineVersion': manifest['engineVersion'],
      'screenshots': [],
    };
    Future<void> wait(bool Function() ready) async {
      final limit = DateTime.now().add(const Duration(seconds: 90));
      while (!ready() && DateTime.now().isBefore(limit)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        ready(),
        true,
        reason: '${blocks.error} / ${desktop.work.run.error}',
      );
      await tester.pump(const Duration(milliseconds: 200));
    }

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 200));
      final boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${session.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      (evidence['screenshots'] as List).add({
        'file': '$name.png',
        'width': image.width,
        'height': image.height,
      });
      image.dispose();
    }

    Future<void> enter(String value) async {
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('workspace-dialog-input')),
        value,
      );
      await tester.tap(find.text('확인'));
      await tester.pump(const Duration(milliseconds: 400));
    }

    Widget application() => AppProviders(
      engineService: engine,
      filePicker: picker,
      workspaceFileService: WorkspaceFileService(
        directory: Directory('${session.path}/workspace'),
      ),
      child: Builder(
        builder: (context) {
          desktop = context.read<DesktopWorkspaceViewModel>();
          blocks = context.read<XmlBlockWorkbenchViewModel>();
          return RepaintBoundary(key: boundaryKey, child: const QaApp());
        },
      ),
    );
    try {
      await binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(application());
      await wait(() => desktop.initialized);
      desktop.work.settings.update(settings);
      await tester.tap(find.text('프로젝트 만들기'));
      await enter('XML 테스트');
      await wait(
        () => desktop.workspace.project != null && !desktop.workspace.busy,
      );
      await tester.tap(find.text('QA 만들기'));
      await enter('로그인 조합');
      await wait(
        () =>
            desktop.workspace.qa != null &&
            !blocks.busy &&
            !desktop.workspace.busy,
      );
      for (final file in files) {
        picker.next = file.path;
        await tester.tap(find.text('XML 가져오기').first);
        await tester.pump();
        await wait(() => !blocks.busy);
        expect(blocks.error, isNull);
        await tester.tap(find.text(file.uri.pathSegments.last).first);
        await tester.pumpAndSettle();
      }
      expect(blocks.instances.length, 3);
      // Use the real pin gestures after the view's fit transform.
      for (var i = 1; i <= 2; i++) {
        final from = find.byKey(Key('xml-pin-out-instance_$i')),
            to = find.byKey(Key('xml-pin-in-instance_${i + 1}'));
        await tester.dragFrom(
          tester.getCenter(from),
          tester.getCenter(to) - tester.getCenter(from),
        );
        await tester.pumpAndSettle();
      }
      expect(blocks.links.length, 2);
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const Key('xml-block-viewport')),
      );
      viewer.transformationController!.value = Matrix4.identity()
        ..scaleByDouble(.5, .5, 1, 1);
      await tester.pumpAndSettle();
      final x = blocks.instances[1].x;
      final header = find.descendant(
        of: find.byKey(const Key('xml-block-instance_2')),
        matching: find.text('greeting.xml'),
      );
      final gesture = await tester.startGesture(tester.getCenter(header));
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      final xAfterThreshold = tester
          .getTopLeft(find.byKey(const Key('xml-block-instance_2')))
          .dx;
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      expect(
        tester.getTopLeft(find.byKey(const Key('xml-block-instance_2'))).dx -
            xAfterThreshold,
        closeTo(20, 1),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(blocks.instances[1].x - x, greaterThanOrEqualTo(40));
      blocks.undo();
      evidence['gestureHalfScale'] =
          '20 screen pixels => 40 document units after recognition';
      final countBeforeCancel = blocks.assets.length,
          modeBeforeCancel = blocks.enabled;
      await tester.tap(find.text('XML 가져오기').first);
      await tester.pumpAndSettle();
      expect(blocks.assets.length, countBeforeCancel);
      expect(blocks.enabled, modeBeforeCancel);
      evidence['pickerCancel'] = true;
      await tester.tap(find.text('전체 보기').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('xml-block-instance_2')));
      await tester.pumpAndSettle();
      await shot('01-workspace-1440');
      await tester.tap(find.text('블록 내용 확인'));
      await tester.pumpAndSettle();
      await shot('02-source-inspection');
      await tester.tap(find.text('돌아가기'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workspace-validate')));
      await wait(() => !blocks.busy && !desktop.work.run.busy);
      expect(blocks.error, isNull);
      expect(desktop.work.canUsePlan, true, reason: desktop.work.run.error);
      expect(desktop.work.run.events, isEmpty);
      final compiled = blocks.compiledXml;
      final before = blocks.revision;
      blocks.move('instance_2', 350, 200);
      blocks.undo();
      expect(blocks.revision, before);
      expect(blocks.current, true);
      desktop.setRunBlock('terminal', true);
      expect(desktop.externalRunBlocked, true);
      blocks.setEnabled(false);
      expect(desktop.externalRunBlocked, true);
      desktop.setRunBlock('terminal', false);
      blocks.setEnabled(true);
      expect(desktop.externalRunBlocked, false);
      await tester.tap(find.byKey(const Key('workspace-run')));
      await wait(() => !desktop.work.run.busy && !desktop.workspace.busy);
      expect(
        desktop.work.run.result?['outcome'],
        'passed',
        reason: desktop.work.run.error,
      );
      expect(desktop.work.run.images, isNotEmpty);
      evidence['pass'] = desktop.work.run.reportDirectory;
      await shot('03-passed');
      await tester.tap(find.text('저장').first);
      await wait(() => !blocks.busy && !desktop.workspace.busy);
      expect(blocks.dirty, false);
      // Exact-sized native Flutter surface captures are recorded with PNG dimensions.
      await binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpAndSettle();
      await tester.tap(find.text('결과 접기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('전체 보기').first);
      await tester.pumpAndSettle();
      await shot('04-workspace-1024');
      await tester.tap(find.text('라이브러리').first);
      await tester.pumpAndSettle();
      expect(find.text('evidence.xml'), findsWidgets);
      await shot('05-library-1024');
      await tester.tap(find.text('닫기').last);
      await tester.pumpAndSettle();
      await binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpAndSettle();
      final projectId = desktop.workspace.projectId!,
          qaId = desktop.workspace.qaId!;
      final savedLayout = blocks.instances.map((n) => n.toJson()).toList();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(application());
      await wait(() => desktop.initialized);
      desktop.work.settings.update(settings);
      desktop.select(projectId, qaId);
      await wait(() => !blocks.busy && blocks.assets.length == 3);
      expect(blocks.enabled, true);
      expect(blocks.instances.map((n) => n.toJson()).toList(), savedLayout);
      expect(blocks.sourceMap, isNotEmpty);
      expect(blocks.current, false);
      await tester.tap(find.byKey(const Key('workspace-validate')));
      await wait(() => !blocks.busy && !desktop.work.run.busy);
      expect(blocks.current, true);
      evidence['reopenComposition'] = true;
      // Direct source mode remains independent from authoring composition.
      await tester.tap(find.text('생성 XML').first);
      await tester.pumpAndSettle();
      expect(blocks.enabled, true);
      expect(find.byKey(const Key('workspace-source')), findsNothing);
      await tester.tap(find.text('직접 문서 / Flow').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('직접 문서 편집'));
      await tester.pumpAndSettle();
      expect(blocks.enabled, false);
      await tester.tap(find.text('XML 원문').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workspace-validate')));
      await wait(() => !desktop.work.run.busy);
      await tester.tap(find.byKey(const Key('workspace-run')));
      await wait(() => !desktop.work.run.busy && !desktop.workspace.busy);
      expect(desktop.work.run.result?['outcome'], 'passed');
      expect(desktop.work.run.images, isNotEmpty);
      evidence['directPass'] = desktop.work.run.reportDirectory;
      final failed = jsonDecode(
        jsonEncode(desktop.work.run.plan!['blueprint']),
      ) as Map<String, dynamic>;
      final assertion = (failed['flow']['nodes'] as List).firstWhere(
        (n) => n['action'] == 'assertText',
      );
      assertion['params']['expected'] = 'INTENTIONAL_MISMATCH';
      assertion['timeoutMs'] = 700;
      final failedXml = await engine.exportXml(settings, jsonEncode(failed));
      await tester.enterText(
        find.byKey(const Key('workspace-source')),
        failedXml,
      );
      await tester.tap(find.byKey(const Key('workspace-validate')));
      await wait(() => !desktop.work.run.busy);
      await tester.tap(find.byKey(const Key('workspace-run')));
      await wait(() => !desktop.work.run.busy && !desktop.workspace.busy);
      expect(desktop.work.run.result?['outcome'], 'failed');
      evidence['fail'] = desktop.work.run.reportDirectory;
      await shot('06-direct-failed');
      assertion['timeoutMs'] = 30000;
      final longXml = await engine.exportXml(settings, jsonEncode(failed));
      await tester.enterText(
        find.byKey(const Key('workspace-source')),
        longXml,
      );
      await tester.tap(find.byKey(const Key('workspace-validate')));
      await wait(() => !desktop.work.run.busy);
      await tester.tap(find.byKey(const Key('workspace-run')));
      await wait(
        () => desktop.work.run.events.any(
          (e) => e['type'] == 'step.started' && e['nodeId'] == assertion['id'],
        ),
      );
      await tester.tap(find.text('취소').first);
      await wait(() => !desktop.work.run.busy && !desktop.workspace.busy);
      expect(desktop.work.run.result?['outcome'], 'cancelled');
      evidence['cancel'] = desktop.work.run.reportDirectory;
      await tester.tap(find.text('저장').first);
      await wait(() => !blocks.busy && !desktop.workspace.busy);
      expect(blocks.dirty, false);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(application());
      await wait(() => desktop.initialized);
      desktop.work.settings.update(settings);
      desktop.select(projectId, qaId);
      await wait(() => !blocks.busy && blocks.assets.length == 3);
      expect(blocks.enabled, false);
      evidence['reopenDirect'] = true;
      // Failed composition points back to the exact file instance that ran.
      for (final n in blocks.instances.toList()) {
        blocks.select(n.id);
        blocks.removeSelected();
      }
      final failFile = File('${session.path}/failure.xml');
      await failFile.writeAsString(failedXml);
      expect(await blocks.importFile(failFile.path), true);
      blocks.add(blocks.assets.last.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workspace-validate')));
      await wait(() => !blocks.busy && !desktop.work.run.busy);
      await tester.tap(find.byKey(const Key('workspace-run')));
      await wait(() => !desktop.work.run.busy && !desktop.workspace.busy);
      expect(desktop.work.run.result?['outcome'], 'failed');
      evidence['compositionFail'] = desktop.work.run.reportDirectory;
      blocks.select(null);
      await tester.pumpAndSettle();
      await tester.tap(find.text('원인 블록 보기').first);
      await tester.pumpAndSettle();
      expect(blocks.selected, 'instance_1');
      await shot('07-composition-failed');
      final longFile = File('${session.path}/cancel.xml');
      await longFile.writeAsString(longXml);
      blocks.removeSelected();
      expect(await blocks.importFile(longFile.path), true);
      blocks.add(blocks.assets.last.id);
      final oldSelected = blocks.selected;
      blocks.select(null);
      blocks.focusGenerated(blocks.runSourceMap.keys.first);
      expect(blocks.selected, isNull);
      blocks.select(oldSelected);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workspace-validate')));
      await wait(() => !blocks.busy && !desktop.work.run.busy);
      await tester.tap(find.byKey(const Key('workspace-run')));
      await wait(
        () => desktop.work.run.events.any((e) => e['type'] == 'step.started'),
      );
      await tester.tap(find.text('취소').first);
      await wait(() => !desktop.work.run.busy && !desktop.workspace.busy);
      expect(desktop.work.run.result?['outcome'], 'cancelled');
      evidence['compositionCancel'] = desktop.work.run.reportDirectory;
      evidence['compiledXml'] = compiled;
      evidence['sourceMap'] = blocks.sourceMap;
      expect(tester.takeException(), isNull);
      evidence['status'] = 'passed';
    } finally {
      await File('${session.path}/verification.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(evidence));
      await File('${output.path}/latest.json').writeAsString(
        jsonEncode({
          'session': session.path,
          'status': evidence['status'] ?? 'failed',
        }),
      );
      await tester.pumpWidget(const SizedBox());
      await binding.setSurfaceSize(null);
      engine.dispose();
      await server.close(force: true);
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}
