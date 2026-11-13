import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/models/terminal_profile.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/services/terminal_profile_service.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/repositories/terminal_preferences_repository.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/repositories/live_document_repository.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/view_models/terminal_readiness_view_model.dart';
import 'package:automated_qa_desktop/features/run_review/services/engine_cli_service.dart';
import 'package:automated_qa_desktop/app/workbench/views/terminal_readiness_dialog.dart';

class Profiles extends TerminalProfileService {
  Completer<TerminalProfile>? pending;
  @override
  Future<String?> chooseExecutable() async => 'C:/tools/program.exe';
  @override
  Future<TerminalProfile> inspect(String id, {String? executable}) async =>
      pending?.future ??
      TerminalProfile(
        id,
        id,
        executable?.isNotEmpty == true ? executable! : 'C:/tools/$id.exe',
        readiness: 'available',
      );
}

class Preferences extends TerminalPreferencesRepository {
  Preferences() : super('unused');
  Map<String, String> paths = {};
  bool fail = false;
  @override
  Future<Map<String, String>> read() async => {...paths};
  @override
  Future<void> remember(String provider, String? executable) async {
    if (fail) throw const FileSystemException('fixture readonly');
    if (executable == null) {
      paths.remove(provider);
    } else {
      paths[provider] = executable;
    }
  }
}

void main() {
  test('local preferences preserve corrupt/nonregular files and atomic replacement', () async {
    final dir = await Directory.systemTemp.createTemp('qa-readiness-');
    final repo = TerminalPreferencesRepository(dir.path);
    try {
      await repo.remember('codex', 'C:/tools/a.exe');
      await repo.remember('claude', 'C:/한글 경로/b.exe');
      expect((await repo.read()).length, 2);
      await repo.remember('codex', null);
      expect((await repo.read()).keys, ['claude']);
      await repo.file.writeAsString('{"version":1,"paths":{},"future":true}');
      final before = await repo.file.readAsBytes();
      await expectLater(
        repo.remember('codex', 'C:/new.exe'),
        throwsFormatException,
      );
      expect(await repo.file.readAsBytes(), before);
      await repo.file.delete();
      await Directory(repo.file.path).create();
      await expectLater(repo.read(), throwsFormatException);
      await Directory(repo.file.path).delete();
      await repo.file.writeAsString('x' * 32769);
      await expectLater(repo.read(), throwsFormatException);
    } finally {
      await dir.delete(recursive: true);
    }
  });
  test('late provider inspection cannot enable changed input; save error is honest and optional', () async {
    final profiles = Profiles(), prefs = Preferences();
    final vm = TerminalReadinessViewModel(profiles, prefs);
    await vm.selectProvider('codex');
    profiles.pending = Completer<TerminalProfile>();
    final inspect = vm.inspect();
    await vm.selectProvider('claude');
    profiles.pending!.complete(
      const TerminalProfile(
        'codex',
        'Codex',
        'C:/old.exe',
        readiness: 'available',
      ),
    );
    await inspect;
    expect(vm.profile, isNull);
    expect(vm.provider, 'claude');
    profiles.pending = null;
    await vm.chooseExecutable();
    await vm.inspect();
    vm.setRemember(true);
    prefs.fail = true;
    expect(await vm.accept(), isNull);
    expect(vm.error, contains('경로 기억 실패'));
    vm.setRemember(false);
    expect((await vm.accept())?.id, 'claude');
    prefs.fail = false;
    vm.setRemember(true);
    await vm.accept();
    await vm.selectProvider('claude');
    expect(vm.path, 'C:/tools/program.exe');
    expect(vm.profile, isNull);
    await vm.forget();
    expect(prefs.paths, isEmpty);
    vm.dispose();
  });
  test(
    'prepared guide inspection verifies bytes and never asserts discovery',
    () async {
      final dir = await Directory.systemTemp.createTemp('qa-readiness-guide-');
      final repo = LiveDocumentRepository(LocalEngineCliService());
      try {
        final session = await repo.createSession(
          dir.path,
          'p',
          'q',
          '{}',
          'context',
        );
        await repo.prepareEnvironment(session, 'codex', {
          'engineVersion': 'fixture',
          'contractVersion': 'fixture',
          'example': {},
        });
        expect(await repo.describeEnvironment(session), contains('별도 확인 필요'));
        final guide = File(
          '${session.path}/.agents/skills/qa-authoring/SKILL.md',
        );
        await guide.writeAsString('modified');
        await expectLater(
          repo.describeEnvironment(session),
          throwsFormatException,
        );
      } finally {
        repo.dispose();
        await dir.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'small large-text setup exposes picker guidance and explicit readiness',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final vm = TerminalReadinessViewModel(Profiles(), Preferences());
      await vm.selectProvider('codex');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ChangeNotifierProvider.value(
                      value: vm,
                      child: const TerminalReadinessDialog(),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('파일 선택'));
      await tester.tap(find.text('파일 선택'));
      await tester.pumpAndSettle();
      expect(vm.path, 'C:/tools/program.exe');
      await tester.ensureVisible(find.text('설치 안내'));
      await tester.tap(find.text('설치 안내'));
      await tester.pumpAndSettle();
      expect(find.textContaining('learn.chatgpt.com'), findsOneWidget);
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('준비 확인'));
      await tester.pumpAndSettle();
      expect(vm.profile?.available, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
}
