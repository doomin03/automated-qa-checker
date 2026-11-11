import 'package:api_client_dart/platform_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'client_test.dart' show FixtureAdapter;

void main() {
  test(
    'platform generated model validation and common errors are retained',
    () async {
      final client = PlatformClient(
        'http://127.0.0.1',
        'token',
        adapter: FixtureAdapter({
          'userId': 'tester',
          'localMode': true,
          'projects': <Object?>[],
          'future': true,
        }),
      );
      addTearDown(client.close);
      expect((await client.me()).localMode, true);
      final malformed = PlatformClient(
        'http://127.0.0.1',
        'token',
        adapter: FixtureAdapter({'userId': 'tester', 'projects': <Object?>[]}),
      );
      addTearDown(malformed.close);
      await expectLater(malformed.me(), throwsA(isA<ContractFailure>()));
      final denied = PlatformClient(
        'http://127.0.0.1',
        'token',
        adapter: FixtureAdapter({
          'code': 'FORBIDDEN',
          'message': 'Forbidden',
          'requestId': '00000000-0000-4000-8000-000000000000',
          'details': <Object?>[],
        }, status: 403),
      );
      addTearDown(denied.close);
      await expectLater(
        denied.me(),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 403)),
      );
    },
  );
  test(
    'platform transport cancellation and timeout have distinct reasons',
    () async {
      for (final entry in {
        DioExceptionType.cancel: 'cancelled',
        DioExceptionType.receiveTimeout: 'timeout',
        DioExceptionType.connectionError: 'connection',
      }.entries) {
        final client = PlatformClient(
          'http://127.0.0.1',
          'token',
          adapter: FixtureAdapter(null, failure: entry.key),
        );
        addTearDown(client.close);
        await expectLater(
          client.me(),
          throwsA(
            isA<TransportFailure>().having(
              (e) => e.reason,
              'reason',
              entry.value,
            ),
          ),
        );
      }
    },
  );
}
