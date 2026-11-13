import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pty2/flutter_pty2.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/services/terminal_service.dart';

void main() {
  test('close and dispose during pending native spawn close only the owned session', () async {
    final directory = await Directory.systemTemp.createTemp('qa-spawn-close-');
    final node = (await Process.run('where.exe', [
      'node.exe',
    ])).stdout.toString().trim().split('\r\n').first;
    final fixture = File('test/fixtures/pty_fixture.cjs').absolute.path;
    try {
      for (final disposing in [false, true]) {
        final gate = Completer<void>();
        PtySession? owned;
        int? ownedPid;
        final service = TerminalService(
          spawn: (options) async {
            await gate.future;
            owned = await Pty.spawn(options);
            ownedPid = owned!.pid;
            return owned!;
          },
        );
        final started = service.start(node, [
          fixture,
          'echo',
          '${directory.path}/receipt-$disposing',
        ], directory.path);
        Future<void>? closed;
        if (disposing) {
          service.dispose();
        } else {
          closed = service.close();
        }
        gate.complete();
        await started;
        await closed;
        await service.close();
        expect(owned, isNotNull);
        expect(service.active, false);
        expect(service.cleanupUnknown, false);
        final listing = await Process.run('tasklist.exe', [
          '/FI',
          'PID eq $ownedPid',
          '/FO',
          'CSV',
          '/NH',
        ]);
        expect(listing.stdout.toString(), isNot(contains('"$ownedPid"')));
        service.dispose();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  }, skip: !Platform.isWindows);
  test(
    'owned service drains flood and closes descendants after parent exit across repeated sessions',
    () async {
      final directory = await Directory.systemTemp.createTemp('QA-owned-');
      final fixture = File('test/fixtures/pty_fixture.cjs').absolute.path;
      final node = (await Process.run('where.exe', [
        'node.exe',
      ])).stdout.toString().trim().split('\r\n').first;
      final service = TerminalService();
      var bytes = 0;
      service.onOutput = (v) => bytes += v.length;
      Future<void> until(bool Function() ready) async {
        final end = DateTime.now().add(const Duration(seconds: 12));
        while (!ready() && DateTime.now().isBefore(end)) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
        expect(ready(), true);
      }

      try {
        for (var i = 0; i < 20; i++) {
          final receipt = '${directory.path}/r$i';
          await service.start(node, [
            fixture,
            i == 19 ? 'flood' : 'echo',
            receipt,
          ], directory.path);
          await until(() => File(receipt).existsSync());
          if (i == 19) await until(() => bytes > 1024 * 1024);
          await service.close();
          expect(service.state, 'closed');
          expect(service.active, false);
        }
        final receipt = '${directory.path}/tree';
        await service.start(node, [fixture, 'tree', receipt], directory.path);
        await until(() => File('$receipt.child').existsSync());
        final child = int.parse(await File('$receipt.child').readAsString());
        await until(() => service.state == 'closed');
        final result = await Process.run('tasklist.exe', [
          '/FI',
          'PID eq $child',
          '/FO',
          'CSV',
          '/NH',
        ]);
        expect(result.stdout.toString(), isNot(contains('"$child"')));
        expect(service.cleanupUnknown, false);
      } finally {
        await service.close();
        service.dispose();
        await directory.delete(recursive: true);
      }
    },
    skip: !Platform.isWindows,
    timeout: const Timeout(Duration(minutes: 2)),
  );
  test(
    'Windows ConPTY preserves Unicode/quoted args, TTY input, resize and close',
    () async {
      final directory = await Directory.systemTemp.createTemp('QA 한글 공백 ');
      final receipt = '${directory.path}/receipt.json';
      final fixture = File('test/fixtures/pty_fixture.cjs').absolute.path;
      final node = (await Process.run('where.exe', [
        'node.exe',
      ])).stdout.toString().trim().split('\r\n').first;
      final session = await Pty.spawn(
        PtySpawnOptions(
          executable: node,
          arguments: [fixture, 'echo', receipt, '한글 공백', 'a"b', 'trailing\\'],
          workingDirectory: directory.path,
          size: const PtySize(columns: 90, rows: 25),
        ),
      );
      final output = StringBuffer();
      final sub = session.utf8Output().listen(output.write);
      Future<void> until(bool Function() predicate) async {
        final end = DateTime.now().add(const Duration(seconds: 10));
        while (!predicate() && DateTime.now().isBefore(end)) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }
        expect(predicate(), isTrue, reason: output.toString());
      }

      try {
        await until(() => output.toString().contains('READY'));
        final info = jsonDecode(await File(receipt).readAsString());
        expect(info['tty'], true);
        expect(info['cwd'], directory.path);
        expect(info['args'], ['한글 공백', 'a"b', 'trailing\\']);
        session.resize(const PtySize(columns: 105, rows: 31));
        await until(() => output.toString().contains('SIZE:105x31'));
        await session.input.write(Uint8List.fromList(utf8.encode('한글')));
        await until(() => output.toString().contains('ed959ceab880'));
        await session.input.write(Uint8List.fromList([4]));
        await session.done.timeout(const Duration(seconds: 10));
      } finally {
        await session.close().timeout(const Duration(seconds: 12));
        await sub.cancel();
        await directory.delete(recursive: true);
      }
    },
    skip: !Platform.isWindows,
  );
}
