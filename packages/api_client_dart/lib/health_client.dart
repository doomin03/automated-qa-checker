import 'package:dio/dio.dart';

import 'api_client_dart.dart';
import 'src/contract_schema.dart';

class ApiFailure implements Exception {
  final int status;
  final ApiErrorResponse body;
  ApiFailure(this.status, this.body);
  @override
  String toString() => body.message;
}

class TransportFailure implements Exception {
  final String reason;
  TransportFailure(this.reason);
  @override
  String toString() => 'API transport failure: $reason';
}

class ContractFailure implements Exception {
  final String message;
  ContractFailure(this.message);
  @override
  String toString() => message;
}

String apiOrigin(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw ArgumentError(
      'API base URL must be an HTTP(S) origin without a path, query or credentials',
    );
  }
  return uri.origin;
}

// Constraints come from generated OpenAPI. There are no handwritten wire models.
void validateModel(String name, Object? value) {
  void visit(Map<String, dynamic> schema, Object? item, String path) {
    Never fail() => throw ContractFailure('Invalid API response at $path');
    if (item == null) {
      if (schema['nullable'] != true) fail();
      return;
    }
    if (schema.containsKey(r'$ref')) {
      final target = (schema[r'$ref'] as String).split('/').last;
      visit(contractSchemas[target] as Map<String, dynamic>, item, path);
      return;
    }
    if (schema['allOf'] is List) {
      for (final child in schema['allOf'] as List) {
        visit(Map<String, dynamic>.from(child as Map), item, path);
      }
      if (schema['type'] == null) return;
    }
    if (schema['enum'] is List && !(schema['enum'] as List).contains(item))
      fail();
    switch (schema['type']) {
      case 'object':
        if (item is! Map) fail();
        for (final key in (schema['required'] as List? ?? [])) {
          if (!item.containsKey(key)) fail();
        }
        for (final entry
            in (schema['properties'] as Map<String, dynamic>? ?? {}).entries) {
          if (item.containsKey(entry.key))
            visit(
              entry.value as Map<String, dynamic>,
              item[entry.key],
              '$path.${entry.key}',
            );
        }
      case 'array':
        if (item is! List ||
            (schema['maxItems'] is num &&
                item.length > (schema['maxItems'] as num)))
          fail();
        for (var i = 0; i < item.length; i++) {
          visit(schema['items'] as Map<String, dynamic>, item[i], '$path[$i]');
        }
      case 'string':
        if (item is! String) fail();
        if (schema['pattern'] is String &&
            !RegExp(schema['pattern'] as String).hasMatch(item))
          fail();
        if (schema['format'] == 'uuid' &&
            !RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
            ).hasMatch(item))
          fail();
        if (schema['format'] == 'date-time') {
          final parsed = DateTime.tryParse(item);
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$')
                  .hasMatch(item) ||
              parsed == null)
            fail();
          if (parsed.toUtc().toIso8601String().substring(0, 19) !=
              item.substring(0, 19))
            fail();
        }
      case 'integer':
      case 'number':
        if (item is! num || !item.isFinite) fail();
        if (schema['type'] == 'integer' &&
            (item != item.truncate() || item.abs() > 9007199254740991))
          fail();
        if (schema['minimum'] is num && item < (schema['minimum'] as num))
          fail();
        if (schema['maximum'] is num && item > (schema['maximum'] as num))
          fail();
      case 'boolean':
        if (item is! bool) fail();
      default:
        throw ContractFailure('Unsupported schema type at $path');
    }
  }

  final schema = contractSchemas[name];
  if (schema is! Map<String, dynamic>)
    throw ContractFailure('Unknown response schema $name');
  visit(schema, value, name);
}

class HealthClient {
  final Dio _dio;
  late final HealthApi _api;
  HealthClient(
    String origin, {
    Duration timeout = const Duration(seconds: 10),
    HttpClientAdapter? adapter,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: apiOrigin(origin),
           connectTimeout: timeout,
           receiveTimeout: timeout,
           sendTimeout: timeout,
         ),
       ) {
    if (timeout <= Duration.zero)
      throw ArgumentError('timeout must be positive');
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          try {
            validateModel('HealthResponse', response.data);
            handler.next(response);
          } catch (error) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                error: error,
              ),
            );
          }
        },
      ),
    );
    _api = HealthApi(_dio);
  }

  Future<HealthResponse> getHealth({String? client}) async {
    try {
      final response = await _api.getHealth(client: client);
      return response.data ?? (throw ContractFailure('Empty API response'));
    } on DioException catch (error) {
      if (error.error is ContractFailure) throw error.error!;
      final response = error.response;
      if (response != null &&
          response.statusCode != null &&
          response.statusCode! >= 400) {
        validateModel('ApiErrorResponse', response.data);
        throw ApiFailure(
          response.statusCode!,
          ApiErrorResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        );
      }
      if (response != null)
        throw ContractFailure('API response could not be decoded');
      throw TransportFailure(
        [
              DioExceptionType.connectionTimeout,
              DioExceptionType.receiveTimeout,
              DioExceptionType.sendTimeout,
            ].contains(error.type)
            ? 'timeout'
            : 'connection',
      );
    }
  }

  void close() => _dio.close(force: true);
}
