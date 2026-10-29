import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/core/errors/draft_file_exception.dart';
import 'package:automated_qa_desktop/features/scenario_editor/models/scenario_draft.dart';
import 'package:automated_qa_desktop/features/scenario_editor/repositories/scenario_repository.dart';
import 'package:automated_qa_desktop/features/scenario_editor/services/scenario_file_service.dart';
import 'package:automated_qa_desktop/features/scenario_editor/view_models/scenario_editor_view_model.dart';

class PendingRepository implements ScenarioRepository {
  final completion = Completer<ScenarioDraft>();
  int calls = 0;
  @override
  Future<ScenarioDraft> open(String path) {
    calls++;
    return completion.future;
  }

  @override
  Future<ScenarioDraft> save(String path, ScenarioDraft draft) {
    calls++;
    return completion.future;
  }
}

void main() {
  test(
    'file repository round trip, UTF-8 bound and missing file errors',
    () async {
      final directory = await Directory.systemTemp.createTemp('qa-draft-test-');
      addTearDown(() => directory.delete(recursive: true));
      final repo = FileScenarioRepository(LocalScenarioFileService());
      final path = '${directory.path}/공용 시나리오.xml';
      const draft = ScenarioDraft(
        content: '<blueprint>한글 &amp; test</blueprint>',
      );
      await repo.save(path, draft);
      expect((await repo.open(path)).content, draft.content);
      expect(draft.path, isNull);
      await expectLater(
        repo.save(path, ScenarioDraft(content: '가' * 350000)),
        throwsA(isA<DraftFileException>()),
      );
      expect((await repo.open(path)).content, draft.content);
      await expectLater(
        repo.open('${directory.path}/missing.xml'),
        throwsA(isA<DraftFileException>()),
      );
      await File(path).writeAsBytes([0xff, 0xfe, 0x01]);
      await expectLater(repo.open(path), throwsA(isA<DraftFileException>()));
      await File(path)
          .writeAsBytes(List.filled(LocalScenarioFileService.maxBytes + 1, 65));
      await expectLater(repo.open(path), throwsA(isA<DraftFileException>()));
    },
  );

  test('staged replacement preserves destination on failure and cleans temporary files', () async {
    final directory = await Directory.systemTemp.createTemp('qa-staged-save-');
    addTearDown(() => directory.delete(recursive: true));
    final service = LocalScenarioFileService();
    final path = '${directory.path}/draft.xml';
    await service.write(path, 'original');
    await service.write(path, 'replacement');
    expect(await service.read(path), 'replacement');
    if (Platform.isWindows) {
      final locked = await File(path).open(mode: FileMode.append);
      try {
        await expectLater(
          service.write(path, 'must not replace'),
          throwsA(isA<DraftFileException>()),
        );
        expect(await service.read(path), 'replacement');
      } finally {
        await locked.close();
      }
    }
    expect(await directory.list().length, 1);
  });

  test(
    'view model preserves dirty draft on failure and blocks duplicate actions',
    () async {
      final repo = PendingRepository();
      final vm = ScenarioEditorViewModel(repo);
      addTearDown(vm.dispose);
      final states = <bool>[];
      vm.addListener(() => states.add(vm.isBusy));
      vm.edit('<blueprint/>');
      final immutableBefore = vm.draft;
      vm.edit('<changed/>');
      expect(immutableBefore.content, '<blueprint/>');
      final pending = vm.save('draft.xml');
      expect(vm.isBusy, isTrue);
      expect(await vm.save('other.xml'), isFalse);
      vm.edit('ignored while saving');
      expect(repo.calls, 1);
      repo.completion.completeError(const DraftFileException('저장 실패'));
      expect(await pending, isFalse);
      expect(vm.draft.content, '<changed/>');
      expect(vm.isDirty, isTrue);
      expect(vm.error, '저장 실패');
      expect(vm.notice, isNull);
      expect(states.last, isFalse);
    },
  );

  test('view model notifies save success and clears dirty state', () async {
    final repo = PendingRepository();
    final vm = ScenarioEditorViewModel(repo);
    addTearDown(vm.dispose);
    vm.edit('<draft/>');
    final pending = vm.save('draft.xml');
    repo.completion.complete(
      const ScenarioDraft(content: '<draft/>', path: 'draft.xml'),
    );
    expect(await pending, isTrue);
    expect(vm.isDirty, isFalse);
    expect(vm.draft.path, 'draft.xml');
    expect(vm.notice, contains('저장'));
  });

  test('completion after disposal does not notify or mutate state', () async {
    final repo = PendingRepository();
    final vm = ScenarioEditorViewModel(repo);
    int notifications = 0;
    vm.addListener(() => notifications++);
    final pending = vm.open('draft.xml');
    vm.dispose();
    repo.completion.complete(const ScenarioDraft(content: 'late'));
    expect(await pending, isFalse);
    expect(notifications, 1);
    expect(vm.draft.content, isEmpty);
  });

  testWidgets(
    'Provider connects edit, busy, file success and disposes owned VM',
    (tester) async {
      final repo = PendingRepository();
      late ScenarioEditorViewModel vm;
      await tester.pumpWidget(
        AppProviders(
          repository: repo,
          child: Builder(
            builder: (context) {
              vm = context.read<ScenarioEditorViewModel>();
              return const QaApp();
            },
          ),
        ),
      );
      expect(find.text('Automated QA Desktop'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('scenario-source')),
        '<test/>',
      );
      await tester.enterText(find.byKey(const Key('file-path')), 'draft.xml');
      await tester.pump();
      expect(find.text('저장하지 않은 변경'), findsOneWidget);
      await tester.tap(find.text('파일 저장'));
      await tester.pump();
      expect(find.text('파일 작업 중'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      repo.completion.complete(
        const ScenarioDraft(content: '<test/>', path: 'draft.xml'),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('file-notice')), findsOneWidget);
      expect(find.text('변경 없음'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(
        () => ChangeNotifier.debugAssertNotDisposed(vm),
        throwsFlutterError,
      );
    },
  );

  testWidgets('Provider removal during file load is safe', (tester) async {
    final repo = PendingRepository();
    await tester.pumpWidget(
      AppProviders(repository: repo, child: const QaApp()),
    );
    await tester.enterText(find.byKey(const Key('file-path')), 'draft.xml');
    await tester.tap(find.text('파일 열기'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    repo.completion.complete(const ScenarioDraft(content: 'late'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
