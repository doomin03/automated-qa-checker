import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/run_review/services/portable_runtime_service.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';

class IsolatedPortable extends PortableRuntimeService {
  IsolatedPortable(String path, String manifest)
    : super(
        executableDirectory: path,
        required: true,
        loadManifest: () async => manifest,
      );
  @override
  Future<Map<String, String>?> environment(String cliPath) async {
    final value = await super.environment(cliPath);
    return value == null
        ? null
        : {
            ...value,
            'PATH':
                '${Platform.environment['SystemRoot']}\\System32;${Platform.environment['SystemRoot']}',
            'PLAYWRIGHT_SKIP_BROWSER_GC': '1',
          };
  }
}

void main() {
  final bundle = Platform.environment['QA_PORTABLE_TEST_ROOT'];
  test(
    'relocated portable public Service PASS FAIL cancel without developer PATH/cache',
    () async {
      final repo = Directory.current.parent.parent.path;
      final output = await Directory(
        '$repo/artifacts/portable-runtime/${Platform.environment['QA_PORTABLE_TEST_LABEL'] ?? 'relocation'}',
      ).create(recursive: true);
      final manifest = jsonDecode(
        await File('$repo/apps/app/assets/desktop-engine-runtime.json')
            .readAsString(),
      ) as Map<String, dynamic>;
      final receipt = await File(
        '$repo/apps/app/assets/desktop-portable-runtime.json',
      ).readAsString();
      final portable = IsolatedPortable(bundle!, receipt);
      final watch = Stopwatch()..start();
      final paths = (await portable.verify())!;
      final verifyMs = watch.elapsedMilliseconds;
      final nodeVerifyMs = portable.lastNodeVerificationMs;
      final settings = EngineSettings(
        nodePath: paths['nodePath']!,
        cliPath: paths['cliPath']!,
        reportRoot: output.path,
      );
      final env = (await portable.environment(settings.cliPath))!;
      expect(env['PATH'], isNot(contains('nvm')));
      expect(env['PLAYWRIGHT_BROWSERS_PATH'], startsWith(bundle));
      final nodeVersion = await Process.run(settings.nodePath, [
        '--version',
      ], environment: env);
      expect(nodeVersion.exitCode, 0);
      expect(nodeVersion.stdout.toString().trim(), 'v24.18.0');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.headers.contentType = ContentType.html;
        request.response.write('<h1 data-testid="greeting">Ready</h1>');
        await request.response.close();
      });
      final service = LocalEngineCliService(
        loadManifest: () async => manifest,
        portableRuntime: portable,
      );
      addTearDown(() async {
        service.dispose();
        await server.close(force: true);
      });
      final package = File(settings.cliPath).parent.parent.parent.path;
      final example = jsonDecode(
        await File('$package/examples/login.qa.json').readAsString(),
      ) as Map<String, dynamic>;
      Map<String, dynamic> document(String expected, int timeout) {
        final b = jsonDecode(jsonEncode(example)) as Map<String, dynamic>;
        final origin = 'http://127.0.0.1:${server.port}';
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
            'timeoutMs': timeout,
            'params': {'selector': 'greeting', 'expected': expected},
          },
          {
            'id': 'capture',
            'type': 'action',
            'action': 'screenshot',
            'params': {},
          },
          {'id': 'end', 'type': 'end'},
        ];
        b['flow']['edges'] = [
          {'from': 'start', 'to': 'open'},
          {'from': 'open', 'to': 'check'},
          {'from': 'check', 'to': 'capture'},
          {'from': 'capture', 'to': 'end'},
        ];
        return b;
      }

      final cases = <Map<String, dynamic>>[];
      for (final mode in ['passed', 'failed', 'cancelled']) {
        final input = await service.prepare(
          settings,
          jsonEncode(
            document(
              mode == 'passed' ? 'Ready' : 'Mismatch',
              mode == 'cancelled' ? 15000 : 300,
            ),
          ),
        );
        var events = 0;
        EngineUpdate? last;
        await for (final update in service.run(input)) {
          if (update.event != null) events++;
          if (mode == 'cancelled' &&
              update.event?['type'] == 'step.started' &&
              update.event?['nodeId'] == 'check') {
            await service.cancel();
          }
          last = update;
        }
        expect(last!.result!['outcome'], mode);
        expect(
          last.result!['executed']['blueprintSnapshotHash'],
          input.plan['blueprintSnapshotHash'],
        );
        if (mode != 'cancelled') expect(last.images, isNotEmpty);
        cases.add({
          'outcome': mode,
          'reportDirectory': last.reportDirectory,
          'events': events,
          'images': last.images.length,
          'snapshotHash': input.plan['blueprintSnapshotHash'],
        });
      }
      await File('${output.path}/verification.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'bundle': bundle,
          'settings': paths,
          'childEnvironment': env,
          'nodeVersion': nodeVersion.stdout.toString().trim(),
          'engineVersion': manifest['engineVersion'],
          'archiveSha256': manifest['sha256'],
          'initialVerifyMs': verifyMs,
          'initialNodeVerifyMs': nodeVerifyMs,
          'cases': cases,
          'physicalFreshPcTested': false,
        }),
      );
    },
    skip: bundle == null
        ? 'Set QA_PORTABLE_TEST_ROOT to a relocated verified runtime'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
