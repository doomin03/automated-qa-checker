import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';

void main() {
  final package = Platform.environment['AQA_TEST_ENGINE_ROOT'];
  final manifestPath = Platform.environment['AQA_TEST_ENGINE_MANIFEST'];
  final expectedVersion = Platform.environment['AQA_TEST_ENGINE_VERSION'];
  final expectedSha = Platform.environment['AQA_TEST_ENGINE_SHA'];
  test(
    'isolated public Service PASS FAIL XML delayed assertion and 1000-node results',
    () async {
      expect(package, isNotNull);
      expect(manifestPath, isNotNull);
      expect(expectedVersion, matches(r'^0\.1\.0-alpha\.[1-9][0-9]*$'));
      expect(expectedSha, matches(r'^[a-f0-9]{64}$'));
      final manifest = jsonDecode(
        await File(manifestPath!).readAsString(),
      ) as Map<String, dynamic>;
      expect(manifest['engineVersion'], expectedVersion);
      expect(manifest['sha256'], expectedSha);
      final node = (await Process.run('where.exe', [
        'node.exe',
      ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
      final repo = Directory.current.parent.parent.path;
      final output = await Directory(
        '$repo/artifacts/engine-refactor/$expectedVersion/$expectedSha',
      ).create(recursive: true);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requests = 0;
      server.listen((request) async {
        requests++;
        request.response.headers.contentType = ContentType.html;
        final delayed = request.uri.path == '/delayed';
        request.response.write(
          '<h1 data-testid="greeting">${delayed ? 'Loading' : 'Ready'}</h1>${delayed ? '<script>setTimeout(()=>document.querySelector("h1").textContent="Ready",350)</script>' : ''}',
        );
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));
      final fixture = jsonDecode(
        await File('$package/examples/login.qa.json').readAsString(),
      ) as Map<String, dynamic>;
      final origin = 'http://127.0.0.1:${server.port}';
      Map<String, dynamic> document() {
        final b = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
        b['target']['launchTargets']['login'] = origin;
        b['target']['allowedOrigins'] = [origin];
        b['flow']['nodes'] = [
          {'id': 'start', 'type': 'start'},
          {
            'id': 'open',
            'type': 'action',
            'action': 'launch',
            'params': {'target': 'login'},
          },
          {
            'id': 'check',
            'type': 'assertion',
            'action': 'assertText',
            'timeoutMs': 1500,
            'params': {'selector': 'greeting', 'expected': 'Ready'},
          },
          {'id': 'end', 'type': 'end'},
        ];
        b['flow']['edges'] = [
          {'from': 'start', 'to': 'open'},
          {'from': 'open', 'to': 'check'},
          {'from': 'check', 'to': 'end'},
        ];
        return b;
      }

      final service = LocalEngineCliService(loadManifest: () async => manifest);
      addTearDown(service.dispose);
      final settings = EngineSettings(
        nodePath: node,
        cliPath: '$package/packages/cli/aqa.mjs',
        reportRoot: output.path,
      );
      final records = <Map<String, dynamic>>[];
      Future<Map<String, dynamic>> run(
        String label,
        Map<String, dynamic> b,
        String outcome, {
        String? source,
      }) async {
        final before = requests;
        final watch = Stopwatch()..start();
        final prepared = await service.prepare(
          settings,
          source ?? jsonEncode(b),
        );
        expect(requests, before, reason: 'prepare must not access target');
        final prepareMs = watch.elapsedMilliseconds;
        watch.reset();
        final updates = await service.run(prepared).toList();
        final result = updates.last.result!;
        expect(result['outcome'], outcome);
        expect(result['executed']['engineVersion'], manifest['engineVersion']);
        expect(
          result['executed']['blueprintSnapshotHash'],
          prepared.plan['blueprintSnapshotHash'],
        );
        records.add({
          'case': label,
          'inputFormat': source == null ? 'json' : 'xml',
          'prepareMs': prepareMs,
          'runMs': watch.elapsedMilliseconds,
          'outcome': outcome,
          'reportDirectory': updates.last.reportDirectory,
          'visited': (result['visitedNodes'] as List).length,
          'unvisited': (result['unvisitedNodes'] as List).length,
        });
        await File('${output.path}/service-candidate.json').writeAsString(
          jsonEncode({
            'engineVersion': manifest['engineVersion'],
            'packageSha256': manifest['sha256'],
            'cases': records,
          }),
        );
        return result;
      }

      await run('pass', document(), 'passed');
      final xmlDocument = document();
      final beforeXml = requests;
      final jsonPlan = await service.prepare(settings, jsonEncode(xmlDocument));
      final xml = await service.exportXml(settings, jsonEncode(xmlDocument));
      expect(xml, contains('<blueprint'));
      final xmlPlan = await service.prepare(settings, xml);
      expect(
        xmlPlan.plan['blueprintSnapshotHash'],
        jsonPlan.plan['blueprintSnapshotHash'],
      );
      expect(
        xmlPlan.plan['flowSnapshotHash'],
        jsonPlan.plan['flowSnapshotHash'],
      );
      expect(xmlPlan.plan['blueprint'], jsonPlan.plan['blueprint']);
      expect(
        requests,
        beforeXml,
        reason: 'XML export/import/validate/plan must not execute',
      );
      await File('${output.path}/roundtrip.xml').writeAsString(xml);
      await run('xml-roundtrip', xmlDocument, 'passed', source: xml);
      final fail = document();
      fail['flow']['nodes'][2]['params']['expected'] = 'intentional mismatch';
      fail['flow']['nodes'][2]['timeoutMs'] = 250;
      final failed = await run('assertion-fail', fail, 'failed');
      expect(failed['failure']['nodeId'], 'check');
      final delayed = document();
      delayed['target']['launchTargets']['login'] = '$origin/delayed';
      await run('delayed-350ms-within-1500ms', delayed, 'passed');
      final large = document();
      large['flow']['variables'] = {
        'flag': {'from': 'literal', 'value': true},
      };
      large['flow']['nodes'] = [
        {'id': 'start', 'type': 'start'},
        for (var i = 0; i < 997; i++)
          {
            'id': 'b$i',
            'type': 'branch',
            'condition': {
              'variable': 'flag',
              'operator': 'equals',
              'value': true,
            },
          },
        {'id': 'end', 'type': 'end'},
        {'id': 'other', 'type': 'end'},
      ];
      large['flow']['edges'] = [
        {'from': 'start', 'to': 'b0'},
        for (var i = 0; i < 997; i++) ...[
          {
            'from': 'b$i',
            'to': i == 996 ? 'end' : 'b${i + 1}',
            'label': 'true',
          },
          {'from': 'b$i', 'to': 'other', 'label': 'false'},
        ],
      ];
      final all = await run('1000-nodes-long-visited', large, 'passed');
      expect((all['visitedNodes'] as List).length, 999);
      expect((all['unvisitedNodes'] as List).length, 1);
      large['flow']['variables']['flag']['value'] = false;
      final short = await run('1000-nodes-long-unvisited', large, 'passed');
      expect((short['visitedNodes'] as List).length, 3);
      expect((short['unvisitedNodes'] as List).length, 997);
    },
    skip:
        package == null &&
            manifestPath == null &&
            expectedVersion == null &&
            expectedSha == null
        ? 'Requires explicitly approved isolated Engine candidate environment'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
