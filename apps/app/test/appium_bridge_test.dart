import 'desktop_runtime.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';

void main() {
  test('native config is separate and actual CLI reaches local protocol fixture, not a real device', () async {
    final root = Directory.current.parent.parent.path;
    final node = (await Process.run('where.exe', [
      'node.exe',
    ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final calls = <String>[];
    server.listen((r) async {
      calls.add('${r.method} ${r.uri.path}');
      await r.drain<void>();
      r.response.headers.contentType = ContentType.json;
      r.response.write(
        jsonEncode({
          'value': r.uri.path == '/session'
              ? {'sessionId': 'fixture-session', 'capabilities': {}}
              : null,
        }),
      );
      await r.response.close();
    });
    addTearDown(() => server.close(force: true));
    final reports = '$root/artifacts/flutter-appium';
    await Directory(reports).create(recursive: true);
    final config = File('$reports/appium.local.json');
    await config.writeAsString(
      jsonEncode({
        'endpoint': 'http://127.0.0.1:${server.port}',
        'capabilities': {
          'platformName': 'Android',
          'appium:automationName': 'UiAutomator2',
          'appium:udid': 'fixture-device',
          'appium:deviceName': 'protocol-fixture',
        },
      }),
    );
    final b =
        jsonDecode(
              await File('assets/engine-contract.json').readAsString(),
            )['example']
            as Map<String, dynamic>;
    b.remove('testCase');
    b['target']['platform'] = 'android';
    b['target']['launchTargets'] = {'app': 'org.example.qa'};
    b['target'].remove('allowedOrigins');
    b['selectors']['selectors'] = {};
    b['flow']['nodes'] = [
      {'id': 'start', 'type': 'start'},
      {
        'id': 'open',
        'type': 'action',
        'action': 'launch',
        'params': {'target': 'app'},
      },
      {'id': 'end', 'type': 'end'},
    ];
    b['flow']['edges'] = [
      {'from': 'start', 'to': 'open'},
      {'from': 'open', 'to': 'end'},
    ];
    final manifest = jsonDecode(
      await File('assets/desktop-engine-runtime.json').readAsString(),
    ) as Map<String, dynamic>;
    final service = LocalEngineCliService(loadManifest: () async => manifest);
    addTearDown(service.dispose);
    EngineSettings settings(String path) => EngineSettings(
      nodePath: node,
      cliPath:
          '${desktopPackageRoot(root)}/packages/cli/aqa.mjs',
      reportRoot: reports,
      appiumConfig: path,
    );
    final missing = await service.prepare(settings(''), jsonEncode(b));
    expect(calls, isEmpty);
    await expectLater(
      service.run(missing).last,
      throwsA(isA<EngineException>()),
    );
    expect(calls, isEmpty);
    final prepared = await service.prepare(
      settings(config.path),
      jsonEncode(b),
    );
    expect(calls, isEmpty);
    final result = await service.run(prepared).last;
    expect(result.result!['outcome'], 'passed');
    expect(
      calls,
      contains('POST /session/fixture-session/appium/device/activate_app'),
    );
    expect(calls, contains('DELETE /session/fixture-session'));
    expect(jsonEncode(prepared.plan), isNot(contains('fixture-device')));
    await File('$reports/verification.json').writeAsString(
      jsonEncode({
        'outcome': result.result!['outcome'],
        'reportDirectory': result.reportDirectory,
        'transport': 'local W3C protocol fixture',
        'realDeviceVerified': false,
        'nonExecutingValidation': true,
        'calls': calls,
      }),
    );
  }, timeout: const Timeout(Duration(minutes: 1)));
}
