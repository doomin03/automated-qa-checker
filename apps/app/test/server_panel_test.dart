import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/features/server_connection/repositories/server_repository.dart';
import 'package:automated_qa_desktop/features/server_connection/view_models/server_view_model.dart';
import 'package:automated_qa_desktop/features/server_connection/views/server_panel.dart';

void main() {
  testWidgets(
    'health loading/API error/transport/retry keeps one request per action',
    (tester) async {
      final previous = HttpOverrides.current;
      HttpOverrides.global = null;
      HttpServer? server;
      var count = 0, port = 0;
      var fail = true;
      Completer<void>? responseGate = Completer<void>();
      final vm = ServerViewModel(ServerRepository());
      Future<void> start() async {
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
        port = server!.port;
        server!.listen((request) async {
          count++;
          await responseGate?.future;
          request.response.statusCode = fail ? 400 : 200;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(
              fail
                  ? {
                      'code': 'VALIDATION_ERROR',
                      'message': 'Fixture rejection',
                      'requestId': 'c00e18a5-0976-49b5-8a5f-ac214dd07b45',
                      'details': [],
                    }
                  : {
                      'status': 'ok',
                      'service': 'automated-qa-checker',
                      'apiVersion': 'v1',
                      'client': 'app',
                    },
            ),
          );
          await request.response.close();
        });
      }

      Future<void> wait() async {
        for (var i = 0; i < 150 && vm.busy; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(vm.busy, false);
      }

      try {
        await tester.runAsync(start);
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: vm,
            child: const MaterialApp(home: Scaffold(body: ServerPanel())),
          ),
        );
        await tester.tap(find.text('공유 서버 연결 (선택)'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('api-origin')),
          'http://127.0.0.1:$port',
        );
        await tester.runAsync(() async {
          await tester.tap(find.byKey(const Key('api-connect')));
          for (var i = 0; i < 100 && count == 0; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        await tester.pump();
        expect(find.text('연결 확인 중'), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(find.byKey(const Key('api-connect')))
              .onPressed,
          isNull,
        );
        await vm.connect('http://127.0.0.1:$port');
        expect(count, 1);
        await tester.runAsync(() async {
          responseGate!.complete();
          responseGate = null;
          await wait();
        });
        await tester.pump();
        expect(
          find.textContaining('API 400: VALIDATION_ERROR'),
          findsOneWidget,
        );
        await tester.runAsync(() async {
          await server!.close(force: true);
          server = null;
          await tester.tap(find.byKey(const Key('api-connect')));
          await wait();
        });
        await tester.pump();
        expect(find.textContaining('연결 오류'), findsOneWidget);
        expect(count, 1);
        await tester.runAsync(() async {
          fail = false;
          await start();
          await tester.tap(find.byKey(const Key('api-connect')));
          await wait();
        });
        await tester.pump();
        expect(
          find.textContaining('automated-qa-checker · ok · app'),
          findsOneWidget,
        );
        expect(count, 2);
        await tester.runAsync(() async {
          await vm.connect('http://127.0.0.1:$port/api/v1');
        });
        await tester.pump();
        expect(find.textContaining('주소 또는 API 계약 오류'), findsOneWidget);
        expect(count, 2);
      } finally {
        await tester.pumpWidget(const SizedBox());
        vm.dispose();
        await tester.runAsync(() async {
          await server?.close(force: true);
        });
        HttpOverrides.global = previous;
      }
    },
  );
}
