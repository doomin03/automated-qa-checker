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
      children: advanced
          ? [
              ModelTextField(
                key: const Key('engine-reference-root'),
                value: settings.referenceRoot,
                enabled: enabled,
                onChanged: (v) =>
                    vm.update(vm.value.copyWith(referenceRoot: v)),
                decoration: const InputDecoration(
                  labelText: '기준 PNG/폰트 폴더 절대 경로 (선택)',
                ),
              ),
              ModelTextField(
                key: const Key('engine-appium-config'),
                value: settings.appiumConfig,
                enabled: enabled,
                onChanged: (v) => vm.update(vm.value.copyWith(appiumConfig: v)),
                decoration: const InputDecoration(
                  labelText: 'Appium 설정 JSON 절대 경로 (모바일 실행)',
                ),
              ),
            ]
          : [
              ModelTextField(
                key: const Key('engine-node'),
                value: settings.nodePath,
                enabled: enabled,
                onChanged: (v) => vm.update(vm.value.copyWith(nodePath: v)),
                decoration: const InputDecoration(
                  labelText: 'Node 실행 파일 절대 경로',
                ),
              ),
              ModelTextField(
                key: const Key('engine-cli'),
                value: settings.cliPath,
                enabled: enabled,
                onChanged: (v) => vm.update(vm.value.copyWith(cliPath: v)),
                decoration: const InputDecoration(
                  labelText: '설치된 aqa.mjs 절대 경로',
                ),
              ),
              ModelTextField(
                key: const Key('engine-report'),
                value: settings.reportRoot,
                enabled: enabled,
                onChanged: (v) => vm.update(vm.value.copyWith(reportRoot: v)),
                decoration: const InputDecoration(labelText: '실행 결과 폴더 절대 경로'),
              ),
            ],
    );
  }
}
