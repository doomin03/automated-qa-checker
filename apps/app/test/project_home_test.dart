import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/desktop_workspace_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/project_home_view_model.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/repositories/shared_repository.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/repositories/qa_receipt_repository.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/services/qa_receipt_file_service.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/services/shared_file_service.dart';
import 'package:automated_qa_desktop/features/shared_scenarios/view_models/shared_view_model.dart';
import 'package:automated_qa_desktop/features/xml_blocks/repositories/xml_block_repository.dart';

import 'desktop_workspace_test.dart' show WorkspaceEngine, FakeDefaults;
import 'qa_receipt_test.dart' show version;

class PendingReceipt extends SharedRepository {
  PendingReceipt() : super(SharedFileService());
  Completer<void>? pending;
  bool? attached;
  @override
  Future<void> accept(
    Map<String, dynamic> value, {
    bool attachToDocument = true,
  }) async {
    attached = attachToDocument;
    await pending?.future;
  }
}

void main() {
  testWidgets(
    'home receipt locks destination, rejects disconnected late result, creates a separate direct QA and reopens provenance',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync('qa-home-vm-');
      addTearDown(() => directory.deleteSync(recursive: true));
      debugPrint('home fixture: directory');
      late DesktopWorkspaceViewModel desktop;
      late ProjectHomeViewModel renderedHome;
      final showHome = ValueNotifier(true);
      addTearDown(showHome.dispose);
      await tester.pumpWidget(
        AppProviders(
          engineService: WorkspaceEngine(),
          desktopDefaultsService: FakeDefaults(),
          workspaceFileService: WorkspaceFileService(directory: directory),
          child: Builder(
            builder: (context) {
              desktop = context.read<DesktopWorkspaceViewModel>();
              renderedHome = context.read<ProjectHomeViewModel>();
              return ValueListenableBuilder<bool>(
                valueListenable: showHome,
                builder: (_, visible, _) =>
                    visible ? const QaApp() : const SizedBox.shrink(),
              );
            },
          ),
        ),
      );
      debugPrint('home fixture: pumped');
      for (var i = 0; i < 100 && !desktop.initialized; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      expect(desktop.initialized, true);
      await tester.pumpAndSettle();
      Finder searchField() => find.byKey(
        ValueKey('home-search-${renderedHome.queryResetRevision}'),
      );
      String visibleQuery() => tester
          .widget<TextField>(
            find.descendant(
              of: searchField(),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text;
      await tester.enterText(searchField(), 'search example');
      expect(renderedHome.query, 'search example');
      await tester.tap(find.text('서버에서 받기'));
      await tester.pumpAndSettle();
      expect(renderedHome.query, isEmpty);
      expect(visibleQuery(), isEmpty);
      await tester.enterText(searchField(), 'same section');
      await tester.tap(find.text('서버에서 받기'));
      await tester.pumpAndSettle();
      expect(renderedHome.query, isEmpty);
      expect(visibleQuery(), isEmpty);
      await tester.enterText(searchField(), 'return home');
      showHome.value = false;
      await tester.pumpAndSettle();
      showHome.value = true;
      await tester.pumpAndSettle();
      expect(renderedHome.query, 'return home');
      expect(visibleQuery(), renderedHome.query);
      await tester.tap(find.text('내 프로젝트'));
      await tester.pumpAndSettle();
      expect(visibleQuery(), isEmpty);
      debugPrint('home fixture: initialized');
      await tester.runAsync(() => desktop.createProject('First'));
      final first = desktop.workspace.projectId!;
      await tester.runAsync(() => desktop.createQa('Existing'));
      final original = desktop.workspace.qa!;
      debugPrint('home fixture: first QA');
      await tester.runAsync(() => desktop.createProject('Second'));
      final second = desktop.workspace.projectId!;
      debugPrint('home fixture: second project');
      final repo = PendingReceipt()
        ..origin = 'http://localhost'
        ..project = 'remote';
      final shared = SharedViewModel(repo, desktop.work.run)
        ..connected = true
        ..preview = version('<received/>', 'version-1');
      final receipts = QaReceiptRepository(
        QaReceiptFileService(directory.path),
      );
      final home =
          ProjectHomeViewModel(
              desktop,
              shared,
              desktop.work.auth,
              receipts,
              XmlBlockRepository(),
            )
            ..serverProject = 'remote'
            ..projects = [
              {'id': 'remote', 'name': 'Remote', 'role': 'qa_tester'},
            ];
      addTearDown(() {
        home.dispose();
        shared.dispose();
        repo.dispose();
      });
      await tester.runAsync(() async {
        repo.pending = Completer<void>();
        debugPrint('home fixture: pending receive');
        final pending = home.receive(first, 'Received');
        await Future<void>.delayed(Duration.zero);
        expect(home.busy, true);
        home.chooseDestination(second);
        expect(home.destination, isNull);
        home.navigate('received');
        expect(home.section, 'projects');
        home.disconnect();
        repo.pending!.complete();
        expect(await pending, false);
      });
      expect(
        desktop.workspace.workspace.projects.first.documents.single.id,
        original.id,
      );
      expect(repo.receivedVersion, isNull);
      expect(repo.attached, false);
      debugPrint('home fixture: cancelled');
      repo.pending = null;
      repo.origin = 'http://localhost';
      repo.project = 'remote';
      shared.connected = true;
      shared.preview = version('<received/>', 'version-1');
      home.serverProject = 'remote';
      home.projects = [
        {'id': 'remote', 'name': 'Remote', 'role': 'qa_tester'},
      ];
      await tester.runAsync(() async {
        expect(await home.receive(first, 'Received'), true);
      });
      debugPrint('home fixture: received first');
      final receivedId = desktop.workspace.qaId!;
      expect(receivedId, isNot(original.id));
      expect(
        desktop.workspace.workspace.projects.first.documents.first.source,
        original.source,
      );
      expect(desktop.work.source, '<received/>');
      expect(home.receipt(first, receivedId)!.versionId, 'version-1');
      final saved = await tester.runAsync(
        () => XmlBlockRepository().read(directory.path, '$first/$receivedId'),
      );
      expect(saved!['mode'], 'direct');
      expect(home.duplicates.length, 1);
      await tester.runAsync(() async {
        expect(await home.receive(second, 'Another copy'), true);
      });
      expect(home.duplicates.length, 2);
      expect(desktop.workspace.projectId, second);
      debugPrint('home fixture: received second');
      await tester.runAsync(home.refreshReceipts);
      expect(home.received.length, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
