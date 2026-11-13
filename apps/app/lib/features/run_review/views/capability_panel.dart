import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/engine_settings_view_model.dart';
import '../view_models/run_view_model.dart';

class CapabilityPanel extends StatelessWidget {
  const CapabilityPanel({required this.busy, required this.inspect, super.key});
  final bool busy;
  final VoidCallback inspect;
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<EngineSettingsViewModel>();
    final vm = context.watch<RunViewModel>();
    return ExpansionTile(
      title: const Text('실행 대상·지원 기능 확인'),
      children: [
        DropdownButton<String>(
          key: const Key('capability-platform'),
          value: settings.platform,
          items: const [
            'web',
            'android',
            'ios',
          ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: busy
              ? null
              : (v) {
                  if (v != null) settings.selectPlatform(v);
                },
          hint: const Text('진단 대상 플랫폼'),
        ),
        TextButton(
          key: const Key('capability-inspect'),
          onPressed: busy ? null : inspect,
          child: const Text('고정 엔진 대상 조회 (실행 안 함)'),
        ),
        if (vm.capabilities != null) ...[
          Text(
            '지원 액션: ${(vm.capabilities!['supportedActions'] as List).join(', ')}',
            key: const Key('capability-actions'),
          ),
          if ((vm.capabilities!['targets'] as List).isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey(
                'capability-target-${vm.capabilities!['engineVersion']}-${vm.capabilities!['platforms']}',
              ),
              initialValue:
                  (vm.capabilities!['targets'] as List).first as String,
              items: (vm.capabilities!['targets'] as List)
                  .map(
                    (v) => DropdownMenuItem(value: v as String, child: Text(v)),
                  )
                  .toList(),
              onChanged: busy ? null : (_) {},
              decoration: const InputDecoration(labelText: '공개 엔진 실행 대상'),
            ),
          Text(
            settings.platform == 'web'
                ? 'Chromium 설치 진단입니다. 현재 공개 web 대상은 chromium-headless 하나이며 실제 실행은 문서 target을 따릅니다.'
                : 'native 정적 설정: ${vm.capabilities!['diagnostics']?['nativeConfigured'] == true ? '설정됨' : '설정 없음'} · 실제 기기 연결 미검증. targets가 비어 있어도 지원 불가 판정은 아닙니다. Appium 설정을 입력하고 명시 실행에서 연결을 확인합니다.',
            key: const Key('capability-status'),
          ),
        ],
      ],
    );
  }
}
