import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:api_client_dart/platform_client.dart';
import 'package:automated_qa_desktop/features/run_review/repositories/engine_repository.dart';
import 'package:automated_qa_desktop/features/run_review/view_models/run_view_model.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/repositories/shared_repository.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/services/shared_file_service.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/view_models/shared_view_model.dart';

import 'engine_bridge_test.dart' show IncompleteService;

final runtime = <String, dynamic>{
  'engineVersion': 'alpha8',
  'contractVersion': 'draft2',
  'bundleSha256': 'a' * 64,
};
ProjectContextResponse contextFor(
  String project, {
  String version = 'alpha8',
  List<String> actions = const ['readPublished', 'pinVersions', 'publishRuns'],
}) => ProjectContextResponse.fromJson({
  'projectId': project,
  'role': 'qa_tester',
  'allowedActions': actions,
  'engine': {
    'engineVersion': version,
    'contractVersion': 'draft2',
    'contractSha256': 'a' * 64,
    'archiveSha256': null,
  },
});
ApiFailure denied(int status) => ApiFailure(
  status,
  ApiErrorResponse(
    code: status == 404 ? 'NOT_FOUND' : 'FORBIDDEN',
    details: [],
    message: 'fixture',
    requestId: 'fixture',
  ),
);

class ContextRepository extends SharedRepository {
  ContextRepository() : super(SharedFileService());
  int generation = 0, reads = 0, pinReads = 0, accepts = 0, mutations = 0;
  String serverVersion = 'alpha8';
  Object? contextFailure, pinsFailure;
  Completer<ProjectContextResponse>? contextPending;
  Completer<PinPage>? pinsPending;
  Completer<Map<String, dynamic>>? suitePending;
  Completer<String>? diffPending;
  final cursors = <String?>[];
  @override
  int get connectionGeneration => generation;
  @override
  Future<IdentityResponse> connect(
    String address,
    String token,
    String projectId,
    String folder,
  ) async {
    generation++;
    origin = address;
    project = projectId;
    cacheFolder = folder;
    return IdentityResponse(
      userId: 'tester',
      localMode: true,
      projects: [
        ProjectResponse(
          id: projectId,
          name: projectId,
          role: ProjectResponseRoleEnum.qaTester,
        ),
      ],
    );
  }

  @override
  Future<ProjectContextResponse> context() async {
    if (contextFailure != null) throw contextFailure!;
    return await contextPending?.future ??
        contextFor(project, version: serverVersion);
  }

  @override
  Future<VersionPage> versions({String? cursor}) async {
    reads++;
    return VersionPage(items: [], nextCursor: null);
  }

  @override
  Future<SuitePage> suites({String? cursor}) async =>
      SuitePage(items: [], nextCursor: null);
  @override
  Future<PinPage> suitePins({String? cursor}) async {
    pinReads++;
    cursors.add(cursor);
    if (pinsFailure != null) throw pinsFailure!;
    return await pinsPending?.future ??
        PinPage(
          items: [
            PinResponse(
              packageId: cursor == null ? 'suite-a' : 'suite-b',
              versionId: cursor == null ? 'v1' : 'v2',
              sha256: 'b' * 64,
            ),
          ],
          nextCursor: cursor == null ? 'MQ' : null,
        );
  }

  @override
  Future<Map<String, dynamic>> suite(String id) async =>
      await suitePending?.future ??
      {
        'id': id,
        'projectId': project,
        'packageId': 'suite-a',
        'sha256': 'b' * 64,
        'engineVersion': 'older',
        'cases': [
          {'caseId': 'first', 'versionId': 'case-1', 'sha256': 'c' * 64},
          {'caseId': 'second', 'versionId': 'case-2', 'sha256': 'c' * 64},
        ],
      };
  @override
  Future<Map<String, dynamic>> preview(String id) async => {
    'id': id,
    'projectId': project,
    'sha256': 'c' * 64,
    'xml': '<fixture/>',
    'blueprintSnapshotHash': 'snapshot',
  };
  @override
  Future<String> diff(Map<String, dynamic> next) async =>
      await diffPending?.future ?? 'fixture';
  @override
  Future<void> accept(
    Map<String, dynamic> version, {
    bool attachToDocument = true,
  }) async {
    accepts++;
  }

  @override
  Future<void> pinSuite(Map<String, dynamic> version) async {
    mutations++;
  }

  @override
  void disconnect() {
    generation++;
    super.disconnect();
  }
}

void main() {
  late ContextRepository repo;
  late IncompleteService service;
  late RunViewModel run;
  late SharedViewModel vm;
  setUp(() {
    repo = ContextRepository();
    service = IncompleteService();
    run = RunViewModel(EngineRepository(service));
    vm = SharedViewModel(
      repo,
      run,
      loadLocalRuntime: () async => Map.of(runtime),
    );
  });
  tearDown(() {
    vm.dispose();
    run.dispose();
    repo.dispose();
  });
  Future<void> connect([String project = 'A']) =>
      vm.connect('http://local', 'fixture', project, 'cache');

  test('missing context 404 and revoked 403 fail closed but preserve explicit local execution', () async {
    repo.contextFailure = denied(404);
    await connect();
    expect(vm.connected, true);
    expect(vm.projectContext, null);
    expect(vm.canPublish, false);
    expect(repo.reads, 0);
    await vm.loadSuitePins();
    expect(repo.pinReads, 0);
    expect(vm.contextError, contains('404'));
    vm.enablePublishing(true);
    expect(vm.autoPublish, false);
    const settings = EngineSettings(
      nodePath: 'node',
      cliPath: 'cli',
      reportRoot: 'report',
    );
    await run.validate(settings, 'local');
    await run.run(settings, 'local');
    expect(service.runs, 1);
    expect(
      run.status,
      'infra_error',
    ); // Fixture has no durable result; no invented pass.
    repo.contextFailure = null;
    await connect();
    expect(vm.canPublish, true);
    repo.pinsFailure = denied(403);
    await vm.loadSuitePins();
    expect(vm.projectContext, null);
    expect(vm.allows('pinVersions'), false);
    expect(run.status, 'infra_error');
  });

  test(
    'local runtime missing or version/hash mismatch blocks only publication',
    () async {
      repo.serverVersion = 'alpha6';
      await connect();
      expect(vm.incompatibility, contains('alpha8 / 서버 alpha6'));
      expect(vm.canPublish, false);
      expect(vm.allows('pinVersions'), true);
      await vm.select('case-1');
      expect(await vm.accept(), '<fixture/>');
      expect(service.runs, 0);
      repo.serverVersion = 'alpha8';
      await connect();
      expect(vm.canPublish, true);
      vm.localRuntime = null;
      expect(vm.canPublish, false);
      vm.localRuntime = {...runtime, 'bundleSha256': 'd' * 64};
      expect(vm.canPublish, false);
      vm.localRuntime = {...runtime, 'contractVersion': 'older'};
      expect(vm.canPublish, false);
    },
  );

  test('late context after disconnect and a newer project does not overwrite context or busy', () async {
    final old = repo.contextPending = Completer<ProjectContextResponse>();
    final connecting = connect('A');
    await Future<void>.delayed(Duration.zero);
    vm.disconnect();
    repo.contextPending = null;
    await connect('B');
    expect(vm.projectContext!.projectId, 'B');
    old.complete(contextFor('A'));
    await connecting;
    expect(vm.projectContext!.projectId, 'B');
    expect(repo.project, 'B');
    expect(vm.busy, false);
    repo.generation++;
    expect(
      vm.canPublish,
      false,
      reason: 'context belongs to its connection generation',
    );
  });

  test(
    'late local runtime does not replace a newer connection runtime',
    () async {
      vm.dispose();
      final pending = Completer<Map<String, dynamic>>();
      var calls = 0;
      vm = SharedViewModel(
        repo,
        run,
        loadLocalRuntime: () =>
            ++calls == 1 ? pending.future : Future.value(Map.of(runtime)),
      );
      final old = connect('A');
      await Future<void>.delayed(Duration.zero);
      vm.disconnect();
      await connect('B');
      pending.complete({...runtime, 'engineVersion': 'stale'});
      await old;
      expect(vm.localRuntime!['engineVersion'], 'alpha8');
      expect(vm.projectContext!.projectId, 'B');
    },
  );

  test('pins page once, old exact pin restores ordered cases without mutation or execution', () async {
    await connect();
    await vm.loadSuitePins();
    await vm.loadSuitePins(more: true);
    await vm.loadSuitePins(more: true);
    expect(repo.cursors, [null, 'MQ']);
    expect(vm.suitePins.length, 2);
    expect(vm.pinCursor, null);
    await vm.openSuitePin(vm.suitePins.first);
    expect(vm.suitePinned, true);
    expect(vm.selectedSuite!['engineVersion'], 'older');
    final cases = vm.selectedSuite!['cases'] as List;
    expect(cases.map((value) => value['caseId']).toList(), ['first', 'second']);
    await vm.selectSuiteCase(Map<String, dynamic>.from(cases.last));
    expect(vm.preview!['id'], 'case-2');
    expect(repo.mutations, 0);
    expect(service.runs, 0);
    await vm.openSuitePin({...vm.suitePins.first, 'sha256': 'd' * 64});
    expect(vm.suitePinned, false);
    expect(vm.selectedSuite, null);
    expect(vm.preview, null);
    repo.suitePending = Completer<Map<String, dynamic>>()
      ..complete({
        'id': 'different-version',
        'packageId': 'suite-a',
        'sha256': 'b' * 64,
      });
    await vm.openSuitePin(vm.suitePins.first);
    expect(
      vm.suitePinned,
      false,
      reason: 'matching package/hash never replaces the exact version ID',
    );
  });

  test(
    'late pin page and pin detail cannot repopulate a disconnected project',
    () async {
      await connect();
      final page = repo.pinsPending = Completer<PinPage>();
      final loading = vm.loadSuitePins();
      await Future<void>.delayed(Duration.zero);
      vm.disconnect();
      page.complete(
        PinPage(
          items: [
            PinResponse(packageId: 'old', versionId: 'old', sha256: 'b' * 64),
          ],
          nextCursor: null,
        ),
      );
      await loading;
      expect(vm.suitePins, isEmpty);
      expect(vm.connected, false);
      repo.pinsPending = null;
      await connect();
      final detail = repo.suitePending = Completer<Map<String, dynamic>>();
      final opening = vm.openSuitePin({
        'versionId': 'v1',
        'packageId': 'suite-a',
        'sha256': 'b' * 64,
      });
      await Future<void>.delayed(Duration.zero);
      vm.disconnect();
      detail.complete({'id': 'v1', 'packageId': 'suite-a', 'sha256': 'b' * 64});
      await opening;
      expect(vm.selectedSuite, null);
      expect(vm.suitePinned, false);
    },
  );

  test(
    'preview is committed only after diff completes for the same project',
    () async {
      await connect();
      final diff = repo.diffPending = Completer<String>();
      final selecting = vm.select('case-1');
      await Future<void>.delayed(Duration.zero);
      expect(vm.preview, null);
      vm.disconnect();
      diff.complete('late');
      await selecting;
      expect(vm.preview, null);
      expect(vm.diff, null);
    },
  );
  test(
    'late rejected context cannot clear a newer pending operation',
    () async {
      final first = repo.contextPending = Completer<ProjectContextResponse>();
      final old = connect('A');
      await Future<void>.delayed(Duration.zero);
      vm.disconnect();
      final second = repo.contextPending = Completer<ProjectContextResponse>();
      final fresh = connect('B');
      await Future<void>.delayed(Duration.zero);
      first.completeError(denied(403));
      await old;
      expect(vm.busy, true);
      expect(vm.contextError, null);
      second.complete(contextFor('B'));
      await fresh;
      expect(vm.canPublish, true);
      expect(vm.projectContext!.projectId, 'B');
    },
  );
  test(
    'disposed context continuation does not mutate state or notify listeners',
    () async {
      final pending = repo.contextPending = Completer<ProjectContextResponse>();
      var notifications = 0;
      vm.addListener(() => notifications++);
      final connecting = connect();
      await Future<void>.delayed(Duration.zero);
      final disposed = vm, count = notifications;
      disposed.dispose();
      pending.complete(contextFor('A'));
      await connecting;
      expect(disposed.projectContext, null);
      expect(disposed.canPublish, false);
      expect(notifications, count);
      vm = SharedViewModel(
        repo,
        run,
      ); // Own a live instance for the common tearDown.
    },
  );
}
