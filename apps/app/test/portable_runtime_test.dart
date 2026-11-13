import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/run_review/services/portable_runtime_service.dart';
import 'package:automated_qa_desktop/features/run_review/view_models/engine_settings_view_model.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';

class DelayedPortable extends PortableRuntimeService {
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<Map<String, String>?> environment(String cliPath) async {
    entered.complete();
    await release.future;
    return null;
  }
}

void main() {
  test('cancel/dispose during portable verification never spawns a late CLI', () async {
    final root = await Directory.systemTemp.createTemp('portable-cancel-');
    try {
      final node = (await Process.run('where.exe', [
        'node.exe',
      ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
      final marker = File('${root.path}/spawned');
      final cli = File('${root.path}/packages/cli/aqa.mjs');
      await cli.parent.create(recursive: true);
      await cli.writeAsString(
        'import {writeFileSync} from "node:fs";writeFileSync(${jsonEncode(marker.path)},"spawned");console.log(JSON.stringify({engineVersion:"test"}));',
      );
      final manifest = {
        'files': {
          'packages/cli/aqa.mjs': sha256
              .convert(await cli.readAsBytes())
              .toString(),
        },
        'entrypoint': 'packages/cli/aqa.mjs',
        'engineVersion': 'test',
      };
      for (final dispose in [false, true]) {
        final gate = DelayedPortable();
        final service = LocalEngineCliService(
          loadManifest: () async => manifest,
          portableRuntime: gate,
        );
        final settings = EngineSettings(
          nodePath: node,
          cliPath: cli.path,
          reportRoot: root.path,
        );
        final future = dispose
            ? service.capabilities(settings, 'web')
            : service
                  .run(
                    PreparedScenario(
                      settings: settings,
                      inputPath: 'unused',
                      reportRoot: root.path,
                      plan: {},
                    ),
                  )
                  .toList();
        final failure = expectLater(future, throwsA(isA<EngineException>()));
        await gate.entered.future;
        if (dispose) {
          service.dispose();
        } else {
          await service.cancel();
        }
        gate.release.complete();
        await failure;
        expect(await marker.exists(), isFalse);
        service.dispose();
      }
    } finally {
      await root.delete(recursive: true);
    }
  });
  test(
    'portable integrity, cache invalidation and external environment isolation',
    () async {
      final root = await Directory.systemTemp.createTemp('portable 한글 path ');
      try {
        final files = <String, dynamic>{};
        for (final path in [
          'runtime/node/node.exe',
          'runtime/engine/aqa.mjs',
          'runtime/browsers/chrome.exe',
        ]) {
          final file = File('${root.path}/$path');
          await file.parent.create(recursive: true);
          await file.writeAsString('original');
          files[path] = {
            'size': 8,
            'sha256': sha256.convert(utf8.encode('original')).toString(),
          };
        }
        final manifest = jsonEncode({
          'schemaVersion': 'qa.desktopPortable/v1',
          'files': files,
          'nodePath': 'runtime/node/node.exe',
          'cliPath': 'runtime/engine/aqa.mjs',
          'browserRoot': 'runtime/browsers',
        });
        final receipt = File('${root.path}/portable-runtime.json');
        await receipt.writeAsString(manifest);
        final service = PortableRuntimeService(
          executableDirectory: root.path,
          nativeVerification: false,
          required: true,
          loadManifest: () async => manifest,
        );
        final first = await service.verify();
        expect(first!['nodePath'], contains('portable 한글 path'));
        expect(
          (await service.environment(
            first['cliPath']!,
          ))!['PLAYWRIGHT_BROWSERS_PATH'],
          first['browserRoot'],
        );
        expect(await service.environment('${root.path}/external.mjs'), isNull);
        await service.verify(); // same inventory can reuse content hashes
        await File('${root.path}/runtime/node/node.exe')
            .writeAsString('modified');
        await expectLater(service.verify(), throwsFormatException);
        await File('${root.path}/runtime/node/node.exe')
            .writeAsString('original');
        await receipt.writeAsString('{}');
        await expectLater(service.verify(), throwsFormatException);
        await receipt.delete();
        await expectLater(service.verify(), throwsFormatException);
        expect(await service.environment('${root.path}/external.mjs'), isNull);
        final dev = PortableRuntimeService(
          executableDirectory: root.path,
          loadManifest: () async => throw StateError('must not load'),
        );
        expect(await dev.verify(), isNull);
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
  test(
    'automatic defaults relocate; explicit and legacy paths remain preserved',
    () {
      final vm = EngineSettingsViewModel();
      final old = {
        'nodePath': 'C:/old/node.exe',
        'cliPath': 'C:/old/aqa.mjs',
        'reportRoot': 'C:/reports',
      };
      vm.restore(old, {});
      expect(vm.usesAutomaticRuntime, isTrue);
      final saved = {...old, ...vm.runtimeProvenance};
      final next = {
        'nodePath': 'D:/새 배포/node.exe',
        'cliPath': 'D:/새 배포/aqa.mjs',
        'reportRoot': 'D:/reports',
      };
      vm.restore(next, saved);
      expect(vm.value.nodePath, next['nodePath']);
      expect(vm.value.reportRoot, old['reportRoot']);
      vm.update(vm.value.copyWith(cliPath: 'C:/custom/aqa.mjs'));
      expect(vm.usesAutomaticRuntime, isFalse);
      vm.restore(next, {
        'nodePath': old['nodePath']!,
        'cliPath': 'C:/custom/aqa.mjs',
        ...vm.runtimeProvenance,
      });
      expect(vm.value.cliPath, 'C:/custom/aqa.mjs');
      vm.restore(next, old); // no historical provenance: never infer intent
      expect(vm.value.nodePath, old['nodePath']);
      expect(vm.usesAutomaticRuntime, isFalse);
      vm.useDefaults();
      expect(vm.value.nodePath, next['nodePath']);
      expect(vm.usesAutomaticRuntime, isTrue);
      vm.dispose();
    },
  );
}
