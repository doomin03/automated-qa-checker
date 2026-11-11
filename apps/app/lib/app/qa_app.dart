import 'package:flutter/material.dart';

import 'workbench/views/scenario_editor_view.dart';
import 'workbench/views/desktop_workspace_view.dart';

class QaApp extends StatelessWidget {
  const QaApp({this.legacyEditor = false, super.key});
  final bool legacyEditor;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Automated QA Desktop',
    debugShowCheckedModeBanner: false,
    theme: legacyEditor
        ? ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true)
        : ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff8ea8bd),
              brightness: Brightness.dark,
            ),
            useMaterial3: false,
            fontFamily: 'Segoe UI',
            fontFamilyFallback: const ['Malgun Gothic'],
            textTheme: const TextTheme(bodyMedium:TextStyle(fontSize:13),bodySmall:TextStyle(fontSize:12),titleMedium:TextStyle(fontSize:14)),
            textButtonTheme: TextButtonThemeData(style:TextButton.styleFrom(foregroundColor:const Color(0xffe0e0e0),minimumSize:const Size(36,28),padding:const EdgeInsets.symmetric(horizontal:10),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(2)),textStyle:const TextStyle(fontSize:12))),
            outlinedButtonTheme: OutlinedButtonThemeData(style:OutlinedButton.styleFrom(foregroundColor:const Color(0xffe0e0e0),minimumSize:const Size(36,28),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(2)),textStyle:const TextStyle(fontSize:12))),
            filledButtonTheme: FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:const Color(0xff8ea8bd),foregroundColor:const Color(0xff151515),minimumSize:const Size(36,28),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(2)),textStyle:const TextStyle(fontSize:12))),
            inputDecorationTheme: const InputDecorationTheme(isDense:true,contentPadding:EdgeInsets.symmetric(horizontal:8,vertical:8),border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(2)))),
            visualDensity: VisualDensity.compact,
            scaffoldBackgroundColor: const Color(0xff292929),
          ),
    home: legacyEditor
        ? const ScenarioEditorView()
        : const DesktopWorkspaceView(),
  );
}
