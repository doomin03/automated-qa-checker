import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xterm2/xterm.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/desktop_workspace_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/xml_block_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/xml_blocks/models/xml_block_document.dart';
import 'package:automated_qa_desktop/app/workbench/views/adaptive_workbench.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/project_home_view_model.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/terminal_workbench_view_model.dart';
import 'package:automated_qa_desktop/features/interactive_terminal/models/terminal_profile.dart';

import 'terminal_workspace_test.dart' show IdleTerminal;

import 'desktop_workspace_test.dart' show WorkspaceEngine, FakeDefaults;

void main() {
  testWidgets(
    'compact detail excludes hidden keyboard focus and preserves text',
    (tester) async {
      final first = FocusNode(), second = FocusNode();
      final input = TextEditingController(text: '보존할 편집');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      addTearDown(input.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: WorkbenchMasterDetail(
                primary: TextField(focusNode: first, controller: input),
                detail: TextField(focusNode: second),
              ),
            ),
          ),
        ),
      );
      first.requestFocus();
      await tester.pump();
      expect(first.hasFocus, isTrue);
      await tester.tap(find.byKey(const Key('compact-detail')));
      await tester.pump();
      expect(first.canRequestFocus, isFalse);
      second.requestFocus();
      await tester.pump();
      expect(second.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(first.hasFocus, isFalse);
      await tester.tap(find.text('목록'));
      await tester.pump();
      expect(second.canRequestFocus, isFalse);
      expect(input.text, '보존할 편집');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('compact home and editor keep actions at large text scale', (
    tester,
  ) async {
    final originalError = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(details.toString());
      originalError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalError);
    final dir = Directory.systemTemp.createTempSync('qa-adaptive-');
    addTearDown(() => dir.deleteSync(recursive: true));
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    late DesktopWorkspaceViewModel vm;
    late XmlBlockWorkbenchViewModel blocks;
    late ProjectHomeViewModel home;
    late TerminalWorkbenchViewModel terminals;
    final blueprint = Map<String, dynamic>.from(
      jsonDecode(
        File('assets/desktop-engine-contract.json').readAsStringSync(),
      )['example'],
    );
    await tester.pumpWidget(
      AppProviders(
        engineService: WorkspaceEngine()..blueprint = blueprint,
        desktopDefaultsService: FakeDefaults(),
        terminalServiceFactory: IdleTerminal.new,
        workspaceFileService: WorkspaceFileService(directory: dir),
        child: Builder(
          builder: (context) {
            vm = context.read<DesktopWorkspaceViewModel>();
            blocks = context.read<XmlBlockWorkbenchViewModel>();
            home = context.read<ProjectHomeViewModel>();
            terminals = context.read<TerminalWorkbenchViewModel>();
            return const QaApp();
          },
        ),
      ),
    );
    for (var i = 0; i < 100 && !vm.initialized; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(vm.initialized, isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(
      () => vm.createProject('긴 한국어 프로젝트 이름으로 화면 배치와 탐색 상태를 확인합니다'),
    );
    await tester.runAsync(() => vm.createQa('작은 창에서 작성하고 실행할 수 있는 긴 이름의 QA'));
    for (var i = 0; i < 100 && blocks.busy; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('workspace-validate')), findsOneWidget);
    await tester.runAsync(
      () => terminals.add(
        TerminalProfile(
          'cmd',
          'fixture',
          Platform.resolvedExecutable,
          readiness: 'available',
        ),
      ),
    );
    final terminalKey = ValueKey(
      'interactive-terminal-${terminals.selected.id}',
    );
    blocks.assets.add(
      XmlBlockAsset(
        id: 'fixture',
        name: '매우 긴 한국어 테스트 블록 이름.xml',
        path: 'fixture.xml',
        xml: '<fixture/>',
        blueprint: blueprint,
      ),
    );
    blocks.add('fixture');
    final documentIdentity = blocks.identity;
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1440, 900);
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    await tester.pumpAndSettle();
    await tester.tap(find.text('탐색').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI 작성 도구').first);
    await tester.pumpAndSettle();
    final canvasController = tester
        .widget<InteractiveViewer>(find.byKey(const Key('xml-block-viewport')))
        .transformationController!;
    canvasController.value = Matrix4.diagonal3Values(.8, .8, 1);
    final selectedBlock = blocks.selected;
    TerminalController? terminalController;
    ScrollController? terminalScroll;
    for (final size in [
      const Size(1440, 900),
      const Size(1024, 768),
      const Size(800, 600),
      const Size(1280, 500),
    ]) {
      for (final scale in [1.0, 1.25, 1.5]) {
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size / text $scale');
        expect(blocks.identity, documentIdentity);
        expect(
          identical(
            tester
                .widget<InteractiveViewer>(
                  find.byKey(const Key('xml-block-viewport')),
                )
                .transformationController,
            canvasController,
          ),
          isTrue,
        );
        expect(canvasController.value.storage[0], .8);
        expect(blocks.selected, selectedBlock);
        expect(
          tester.getSize(find.byKey(const Key('xml-block-viewport'))).height,
          greaterThan(150),
        );
        await tester.tap(find.byKey(const Key('studio-properties')));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'properties $size / $scale',
        );
        final close = find.text('닫기');
        if (close.evaluate().isNotEmpty) {
          await tester.tap(close.last);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('터미널 열기'));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'terminal $size / $scale',
        );
        expect(find.byKey(terminalKey), findsOneWidget);
        final terminalView = tester.widget<TerminalView>(
          find.byKey(terminalKey),
        );
        terminalController ??= terminalView.controller;
        terminalScroll ??= terminalView.scrollController;
        expect(identical(terminalView.controller, terminalController), isTrue);
        expect(
          identical(terminalView.scrollController, terminalScroll),
          isTrue,
        );
        terminalView.focusNode!.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.delete);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        expect(blocks.instances.length, 1);
        if (find.text('작업실로').evaluate().isNotEmpty) {
          await tester.tap(find.text('작업실로'));
          await tester.pumpAndSettle();
        }
        final before = tester.getSize(
          find.byKey(const Key('xml-block-viewport')),
        );
        expect(
          before.height,
          greaterThan(100),
          reason: 'usable canvas $size / $scale',
        );
        await tester.tap(find.text('실행 로그 / 결과'));
        await tester.pumpAndSettle();
        if (size.height >= 700) {
          expect(find.text('터미널 열기'), findsOneWidget);
        }
        expect(tester.takeException(), isNull, reason: 'result $size / $scale');
        await tester.tap(find.text(size.height < 700 ? '결과 닫기' : '결과 접기'));
        await tester.pumpAndSettle();
        if (find.text('터미널 접기').evaluate().isNotEmpty) {
          await tester.tap(find.text('터미널 접기'));
          await tester.pumpAndSettle();
        }
      }
    }
    blocks.setEnabled(false);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('XML 원문'));
    await tester.tap(find.text('XML 원문'));
    await tester.pumpAndSettle();
    final rawField = find.byKey(const Key('workspace-source'));
    await tester.tap(rawField);
    await tester.pump();
    final controller = tester.widget<TextField>(rawField).controller!;
    controller.selection = const TextSelection(baseOffset: 4, extentOffset: 9);
    final rawFocus = tester
        .widget<EditableText>(
          find.descendant(of: rawField, matching: find.byType(EditableText)),
        )
        .focusNode;
    for (final size in [
      const Size(1440, 900),
      const Size(800, 600),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      await tester.pumpAndSettle();
      expect(
        identical(tester.widget<TextField>(rawField).controller, controller),
        true,
      );
      expect(
        controller.selection,
        const TextSelection(baseOffset: 4, extentOffset: 9),
      );
      expect(rawFocus.hasFocus, true);
      expect(tester.takeException(), isNull);
    }
    final project = vm.workspace.projectId!, qa = vm.workspace.qaId!;
    tester.view.physicalSize = const Size(800, 600);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('실행 환경 / 연결').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final inputs = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.tap(inputs.first);
    for (var i = 0; i < 18; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused != null) {
        final box = focused.findRenderObject();
        if (box is RenderBox && box.hasSize) {
          final center = box.localToGlobal(box.size.center(Offset.zero));
          expect(
            center.dy,
            inInclusiveRange(0, 600),
            reason: 'focused settings control $i',
          );
        }
      }
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text('닫기').last);
    await tester.pumpAndSettle();
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    for (final ratio in [1.0, 1.25, 1.5]) {
      tester.view.devicePixelRatio = ratio;
      tester.view.physicalSize = Size(1024 * ratio, 768 * ratio);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'logical 1024x768 / DPR $ratio',
      );
      expect(
        identical(tester.widget<TextField>(rawField).controller, controller),
        true,
      );
      expect(
        controller.selection,
        const TextSelection(baseOffset: 4, extentOffset: 9),
      );
    }
    tester.view.devicePixelRatio = 1;
    vm.select(project, null);
    home.chooseLocalQa(qa);
    for (final size in [
      const Size(1440, 900),
      const Size(1024, 768),
      const Size(800, 600),
      const Size(1280, 500),
    ]) {
      for (final scale in [1.0, 1.25, 1.5]) {
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'home $size / $scale');
        final detail = find.byKey(const Key('compact-detail'));
        if (detail.evaluate().isNotEmpty) {
          await tester.tap(detail);
          await tester.pumpAndSettle();
          expect(find.text('최근 실행  실행 전'), findsOneWidget);
          await tester.tap(find.text('목록'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const Key('home-connect')));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'connection dialog $size / $scale',
        );
        await tester.tap(find.text('취소').last);
        await tester.pumpAndSettle();
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
