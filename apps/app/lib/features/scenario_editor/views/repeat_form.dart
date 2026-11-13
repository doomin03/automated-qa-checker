import 'dart:convert';

import 'package:flutter/material.dart';

class RepeatForm extends StatefulWidget {
  const RepeatForm({required this.blueprint, super.key});
  final Map<String, dynamic> blueprint;
  @override
  State<RepeatForm> createState() => _RepeatFormState();
}

class _RepeatFormState extends State<RepeatForm> {
  final _id = TextEditingController(text: 'repeatChecks'),
      _count = TextEditingController(text: '3');
  final List<String> _steps = [];
  String? _choice, _error;
  @override
  void dispose() {
    _id.dispose();
    _count.dispose();
    super.dispose();
  }

  void submit() {
    try {
      final b =
          jsonDecode(jsonEncode(widget.blueprint)) as Map<String, dynamic>;
      final nodes = b['flow']['nodes'] as List;
      final ends = nodes.where((n) => n['type'] == 'end').toList();
      final count = int.tryParse(_count.text);
      if (ends.length != 1 ||
          _steps.isEmpty ||
          count == null ||
          count < 1 ||
          count > 100 ||
          nodes.any((n) => n['id'] == _id.text) ||
          !RegExp(r'^[A-Za-z][A-Za-z0-9_.-]{0,127}$').hasMatch(_id.text)) {
        throw const FormatException();
      }
      final steps = [
        for (var i = 0; i < _steps.length; i++)
          {
            ...Map<String, dynamic>.from(
              nodes.firstWhere((n) => n['id'] == _steps[i]),
            ),
            'id': 'body${i + 1}',
          },
      ];
      final end = ends.single['id'];
      final edges = b['flow']['edges'] as List;
      for (final e in edges) {
        if (e['to'] == end) e['to'] = _id.text;
      }
      nodes.insert(nodes.length - 1, {
        'id': _id.text,
        'type': 'repeat',
        'count': count,
        'steps': steps,
      });
      edges.add({'from': _id.text, 'to': end});
      Navigator.pop(
        context,
        jsonEncode({'schemaVersion': 'qa.authoring/v1', 'blueprint': b}),
      );
    } catch (_) {
      setState(() => _error = '단일 종료 노드, 고유 반복 ID, 횟수 1..100, 본문 블록을 확인하세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodes = (widget.blueprint['flow']['nodes'] as List)
        .where((n) => n['type'] == 'action' || n['type'] == 'assertion')
        .toList();
    return AlertDialog(
      title: const Text('반복 블록 작성'),
      content: SizedBox(
        width: 550,
        height: 420,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                '설정한 action/assertion 블록을 순서대로 복사하여 단일 종료 직전에 반복합니다. 기존 블록은 유지합니다. 분기·중첩 반복은 본문에서 지원하지 않습니다.',
              ),
              TextField(
                controller: _id,
                decoration: const InputDecoration(labelText: '반복 ID'),
              ),
              TextField(
                controller: _count,
                key: const Key('repeat-count'),
                decoration: const InputDecoration(labelText: '반복 횟수 1..100'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _choice,
                items: nodes
                    .map(
                      (n) => DropdownMenuItem<String>(
                        value: n['id'],
                        child: Text('${n['id']} · ${n['action']}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _choice = v),
                decoration: const InputDecoration(labelText: '본문에 복사할 설정된 블록'),
              ),
              TextButton(
                onPressed: _choice == null
                    ? null
                    : () => setState(() => _steps.add(_choice!)),
                child: const Text('본문 순서에 추가'),
              ),
              for (var i = 0; i < _steps.length; i++)
                ListTile(
                  title: Text('${i + 1}. ${_steps[i]}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _steps.removeAt(i)),
                  ),
                ),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: submit, child: const Text('작성 문서 만들기')),
      ],
    );
  }
}
