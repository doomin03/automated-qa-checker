import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:api_client_dart/organization_client.dart';

class OrganizationService {
  OrganizationService({Future<void> Function(String)? launchBrowser})
    : _launch = launchBrowser ?? _windowsBrowser;
  final Future<void> Function(String) _launch;
  HttpServer? _callback;
  OrganizationClient? _client;
  Completer<String>? _code;
  bool _disposed = false;
  bool _loggingIn = false;
  int _generation = 0;
  static Future<void> _windowsBrowser(String url) async {
    if (!Platform.isWindows) {
      throw const FormatException('현재 기본 브라우저 실행은 Windows Desktop에서 지원합니다.');
    }
    final process = await Process.start('rundll32.exe', [
      'url.dll,FileProtocolHandler',
      url,
    ], runInShell: false);
    unawaited(process.stdout.drain<void>());
    unawaited(process.stderr.drain<void>());
  }

  String _random() => base64UrlEncode(
    List<int>.generate(32, (_) => Random.secure().nextInt(256)),
  ).replaceAll('=', '');
  Future<DesktopSessionResponse> login(String origin) async {
    if (_disposed || _loggingIn) {
      throw StateError('Login is unavailable');
    }
    final api = OrganizationClient(origin);
    _loggingIn = true;
    final generation = ++_generation;
    _client = api;
    final verifier = _random();
    final challenge = base64UrlEncode(
      sha256.convert(utf8.encode(verifier)).bytes,
    ).replaceAll('=', '');
    late final HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    } catch (_) {
      _loggingIn = false;
      _client = null;
      api.close();
      rethrow;
    }
    if (_disposed || generation != _generation) {
      await server.close(force: true);
      api.close();
      _client = null;
      _loggingIn = false;
      throw const FormatException('로그인이 취소되었습니다.');
    }
    _callback = server;
    final code = Completer<String>();
    _code = code;
    final pendingCode = code.future.timeout(const Duration(minutes: 5));
    unawaited(
      pendingCode.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    );
    final redirectUri = 'http://127.0.0.1:${server.port}/qa/callback';
    final subscription = server.listen((request) async {
      request.response.headers.set('cache-control', 'no-store');
      request.response.headers.set('referrer-policy', 'no-referrer');
      final query = request.uri.queryParametersAll;
      final value = query['code']?.singleOrNull;
      if (request.method != 'GET' ||
          request.uri.path != '/qa/callback' ||
          query['state']?.singleOrNull != challenge ||
          value == null ||
          !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(value) ||
          code.isCompleted) {
        request.response.statusCode = 400;
        request.response.write('Invalid login callback');
      } else {
        code.complete(value);
        request.response.write(
          'Login received. Return to Automated QA Desktop.',
        );
      }
      await request.response.close();
    });
    try {
      await _launch(
        api.loginUrl('desktop', redirectUri: redirectUri, challenge: challenge),
      );
      final value = await pendingCode;
      if (_disposed || generation != _generation) {
        throw const FormatException('로그인이 취소되었습니다.');
      }
      final session = await api.desktopExchange(
        DesktopExchangeInput(
          code: value,
          redirectUri: redirectUri,
          verifier: verifier,
        ),
      );
      if (_disposed || generation != _generation) {
        try {
          await logout(origin, session.token);
        } catch (_) {}
        throw const FormatException('로그인이 취소되었습니다.');
      }
      return session;
    } finally {
      await subscription.cancel();
      await server.close(force: true);
      _callback = null;
      _code = null;
      api.close();
      _client = null;
      _loggingIn = false;
    }
  }

  Future<SessionResponse> session(String origin, String token) async {
    final api = OrganizationClient(origin, token: token);
    try {
      return await api.getSession();
    } finally {
      api.close();
    }
  }

  Future<void> logout(String origin, String token) async {
    final api = OrganizationClient(origin, token: token);
    try {
      await api.logout();
    } finally {
      api.close();
    }
  }

  void cancel() {
    _generation++;
    final code = _code;
    if (code != null && !code.isCompleted) {
      code.completeError(const FormatException('로그인이 취소되었습니다.'));
    }
    _client?.close();
  }

  void dispose() {
    _disposed = true;
    cancel();
    unawaited(_callback?.close(force: true) ?? Future<void>.value());
  }
}
