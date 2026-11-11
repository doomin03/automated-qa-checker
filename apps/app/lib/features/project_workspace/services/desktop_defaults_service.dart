import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class DesktopDefaultsService {
  Future<Map<String, String>> load() async {
    final values = <String, String>{
      'aiProvider': 'codex',
      'reportRoot':
          '${Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path}${Platform.pathSeparator}AutomatedQA${Platform.pathSeparator}reports',
    };
    final codex =
        '${Platform.environment['LOCALAPPDATA'] ?? ''}${Platform.pathSeparator}Programs${Platform.pathSeparator}OpenAI${Platform.pathSeparator}Codex${Platform.pathSeparator}bin${Platform.pathSeparator}codex.exe';
    if (await File(codex).exists()) values['aiExecutable'] = codex;
    try {
      final asset = jsonDecode(
        await rootBundle.loadString('assets/desktop-installation.json'),
      );
      for (final key in ['nodePath', 'cliPath']) {
        if (asset[key] is String) values[key] = asset[key];
      }
    } catch (_) {
      /* Explicit settings remain available when no install receipt was bundled. */
    }
    return values;
  }
}
