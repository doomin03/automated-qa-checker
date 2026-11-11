import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/xml_blocks/models/xml_block_document.dart';
import 'package:automated_qa_desktop/features/xml_blocks/services/xml_block_compiler.dart';
import 'package:automated_qa_desktop/features/xml_blocks/repositories/xml_block_repository.dart';

void main() {
  final blueprint = Map<String, dynamic>.from(
    jsonDecode(
      File('assets/desktop-engine-contract.json').readAsStringSync(),
    )['example'],
  );
  XmlBlockAsset source(String id, Map<String, dynamic> b) => XmlBlockAsset(
    id: id,
    name: '$id.xml',
    path: 'fixtures/$id.xml',
    xml: '<fixture id="$id"/>',
    blueprint: b,
  );
  test(
    'same XML instances namespace all nodes and preserve deterministic mapping',
    () {
      final a = source('a', blueprint),
          nodes = [
            const XmlBlockInstance('one', 'a', 0, 0),
            const XmlBlockInstance('two', 'a', 300, 0),
          ],
          edges = [const XmlBlockLink('one', 'two')];
      final first = XmlBlockCompiler().compile([a], nodes, edges),
          second = XmlBlockCompiler().compile([a], nodes, edges);
      expect(jsonEncode(first.blueprint), jsonEncode(second.blueprint));
      final ids = (first.blueprint['flow']['nodes'] as List)
          .map((n) => n['id'])
          .toList();
      expect(ids.toSet().length, ids.length);
      expect(first.sourceMap.values.map((m) => m['instanceId']).toSet(), {
        'one',
        'two',
      });
      expect(
        first.sourceMap.values.every((m) => m['sourceHash'] == a.hash),
        true,
      );
      expect(first.blueprint['target'], blueprint['target']);
    },
  );
  test('disconnected and cyclic outer graphs fail before execution', () {
    final a = source('a', blueprint),
        nodes = [
          const XmlBlockInstance('one', 'a', 0, 0),
          const XmlBlockInstance('two', 'a', 300, 0),
        ];
    expect(
      () => XmlBlockCompiler().compile([a], nodes, []),
      throwsA(isA<BlockDiagnostic>()),
    );
    expect(
      () => XmlBlockCompiler().compile(
        [a],
        nodes,
        [const XmlBlockLink('one', 'two'), const XmlBlockLink('two', 'one')],
      ),
      throwsA(isA<BlockDiagnostic>()),
    );
  });
  test(
    'target mismatch and unsupported source remain rejected without mutation',
    () {
      final different = blockCopy(blueprint);
      different['target']['allowedOrigins'] = ['http://other.local'];
      final a = source('a', blueprint), b = source('b', different);
      expect(
        () => XmlBlockCompiler().compile(
          [a, b],
          [
            const XmlBlockInstance('one', 'a', 0, 0),
            const XmlBlockInstance('two', 'b', 0, 0),
          ],
          [const XmlBlockLink('one', 'two')],
        ),
        throwsA(isA<BlockDiagnostic>()),
      );
      final unsupported = blockCopy(blueprint);
      unsupported['references'] = {'image': {}};
      expect(
        () => XmlBlockCompiler.checkAsset(source('bad', unsupported)),
        throwsA(isA<BlockDiagnostic>()),
      );
      expect(a.blueprint, blueprint);
    },
  );
  test(
    'sidecar save/reopen mode, conflict and corruption preserve prior bytes',
    () async {
      final dir = await Directory.systemTemp.createTemp('qa-block-test-');
      addTearDown(() => dir.delete(recursive: true));
      final repository = XmlBlockRepository(),
          data = {'mode': 'direct', 'assets': [], 'instances': [], 'links': []};
      await repository.write(dir.path, 'project/qa', data, 0);
      expect(
        (await repository.read(dir.path, 'project/qa'))!['mode'],
        'direct',
      );
      await expectLater(
        repository.write(dir.path, 'project/qa', {
          ...data,
          'mode': 'composition',
        }, 0),
        throwsFormatException,
      );
      expect(
        (await repository.read(dir.path, 'project/qa'))!['mode'],
        'direct',
      );
      final file = File(
        '${dir.path}/xml-blocks-v1/${blockHash('project/qa')}.json',
      );
      await file.writeAsString('{broken');
      await expectLater(
        repository.write(dir.path, 'project/qa', data, 1),
        throwsFormatException,
      );
      expect(await file.readAsString(), '{broken');
    },
  );
}
