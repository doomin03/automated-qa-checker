import 'dart:convert';
import 'dart:io';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  final user = ManagedUserResponse.fromJson({
    'userId': 'member', 'displayName': null, 'active': true,
    'role': 'qa_tester', 'userRevision': 0, 'membershipRevision': 3,
  });
  check(user.toJson().containsKey('displayName') && user.toJson()['displayName'] == null, 'Required nullable name was lost');
  final removed = ManagedMembershipState.fromJson({'userId': 'member', 'role': null, 'membershipRevision': 4});
  check(removed.toJson().containsKey('role') && removed.toJson()['role'] == null, 'Removed membership role was lost');
  final create = ManagedUserCreate(userId: 'new', displayName: null, role: ManagedUserCreateRoleEnum.viewer);
  check(create.toJson().containsKey('displayName') && create.toJson()['displayName'] == null, 'Creation must carry explicit nullable name');
  final clear = ManagedUserUpdate(userRevision: 1, clearDisplayName: true).toJson();
  check(clear['clearDisplayName'] == true && !clear.containsKey('displayName'), 'Explicit clear intent was lost');
  final activeOnly = ManagedUserUpdate(userRevision: 2, active: false).toJson();
  check(activeOnly['active'] == false && !activeOnly.containsKey('clearDisplayName') && !activeOnly.containsKey('displayName'), 'Active-only patch must preserve name');
  var rejected = false;
  try { ManagedMembershipState.fromJson({'userId': 'member', 'membershipRevision': 4}); } catch (_) { rejected = true; }
  check(rejected, 'Missing required nullable role accepted');
  stdout.writeln(jsonEncode({'status': 'passed', 'checks': 6, 'scope': 'generated Dart administration model serialization; no external identity provider'}));
  final origin = Platform.environment['QA_TEST_ORIGIN'];
  if (origin != null) {
    final dio = Dio(BaseOptions(baseUrl: origin, headers: {'Authorization': 'Bearer ${Platform.environment['QA_TEST_ADMIN_TOKEN']}'}, connectTimeout: const Duration(seconds: 5), receiveTimeout: const Duration(seconds: 10)));
    final api = AdministrationApi(dio);
    try {
      final created = (await api.createManagedProjectUser(projectId: 'sdk', idempotencyKey: 'dart-create', managedUserCreate: ManagedUserCreate(userId: 'dart-member', displayName: '한글 이름', role: ManagedUserCreateRoleEnum.viewer))).data!;
      final cleared = (await api.updateManagedProjectUser(projectId: 'sdk', userId: created.userId, managedUserUpdate: ManagedUserUpdate(userRevision: created.userRevision, clearDisplayName: true))).data!;
      check(cleared.displayName == null && cleared.toJson().containsKey('displayName') && cleared.userRevision == 1, 'Dart HTTP clear failed');
      final named = (await api.updateManagedProjectUser(projectId: 'sdk', userId: created.userId, managedUserUpdate: ManagedUserUpdate(userRevision: 1, displayName: '보존'))).data!;
      final disabled = (await api.updateManagedProjectUser(projectId: 'sdk', userId: created.userId, managedUserUpdate: ManagedUserUpdate(userRevision: named.userRevision, active: false))).data!;
      check(disabled.displayName == '보존' && !disabled.active, 'Dart active-only HTTP patch changed name');
      final removed = (await api.removeManagedMembership(projectId: 'sdk', userId: created.userId, membershipRevision: disabled.membershipRevision)).data!;
      check(removed.role == null && removed.toJson().containsKey('role'), 'Dart HTTP removed role lost');
      stdout.writeln('Dart generated API: real Nest create/clear/name/active-only/remove PASS');
    } catch (_) {
      throw StateError('Dart administration HTTP integration failed; request credentials omitted');
    } finally { dio.close(force: true); }
  }
}
