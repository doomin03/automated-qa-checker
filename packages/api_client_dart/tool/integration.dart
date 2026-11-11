import 'dart:io';

import 'package:api_client_dart/health_client.dart';

Future<void> main() async {
  final origin = Platform.environment['QA_TEST_ORIGIN'];
  if (origin == null)
    throw StateError(
      'QA_TEST_ORIGIN required; use contract integration runner',
    );
  final client = HealthClient(origin);
  try {
    for (final value in [null, 'web', 'app']) {
      final response = await client.getHealth(client: value);
      if (response.client?.value != value || response.status.value != 'ok')
        throw StateError('Health contract mismatch');
    }
    try {
      await client.getHealth(client: 'desktop');
      throw StateError('Expected HTTP 400');
    } on ApiFailure catch (error) {
      if (error.status != 400 || error.body.code != 'VALIDATION_ERROR') rethrow;
    }
    final unreachable = HealthClient('http://127.0.0.1:1');
    try {
      await unreachable.getHealth();
      throw StateError('Expected transport failure');
    } on TransportFailure catch (_) {
    } finally {
      unreachable.close();
    }
    stdout.writeln(
      'Dart generated SDK + adapter: same Nest server health null/web/app, HTTP400, unreachable passed',
    );
  } finally {
    client.close();
  }
}
