import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/run_review/services/cli_process.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';

void main() {
  late String node;
  late Directory root;
  const policy = CliProcessPolicy(
    commandTimeout: Duration(seconds: 3),
    runTimeout: Duration(seconds: 3),
    cleanupTimeout: Duration(milliseconds: 400),
    cancelGrace: Duration(milliseconds: 250),
  );
  setUpAll(() async {
    node = (await Process.run('where.exe', [
      'node.exe',
    ])).stdout.toString().trim().split(RegExp(r'\r?\n')).first;
    root = await Directory(
      '${Directory.current.parent.parent.path}/artifacts/service-audit',
    ).create(recursive: true);
  });
  Future<File> script(String code) async {
    final dir = await root.createTemp('transport-');
    return File('${dir.path}/child.mjs')..writeAsStringSync(code);
  }

  Future<CliProcess> launch(
    String code, {
    CliProcessPolicy limits = policy,
    bool gracefulStop = false,
  }) async {
    final file = await script(code);
    final child = await CliProcess.start(
      node,
      [file.path],
      policy: limits,
      timeout: limits.commandTimeout,
      gracefulStop: gracefulStop,
    );
    addTearDown(child.stop);
    return child;
  }

  test('run stop lets a cooperative child clean up its descendant', () async {
    for (final mode in ['unsubscribe', 'watchdog', 'overflow']) {
      final dir = await root.createTemp('descendant-');
      final marker = File('${dir.path}/cleanup');
      final pid = File('${dir.path}/child.pid');
      final child = await launch(
        '''
import {spawn} from 'node:child_process';import {writeFileSync} from 'node:fs';
const child=spawn(process.execPath,['-e','setInterval(()=>{},1000)'],{stdio:'ignore',windowsHide:true});
writeFileSync(${jsonEncode(pid.path)},String(child.pid));
process.stdin.once('data',()=>{child.once('exit',()=>{writeFileSync(${jsonEncode(marker.path)},'confirmed');process.exit(0);});child.kill();});
process.stdout.write('ready');
if('$mode'==='overflow')setTimeout(()=>process.stdout.write('x'.repeat(65536)),60);
''',
        gracefulStop: true,
        limits: const CliProcessPolicy(
          commandTimeout: Duration(milliseconds: 500),
          cancelGrace: Duration(seconds: 1),
          maxStdout: 32768,
        ),
      );
      final ready = Completer<void>();
      final sub = child.stdout.listen((_) {
        if (!ready.isCompleted) ready.complete();
      });
      await ready.future;
      if (mode == 'unsubscribe') await sub.cancel();
      await child.done.timeout(const Duration(seconds: 3));
      expect(await marker.readAsString(), 'confirmed');
      final childPid = int.parse(await pid.readAsString());
      final check = await Process.run(node, [
        '-e',
        'try{process.kill($childPid,0);process.exit(1)}catch{process.exit(0)}',
      ]);
      expect(check.exitCode, 0);
      expect(child.exitCode, 0);
      if (mode != 'unsubscribe') expect(child.failure, isNotNull);
      await sub.cancel();
    }
  });

  test(
    'paused UI does not stop output drain or cancel; cancel sent once',
    () async {
      final dir = await root.createTemp('paused-');
      final marker = File('${dir.path}/drained');
      final cancelled = File('${dir.path}/cancelled');
      final child = await launch('''
import {writeFileSync} from 'node:fs';
let count=0;process.stdin.setEncoding('utf8');
process.stdin.on('data',text=>{count+=text.trim().split('\\n').length;writeFileSync(${jsonEncode(cancelled.path)},String(count));process.exitCode=5;process.stdin.destroy();});
process.stdout.write('first');
setTimeout(()=>{const done=()=>writeFileSync(${jsonEncode(marker.path)},'done');if(process.stdout.write('x'.repeat(3*1024*1024)))done();else process.stdout.once('drain',done);},60);
''');
      final first = Completer<void>();
      var size = 0;
      late StreamSubscription<List<int>> sub;
      sub = child.stdout.listen((bytes) {
        size += bytes.length;
        if (!first.isCompleted) {
          sub.pause();
          first.complete();
        }
      });
      await first.future;
      for (var i = 0; i < 40 && !await marker.exists(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      expect(
        await marker.exists(),
        isTrue,
        reason: 'OS pipe must drain while UI pauses',
      );
      await child.cancel(controlStdin: true);
      await child.cancel(controlStdin: true);
      await child.done.timeout(const Duration(seconds: 2));
      child.check();
      expect(child.exitCode, 5);
      expect(await cancelled.readAsString(), '1');
      final consumed = sub.asFuture<void>();
      sub.resume();
      await consumed;
      expect(size, 3 * 1024 * 1024 + 5);
    },
  );

  for (final channel in ['stdout', 'stderr']) {
    test('$channel overflow aborts child while UI is paused', () async {
      final child = await launch(
        "process.$channel.write('x'.repeat(131072));setInterval(()=>{},1000);",
        limits: const CliProcessPolicy(maxStdout: 32768, maxStderr: 32768),
      );
      final sub = child.stdout.listen((_) {});
      sub.pause();
      await child.done.timeout(const Duration(seconds: 3));
      expect(() => child.check(), throwsA(isA<EngineException>()));
      expect(child.failure.toString(), contains(channel));
      expect(child.exitCode, isNotNull);
      await sub.cancel();
    });
  }

  test(
    'deadline covers lifetime; unresponsive cancellation has bounded fallback',
    () async {
      final hung = await launch(
        "setInterval(()=>{},1000);",
        limits: const CliProcessPolicy(
          commandTimeout: Duration(milliseconds: 200),
        ),
      );
      await hung.stdout.drain<void>();
      await hung.done;
      expect(hung.failure.toString(), contains('초과'));
      expect(hung.exitCode, isNotNull);
      final cancel = await launch(
        "process.stdin.resume();setInterval(()=>{},1000);",
      );
      final drain = cancel.stdout.drain<void>();
      await cancel.cancel(controlStdin: true);
      await cancel.done.timeout(const Duration(seconds: 2));
      await drain;
      expect(cancel.failure.toString(), contains('정상 취소가 아닙니다'));
      expect(cancel.exitCode, isNotNull);
    },
  );

  test('subscription cancellation stops its directly owned child', () async {
    final child = await launch(
      "setInterval(()=>process.stdout.write('tick'),20);",
    );
    final first = Completer<void>();
    final sub = child.stdout.listen((_) {
      if (!first.isCompleted) first.complete();
    });
    await first.future;
    await sub.cancel();
    await child.done;
    expect(child.exitCode, isNotNull);
  });

  test(
    'service rejects excessive diagnostics and sanitizes malformed bytes/JSON',
    () async {
      for (final mode in ['stderr', 'utf8', 'json', 'array']) {
        final dir = await root.createTemp('service-');
        final cli = File('${dir.path}/packages/cli/aqa.mjs');
        await cli.parent.create(recursive: true);
        await cli.writeAsString('''
if(process.argv[2]==='--version')console.log(JSON.stringify({engineVersion:'fixture'}));
else if('$mode'==='stderr'){process.stderr.write('x'.repeat(3*1024*1024));console.log('{}');}
else if('$mode'==='utf8')process.stdout.write(Buffer.from([0xff]));
else if('$mode'==='array')console.log('[]');
else console.log('PRIVATE_SENTINEL_INVALID_JSON');
''');
        final svc = LocalEngineCliService(
          processPolicy: policy,
          loadManifest: () async => {
            'engineVersion': 'fixture',
            'entrypoint': 'packages/cli/aqa.mjs',
            'files': {
              'packages/cli/aqa.mjs': sha256
                  .convert(await cli.readAsBytes())
                  .toString(),
            },
          },
        );
        addTearDown(svc.dispose);
        try {
          await svc.capabilities(
            EngineSettings(
              nodePath: node,
              cliPath: cli.path,
              reportRoot: dir.path,
            ),
            'web',
          );
          fail('invalid response accepted: $mode');
        } on EngineException catch (error) {
          expect(error.message, isNot(contains('PRIVATE_SENTINEL')));
        }
      }
    },
  );

  test(
    'service run errors, dispose and subscription cancel release the child',
    () async {
      for (final mode in [
        'malformed',
        'sequence',
        'cancel',
        'dispose',
        'unsubscribe',
      ]) {
        final dir = await root.createTemp('run-');
        final cli = File('${dir.path}/packages/cli/aqa.mjs');
        final pidFile = File('${dir.path}/run.pid');
        await cli.parent.create(recursive: true);
        final plan = <String, dynamic>{
          'schemaVersion': 'qa.plan/v1',
          'engineVersion': 'fixture',
          'blueprintSnapshotHash': 'hash',
          'flowSnapshotHash': 'flow',
          'nodeOrder': ['start'],
          'requiredActions': <String>[],
          'blueprint': {
            'target': {'platform': 'web'},
          },
        };
        await cli.writeAsString('''
import {writeFileSync} from 'node:fs';
const cmd=process.argv[2];
if(cmd==='--version')console.log('{"engineVersion":"fixture"}');
if(cmd==='devices')console.log('{"platforms":["web"],"supportedActions":[],"targets":[{}]}');
if(cmd==='plan')console.log(${jsonEncode(jsonEncode(plan))});
if(cmd==='run'){
 writeFileSync(${jsonEncode(pidFile.path)},String(process.pid));
 if('$mode'==='malformed')console.log('PRIVATE_SENTINEL_INVALID_JSON');
 else console.log(JSON.stringify({schemaVersion:'qa.runEvent/v1',type:'run.started',runId:'run_fixture',attempt:1,sequence:'$mode'==='sequence'?2:1,blueprintSnapshotHash:'hash'}));
 process.stdin.resume();setInterval(()=>{},1000);
}
''');
        final svc = LocalEngineCliService(
          processPolicy: policy,
          loadManifest: () async => {
            'engineVersion': 'fixture',
            'entrypoint': 'packages/cli/aqa.mjs',
            'controlStdin': true,
            'files': {
              'packages/cli/aqa.mjs': sha256
                  .convert(await cli.readAsBytes())
                  .toString(),
            },
          },
        );
        addTearDown(svc.dispose);
        final settings = EngineSettings(
          nodePath: node,
          cliPath: cli.path,
          reportRoot: dir.path,
        );
        final scenario = PreparedScenario(
          settings: settings,
          inputPath: 'unused.json',
          reportRoot: dir.path,
          plan: plan,
        );
        if (mode == 'unsubscribe') {
          final first = Completer<void>();
          final sub = svc.run(scenario).listen((_) {
            if (!first.isCompleted) first.complete();
          });
          await first.future;
          await sub.cancel().timeout(const Duration(seconds: 2));
        } else {
          Object? failure;
          try {
            await for (final update in svc.run(scenario)) {
              expect(update.result, isNull);
              if (mode == 'cancel') await svc.cancel();
              if (mode == 'dispose') svc.dispose();
            }
          } catch (error) {
            failure = error;
          }
          expect(failure, isA<EngineException>());
          expect(failure.toString(), isNot(contains('PRIVATE_SENTINEL')));
        }
        final pid = int.parse(await pidFile.readAsString());
        final alive = await Process.run(node, [
          '-e',
          'try{process.kill($pid,0);process.exit(1)}catch{process.exit(0)}',
        ]);
        expect(
          alive.exitCode,
          0,
          reason: 'direct child must have exited: $mode',
        );
      }
    },
  );
}
