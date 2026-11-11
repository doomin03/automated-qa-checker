import 'dart:convert';
import 'dart:io';

import 'dart_runtime.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:automated_qa_desktop/features/project_workspace/models/workspace.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/project_workspace/repositories/workspace_repository.dart';
import 'package:automated_qa_desktop/features/project_workspace/view_models/workspace_view_model.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('qa-workspace-');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  test(
    'project/QA/prompt restart and stale save preserve newest bytes',
    () async {
      final service = WorkspaceFileService(directory: directory);
      final vm = WorkspaceViewModel(WorkspaceRepository(service));
      expect(await vm.initialize(), isTrue);
      expect(await vm.createProject('프로젝트'), isTrue);
      expect(await vm.createQa('로그인', '<source/>'), isTrue);
      vm.editInstructions('프로젝트 지침');
      vm.editPrompt('QA 요구');
      expect(vm.promptsDirty, isTrue);
      expect(await vm.save('<changed/>'), isTrue);
      expect(vm.promptsDirty, isFalse);
      final ownerProject = vm.projectId!, ownerQa = vm.qaId!;
      vm.editInstructions('unsaved instructions');
      vm.editPrompt('unsaved request');
      expect(
        await vm.recordRun(
          ownerProject,
          ownerQa,
          const LastRun(
            runId: 'run-one',
            snapshotHash: 'sha256:abc',
            reportDirectory: 'C:/reports/run-one',
            outcome: 'passed',
          ),
        ),
        isTrue,
      );
      expect(vm.instructions, 'unsaved instructions');
      expect(vm.prompt, 'unsaved request');
      expect(vm.promptsDirty, isTrue);
      final stored = await service.read();
      final stale = stored;
      await service.write(stored.copyWith(settings: {'aiProvider': 'codex'}));
      final bytes = await service.file.readAsBytes();
      await expectLater(service.write(stale), throwsFormatException);
      expect(await service.file.readAsBytes(), bytes);
      final restart = WorkspaceViewModel(WorkspaceRepository(service));
      await restart.initialize();
      restart.select(vm.projectId, vm.qaId);
      expect(restart.instructions, '프로젝트 지침');
      expect(restart.prompt, 'QA 요구');
      expect(restart.qa!.source, '<changed/>');
      expect(restart.qa!.lastRun!.runId, 'run-one');
      vm.dispose();
      restart.dispose();
    },
  );
  test(
    'failed replacement, invalid document and over-limit preserve original',
    () async {
      final service = WorkspaceFileService(directory: directory);
      final current = await service.write(Workspace());
      final bytes = await service.file.readAsBytes();
      final failure = WorkspaceFileService(
        directory: directory,
        beforeCommit: () async {
          throw const FileSystemException('injected failure');
        },
      );
      await expectLater(
        failure.write(current),
        throwsA(isA<FileSystemException>()),
      );
      expect(await service.file.readAsBytes(), bytes);
      await expectLater(
        service.write(
          current.copyWith(
            projects: [
              QaProject(
                id: 'p',
                name: 'p',
                documents: [
                  QaDocument(
                    id: 'q',
                    name: 'q',
                    source: 'x' * (1024 * 1024 + 1),
                  ),
                ],
              ),
            ],
          ),
        ),
        throwsFormatException,
      );
      expect(await service.file.readAsBytes(), bytes);
      await service.file.writeAsString('{broken');
      await expectLater(service.read(), throwsFormatException);
      expect(await service.file.readAsString(), '{broken');
      await service.file.writeAsString(
        jsonEncode({...current.toJson(), 'futureData': true}),
      );
      await expectLater(service.read(), throwsFormatException);
      expect(
        (await service.file.readAsString()).contains('futureData'),
        isTrue,
      );
      await service.file.delete();
      await Directory(service.file.path).create();
      await expectLater(service.read(), throwsFormatException);
    },
  );
  test('two Windows processes and interrupted stage do not overwrite saved workspace', () async {
    final dart = testDartExecutable();
    final service = WorkspaceFileService(directory: directory);
    final current = await service.write(Workspace());
    Future<Process> start(int delay) => Process.start(dart, [
      'test/fixtures/workspace_writer.dart',
      directory.path,
      '$delay',
      '${current.revision}',
    ], runInShell: false);
    final first = await start(1000);
    final lines = first.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
    final firstError = first.stderr.drain<void>();
    await lines
        .firstWhere((s) => s == 'locked')
        .timeout(const Duration(seconds: 15));
    final second = await start(0);
    await second.stdout.drain<void>();
    await second.stderr.drain<void>();
    expect(await second.exitCode, 2);
    expect(await first.exitCode, 0);
    await firstError;
    final saved = await service.file.readAsBytes();
    final third = await Process.start(dart, [
      'test/fixtures/workspace_writer.dart',
      directory.path,
      '30000',
      '${(await service.read()).revision}',
    ], runInShell: false);
    final thirdLines = third.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
    final thirdError = third.stderr.drain<void>();
    await thirdLines
        .firstWhere((s) => s == 'locked')
        .timeout(const Duration(seconds: 15));
    third.kill();
    await third.exitCode;
    await thirdError;
    expect(await service.file.readAsBytes(), saved);
    expect((await service.write(await service.read())).revision, 3);
  });
}
