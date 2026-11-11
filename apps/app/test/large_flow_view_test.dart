import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/features/scenario_editor/repositories/blueprint_catalog.dart';
import 'package:automated_qa_desktop/features/scenario_editor/view_models/flow_editor_view_model.dart';
import 'package:automated_qa_desktop/features/scenario_editor/views/flow_editor_view.dart';
import 'package:automated_qa_desktop/features/run_review/view_models/run_view_model.dart';
import 'package:automated_qa_desktop/features/run_review/repositories/engine_repository.dart';

import 'engine_bridge_test.dart' show IncompleteService;

void main() {
  testWidgets(
    '40/1000 node canvas supports last-node access without implicit edits',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final results = <Map<String, dynamic>>[];
      for (final count in [40, 1000]) {
        final vm = FlowEditorViewModel(BlueprintCatalog());
        final run = RunViewModel(EngineRepository(IncompleteService()));
        vm.load({
          'id': 'large',
          'flow': {
            'entryNode': 'n0',
            'nodes': List.generate(
              count,
              (i) => {
                'id': 'n$i',
                'type': 'action',
                'action': 'tap',
                'params': {'selector': 'entry'},
              },
            ),
            'edges': List.generate(
              count - 1,
              (i) => {'from': 'n$i', 'to': 'n${i + 1}'},
            ),
            'metadata': {
              'presentation': {
                'positions': {
                  'n0': {'x': 1800.0, 'y': 1500.0},
                },
              },
            },
          },
          'selectors': {'selectors': {}},
          'target': {'platform': 'web', 'launchTargets': {}},
        });
        final source = vm.source;
        final watch = Stopwatch()..start();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: vm),
              ChangeNotifierProvider.value(value: run),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: FlowEditorView(
                  loadSource: () {},
                  loadPlan: () {},
                  applyFlow: () {},
                  canLoadPlan: false,
                ),
              ),
            ),
          ),
        );
        final buildMs = watch.elapsedMilliseconds;
        final last = find.byKey(Key('flow-node-n${count - 1}'));
        final canvas = find.byKey(const Key('flow-canvas'));
        final lastRect = tester.getRect(last),
            canvasRect = tester.getRect(canvas);
        expect(lastRect.bottom, lessThanOrEqualTo(canvasRect.bottom));
        final saved = tester.getRect(find.byKey(const Key('flow-node-n0')));
        expect(saved.top - canvasRect.top, 1500);
        expect(saved.left - canvasRect.left, 1800);
        watch.reset();
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        expect(last.hitTestable(), findsOneWidget);
        await tester.tap(last);
        await tester.pump();
        final selectionMs = watch.elapsedMilliseconds;
        expect(
          vm.source,
          source,
          reason: 'scrolling and selecting must not create metadata edits',
        );
        final gesture = await tester.startGesture(tester.getCenter(last));
        await gesture.moveBy(const Offset(18, -12));
        await tester.pump();
        await gesture.up();
        await tester.pump();
        expect(vm.source, isNot(source));
        expect(
          vm.blueprint!['flow']['metadata']['presentation']['positions']['n0'],
          {'x': 1800.0, 'y': 1500.0},
        );
        vm.undo();
        await tester.pump();
        expect(vm.source, source);
        expect(tester.takeException(), isNull);
        results.add({
          'nodes': count,
          'buildMs': buildMs,
          'scrollAndSelectMs': selectionMs,
          'canvasWidth': canvasRect.width,
          'canvasHeight': canvasRect.height,
          'lastNodeReachable': true,
          'selectionPreservedSource': true,
          'moveUndoPreservedCoordinates': true,
        });
        await tester.pumpWidget(const SizedBox());
        vm.dispose();
        run.dispose();
      }
      await tester.runAsync(() async {
        final out = Directory(
          '${Directory.current.parent.parent.path}/artifacts/service-audit',
        );
        await out.create(recursive: true);
        await File('${out.path}/large-flow-view.json')
            .writeAsString(jsonEncode(results));
      });
    },
  );
}
