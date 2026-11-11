import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Windows QA app calls actual Nest and retries after server restart',
    (tester) async {
      const root = String.fromEnvironment('QA_REPO');
      if (root.isEmpty) {
        throw StateError('QA_REPO absolute repository path is required');
      }
      Process? server;
      var port = 0;
      Future<String> start() async {
        server = await Process.start(
          'node',
          ['$root/apps/server/dist/src/main.js'],
          workingDirectory: root,
          environment: {
            ...Platform.environment,
            'PORT': '$port',
            'HOST': '127.0.0.1',
            'QA_AUTH_MODE': 'disabled',
          },
        );
        unawaited(server!.stderr.drain<void>());
        final line = await server!.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .firstWhere((s) => s.startsWith('{"event":"listening"'))
            .timeout(const Duration(seconds: 20));
        final origin = (jsonDecode(line) as Map)['url'] as String;
        port = Uri.parse(origin).port;
        return origin;
      }

      Future<void> waitFor(String text) async {
        for (var i = 0; i < 150; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          final message =
              tester.widget<Text>(find.byKey(const Key('api-status'))).data ??
              '';
          if (message.contains(text)) return;
        }
        throw StateError('Expected API status: $text');
      }

      try {
        final origin = await start();
        await tester.pumpWidget(const AppProviders(child: QaApp(legacyEditor: true)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('공유 서버 연결 (선택)'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('api-origin')), origin);
        await tester.tap(find.byKey(const Key('api-connect')));
        await waitFor('automated-qa-checker · ok · app');
        server!.kill();
        await server!.exitCode;
        server = null;
        await tester.tap(find.byKey(const Key('api-connect')));
        await waitFor('연결 오류');
        await start();
        await tester.tap(find.byKey(const Key('api-connect')));
        await waitFor('automated-qa-checker · ok · app');
        expect(tester.takeException(), isNull);
        final artifact = File(
          '$root/artifacts/windows-health-integration.json',
        );
        await artifact.parent.create(recursive: true);
        await artifact.writeAsString(
          jsonEncode({
            'platform': Platform.operatingSystem,
            'actualNativeApp': true,
            'actualNest': true,
            'origin': origin,
            'stoppedServerTransportFailure': true,
            'restartRetry': true,
            'engineExecutionRequested': false,
          }),
        );
      } finally {
        server?.kill();
        if (server != null) await server!.exitCode;
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}
