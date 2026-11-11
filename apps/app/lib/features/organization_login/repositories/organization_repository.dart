import 'package:api_client_dart/organization_client.dart';

import '../services/organization_service.dart';

class OrganizationRepository {
  OrganizationRepository(this.service);
  final OrganizationService service;
  String? _token;
  String? origin;
  SessionResponse? identity;
  bool _disposed = false;
  String credentialFor(String value) {
    if (origin != value || _token == null) {
      throw const FormatException('로그인한 서버 주소가 다릅니다.');
    }
    return _token!;
  }

  Future<void> login(String value) async {
    await logout();
    final session = await service.login(value);
    try {
      final me = await service.session(value, session.token);
      if (_disposed) throw StateError('Disposed');
      identity = me;
      _token = session.token;
      origin = value;
    } catch (_) {
      try {
        await service.logout(value, session.token);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> logout() async {
    final token = _token, server = origin;
    _token = null;
    origin = null;
    identity = null;
    if (token != null && server != null) await service.logout(server, token);
  }

  void cancel() => service.cancel();
  void dispose() {
    _disposed = true;
    _token = null;
    identity = null;
    origin = null;
  }
}
