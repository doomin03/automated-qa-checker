import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/models/qa_receipt.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/services/qa_receipt_file_service.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/services/shared_file_service.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/repositories/shared_repository.dart';
import 'package:automated_qa_desktop/features/project_workspace/models/workspace.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/project_workspace/repositories/workspace_repository.dart';
import 'package:automated_qa_desktop/features/project_workspace/view_models/workspace_view_model.dart';

Map<String, dynamic> version(String xml, String id) => {
  'id': id,
  'projectId': 'remote',
  'packageId': 'login',
  'version': '1.0.0',
  'sha256': sha256.convert(utf8.encode(xml)).toString(),
  'blueprintSnapshotHash': 'same-snapshot',
  'xml': xml,
};
QaReceipt receipt(
  String project,
  String qa,
  String xml, {
  String id = 'version-1',
}) => QaReceipt(
  projectId: project,
  qaId: qa,
  origin: 'http://localhost:4319',
  serverProjectId: 'remote',
  version: version(xml, id),
  receivedAt: '2026-11-11T00:00:00Z',
);

class WaitingCache extends SharedFileService {
  final pending = Completer<Map<String, dynamic>?>();
  @override
  Future<Map<String, dynamic>?> cached(
    String folder,
    String origin,
    String project,
  ) => pending.future;
}

void main() {
  test('immutable receipt has exactly one successful writer and preserves original', () async {
    final root = await Directory.systemTemp.createTemp('qa-receipt-');
    addTearDown(() => root.delete(recursive: true));
    final files = QaReceiptFileService(root.path), p = '1' * 32, q = '2' * 32;
    Future<bool> write(String xml) async {
      try {
        await files.write(receipt(p, q, xml));
        return true;
      } catch (_) {
        return false;
      }
    }

    final outcomes = await Future.wait([write('<first/>'), write('<second/>')]);
    expect(outcomes.where((v) => v).length, 1);
    final original = await files.read(p, q);
    expect(original!.xml, outcomes.first ? '<first/>' : '<second/>');
    await expectLater(
      files.write(receipt(p, q, '<replace/>')),
      throwsFormatException,
    );
    expect((await files.read(p, q))!.xml, original.xml);
  });
  test('receipt rejects path escape, hash mismatch, oversize and non-file without replacement', () async {
    final root = await Directory.systemTemp.createTemp('qa-receipt-');
    addTearDown(() => root.delete(recursive: true));
    final files = QaReceiptFileService(root.path), p = '1' * 32, q = '2' * 32;
    await expectLater(files.read('../outside', q), throwsFormatException);
    final invalid = receipt(p, q, '<xml/>').toJson();
    (invalid['version'] as Map)['sha256'] = 'wrong';
    expect(() => QaReceipt.fromJson(invalid), throwsFormatException);
    await expectLater(
      files.write(receipt(p, q, 'x' * (QaReceiptFileService.limit + 1))),
      throwsFormatException,
    );
    await Directory('${root.path}/received-qa/$p-$q.json')
        .create(recursive: true);
    await expectLater(files.read(p, q), throwsFormatException);
    expect(
      await Directory('${root.path}/received-qa/$p-$q.json').exists(),
      true,
    );
  });
  test('late receipt cancellation at workspace commit preserves old bytes and hides orphan', () async {
    final root = await Directory.systemTemp.createTemp('qa-home-');
    addTearDown(() => root.delete(recursive: true));
    var cancelled = false, intercept = false;
    final p = '1' * 32;
    final files = WorkspaceFileService(
      directory: root,
      beforeCommit: () async {
        if (intercept) cancelled = true;
      },
    );
    await files.write(
      Workspace(
        projects: [QaProject(id: p, name: 'Existing')],
      ),
    );
    final before = await files.file.readAsBytes();
    final vm = WorkspaceViewModel(WorkspaceRepository(files));
    addTearDown(vm.dispose);
    await vm.initialize();
    final receipts = QaReceiptFileService(root.path);
    String? orphan;
    intercept = true;
    final ok = await vm.receiveQa(
      p,
      'Received',
      '<xml/>',
      isCurrent: () => !cancelled,
      prepare: (id) async {
        orphan = id;
        await receipts.write(receipt(p, id, '<xml/>'));
      },
    );
    expect(ok, false);
    expect(await files.file.readAsBytes(), before);
    expect(vm.workspace.projects.single.documents, isEmpty);
    expect(await receipts.read(p, orphan!), isNotNull);
  });
  test('successful receipt preserves v1 shape and persistence failure creates no QA', () async {
    final root = await Directory.systemTemp.createTemp('qa-home-');
    addTearDown(() => root.delete(recursive: true));
    final files = WorkspaceFileService(directory: root), p = '1' * 32;
    await files.write(
      Workspace(
        projects: [QaProject(id: p, name: 'Existing')],
      ),
    );
    final vm = WorkspaceViewModel(WorkspaceRepository(files));
    addTearDown(vm.dispose);
    await vm.initialize();
    expect(
      await vm.receiveQa(
        p,
        'Bad',
        '<xml/>',
        isCurrent: () => true,
        prepare: (_) async {
          throw const FileSystemException('fixture failure');
        },
      ),
      false,
    );
    expect(vm.workspace.projects.single.documents, isEmpty);
    final receipts = QaReceiptFileService(root.path);
    expect(
      await vm.receiveQa(
        p,
        'Received',
        '<xml/>',
        isCurrent: () => true,
        prepare: (id) => receipts.write(receipt(p, id, '<xml/>')),
      ),
      true,
    );
    final loaded = await files.read(),
        q = loaded.projects.single.documents.single;
    expect(q.source, '<xml/>');
    expect(loaded.toJson()['version'], 1);
    expect(
      q.toJson().keys,
      unorderedEquals(['id', 'name', 'source', 'prompt', 'updatedAt']),
    );
    expect((await receipts.read(p, q.id))!.matches(q.source), true);
  });
  test(
    'same XML in a different QA cannot inherit original execution version',
    () {
      final repo = SharedRepository(SharedFileService());
      addTearDown(repo.dispose);
      repo.origin = 'http://localhost';
      repo.project = 'remote';
      repo.activateDocument('project/first');
      repo.restoreDocumentReceipt(
        'project/first',
        version('<xml/>', 'first-version'),
        'http://localhost',
        'remote',
      );
      expect(
        repo.versionFor({'blueprintSnapshotHash': 'same-snapshot'}),
        'first-version',
      );
      repo.activateDocument('project/second');
      expect(
        repo.versionFor({'blueprintSnapshotHash': 'same-snapshot'}),
        isNull,
      );
      repo.activateDocument('project/first');
      expect(
        repo.versionFor({'blueprintSnapshotHash': 'changed-snapshot'}),
        isNull,
      );
    },
  );
  test(
    'offline late response cannot attach provenance to switched document',
    () async {
      final files = WaitingCache(), repo = SharedRepository(WaitingCache());
      repo.dispose();
      final actual = SharedRepository(files);
      addTearDown(actual.dispose);
      actual.activateDocument('first');
      final pending = actual.offline('unused', 'http://localhost', 'remote');
      actual.activateDocument('second');
      files.pending.complete(version('<xml/>', 'first-version'));
      await expectLater(pending, throwsFormatException);
      expect(actual.receivedVersion, isNull);
    },
  );
}
