import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  switch (args.first) {
    case 'help':
      stdout.write('x' * 60000);
      stdout.write('--no-daemon --no-alt-screen --sandbox --ask-for-approval');
      await stdout.flush();
    case 'overflow':
      stdout.write('x' * 90000);
      await stdout.flush();
    case 'legacy-code-page':
      stdout.add([0x81, 0x82, 0xff, 0x0a]);
      await stdout.flush();
    case 'hang':
      await File(args[1]).writeAsString('$pid', flush: true);
      await Future<void>.delayed(const Duration(seconds: 30));
  }
}
