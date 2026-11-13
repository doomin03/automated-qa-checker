import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/run_view_model.dart';

class RunResults extends StatelessWidget {
  const RunResults({required this.source, super.key});
  final String source;
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RunViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(vm.status, key: const Key('engine-status')),
        if (vm.expansion != null)
          SelectableText(
            '원본·대응표·확장 XML 보관: ${vm.expansion!.directory}\n확장 XML을 확인하고 다시 검증한 뒤 실행하세요. 편집한 초안에는 이전 반복 라벨을 적용하지 않습니다.',
          ),
        if (vm.error != null)
          Text(
            vm.error!,
            key: const Key('engine-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (vm.reportDirectory != null)
          SelectableText(
            '결과: ${vm.reportDirectory}\n웹에서 이 폴더의 blueprint.json / events.jsonl을 여세요.',
          ),
        if (vm.plan != null)
          SelectableText(
            '계획: ${(vm.plan!['nodeOrder'] as List).join(' → ')}\n요구 액션: ${vm.plan!['requiredActions']}',
          ),
        for (final event in vm.events)
          Text(
            '${event['sequence']} · ${event['type']} · ${vm.iterationLabel(event['nodeId'] ?? '', source) ?? event['nodeId'] ?? ''} · ${event['outcome'] ?? ''}',
          ),
        for (final check in vm.checks)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${check['nodeId']} · ${check['kind']} · ${check['verdict']} · ${check['reason']}',
                  ),
                  SelectableText(
                    'expected: ${jsonEncode(check['expected'])}\nactual: ${jsonEncode(check['actual'])}\ntolerance: ${jsonEncode(check['tolerance'])}',
                  ),
                  for (final ref in check['artifactRefs'] as List)
                    Text('${ref['role']}: ${ref['path']}'),
                  if (check['fontsInjected'] == true)
                    const Text('명시한 테스트 폰트를 주입했습니다. 앱 원래 폰트 로딩 인수가 아닙니다.'),
                ],
              ),
            ),
          ),
        for (final evidence in vm.images)
          ExpansionTile(
            title: Text('검증된 PNG · ${evidence.path}'),
            children: [
              Image.memory(
                evidence.bytes,
                key: Key('evidence-image-${evidence.path}'),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Text('이미지를 표시할 수 없습니다. 원본 증거의 해석을 확인하세요.'),
              ),
            ],
          ),
        if (vm.result != null)
          SelectableText(
            const JsonEncoder.withIndent('  ').convert(vm.result),
            key: const Key('engine-result'),
          ),
      ],
    );
  }
}
