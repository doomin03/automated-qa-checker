import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/run_review/services/portable_runtime_service.dart';

void main() {
  final root = Platform.environment['QA_PORTABLE_TEST_ROOT'];
  test(
    'actual verified Node performance and changed payload fail closed',
    () async {
      final repo = Directory.current.parent.parent.path;
      final manifest = await File(
        '$repo/apps/app/assets/desktop-portable-runtime.json',
      ).readAsString();
      final service = PortableRuntimeService(
        executableDirectory: root!,
        required: true,
        loadManifest: () async => manifest,
      );
      final observations = <Map<String, dynamic>>[];
      for (final name in ['first', 'cached']) {
        await service.verify();
        observations.add({
          'name': name,
          'totalMs': service.lastVerificationMs,
          'nodeMs': service.lastNodeVerificationMs,
          ...service.lastNativeTiming,
        });
      }
      final license = File('$root/runtime/node/LICENSE');
      final original = await license.readAsBytes();
      try {
        final changed = [...original];
        changed[0] ^= 1;
        await license.writeAsBytes(changed, flush: true);
        await expectLater(service.verify(), throwsFormatException);
      } finally {
        await license.writeAsBytes(original, flush: true);
      }
      await service.verify();
      Future<void> junction(
        String node,
        String path,
        String target,
        bool create,
      ) async {
        final result = await Process.run(
          node,
          [
            '--input-type=module',
            '-e',
            create
                ? "import{symlinkSync}from'node:fs';symlinkSync(process.argv[2],process.argv[1],'junction');"
                : "import{unlinkSync}from'node:fs';unlinkSync(process.argv[1]);",
            path,
            target,
          ],
          includeParentEnvironment: false,
          environment: {'SystemRoot': Platform.environment['SystemRoot']!},
        );
        expect(result.exitCode, 0, reason: result.stderr.toString());
      }

      final runtime = Directory('$root/runtime');
      final moved = await runtime.rename('$root/runtime-moved');
      try {
        await junction(
          '${moved.path}/node/node.exe',
          runtime.path,
          moved.path,
          true,
        );
        await expectLater(service.verify(), throwsFormatException);
      } finally {
        await junction(
          '${moved.path}/node/node.exe',
          runtime.path,
          moved.path,
          false,
        );
        await moved.rename(runtime.path);
      }
      final outside = await Directory('$root/outside-fixture').create();
      final nested = '$root/runtime/nested-junction';
      try {
        await junction(
          '$root/runtime/node/node.exe',
          nested,
          outside.path,
          true,
        );
        await expectLater(service.verify(), throwsFormatException);
      } finally {
        await junction(
          '$root/runtime/node/node.exe',
          nested,
          outside.path,
          false,
        );
        await outside.delete();
      }
      await service.verify();
      final out = File(
        '$repo/artifacts/portable-runtime/${Platform.environment['QA_PORTABLE_PERF_LABEL'] ?? 'verifier-performance'}.json',
      );
      await out.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'root': root,
          'observations': observations,
          'sameSizeTamperRejected': true,
          'restoredVerified': true,
          'runtimeRootJunctionRejected': true,
          'nestedJunctionRejected': true,
        }),
      );
    },
    skip: root == null ? 'Set QA_PORTABLE_TEST_ROOT' : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
