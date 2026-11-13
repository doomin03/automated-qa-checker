import 'package:flutter/material.dart';

class PresetForm extends StatefulWidget {
  const PresetForm({required this.presets, required this.blueprint, super.key});
  final List<Map<String, dynamic>> presets;
  final Map<String, dynamic> blueprint;
  @override
  State<PresetForm> createState() => _PresetFormState();
}

class _PresetFormState extends State<PresetForm> {
  late String id = widget.presets.first['id'];
  final fields = <String, TextEditingController>{};
  bool secret = false;
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.presets.firstWhere((p) => p['id'] == id);
    final keys = (preset['inputBindings'] as List).cast<String>().where(
      (k) => !['target', 'selectors'].contains(k),
    );
    for (final key in keys) {
      fields.putIfAbsent(key, () => TextEditingController());
    }
    return AlertDialog(
      title: const Text('공개 UX 팩 매핑'),
      content: SizedBox(
        width: 650,
        height: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButton<String>(
                value: id,
                items: widget.presets
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(p['id']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => id = v!),
              ),
              SelectableText(
                'version ${preset['version']}\nhash ${preset['sha256']}\nrequired ${preset['requiredCapabilities']}',
              ),
              Text(
                'target/selector는 현재 검증한 XML에서 가져옵니다. 대상: ${(widget.blueprint['target']['launchTargets'] as Map).keys.join(', ')}\nselector: ${(widget.blueprint['selectors']['selectors'] as Map).keys.join(', ')}',
              ),
              for (final key in keys)
                TextField(
                  key: Key('preset-$key'),
                  controller: fields[key],
                  decoration: InputDecoration(labelText: key),
                ),
              if (keys.contains('value'))
                CheckboxListTile(
                  value: secret,
                  onChanged: (v) => setState(() => secret = v!),
                  title: const Text('value는 비밀값 대신 secretRef 이름'),
                ),
              const Text(
                '매핑한 웹 입력/경로만 검사합니다. 브라우저 hit-test는 실제 OS 키보드 검사나 모든 overlay 검사가 아닙니다. back 기대 URL과 selector를 직접 지정하세요.',
              ),
              const Text(
                'secretRef는 XML에 참조만 저장합니다. 실제 실행에는 앱을 시작한 환경의 Engine AQA_SECRET_* 변수가 필요하며 입력값을 여기 붙여넣지 않습니다.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final bindings = <String, dynamic>{
              'target': widget.blueprint['target'],
              'selectors': widget.blueprint['selectors'],
              for (final key in keys) key: fields[key]!.text,
            };
            if (secret && bindings.containsKey('value')) {
              bindings['value'] = {'secretRef': bindings['value']};
            }
            Navigator.pop(context, {
              'id': id,
              'version': preset['version'],
              'bindings': bindings,
            });
          },
          child: const Text('팩 XML 만들기 (미실행)'),
        ),
      ],
    );
  }
}
