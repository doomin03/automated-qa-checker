import 'desktop_runtime.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/repositories/engine_repository.dart';
import 'package:automated_qa_desktop/features/run_review/view_models/run_view_model.dart';

void main() {
  test('public authoring expansion and capture execute with source-bound iteration labels', () async {
    final root = Directory.current.parent.parent.path,
        node = (await Process.run('where.exe', [
          'node.exe',
        ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requests = 0;
    server.listen((r) async {
      requests++;
      r.response.headers.contentType = ContentType.html;
      r.response.write(
        '<h1 data-testid="greeting">Ready</h1><input data-testid="destination">',
      );
      await r.response.close();
    });
    addTearDown(() => server.close(force: true));
    final bundle = jsonDecode(
          await File('assets/engine-contract.json').readAsString(),
        ),
        b = bundle['example'] as Map<String, dynamic>;
    final origin = 'http://127.0.0.1:${server.port}';
    b.remove('testCase');
    b['target']['launchTargets'] = {'page': origin};
    b['target']['allowedOrigins'] = [origin];
    b['selectors']['selectors'] = {
      'greeting': {
        'web': {'strategy': 'testId', 'value': 'greeting'},
      },
      'destination': {
        'web': {'strategy': 'testId', 'value': 'destination'},
      },
    };
    b['flow']['variables'] = {
      'observed': {'from': 'capture', 'public': true},
    };
    b['flow']['nodes'] = [
      {'id': 'start', 'type': 'start'},
      {
        'id': 'open',
        'type': 'action',
        'action': 'launch',
        'params': {'target': 'page'},
      },
      {
        'id': 'checks',
        'type': 'repeat',
        'count': 3,
        'steps': [
          {
            'id': 'visible',
            'type': 'assertion',
            'action': 'assertText',
            'params': {'selector': 'greeting', 'expected': 'Ready'},
          },
        ],
      },
      {
        'id': 'capture',
        'type': 'action',
        'action': 'captureText',
        'params': {'selector': 'greeting', 'variable': 'observed'},
      },
      {
        'id': 'input',
        'type': 'action',
        'action': 'input',
        'params': {'selector': 'destination', 'valueRef': 'observed'},
      },
      {
        'id': 'checkValue',
        'type': 'assertion',
        'action': 'assertValue',
        'params': {'selector': 'destination', 'expectedRef': 'observed'},
      },
      {'id': 'end', 'type': 'end'},
    ];
    final ids = [
      'start',
      'open',
      'checks',
      'capture',
      'input',
      'checkValue',
      'end',
    ];
    b['flow']['edges'] = [
      for (var i = 0; i < ids.length - 1; i++)
        {'from': ids[i], 'to': ids[i + 1]},
    ];
    final source = jsonEncode({
      'schemaVersion': 'qa.authoring/v1',
      'blueprint': b,
    });
    final manifest = jsonDecode(
      await File('assets/desktop-engine-runtime.json').readAsString(),
    ) as Map<String, dynamic>;
    final service = LocalEngineCliService(loadManifest: () async => manifest),
        settings = EngineSettings(
          nodePath: node,
          cliPath:
              '${desktopPackageRoot(root)}/packages/cli/aqa.mjs',
          reportRoot: '$root/artifacts/flutter-authoring',
        );
    final vm = RunViewModel(EngineRepository(service));
    addTearDown(service.dispose);
    addTearDown(vm.dispose);
    final xml = await vm.expandAuthoring(settings, source);
    expect(xml, isNotNull, reason: vm.error);
    expect(requests, 0);
    await vm.validate(settings, xml!);
    expect(vm.status, 'validated', reason: vm.error);
    final repeated = (vm.expansion!.sourceMap['nodes'] as List)
        .where((n) => n['iteration'] != null)
        .toList();
    expect(repeated.length, 3);
    expect(vm.iterationLabel(repeated[1]['nodeId'], xml), contains('2회차'));
    expect(vm.iterationLabel(repeated[1]['nodeId'], '$xml '), isNull);
    await vm.run(settings, xml);
    expect(vm.status, 'passed', reason: vm.error);
    final invalid = jsonDecode(source);
    invalid['blueprint']['flow']['nodes'][2]['count'] = 101;
    expect(await vm.expandAuthoring(settings, jsonEncode(invalid)), isNull);
    final directory = Directory('$root/artifacts/flutter-authoring');
    await directory.create(recursive: true);
    await File('${directory.path}/verification.json').writeAsString(
      jsonEncode({
        'engineVersion': manifest['engineVersion'],
        'resultDirectory': vm.reportDirectory,
        'repeatNodes': 3,
        'publicCapturePassed': true,
        'editedSourceMapDisabled': true,
        'expandDidNotExecute': true,
      }),
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
