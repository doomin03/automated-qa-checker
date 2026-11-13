import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../run_review/services/portable_runtime_service.dart';

class DesktopDefaultsService {
  DesktopDefaultsService({PortableRuntimeService? portableRuntime})
    : _portableRuntime = portableRuntime ?? PortableRuntimeService();
  final PortableRuntimeService _portableRuntime;
  Future<Map<String, String>> load() async {
    final values = <String, String>{
      'aiProvider': 'codex',
      'reportRoot':
          '${Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path}${Platform.pathSeparator}AutomatedQA${Platform.pathSeparator}reports',
    };
    final codex =
        '${Platform.environment['LOCALAPPDATA'] ?? ''}${Platform.pathSeparator}Programs${Platform.pathSeparator}OpenAI${Platform.pathSeparator}Codex${Platform.pathSeparator}bin${Platform.pathSeparator}codex.exe';
    if (await File(codex).exists()) values['aiExecutable'] = codex;
    // A malformed portable receipt is a visible failure, never a developer fallback.
    final portable = await _portableRuntime.verify();
    if (portable != null) {
      values.addAll({
        'nodePath': portable['nodePath']!,
        'cliPath': portable['cliPath']!,
        'runtimeDefaultsSource': 'portable',
      });
      return values;
    }
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
