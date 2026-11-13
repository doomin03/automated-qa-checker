import 'package:automated_qa_desktop/features/scenario_editor/view_models/scenario_editor_view_model.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/features/organization_login/services/organization_service.dart';
import 'package:automated_qa_desktop/features/organization_login/view_models/organization_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/views/shared_panel.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/view_models/shared_view_model.dart';

void main() {
  testWidgets(
    'actual organization OIDC callback and Provider shared connection never execute QA',
    (tester) async {
      final overrides = HttpOverrides.current;
      HttpOverrides.global = null;
      tester.view.physicalSize = const Size(1300, 2200);
      tester.view.devicePixelRatio = 1;
      Process? server;
      final serverErrors = StringBuffer();
      String? origin;
      final cookieJar = <String, List<Cookie>>{};
      final root = Directory.current.parent.parent.path;
      late Directory folder;
      Future<void> browser(String initial) async {
        final client = HttpClient();
        var current = Uri.parse(initial);
        try {
          for (var i = 0; i < 8; i++) {
            final request = await client.getUrl(current);
            request.followRedirects = false;
            request.cookies.addAll(
              (cookieJar[current.authority] ?? []).where(
                (c) => current.path.startsWith(c.path ?? '/'),
              ),
            );
            final response = await request.close();
            if (response.cookies.isNotEmpty) {
              cookieJar[current.authority] = response.cookies;
            }
            final location = response.headers.value(HttpHeaders.locationHeader);
            await response.drain<void>();
            if (location == null) {
              expect(response.statusCode, 200);
              return;
            }
            current = current.resolve(location);
          }
          throw StateError('Too many fixture redirects');
        } finally {
          client.close(force: true);
        }
      }

      final organizationService = OrganizationService(launchBrowser: browser);
      try {
        await tester.runAsync(() async {
          folder = await Directory.systemTemp.createTemp('qa-org-ui-');
          server = await Process.start('node', [
            '$root/tests/auth-fixture.mjs',
          ], workingDirectory: root);
          server!.stderr
              .transform(const Utf8Decoder(allowMalformed: true))
              .listen((text) {
                if (serverErrors.length < 65536) serverErrors.write(text);
              });
          final line = await server!.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .first
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw StateError(
                  'OIDC fixture readiness timeout: $serverErrors',
                ),
              );
          origin = (jsonDecode(line) as Map)['origin'] as String;
        });
        await tester.pumpWidget(
          AppProviders(
            organizationService: organizationService,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(child: const SharedPanel()),
              ),
            ),
          ),
        );
        await tester.tap(find.text('공용 XML · 서버 진행 공유 (선택)'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('shared-origin')), origin!);
        await tester.enterText(
          find.byKey(const Key('shared-cache')),
          folder.path,
        );
        await tester.runAsync(() async {
          await tester.tap(find.text('브라우저에서 조직 로그인'));
        });
        final context = tester.element(find.byType(SharedPanel));
        final auth = context.read<OrganizationViewModel>();
        expect(context.read<ScenarioEditorViewModel>().draft.content, isEmpty);
        await tester.runAsync(() async {
          for (var i = 0; i < 200 && auth.busy; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        });
        await tester.pumpAndSettle();
        expect(
          auth.repository.identity?.userId,
          'organization-user',
          reason: auth.message,
        );
        await tester.tap(find.text('프로젝트 Organization project'));
        await tester.pump();
        await tester.runAsync(() async {
          await tester.tap(find.text('공유 연결'));
        });
        final shared = context.read<SharedViewModel>();
        await tester.runAsync(() async {
          for (var i = 0; i < 100 && shared.busy; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        });
        await tester.pumpAndSettle();
        expect(shared.connected, true, reason: shared.message);
        expect(shared.autoPublish, false);
        await tester.runAsync(() async {
          await tester.tap(find.text('조직 로그아웃'));
        });
        await tester.runAsync(() async {
          for (var i = 0; i < 100 && auth.busy; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        });
        await tester.pumpAndSettle();
        expect(auth.repository.identity, isNull);
        expect(shared.connected, false);
      } finally {
        await tester.pumpWidget(const SizedBox());
        organizationService.dispose();
        await tester.runAsync(() async {
          await server?.stdin.close();
          try {
            await server?.exitCode.timeout(const Duration(seconds: 15));
          } on TimeoutException {
            server?.kill();
            await server?.exitCode.timeout(const Duration(seconds: 3));
          }
        });
        HttpOverrides.global = overrides;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
