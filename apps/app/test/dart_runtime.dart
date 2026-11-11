import 'dart:io';

String testDartExecutable() {
  final override = Platform.environment['AQA_TEST_DART'];
  if (override != null && override.isNotEmpty) return override;
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null || root.isEmpty) {
    throw StateError('Use node scripts/flutter.mjs test or set FLUTTER_ROOT.');
  }
  return '$root/bin/cache/dart-sdk/bin/${Platform.isWindows ? 'dart.exe' : 'dart'}';
}
