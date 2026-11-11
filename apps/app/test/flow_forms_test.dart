import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/scenario_editor/repositories/blueprint_catalog.dart';
import 'package:automated_qa_desktop/features/scenario_editor/view_models/flow_editor_view_model.dart';
import 'package:automated_qa_desktop/features/scenario_editor/views/flow_forms.dart';
import 'package:automated_qa_desktop/features/scenario_editor/views/repeat_form.dart';

class FormCatalog extends BlueprintCatalog {
  FormCatalog(this.bundle);
  final Map<String, dynamic> bundle;
  @override
  Future<Map<String, dynamic>> load() async => bundle;
}

void main() {
  testWidgets(
    'repeat form makes an explicit ordered authoring document without code input',
    (tester) async {
      final b = {
        'schemaVersion': 'qa.blueprint/v1',
        'flow': {
          'nodes': [
            {'id': 'start', 'type': 'start'},
            {
              'id': 'check',
              'type': 'assertion',
              'action': 'assertVisible',
              'params': {'selector': 'entry'},
            },
            {'id': 'end', 'type': 'end'},
          ],
          'edges': [
            {'from': 'start', 'to': 'check'},
            {'from': 'check', 'to': 'end'},
          ],
        },
      };
      String? source;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  source = await showDialog<String>(
                    context: context,
                    builder: (_) => RepeatForm(blueprint: b),
                  );
                },
                child: const Text('repeat'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('repeat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('check · assertVisible').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('본문 순서에 추가'));
      await tester.enterText(find.byKey(const Key('repeat-count')), '2');
      await tester.tap(find.text('작성 문서 만들기'));
      await tester.pumpAndSettle();
      final d = jsonDecode(source!);
      expect(d['schemaVersion'], 'qa.authoring/v1');
      final repeat = (d['blueprint']['flow']['nodes'] as List).firstWhere(
        (n) => n['type'] == 'repeat',
      );
      expect(repeat['count'], 2);
      expect(repeat['steps'].single['action'], 'assertVisible');
      expect((b['flow'] as Map)['nodes'], hasLength(3));
    },
  );
  testWidgets(
    'basic node form edits assertion without JSON and keeps node identity',
    (tester) async {
      final bundle = await tester.runAsync(
        () async =>
            jsonDecode(await File('assets/engine-contract.json').readAsString())
                as Map<String, dynamic>,
      );
      final vm = FlowEditorViewModel(FormCatalog(bundle!));
      await vm.initialize();
      vm.create();
      addTearDown(vm.dispose);
      final node = vm.nodes.firstWhere((n) => n['id'] == 'home');
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => NodeForm(node: node, editor: vm),
                  );
                  if (result != null) vm.updateNode('home', result);
                },
                child: const Text('노드'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('노드'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('node-param-selector')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('node-param-expected')),
        'Changed using form',
      );
      await tester.tap(find.text('노드 적용'));
      await tester.pumpAndSettle();
      final changed = vm.nodes.firstWhere((n) => n['id'] == 'home');
      expect(changed['id'], 'home');
      expect(changed['params']['expected'], 'Changed using form');
      vm.undo();
      expect(
        vm.nodes.firstWhere((n) => n['id'] == 'home')['params']['expected'],
        node['params']['expected'],
      );
    },
  );
}
