import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:automated_qa_desktop/app/providers/app_providers.dart';
import 'package:automated_qa_desktop/app/qa_app.dart';
import 'package:automated_qa_desktop/app/workbench/view_models/workbench_view_model.dart';
import 'package:automated_qa_desktop/features/run_review/models/engine_execution.dart';
import 'package:automated_qa_desktop/features/run_review/view_models/run_view_model.dart';
import 'package:automated_qa_desktop/features/run_review/repositories/engine_repository.dart';

import 'engine_bridge_test.dart' show IncompleteService;

class ControlledService extends IncompleteService {
  int closes = 0, exports = 0, presets = 0;
  Completer<String> exportResult = Completer<String>();
  Completer<Map<String, dynamic>> capabilityResult =
      Completer<Map<String, dynamic>>();
  Completer<PreparedScenario>? prepareResult;
  @override
  Future<PreparedScenario> prepare(EngineSettings settings, String source) =>
      prepareResult?.future ?? super.prepare(settings, source);
  @override
  Future<String> exportXml(EngineSettings settings, String source) {
    exports++;
    return exportResult.future;
  }

  @override
  Future<String> expandPreset(
    EngineSettings settings,
    String id,
    String version,
    Map<String, dynamic> bindings,
  ) async {
    presets++;
    return 'preset';
  }

  @override
  Future<Map<String, dynamic>> capabilities(
    EngineSettings settings,
    String platform,
  ) => capabilityResult.future;
  @override
  void dispose() {
    closes++;
  }
}

void main() {
  testWidgets(
    'settings and document survive panel remount; external updates project without duplicate edits',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      late WorkbenchViewModel work;
      await tester.pumpWidget(
        AppProviders(
          child: Builder(
            builder: (context) {
              work = context.read<WorkbenchViewModel>();
              return ValueListenableBuilder<bool>(
                valueListenable: visible,
                builder: (_, show, child) =>
                    show ? const QaApp(legacyEditor: true) : const SizedBox(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('engine-node')),
        r'C:\Program Files\node.exe',
      );
      await tester.enterText(find.byKey(const Key('scenario-source')), 'draft');
      await tester.ensureVisible(find.text('실행 대상·지원 기능 확인'));
      await tester.tap(find.text('실행 대상·지원 기능 확인'));
      await tester.pumpAndSettle();
      work.settings.selectPlatform('android');
      await tester.pump();
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.byKey(const Key('capability-platform')),
            )
            .value,
        'android',
      );
      final revision = work.editor.revision;
      visible.value = false;
      await tester.pump();
      visible.value = true;
      await tester.pumpAndSettle();
      expect(work.settings.value.nodePath, r'C:\Program Files\node.exe');
      expect(work.settings.platform, 'android');
      expect(find.text('draft'), findsOneWidget);
      expect(work.editor.revision, revision);
      final input = tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const Key('scenario-source')),
              matching: find.byType(EditableText),
            ),
          )
          .controller;
      input.value = const TextEditingValue(
        text: 'draft',
        selection: TextSelection(baseOffset: 1, extentOffset: 3),
        composing: TextRange(start: 1, end: 4),
      );
      work.settings.update(work.settings.value.copyWith(reportRoot: 'reports'));
      await tester.pump();
      expect(
        input.selection,
        const TextSelection(baseOffset: 1, extentOffset: 3),
      );
      expect(input.value.composing, const TextRange(start: 1, end: 4));
      work.editor.edit('received');
      await tester.pump();
      expect(find.text('received'), findsOneWidget);
      final projected = work.editor.revision;
      await tester.pump();
      expect(work.editor.revision, projected);
      expect(work.run.events, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'late transforms reject document ABA, changed settings, stale dialog ticket and disposed scope',
    (tester) async {
      final service = ControlledService();
      late WorkbenchViewModel work;
      await tester.pumpWidget(
        AppProviders(
          engineService: service,
          child: Builder(
            builder: (context) {
              work = context.read<WorkbenchViewModel>();
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      work.editor.edit('A');
      var pending = work.exportXml();
      work.editor.edit('B');
      work.editor.edit('A');
      service.exportResult.complete('old');
      await pending;
      expect(work.source, 'A');
      expect(work.message, contains('이전 결과'));
      service.exportResult = Completer<String>();
      pending = work.exportXml();
      work.settings.update(work.settings.value.copyWith(reportRoot: 'new'));
      service.exportResult.complete('old-settings');
      await pending;
      expect(work.source, 'A');
      final ticket = work.stamp;
      work.editor.edit('new document');
      await work.expandPreset({
        'id': 'old',
        'version': '1',
        'bindings': <String, dynamic>{},
      }, ticket);
      expect(service.presets, 0);
      expect(work.source, 'new document');
      service.exportResult = Completer<String>();
      pending = work.exportXml();
      final editor = work.editor;
      await tester.pumpWidget(const SizedBox());
      service.exportResult.complete('after-dispose');
      await pending;
      expect(editor.draft.content, 'new document');
      expect(tester.takeException(), isNull);
      expect(service.closes, 0);
      service.dispose();
    },
  );

  testWidgets(
    'settings changes invalidate pending capabilities and earlier validation',
    (tester) async {
      final service = ControlledService();
      late WorkbenchViewModel work;
      await tester.pumpWidget(
        AppProviders(
          engineService: service,
          child: Builder(
            builder: (context) {
              work = context.read<WorkbenchViewModel>();
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pending = work.inspectCapabilities();
      work.settings.selectPlatform('ios');
      service.capabilityResult.complete({
        'platforms': ['web'],
        'targets': ['old'],
        'supportedActions': [],
      });
      await pending;
      expect(work.run.capabilities, isNull);
      service.capabilityResult = Completer<Map<String, dynamic>>();
      final failed = work.inspectCapabilities();
      work.settings.selectPlatform('web');
      service.capabilityResult.completeError(
        const EngineException('obsolete diagnostic'),
      );
      await failed;
      expect(work.run.error, isNull);
      expect(work.run.capabilities, isNull);
      await work.validate();
      expect(work.canUsePlan, isTrue);
      final original = work.settings.value;
      work.settings.update(original.copyWith(cliPath: 'other'));
      work.settings.update(original);
      expect(work.canUsePlan, isFalse);
      service.prepareResult = Completer<PreparedScenario>();
      final staleValidation = work.validate();
      work.settings.selectPlatform('android');
      service.prepareResult!.completeError(
        const EngineException('obsolete validation'),
      );
      await staleValidation;
      expect(work.run.error, isNull);
      expect(work.run.status, 'validation_stale');
      expect(work.canUsePlan, isFalse);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
    },
  );

  testWidgets(
    'composition owns created service once; consumer disposal and borrowed injection do not close shared service',
    (tester) async {
      final owned = ControlledService();
      late EngineRepository repository;
      await tester.pumpWidget(
        AppProviders(
          engineServiceFactory: () => owned,
          child: Builder(
            builder: (context) {
              context.read<WorkbenchViewModel>();
              repository = context.read<EngineRepository>();
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final temporaryConsumer = RunViewModel(repository);
      temporaryConsumer.dispose();
      expect(owned.closes, 0);
      final pending = repository.exportXml(
        const EngineSettings(),
        'remaining-consumer',
      );
      owned.exportResult.complete('alive');
      expect(await pending, 'alive');
      await tester.pumpWidget(const SizedBox());
      expect(owned.closes, 1);
      final borrowed = ControlledService();
      await tester.pumpWidget(
        AppProviders(
          engineService: borrowed,
          child: Builder(
            builder: (context) {
              context.read<WorkbenchViewModel>();
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      expect(borrowed.closes, 0);
      borrowed.dispose();
      expect(borrowed.closes, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
