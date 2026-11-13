import 'package:api_client_dart/organization_client.dart';
import 'package:flutter/foundation.dart';

import '../repositories/organization_repository.dart';

class OrganizationViewModel extends ChangeNotifier {
  OrganizationViewModel(this.repository);
  final OrganizationRepository repository;
  SessionResponse? get identity => repository.identity;
  String? get origin => repository.origin;
  String credentialFor(String origin) => repository.credentialFor(origin);
  bool busy = false, _disposed = false;
  String message = '조직 로그인은 선택 기능이며 로컬 테스트 실행에 필요하지 않습니다.';
  Future<void> _action(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    notifyListeners();
    try {
      await action();
    } catch (_) {
      message = '조직 인증 요청을 완료하지 못했습니다. 서버 설정과 브라우저 인증을 확인하세요.';
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> login(String origin) => _action(() async {
    await repository.login(origin);
    message = '조직 사용자 ${repository.identity!.userId}. 프로젝트를 선택하고 공유 연결을 누르세요.';
  });
  Future<void> logout() => _action(() async {
    await repository.logout();
    message = '조직 세션을 로그아웃했습니다.';
  });
  void cancel() => repository.cancel();
  @override
  void dispose() {
    _disposed = true;

    super.dispose();
  }
}
