import 'dart:convert';
import 'dart:io';

import 'package:api_client_dart/platform_client.dart';

void require(bool condition) {
  if (!condition) throw StateError('Platform contract mismatch');
}

Future<void> main() async {
  final fixture = jsonDecode(
    await File(Platform.environment['QA_TEST_FIXTURE']!).readAsString(),
  ) as Map<String, dynamic>;
  final plan = fixture['plan'] as Map<String, dynamic>;
  final origin = Platform.environment['QA_TEST_ORIGIN']!;
  final author = PlatformClient(
    origin,
    'author-sdk-local-test-token-32-characters',
  );
  final reviewer = PlatformClient(
    origin,
    'reviewer-sdk-local-test-token-32-characters',
  );
  final viewer = PlatformClient(
    origin,
    'viewer-sdk-local-test-token-32-characters',
  );
  const project = 'sdk-project';
  try {
    require((await author.me()).localMode);
    require((await viewer.projects()).items.first.id == project);
    final context = await viewer.context(project);
    require(context.engine.engineVersion == plan['engineVersion']);
    require(RegExp(r'^[a-f0-9]{64}$').hasMatch(context.engine.contractSha256));
    require(context.engine.archiveSha256 != null);
    require(
      context.allowedActions.length == 1 &&
          context.allowedActions.first.value == 'readPublished',
    );
    require(
      (await author.members(project)).items
          .every((member) => member.displayName == null),
    );
    try {
      await viewer.members(project);
      throw StateError('Expected member lookup 403');
    } on ApiFailure catch (error) {
      require(error.status == 403);
    }
    final draft = await author.createDraft(
      project,
      DraftInput(
        packageId: 'dart-sdk',
        title: 'Dart SDK',
        xml: fixture['xml'] as String,
        dependencies: [],
      ),
    );
    require(draft.reviewerId == null);
    try {
      await author.reviewDraft(project, draft.id);
      throw StateError('Expected 403');
    } on ApiFailure catch (error) {
      require(error.status == 403);
    }
    await reviewer.reviewDraft(project, draft.id);
    final version = await author.publishDraft(
      project,
      draft.id,
      '1.0.0',
      'dart-publish',
    );
    require(
      (await author.publishDraft(
            project,
            draft.id,
            '1.0.0',
            'dart-publish',
          )).id ==
          version.id,
    );
    require(
      (await viewer.version(project, version.id)).sha256 == version.sha256,
    );
    await author.pin(project, version.id, version.sha256);
    require(
      (await author.pins(project)).items
          .any((pin) => pin.versionId == version.id),
    );
    final suiteDraft = await author.createSuiteDraft(
      project,
      SuiteDraftInput(
        packageId: 'dart-suite-sdk',
        title: 'Dart Suite SDK',
        stopOnFailure: true,
        cases: [
          SuiteCase(
            caseId: 'first',
            versionId: version.id,
            sha256: version.sha256,
          ),
        ],
      ),
    );
    await reviewer.reviewSuiteDraft(project, suiteDraft.id);
    final suite = await author.publishSuiteDraft(
      project,
      suiteDraft.id,
      '1.0.0',
      'dart-suite-publish',
    );
    await author.pinSuite(project, suite.id, suite.sha256);
    require(
      (await author.suitePins(project)).items.any(
        (pin) => pin.versionId == suite.id && pin.sha256 == suite.sha256,
      ),
    );
    final start = {
      'schemaVersion': 'qa.runEvent/v1',
      'runId': 'dart-sdk-run',
      'attempt': 1,
      'sequence': 1,
      'type': 'run.started',
      'timestamp': '2026-10-31T00:00:00.000Z',
      'blueprintSnapshotHash': plan['blueprintSnapshotHash'],
    };
    final input = RunInput(
      blueprintJson: jsonEncode(plan['blueprint']),
      engineRunId: 'dart-sdk-run',
      attempt: 1,
      snapshotHash: plan['blueprintSnapshotHash'] as String,
      engineVersion: plan['engineVersion'] as String,
      startedEventJson: jsonEncode(start),
      versionId: version.id,
    );
    final run = await author.createRun(project, input, 'dart-create');
    require(jsonDecode(run.blueprintJson) is Map && run.resultJson == null);
    require(
      (await author.createRun(project, input, 'dart-create')).id == run.id,
    );
    final finish = {
      'schemaVersion': 'qa.runEvent/v1',
      'runId': 'dart-sdk-run',
      'attempt': 1,
      'sequence': 2,
      'type': 'run.finished',
      'timestamp': start['timestamp'],
      'outcome': 'infra_error',
      'resultPath': 'result.json',
    };
    await author.appendEvents(project, run.id, [jsonEncode(finish)]);
    final events = await viewer.events(
      project,
      run.id,
      afterSequence: 0,
      limit: 1,
    );
    require(
      events.hasMore &&
          decodeEngineEvents(events).first['type'] == 'run.started',
    );
    final result = {
      'schemaVersion': 'qa.result/v1',
      'runId': 'dart-sdk-run',
      'attempt': 1,
      'status': 'finished',
      'outcome': 'infra_error',
      'startedAt': start['timestamp'],
      'finishedAt': start['timestamp'],
      'artifacts': <Object?>[],
      'executed': {
        'engineVersion': plan['engineVersion'],
        'platform': 'web',
        'flowSnapshotHash': plan['flowSnapshotHash'],
        'blueprintSnapshotHash': plan['blueprintSnapshotHash'],
      },
      'visitedNodes': <String>[],
      'unvisitedNodes': plan['nodeOrder'],
      'cleanupErrors': <Object?>[],
    };
    final stored = await author.result(project, run.id, jsonEncode(result));
    require(
      decodeEngineResult(stored)?['outcome'] == 'infra_error' &&
          stored.workStatus.value == 'todo',
    );
    try {
      await viewer.appendEvents(project, run.id, [jsonEncode(finish)]);
      throw StateError('Expected 403');
    } on ApiFailure catch (error) {
      require(error.status == 403);
    }
    stdout.writeln(
      'Dart SDK: same real Registry/run API, generated nullable/enum/date/list/number serialization and 403 passed',
    );
  } finally {
    author.close();
    reviewer.close();
    viewer.close();
  }
}
