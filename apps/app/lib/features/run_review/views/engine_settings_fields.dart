import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/model_text_field.dart';
import '../view_models/engine_settings_view_model.dart';

class EngineSettingsFields extends StatelessWidget {
  const EngineSettingsFields({
    required this.enabled,
    this.advanced = false,
    super.key,
  });
  final bool enabled, advanced;
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EngineSettingsViewModel>();
    final settings = vm.value;
    return Column(
      spacing: 12,
      children: advanced
          ? [
              ModelTextField(
                key: const Key('engine-reference-root'),
                value: settings.referenceRoot,
                enabled: enabled,
                onChanged: (v) =>
                    vm.update(vm.value.copyWith(referenceRoot: v)),
                decoration: const InputDecoration(
                  isDense: false,
                  contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 14),
                  labelText: '기준 PNG/폰트 폴더 절대 경로 (선택)',
                ),
              ),
              ModelTextField(
                key: const Key('engine-appium-config'),
                value: settings.appiumConfig,
                enabled: enabled,
                onChanged: (v) => vm.update(vm.value.copyWith(appiumConfig: v)),
                decoration: const InputDecoration(
                  isDense: false,
                  contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 14),
                  labelText: 'Appium 설정 JSON 절대 경로 (모바일 실행)',
                ),
              ),
            ]
          : [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: enabled && vm.canUseDefaults
                      ? vm.useDefaults
                      : null,
                  child: Text(
                    vm.usesAutomaticRuntime
                        ? '기본 실행 환경 사용 중'
                        : '이 앱의 기본 실행 환경 사용',
                  ),
                ),
              ),
              ModelTextField(
                key: const Key('engine-node'),
                value: settings.nodePath,
                enabled: enabled,
                onChanged: (v) => vm.update(vm.value.copyWith(nodePath: v)),
                decoration: const InputDecoration(
                  isDense: false,
                  contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 14),
                  labelText: 'Node 실행 파일 절대 경로',
                ),
              ),
              ModelTextField(
                key: const Key('engine-cli'),
                value: settings.cliPath,
                enabled: enabled,
                onChanged: (v) => vm.update(vm.value.copyWith(cliPath: v)),
                decoration: const InputDecoration(
                  isDense: false,
                  contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 14),
                  labelText: '설치된 aqa.mjs 절대 경로',
                ),
              ),
              ModelTextField(
                key: const Key('engine-report'),
                value: settings.reportRoot,
                enabled: enabled,
                onChanged: (v) => vm.update(vm.value.copyWith(reportRoot: v)),
                decoration: const InputDecoration(
                  isDense: false,
                  contentPadding: EdgeInsets.fromLTRB(12, 18, 12, 14),
                  labelText: '실행 결과 폴더 절대 경로',
                ),
              ),
            ],
    );
  }
}
