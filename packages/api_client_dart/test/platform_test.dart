import 'package:api_client_dart/platform_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'client_test.dart' show FixtureAdapter;

void main() {
  test('project context nullable metadata and invalid actions preserve generated validation', () async {
    final payload = <String, dynamic>{
      'projectId': 'one',
      'role': 'viewer',
      'allowedActions': ['readPublished'],
      'engine': {
        'engineVersion': '0.1.0-alpha.6',
        'contractVersion': 'qa.engine/v1',
        'contractSha256': 'a' * 64,
        'archiveSha256': null,
      },
    };
    PlatformClient client(Object? data) {
      final value = PlatformClient(
        'http://127.0.0.1',
        'token',
        adapter: FixtureAdapter(data),
      );
      addTearDown(value.close);
      return value;
    }

    expect((await client(payload).context('one')).engine.archiveSha256, null);
    await expectLater(
      client({
        ...payload,
        'allowedActions': ['inventedPermission'],
      }).context('one'),
      throwsA(isA<ContractFailure>()),
    );
    await expectLater(
      client({...payload, 'engine': null}).context('one'),
      throwsA(isA<ContractFailure>()),
    );
    expect(
      (await client({
        'items': [
          {'userId': 'one', 'role': 'viewer', 'displayName': null},
        ],
        'nextCursor': null,
      }).members('one')).items.first.displayName,
      null,
    );
    expect(
      (await client({'items': <Object?>[], 'nextCursor': null})
              .suitePins('one'))
          .items,
      isEmpty,
    );
  });
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
