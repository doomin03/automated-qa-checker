import 'package:integration_test/integration_test.dart';
import '../test/pty_native_test.dart' as spike;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  spike.main();
}
