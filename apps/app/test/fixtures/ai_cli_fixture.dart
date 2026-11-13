import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final mode = args[0], dir = args[1];
  final input = await stdin.transform(utf8.decoder).join();
  if (mode == 'diagnose') {
    stdout.writeln('codex-cli fixture');
    return;
  }
  if (mode == 'auth-ok') { stdout.writeln('Logged in using fixture'); return; }
  if (mode == 'auth-fail') { stderr.writeln('Not logged in'); exitCode = 1; return; }
  stdout.writeln(jsonEncode({'type': 'thread.started'}));
  if (mode == 'hang') {
    await Future<void>.delayed(const Duration(minutes: 1));
    return;
  }
  if (mode == 'overflow') {
    stdout.write('x' * 20000);
    return;
  }
  if (mode == 'invalid') {
    stdout.writeln('broken-json');
    return;
  }
  if (mode == 'tool') {
    stdout.writeln(
      jsonEncode({
        'type': 'item.completed',
        'item': {'type': 'command_execution'},
      }),
    );
    return;
  }
  if (mode == 'failure') {
    exitCode = 1;
    return;
  }
  await File('$dir/answer.json').writeAsString(
    jsonEncode({
      'summary': 'fixture',
      'xml': input.isEmpty ? '<blueprint />' : '<blueprint />',
    }),
  );
  stdout.writeln(
    jsonEncode({
      'type': 'item.completed',
      'item': {'type': 'agent_message', 'text': '{}'},
    }),
  );
  stdout.writeln(jsonEncode({'type': 'turn.completed'}));
}
