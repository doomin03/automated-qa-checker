import 'package:dio/dio.dart';

import 'api_client_dart.dart';
import 'health_client.dart';
import 'src/contract_schema.dart';
export 'api_client_dart.dart';
export 'health_client.dart' show ApiFailure, ContractFailure, TransportFailure;

class OrganizationClient {
  final Dio _dio;
  final CancelToken _lifetime = CancelToken();
  late final AuthApi _api;
  OrganizationClient(
    String origin, {
    String? token,
    String? csrfToken,
    Duration timeout = const Duration(seconds: 30),
    HttpClientAdapter? adapter,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: apiOrigin(origin),
           connectTimeout: timeout,
           receiveTimeout: timeout,
           sendTimeout: timeout,
           headers: {
             if (token != null) 'Authorization': 'Bearer $token',
             if (csrfToken != null) 'X-CSRF-Token': csrfToken,
           },
         ),
       ) {
    if (timeout <= Duration.zero)
      throw ArgumentError('timeout must be positive');
    if (token != null && (token.isEmpty || RegExp(r'\s').hasMatch(token)))
      throw ArgumentError('Invalid bearer token');
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          try {
            final operation = responseOperations
                .cast<Map<String, dynamic>>()
                .where(
                  (op) =>
                      op['path'] ==
                          Uri.parse(response.requestOptions.path).path &&
                      op['method'] ==
                          response.requestOptions.method.toUpperCase(),
                )
                .firstOrNull;
            if (operation == null || operation['schema'] == '')
              throw ContractFailure('No generated response contract');
            validateModel(operation['schema'] as String, response.data);
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
    _api = AuthApi(_dio);
  }
  String loginUrl(String kind, {String? redirectUri, String? challenge}) {
    if (!['web', 'desktop'].contains(kind))
      throw ArgumentError('Unknown login kind');
    final operation = responseOperations
        .cast<Map<String, dynamic>>()
        .where((op) => op['operationId'] == 'startOrganizationLogin')
        .firstOrNull;
    if (operation == null)
      throw ContractFailure('Organization login operation is absent');
    return Uri.parse(_dio.options.baseUrl)
        .resolve(operation['path'] as String)
        .replace(
          queryParameters: {
            'kind': kind,
            if (redirectUri != null) 'redirectUri': redirectUri,
            if (challenge != null) 'challenge': challenge,
          },
        )
        .toString();
  }

  Future<T> _call<T>(Future<Response<T>> Function() action) async {
    try {
      final response = await action();
      return response.data ??
          (throw ContractFailure('Empty organization response'));
    } on DioException catch (error) {
      if (error.error is ContractFailure) throw error.error!;
      final response = error.response;
      if (response != null && (response.statusCode ?? 0) >= 400) {
        validateModel('ApiErrorResponse', response.data);
        throw ApiFailure(
          response.statusCode!,
          ApiErrorResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        );
      }
      if (response != null)
        throw ContractFailure('Organization response could not be decoded');
      throw TransportFailure(
        error.type == DioExceptionType.cancel
            ? 'cancelled'
            : [
                DioExceptionType.connectionTimeout,
                DioExceptionType.receiveTimeout,
                DioExceptionType.sendTimeout,
              ].contains(error.type)
            ? 'timeout'
            : 'connection',
      );
    }
  }

  Future<SessionResponse> getSession() =>
      _call(() => _api.getOrganizationSession(cancelToken: _lifetime));
  Future<LogoutResponse> logout() =>
      _call(() => _api.logoutOrganizationSession(cancelToken: _lifetime));
  Future<DesktopSessionResponse> desktopExchange(DesktopExchangeInput input) =>
      _call(
        () => _api.exchangeDesktopLogin(
          desktopExchangeInput: input,
          cancelToken: _lifetime,
        ),
      );
  void close() {
    _lifetime.cancel('Client disposed');
    _dio.close(force: true);
  }
}
