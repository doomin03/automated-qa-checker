import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:api_client_dart/health_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class FixtureAdapter implements HttpClientAdapter {
  final Object? body;
  final int status;
  final DioExceptionType? failure;
  FixtureAdapter(this.body, {this.status = 200, this.failure});
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (failure != null)
      throw DioException(requestOptions: options, type: failure!);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final fixture = <String, dynamic>{
    'status': 'ok',
    'service': 'automated-qa-checker',
    'apiVersion': 'v1',
    'client': null,
  };
  test(
    'generated parser preserves required null and rejects missing fields',
    () {
      expect(HealthResponse.fromJson(fixture).toJson(), fixture);
      expect(
        () => HealthResponse.fromJson({...fixture}..remove('client')),
        throwsA(anything),
      );
      expect(
        HealthResponse.fromJson({...fixture, 'future': true}).toJson(),
        fixture,
      );
      for (final bad in [
        {...fixture}..remove('client'),
        {...fixture, 'client': 'desktop'},
        {...fixture, 'status': null},
      ]) {
        expect(
          () => validateModel('HealthResponse', bad),
          throwsA(isA<ContractFailure>()),
        );
      }
    },
  );
  test('adapter preserves API400 and separates connection/timeout without fake HTTP status', () async {
    final error = {
      'code': 'VALIDATION_ERROR',
      'message': 'Request validation failed',
      'requestId': '00000000-0000-4000-8000-000000000000',
      'details': <dynamic>[],
    };
    final api = HealthClient(
      'http://127.0.0.1',
      adapter: FixtureAdapter(error, status: 400),
    );
    addTearDown(api.close);
    await expectLater(
      api.getHealth(),
      throwsA(
        isA<ApiFailure>()
            .having((e) => e.status, 'status', 400)
            .having((e) => e.body.code, 'code', 'VALIDATION_ERROR'),
      ),
    );
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.receiveTimeout,
    ]) {
      final client = HealthClient(
        'http://127.0.0.1',
        adapter: FixtureAdapter(null, failure: type),
      );
      addTearDown(client.close);
      await expectLater(
        client.getHealth(),
        throwsA(
          isA<TransportFailure>().having(
            (e) => e.reason,
            'reason',
            type == DioExceptionType.receiveTimeout ? 'timeout' : 'connection',
          ),
        ),
      );
    }
    final client = HealthClient(
      'http://127.0.0.1',
      adapter: FixtureAdapter({...fixture, 'future': true}),
    );
    addTearDown(client.close);
    expect((await client.getHealth()).client, null);
    final invalid = HealthClient(
      'http://127.0.0.1',
      adapter: FixtureAdapter({...fixture}..remove('client')),
    );
    addTearDown(invalid.close);
    await expectLater(invalid.getHealth(), throwsA(isA<ContractFailure>()));
  });
  test('origin validation excludes duplicated API paths', () {
    expect(apiOrigin('http://127.0.0.1:3000/'), 'http://127.0.0.1:3000');
    for (final bad in [
      '',
      'file:///tmp',
      'https://x/api/v1',
      'https://x?foo=bar',
      'https://user:secret@x',
    ]) {
      expect(() => apiOrigin(bad), throwsArgumentError);
    }
  });
}
