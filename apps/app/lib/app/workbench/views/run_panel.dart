import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/workbench_view_model.dart';
import '../../../features/server_connection/views/server_panel.dart';
import '../../../features/run_review/views/engine_settings_fields.dart';
import '../../../features/run_review/views/capability_panel.dart';
import '../../../features/run_review/views/run_results.dart';
import '../../../features/design_baselines/views/reference_form.dart';
import '../../../features/design_baselines/models/reference_input.dart';
import '../../../features/scenario_editor/views/preset_form.dart';
import '../../../features/scenario_editor/views/repeat_form.dart';
import 'shared_panel.dart';

class RunPanel extends StatelessWidget {
  const RunPanel({
    this.execute,
    this.validate,
    this.blocked = false,
    this.openReceivedHome,
    super.key,
  });
  final VoidCallback? execute, validate;
  final VoidCallback? openReceivedHome;
  final bool blocked;
  @override
  Widget build(BuildContext context) {
    final work = context.watch<WorkbenchViewModel>();
    final run = work.run;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('로컬 엔진 · 검증 후 명시 실행'),
          const ServerPanel(),
          SharedPanel(openReceivedHome: openReceivedHome),
          CapabilityPanel(busy: work.busy, inspect: work.inspectCapabilities),
          EngineSettingsFields(enabled: !work.busy),
          ExpansionTile(
            title: const Text('디자인 기준 / Appium 로컬 설정'),
            children: [
              TextButton(
                onPressed: work.busy
                    ? null
                    : () async {
                        final ticket = work.stamp;
                        final input = await showDialog<ReferenceInput>(
                          context: context,
                          builder: (_) => ReferenceForm(
                            root: work.settings.execution.referenceRoot,
                            selectors: work.selectorIds,
                          ),
                        );
                        if (!context.mounted || input == null) return;
                        await work.attachReference(input, ticket);
                      },
                child: const Text('PNG·수치 기준 연결'),
              ),
              if (work.design.busy) const Text('기준 파일·Engine 검증 중 (미실행)'),
              if (work.design.error != null) Text(work.design.error!),
              if (work.design.summary != null)
                SelectableText(work.design.summary!),
              TextButton(
                onPressed:
                    work.busy || work.flow.presets.isEmpty || !work.canUsePlan
                    ? null
                    : () async {
                        final ticket = work.stamp;
                        final selected = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (_) => PresetForm(
                            presets: work.flow.presets,
                            blueprint: run.plan!['blueprint'],
                          ),
                        );
                        if (!context.mounted || selected == null) return;
                        await work.expandPreset(selected, ticket);
                      },
                child: const Text('검증한 대상에 UX 팩 매핑'),
              ),
              EngineSettingsFields(enabled: !work.busy, advanced: true),
              const Text(
                '고정 배포판 지원이 필요합니다. 설정 파일의 endpoint/기기 정보는 XML에 저장하지 않습니다. 기기 연결은 실제 실행 때 확인하며 정적 설정 검사는 실기기 검증이 아닙니다.',
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: work.busy ? null : work.expandAuthoring,
                child: const Text('작성 XML/JSON 전개 (미실행)'),
              ),
              OutlinedButton(
                onPressed: work.busy || !work.canUsePlan
                    ? null
                    : () async {
                        final ticket = work.stamp;
                        final source = await showDialog<String>(
                          context: context,
                          builder: (_) =>
                              RepeatForm(blueprint: run.plan!['blueprint']),
                        );
                        if (!context.mounted || source == null) return;
                        await work.expandAuthoring(
                          document: source,
                          ticket: ticket,
                        );
                      },
                child: const Text('검증한 블록으로 반복 작성'),
              ),
              OutlinedButton(
                onPressed: work.busy ? null : work.exportXml,
                child: const Text('원문을 XML로 변환'),
              ),
              OutlinedButton(
                key: const Key('engine-validate'),
                onPressed: work.busy || blocked
                    ? null
                    : validate ?? work.validate,
                child: const Text('검증·계획'),
              ),
              FilledButton(
                key: const Key('engine-run'),
                onPressed: work.busy || blocked
                    ? null
                    : execute ?? work.execute,
                child: const Text('테스트 실행'),
              ),
              OutlinedButton(
                key: const Key('engine-cancel'),
                onPressed: run.running ? work.cancel : null,
                child: const Text('실행 취소'),
              ),
            ],
          ),
          if (work.message != null)
            Text(work.message!, key: const Key('workbench-message')),
          RunResults(source: work.source),
        ],
      ),
    );
  }
}
