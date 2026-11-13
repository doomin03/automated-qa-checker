import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/organization_login/services/organization_service.dart';

void main() {
  test(
    'cancellation while binding never opens browser or exchanges code',
    () async {
      var launched = 0;
      final service = OrganizationService(
        launchBrowser: (_) async {
          launched++;
        },
      );
      await expectLater(service.login('not-an-origin'), throwsArgumentError);
      final login = service.login('http://127.0.0.1:4319');
      service.cancel();
      await expectLater(login, throwsA(isA<FormatException>()));
      expect(launched, 0);
      service.dispose();
    },
  );
}
