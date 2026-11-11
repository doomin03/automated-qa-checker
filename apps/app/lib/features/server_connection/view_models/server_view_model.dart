import 'package:flutter/foundation.dart';
import 'package:api_client_dart/health_client.dart';

import '../repositories/server_repository.dart';

class ServerViewModel extends ChangeNotifier {
  ServerViewModel(this._repository);
  final ServerRepository _repository;
  bool busy = false;
  bool _disposed = false;
  String message = '서버 없이 로컬 QA를 실행할 수 있습니다.';
  Future<void> connect(String origin) async {
    if (_disposed || busy) return;
    busy = true;
    message = '연결 확인 중';
    notifyListeners();
    try {
      final result = await _repository.connect(origin);
      if (!_disposed) message = result;
    } on ApiFailure catch (e) {
      if (!_disposed) {
        message = 'API ${e.status}: ${e.body.code} (${e.body.requestId})';
      }
    } on TransportFailure catch (e) {
      if (!_disposed) message = '연결 오류: ${e.reason}';
    } catch (_) {
      if (!_disposed) message = '주소 또는 API 계약 오류입니다.';
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;

    super.dispose();
  }
}
