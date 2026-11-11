import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/reference_input.dart';

class ReferenceForm extends StatefulWidget {
  const ReferenceForm({required this.root, required this.selectors, super.key});
  final String root;
  final List<String> selectors;
  @override
  State<ReferenceForm> createState() => _ReferenceFormState();
}

class _ReferenceFormState extends State<ReferenceForm> {
  final fields = <String, TextEditingController>{};
  String? error;
  @override
  void initState() {
    super.initState();
    for (final e in {
      'id': 'design-v1',
      'png': '',
      'rules': '',
      'width': '1280',
      'height': '720',
      'dpr': '1',
      'browserVersion': '',
      'os': 'win32',
      'locale': 'en-US',
      'colorScheme': 'light',
      'ready': '',
      'timeout': '5000',
      'channelTolerance': '0',
      'maxDiffRatio': '0',
      'fonts': '[]',
    }.entries) {
      fields[e.key] = TextEditingController(text: e.value);
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget input(String key, String label) => TextField(
    key: Key('design-$key'),
    controller: fields[key],
    decoration: InputDecoration(labelText: label),
  );
  void save() {
    try {
      final profile = {
        'viewport': {
          'width': int.parse(fields['width']!.text),
          'height': int.parse(fields['height']!.text),
        },
        'dpr': double.parse(fields['dpr']!.text),
        'browserVersion': fields['browserVersion']!.text,
        'os': fields['os']!.text,
        'locale': fields['locale']!.text,
        'colorScheme': fields['colorScheme']!.text,
        'fonts': jsonDecode(fields['fonts']!.text),
        'readiness': {
          'selector': fields['ready']!.text,
          'timeoutMs': int.parse(fields['timeout']!.text),
        },
      };
      Navigator.pop(
        context,
        ReferenceInput(
          root: widget.root,
          id: fields['id']!.text,
          pngPath: fields['png']!.text,
          measurementsPath: fields['rules']!.text,
          profileJson: jsonEncode(profile),
          channelTolerance: int.parse(fields['channelTolerance']!.text),
          maxDiffRatio: double.parse(fields['maxDiffRatio']!.text),
        ),
      );
    } catch (_) {
      setState(() => error = '수치와 폰트 JSON 입력을 확인하세요.');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('새 디자인 기준 버전'),
    content: SizedBox(
      width: 700,
      height: 560,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              '기준 폴더: ${widget.root}\n이미지에서 수치를 추정하지 않습니다. 수치 JSON은 공개 measurementRules의 source 없는 배열입니다.',
            ),
            Text('현재 selector 별칭: ${widget.selectors.join(', ')}'),
            input('id', '새 기준 ID / 버전'),
            input('png', 'PNG 상대 경로 (선택, 최대 10 MiB)'),
            input('rules', '수치 JSON 상대 경로 (선택, 최대 1 MiB)'),
            input('width', '기준 viewport width (CSS px)'),
            input('height', '기준 viewport height (CSS px)'),
            input('dpr', '기준 DPR'),
            input('browserVersion', '기준을 만든 정확 browser version'),
            input('os', '기준 OS: win32 / linux / darwin'),
            input('locale', '기준 locale'),
            input('colorScheme', '기준 theme: light / dark / no-preference'),
            input('ready', '준비 완료 selector 별칭'),
            input('timeout', '준비 timeout (ms)'),
            input('channelTolerance', '픽셀 channel 허용 차이 (0~255)'),
            input('maxDiffRatio', '허용 diff 비율 (0~1)'),
            input('fonts', '명시 웹폰트 배열 JSON (없으면 [])'),
            const Text(
              '현재 Flow의 end 진입 직전에 이미지·수치 검사 노드를 연결합니다. URL과 selector는 기존 대상 설정에서 지정하세요. 기준 원본을 덮어쓰지 않습니다.',
            ),
            if (error != null) Text(error!),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(onPressed: save, child: const Text('기준을 새 XML에 연결')),
    ],
  );
}
