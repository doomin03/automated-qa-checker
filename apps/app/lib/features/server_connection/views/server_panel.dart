import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/server_view_model.dart';

class ServerPanel extends StatefulWidget {
  const ServerPanel({super.key});
  @override
  State<ServerPanel> createState() => _ServerPanelState();
}

class _ServerPanelState extends State<ServerPanel> {
  final _origin = TextEditingController(
    text: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:4319',
    ),
  );
  @override
  void dispose() {
    _origin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<ServerViewModel>(
    builder: (context, vm, _) => ExpansionTile(
      title: const Text('공유 서버 연결 (선택)'),
      children: [
        TextField(
          key: const Key('api-origin'),
          controller: _origin,
          enabled: !vm.busy,
          decoration: const InputDecoration(labelText: 'API origin'),
        ),
        TextButton(
          key: const Key('api-connect'),
          onPressed: vm.busy ? null : () => vm.connect(_origin.text),
          child: const Text('서버 연결 확인'),
        ),
        Text(vm.message, key: const Key('api-status')),
        const Text('health 연결 확인이며 로그인·공용 Registry는 별도 기능입니다.'),
      ],
    ),
  );
}
