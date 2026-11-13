import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/desktop_workspace_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/terminal_workbench_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/xml_block_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/models/terminal_profile.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';

// Explicit test-only session-scoped override. Never writes user configuration.
class FixtureCodex extends TerminalProfile {
  const FixtureCodex(String executable)
    : super('codex', 'Codex', executable, readiness: 'available');
  @override
  List<String> arguments(String cwd) => [
    ...super.arguments(cwd),
    '-c',
    'projects.${jsonEncode(cwd)}.trust_level="trusted"',
  ];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('actual Codex interactive edit to public plan GUI and explicit run', (
    tester,
  ) async {
    const root = String.fromEnvironment('QA_REPO');
    final out = await Directory('$root/artifacts/terminal-readiness/native')
        .create(recursive: true)
        .then((d) => d.createTemp('run-'));
    final isolated = await Directory.systemTemp.createTemp(
      'qa-interactive-acceptance-',
    );
    final config = File(
      '${Platform.environment['CODEX_HOME'] ?? '${Platform.environment['USERPROFILE']}/.codex'}/config.toml',
    );
    Future<String?> configHash() async => await config.exists()
        ? sha256.convert(await config.readAsBytes()).toString()
        : null;
    final beforeConfig = await configHash();
    final evidence = <String, dynamic>{
      'workspace': isolated.path,
      'configHashBefore': beforeConfig,
      'cases': [],
      'modelRequests': 0,
      'complete': false,
    };
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var targetFails = false;
    server.listen((r) async {
      r.response.headers.contentType = ContentType.html;
      r.response.write(
        '<input data-testid="username"><button data-testid="submit" onclick="document.querySelector(\'[data-testid=greeting]\').textContent=\'${targetFails ? 'Mismatch' : 'Welcome '}\'+document.querySelector(\'input\').value">Go</button><h1 data-testid="greeting"></h1>',
      );
      await r.response.close();
    });
    late DesktopWorkspaceViewModel desktop;
    late TerminalWorkbenchViewModel pool;
    late XmlBlockWorkbenchViewModel blocks;
    final boundary = GlobalKey();
    Future<void> pumpFor(Duration time) async {
      final end = DateTime.now().add(time);
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> until(bool Function() ready, {int seconds = 40}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!ready() && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(ready(), true, reason: '${pool.error} / ${desktop.error}');
    }

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 150));
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${out.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    }

    try {
      await tester.pumpWidget(
        AppProviders(
          workspaceFileService: WorkspaceFileService(directory: isolated),
          child: Builder(
            builder: (context) {
              desktop = context.read<DesktopWorkspaceViewModel>();
              pool = context.read<TerminalWorkbenchViewModel>();
              blocks = context.read<XmlBlockWorkbenchViewModel>();
              return RepaintBoundary(key: boundary, child: const QaApp());
            },
          ),
        ),
      );
      await until(() => desktop.initialized);
      await desktop.createProject('AI 실제 인수');
      await desktop.createQa('seed');
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
      final profile = await pool.inspect('codex');
      expect(profile.available, true);
      for (final format
          in const bool.fromEnvironment('QA_ONLY_XML')
              ? ['xml']
              : ['xml', 'json']) {
        targetFails = false;
        expect(
          await desktop.createQaFromSource(
            'AI $format',
            format == 'xml' ? xml : jsonEncode(blueprint),
          ),
          true,
        );
        await until(() => !blocks.busy);
        blocks.setEnabled(false);
        await tester.pump();
        await pool.add(FixtureCodex(profile.executable), writer: true);
        final session = pool.selected;
        await tester.tap(find.text('터미널 열기').first);
        await tester.pumpAndSettle();
        final receipt = <String, dynamic>{
          'format': format,
          'session': session.session!.path,
          'qa': session.qaIdentity,
          'pid': session.service.pid,
          'guide': await session.authoringEnvironment(),
        };
        (evidence['cases'] as List).add(receipt);
        await pumpFor(const Duration(seconds: 6));
        var text = session.terminal.buffer.getText();
        if (text.contains('Update available') ||
            text.contains('Skip for now') ||
            text.contains('Skip until')) {
          session.input('\x1b');
          await pumpFor(const Duration(seconds: 4));
        }
        text = session.terminal.buffer.getText();
        receipt['startupText'] = text.substring(
          text.length > 12000 ? text.length - 12000 : 0,
        );
        await shot('$format-start');
        if (text.contains('Trust and continue') ||
            text.contains('Folder access') ||
            text.contains('trust this folder')) {
          receipt['blocked'] =
              'persistent trust prompt remained; no selection made';
          fail('Session-only trust override was not accepted');
        }
        final file = File('${session.session!.path}/scenario.$format');
        final original = await file.readAsString();
        receipt['beforeSha256'] = sha256
            .convert(utf8.encode(original))
            .toString();
        final request =
            r'$qa-authoring'
            ' Read QA-CONTEXT.md and the prepared qa-authoring skill. In scenario.$format only, insert exactly one action node {"id":"ai_added_capture","type":"action","action":"screenshot","params":{}} between capture and end by replacing edge capture->end with capture->ai_added_capture and ai_added_capture->end. Preserve every existing node, selector, variable and target unchanged. Keep the same $format file format. Do not run QA, start services, open a browser, contact any target or external service, or change any file outside this session. Do not change configuration or credentials. Save the file and summarize.';
        session.input('\x1b[200~$request\x1b[201~');
        await pumpFor(const Duration(milliseconds: 700));
        session.input('\r');
        evidence['modelRequests'] = (evidence['modelRequests'] as int) + 1;
        await until(
          () =>
              desktop.work.flow.nodes.any(
                (n) => n['id'] == 'ai_added_capture',
              ) &&
              session.state == 'synced',
          seconds: 180,
        );
        expect(desktop.work.run.running, false);
        expect(desktop.work.run.result, isNull);
        final after = await file.readAsString();
        receipt['afterSha256'] = sha256.convert(utf8.encode(after)).toString();
        await File('${out.path}/candidate.$format').writeAsString(after);
        expect(receipt['afterSha256'], isNot(receipt['beforeSha256']));
        expect(
          desktop.work.flow.nodes.length,
          (blueprint['flow']['nodes'] as List).length + 1,
        );
        receipt['finalTerminal'] = session.terminal.buffer.getText();
        await shot('$format-applied');
        await session.close();
        expect(session.service.cleanupUnknown, false);
        if (find.text('작업실로').evaluate().isNotEmpty) {
          await tester.tap(find.text('작업실로'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const Key('workspace-validate')));
        await until(() => desktop.work.canUsePlan);
        receipt['snapshotHash'] =
            desktop.work.run.plan!['blueprintSnapshotHash'];
        await tester.tap(find.byKey(const Key('workspace-run')));
        await until(
          () => !desktop.work.run.running && desktop.work.run.result != null,
          seconds: 60,
        );
        expect(desktop.work.run.result!['outcome'], 'passed');
        receipt['pass'] = desktop.work.run.reportDirectory;
        targetFails = true;
        await tester.tap(find.byKey(const Key('workspace-run')));
        await until(
          () =>
              !desktop.work.run.running &&
              desktop.work.run.result?['outcome'] == 'failed',
          seconds: 60,
        );
        receipt['fail'] = desktop.work.run.reportDirectory;
        await shot('$format-result');
      }
      evidence['complete'] = true;
    } finally {
      for (final value in evidence['cases'] as List) {
        final record = value as Map<String, dynamic>;
        final item = pool.sessions
            .where((s) => s.qaIdentity == record['qa'])
            .firstOrNull;
        if (item != null) {
          final tail = item.terminal.buffer.getText();
          record['afterRequestTerminal'] = tail.substring(
            tail.length > 40000 ? tail.length - 40000 : 0,
          );
          record['syncState'] = item.state;
          record['syncError'] = item.error;
          record['guiHasExpectedNode'] = desktop.work.flow.nodes.any(
            (n) => n['id'] == 'ai_added_capture',
          );
          final file = File(
            '${item.session!.path}/scenario.${record['format']}',
          );
          record['fileExists'] = await file.exists();
          if (await file.exists()) {
            record['finalFileSha256'] = sha256
                .convert(await file.readAsBytes())
                .toString();
          }
        }
      }
      try {
        await shot('final-state');
      } catch (_) {}
      await pool.closeAll();
      for (final record in evidence['cases'] as List) {
        final item = pool.sessions
            .where((s) => s.qaIdentity == record['qa'])
            .firstOrNull;
        record['closed'] = item?.service.state;
        record['cleanupUnknown'] = item?.service.cleanupUnknown;
        final listing = await Process.run('tasklist.exe', [
          '/FI',
          'PID eq ${record['pid']}',
          '/FO',
          'CSV',
          '/NH',
        ]);
        record['ownedPidAbsent'] = !listing.stdout.toString().contains(
          '"${record['pid']}"',
        );
      }
      await server.close(force: true);
      evidence['configHashAfter'] = await configHash();
      evidence['configUnchanged'] = evidence['configHashAfter'] == beforeConfig;
      await File('${out.path}/verification.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(evidence));
      await File('$root/artifacts/terminal-readiness/native-latest.json')
          .writeAsString(jsonEncode({'directory': out.path}));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(evidence['configUnchanged'], true);
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
