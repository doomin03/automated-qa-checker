import 'package:flutter/material.dart';

import '../features/scenario_editor/views/scenario_editor_view.dart';

class QaApp extends StatelessWidget {
  const QaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Automated QA Desktop',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const ScenarioEditorView(),
  );
}
