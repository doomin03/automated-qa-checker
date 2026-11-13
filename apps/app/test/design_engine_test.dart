import 'desktop_runtime.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/design_baselines/models/reference_input.dart';
import 'package:automated_qa_desktop/features/design_baselines/services/reference_file_service.dart';
import 'package:automated_qa_desktop/features/design_baselines/repositories/reference_repository.dart';
import 'package:automated_qa_desktop/features/design_baselines/view_models/design_view_model.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/repositories/engine_repository.dart';

void main() {
  test('explicit reference/preset authoring uses installed engine with actual visual evidence', () async {
    final root = Directory.current.parent.parent.path;
    final node = (await Process.run('where.exe', [
      'node.exe',
    ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
    final resources = '$root/artifacts/design-reference';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var changed = false, requests = 0, overlay = false;
    server.listen((request) async {
      requests++;
      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<style>body{margin:0;background:${changed ? 'red' : 'white'}}input{box-sizing:border-box;width:100px;height:30px;position:absolute;left:20px;top:20px}</style><input data-testid="entry">${overlay ? '<div style="position:fixed;inset:0;background:gray"></div>' : ''}',
      );
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));
    final origin = 'http://127.0.0.1:${server.port}';
    final fixture = await Process.run(node, [
      '$root/tests/create-design-fixture.mjs',
      origin,
      resources,
    ]);
    expect(fixture.exitCode, 0, reason: fixture.stderr.toString());
    final profile =
        jsonDecode(fixture.stdout.toString()) as Map<String, dynamic>;
    final b =
        jsonDecode(
              await File('assets/engine-contract.json').readAsString(),
            )['example']
            as Map<String, dynamic>;
    b['target']['launchTargets'] = {'page': origin};
    b['target']['allowedOrigins'] = [origin];
    b['selectors']['selectors'] = {
      'entry': {
        'web': {'strategy': 'testId', 'value': 'entry'},
      },
    };
    b.remove('testCase');
    b['flow']['nodes'] = [
      {'id': 'start', 'type': 'start'},
      {
        'id': 'open',
        'type': 'action',
        'action': 'launch',
        'params': {'target': 'page'},
      },
      {'id': 'end', 'type': 'end'},
    ];
    b['flow']['edges'] = [
      {'from': 'start', 'to': 'open'},
      {'from': 'open', 'to': 'end'},
    ];
    final settings = EngineSettings(
      nodePath: node,
      cliPath:
          '${desktopPackageRoot(root)}/packages/cli/aqa.mjs',
      reportRoot: '$root/artifacts/flutter-design',
      referenceRoot: resources,
    );
    final manifest = jsonDecode(
      await File('assets/desktop-engine-runtime.json').readAsString(),
    ) as Map<String, dynamic>;
    final service = LocalEngineCliService(loadManifest: () async => manifest);
    addTearDown(service.dispose);
    final files = ReferenceFileService();
    final vm = DesignViewModel(
      ReferenceRepository(files),
      EngineRepository(service),
    );
    addTearDown(vm.dispose);
    ReferenceInput input({
      String png = 'baseline.png',
      String id = 'design-v1',
    }) => ReferenceInput(
      root: resources,
      id: id,
      pngPath: png,
      measurementsPath: 'measurements.json',
      profileJson: jsonEncode(profile),
      channelTolerance: 0,
      maxDiffRatio: 0,
    );
    final count = requests;
    final xml = await vm.attach(settings, jsonEncode(b), input());
    expect(xml, isNotNull, reason: vm.error);
    expect(requests, count);
    final prepared = await service.prepare(settings, xml!);
    final pass = await service.run(prepared).last;
    expect(pass.result!['outcome'], 'passed');
    expect(pass.checks.length, 2);
    expect(pass.images, isNotEmpty);
    final original = await File('$resources/baseline.png').readAsBytes();
    changed = true;
    final failed = await service.run(await service.prepare(settings, xml)).last;
    expect(failed.result!['outcome'], 'failed');
    expect(failed.checks.first['verdict'], 'failed');
    expect(
      failed.checks.first['artifactRefs'].map((r) => r['role']),
      contains('diff'),
    );
    expect(await File('$resources/baseline.png').readAsBytes(), original);
    expect(await vm.attach(settings, xml, input()), isNull);
    expect(vm.error, contains('덮어쓰지'));
    await expectLater(
      files.read(input(png: '../outside.png')),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      files.read(input(png: 'missing.png')),
      throwsA(isA<FileSystemException>()),
    );
    changed = false;
    final preset = await service.expandPreset(settings, 'web-input', '1.0.0', {
      'id': 'input-preset',
      'target': b['target'],
      'selectors': b['selectors'],
      'launch': 'page',
      'selector': 'entry',
      'value': 'typed by preset',
    });
    final presetResult = await service
        .run(await service.prepare(settings, preset))
        .last;
    expect(presetResult.result!['outcome'], 'passed');
    expect(presetResult.checks, isNotEmpty);
    overlay = true;
    final obstructed = await service
        .run(await service.prepare(settings, preset))
        .last;
    expect(obstructed.result!['outcome'], 'failed');
    overlay = false;
    final historyTarget =
        jsonDecode(jsonEncode(b['target'])) as Map<String, dynamic>;
    historyTarget['launchTargets'] = {'from': '$origin/a', 'to': '$origin/b'};
    final history = await service.expandPreset(
      settings,
      'web-history-back',
      '1.0.0',
      {
        'id': 'history',
        'target': historyTarget,
        'selectors': b['selectors'],
        'from': 'from',
        'to': 'to',
        'expectedUrl': '$origin/a',
        'expectedSelector': 'entry',
      },
    );
    final back = await service
        .run(await service.prepare(settings, history))
        .last;
    expect(back.result!['outcome'], 'passed');
    final mismatch = jsonDecode(
      jsonEncode(prepared.plan['blueprint']),
    ) as Map<String, dynamic>;
    mismatch['target']['profile']['browserVersion'] =
        'different-explicit-version';
    mismatch['references'][0]['profile']['browserVersion'] =
        'different-explicit-version';
    final incomparable = await service
        .run(await service.prepare(settings, jsonEncode(mismatch)))
        .last;
    expect(incomparable.result!['outcome'], 'blocked');
    final badHash = jsonDecode(
      jsonEncode(prepared.plan['blueprint']),
    ) as Map<String, dynamic>;
    badHash['references'][0]['images'][0]['sha256'] = '0' * 64;
    await expectLater(
      service.prepare(settings, jsonEncode(badHash)),
      throwsA(isA<EngineException>()),
    );
    await expectLater(
      service.expandPreset(settings, 'web-history-back', '1.0.0', {
        'id': 'missing',
      }),
      throwsA(isA<EngineException>()),
    );
    await File('$root/artifacts/flutter-design/verification.json')
        .writeAsString(
          jsonEncode({
            'engineVersion': manifest['engineVersion'],
            'pass': pass.reportDirectory,
            'fail': failed.reportDirectory,
            'preset': presetResult.reportDirectory,
            'syntheticOverlay': obstructed.reportDirectory,
            'webHistory': back.reportDirectory,
            'profileMismatch': incomparable.reportDirectory,
            'nonExecutingAuthoring': true,
            'baselineUnchanged': true,
          }),
        );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
