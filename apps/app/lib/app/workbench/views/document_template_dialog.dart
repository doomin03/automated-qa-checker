import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/document_template_view_model.dart';
import 'adaptive_workbench.dart';

class DocumentTemplateDialog extends StatefulWidget {
  const DocumentTemplateDialog({super.key});
  @override
  State<DocumentTemplateDialog> createState() => _DocumentTemplateDialogState();
}

class _DocumentTemplateDialogState extends State<DocumentTemplateDialog> {
  final name = TextEditingController(text: '새 템플릿 QA'),
      id = TextEditingController(text: 'new-qa'),
      url = TextEditingController(text: 'http://127.0.0.1:4339'),
      selector = TextEditingController(text: 'username'),
      value = TextEditingController(text: 'qa-user'),
      advanced = TextEditingController();
  String? selected, error;
  bool useAdvanced = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DocumentTemplateViewModel>().load();
    });
  }

  @override
  void dispose() {
    for (final c in [name, id, url, selector, value, advanced]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> bindings(String template) {
    final uri = Uri.parse(url.text.trim());
    final output = <String, dynamic>{
      'id': id.text.trim(),
      'target': {
        'schemaVersion': 'qa.target/v1',
        'id': 'web-target',
        'platform': 'web',
        'environment': 'local',
        'launchTargets': {'main': uri.toString()},
        'allowedOrigins': [uri.origin],
      },
    };
    if (template != 'empty') {
      output.addAll({
        'launch': 'main',
        'selector': 'element',
        'selectors': {
          'schemaVersion': 'qa.selectors/v1',
          'id': 'selectors',
          'selectors': {
            'element': {
              'web': {'strategy': 'testId', 'value': selector.text},
            },
          },
        },
      });
    }
    if (template == 'web-input-check') {
      output['value'] = value.text;
    }
    return output;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DocumentTemplateViewModel>();
    final template = vm.catalog.where((t) => t['id'] == selected).firstOrNull;
    return AlertDialog(
      title: const Text('템플릿으로 새 QA'),
      content: WorkbenchDialogBody(
        width: 850,
        height: 650,
        child: SingleChildScrollView(
          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('입력 → 생성·검증 → 미리보기 → 새 QA 저장. 실행은 별도로 요청합니다.'),
              DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '기술 템플릿'),
                items: [
                  for (final t in vm.catalog)
                    DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text('${t['id']} · ${t['version']}'),
                    ),
                ],
                onChanged: vm.busy
                    ? null
                    : (v) {
                        vm.clear();
                        setState(() {
                          selected = v;
                          error = null;
                        });
                      },
              ),
              if (template != null) Text(template['description'] as String),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'QA 이름'),
              ),
              TextField(
                enabled: !vm.busy,
                onChanged: (_) => vm.clear(),
                controller: id,
                decoration: const InputDecoration(labelText: '문서 ID'),
              ),
              TextField(
                enabled: !vm.busy,
                onChanged: (_) => vm.clear(),
                controller: url,
                decoration: const InputDecoration(labelText: '웹 시작 URL'),
              ),
              if (selected != 'empty')
                TextField(
                  enabled: !vm.busy,
                  onChanged: (_) => vm.clear(),
                  controller: selector,
                  decoration: const InputDecoration(labelText: '대상 testId'),
                ),
              if (selected == 'web-input-check')
                TextField(
                  enabled: !vm.busy,
                  onChanged: (_) => vm.clear(),
                  controller: value,
                  decoration: const InputDecoration(
                    labelText: '입력·확인할 값 (비밀은 고급 secretRef 사용)',
                  ),
                ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: useAdvanced,
                title: const Text('고급 bindings JSON / native 대상'),
                onChanged: vm.busy
                    ? null
                    : (v) {
                        vm.clear();
                        setState(() {
                          useAdvanced = v!;
                          if (useAdvanced && advanced.text.isEmpty) {
                            try {
                              advanced.text = const JsonEncoder.withIndent('  ')
                                  .convert(bindings(selected ?? 'empty'));
                            } catch (_) {
                              advanced.text = '{}';
                            }
                          }
                        });
                      },
              ),
              if (useAdvanced)
                TextField(
                  enabled: !vm.busy,
                  onChanged: (_) => vm.clear(),
                  controller: advanced,
                  minLines: 6,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText:
                        '공개 inputSchema의 bindings · native target은 직접 지정',
                  ),
                ),
              if (template != null)
                ExpansionTile(
                  title: const Text('공개 입력 규격'),
                  children: [
                    SelectableText(
                      const JsonEncoder.withIndent('  ')
                          .convert(template['inputSchema']),
                    ),
                  ],
                ),
              if (vm.error != null || error != null)
                Text(
                  error ?? vm.error!,
                  style: const TextStyle(color: Colors.orange),
                ),
              if (vm.candidate != null) ...[
                const Divider(),
                const Text('검증된 생성 XML · 아직 저장하지 않음'),
                SelectableText(vm.candidate!['xml'] as String),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        TextButton(
          key: const Key('template-generate'),
          onPressed: vm.busy || template == null
              ? null
              : () async {
                  try {
                    final input = useAdvanced
                        ? Map<String, dynamic>.from(jsonDecode(advanced.text))
                        : bindings(selected!);
                    setState(() => error = null);
                    await vm.generate(template, input);
                  } catch (e) {
                    if (mounted) setState(() => error = '$e');
                  }
                },
          child: Text(vm.busy ? '생성·검증 중' : '생성·검증'),
        ),
        FilledButton(
          key: const Key('template-accept'),
          onPressed: vm.busy || !vm.current
              ? null
              : () async {
                  if (name.text.trim().isEmpty) {
                    setState(() => error = 'QA 이름을 입력하세요.');
                    return;
                  }
                  if (await vm.accept(name.text.trim()) && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
          child: const Text('새 QA로 저장'),
        ),
      ],
    );
  }
}
