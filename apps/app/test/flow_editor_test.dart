import 'desktop_runtime.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/features/scenario_editor/repositories/blueprint_catalog.dart';
import 'package:automated_qa_desktop/features/scenario_editor/view_models/flow_editor_view_model.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';

class MemoryCatalog extends BlueprintCatalog {
  MemoryCatalog(this.value);
  final Map<String, dynamic> value;
  @override
  Future<Map<String, dynamic>> load() async => value;
}

void main() {
  test('graph edits/undo/redo/branch and metadata roundtrip through official XML compiler', () async {
    final bundle = jsonDecode(
      await File('assets/engine-contract.json').readAsString(),
    ) as Map<String, dynamic>;
    final vm = FlowEditorViewModel(MemoryCatalog(bundle));
    addTearDown(vm.dispose);
    await vm.initialize();
    vm.create();
    expect(vm.actions, contains('assertText'));
    expect(vm.nodeTypes, contains('branch'));
    final original = vm.source;
    vm.load({
      'flow': {
        'nodes': [
          {'id': 12},
        ],
        'edges': [],
      },
    });
    expect(vm.source, original);
    expect(vm.error, isNotNull);
    final malformed = vm.blueprint!;
    (malformed['flow']['nodes'] as List).add(
      Map<String, dynamic>.from(malformed['flow']['nodes'][0]),
    );
    vm.load(malformed);
    expect(vm.source, original);
    final firstNode = vm.nodes.first;
    vm.updateNode(firstNode['id'], {...firstNode, 'id': 'renamed'});
    expect(vm.source, original);
    vm.move('start', 240, 120);
    expect(
      vm.blueprint!['flow']['metadata']['presentation']['positions']['start']['x'],
      240,
    );
    vm.undo();
    expect(vm.source, original);
    vm.redo();
    vm.addNode('branch');
    final id = vm.nodes.last['id'] as String;
    vm.connect('start', id, '');
    vm.connect(id, 'open', 'true');
    vm.connect(id, 'end', 'false');
    final old = vm.edges.indexWhere(
      (e) => e['from'] == 'start' && e['to'] == 'open',
    );
    vm.removeEdge(old);
    final source = vm.source;
    vm.removeNode(id);
    expect(vm.edges.any((e) => e['from'] == id || e['to'] == id), isFalse);
    vm.undo();
    expect(vm.source, source);
    final root = Directory.current.parent.parent.path;
    final node = (await Process.run('where.exe', [
      'node.exe',
    ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
    final settings = EngineSettings(
      nodePath: node,
      cliPath: '${desktopPackageRoot(root)}/packages/cli/aqa.mjs',
      reportRoot: '$root/artifacts/flow-roundtrip',
    );
    final manifest = jsonDecode(
      await File('assets/desktop-engine-runtime.json').readAsString(),
    ) as Map<String, dynamic>;
    final service = LocalEngineCliService(loadManifest: () async => manifest);
    addTearDown(service.dispose);
    final jsonPlan = await service.prepare(settings, source);
    final xml = await service.exportXml(settings, source);
    final xmlPlan = await service.prepare(settings, xml);
    expect(
      xmlPlan.plan['blueprintSnapshotHash'],
      jsonPlan.plan['blueprintSnapshotHash'],
    );
    expect(
      xmlPlan.plan['blueprint']['flow']['metadata'],
      vm.blueprint!['flow']['metadata'],
    );
    final validBefore = vm.source;
    vm.connect('end', 'start', '');
    expect(
      vm.source,
      validBefore,
      reason: 'invalid end output/start input is rejected before changing the document',
    );
    await service.prepare(settings, vm.source);
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('visual node drag stores presentation only and can undo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late FlowEditorViewModel vm;
    final catalog = await tester.runAsync(
      () async => MemoryCatalog(
        jsonDecode(await File('assets/engine-contract.json').readAsString())
            as Map<String, dynamic>,
      ),
    );
    await tester.pumpWidget(
      AppProviders(
        blueprintCatalog: catalog,
        child: Builder(
          builder: (context) {
            vm = context.read<FlowEditorViewModel>();
            return const QaApp(legacyEditor: true);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('블록 / Flow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('공개 예제로 새 Flow'));
    await tester.pumpAndSettle();
    final before = vm.nodes;
    await tester.drag(
      find.byKey(const Key('flow-node-start')),
      const Offset(40, 50),
    );
    await tester.pumpAndSettle();
    expect(vm.nodes, before);
    expect(
      vm.blueprint!['flow']['metadata']['presentation']['positions']['start'],
      isNotNull,
    );
    await tester.tap(find.byTooltip('되돌리기'));
    await tester.pumpAndSettle();
    expect(vm.blueprint!['flow']['metadata'], isNull);
    await tester.tap(find.text('Flow를 원문에 적용'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XML / JSON'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('scenario-source')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      contains('qa.blueprint/v1'),
    );
  });
}
