import 'package:flutter/foundation.dart';

import '../models/engine_settings.dart';

class EngineSettingsViewModel extends ChangeNotifier {
  EngineSettings _value = const EngineSettings();
  String _platform = 'web';
  int _revision = 0;
  String _defaultNode = '', _defaultCli = '';
  bool _automatic = false;
  bool get canUseDefaults => _defaultNode.isNotEmpty && _defaultCli.isNotEmpty;
  bool get usesAutomaticRuntime => _automatic;
  Map<String, String> get runtimeProvenance => {
    'runtimeMode': _automatic ? 'automatic' : 'explicit',
    'runtimeDefaultNode': _defaultNode,
    'runtimeDefaultCli': _defaultCli,
  };
  void restore(Map<String, String> initial, Map<String, String> saved) {
    _defaultNode = initial['nodePath'] ?? '';
    _defaultCli = initial['cliPath'] ?? '';
    final noSavedRuntime =
        (saved['nodePath'] ?? '').isEmpty && (saved['cliPath'] ?? '').isEmpty;
    final previousAutomatic =
        saved['runtimeMode'] == 'automatic' &&
        saved['nodePath'] == saved['runtimeDefaultNode'] &&
        saved['cliPath'] == saved['runtimeDefaultCli'];
    final useDefaults = canUseDefaults && (noSavedRuntime || previousAutomatic);
    final s = {...initial, ...saved};
    update(
      EngineSettings(
        nodePath: useDefaults ? _defaultNode : (s['nodePath'] ?? ''),
        cliPath: useDefaults ? _defaultCli : (s['cliPath'] ?? ''),
        reportRoot: s['reportRoot'] ?? '',
        referenceRoot: s['referenceRoot'] ?? '',
        appiumConfig: s['appiumConfig'] ?? '',
      ),
    );
    _automatic = useDefaults;
    notifyListeners();
  }

  void useDefaults() {
    if (!canUseDefaults) return;
    update(_value.copyWith(nodePath: _defaultNode, cliPath: _defaultCli));
    _automatic = true;
    notifyListeners();
  }

  EngineSettings get value => _value;
  EngineSettings get execution => _value.normalized;
  String get platform => _platform;
  int get revision => _revision;
  void update(EngineSettings value) {
    if (_value == value) return;
    if (_value.nodePath != value.nodePath || _value.cliPath != value.cliPath) {
      _automatic = false;
    }
    _value = value;
    _revision++;
    notifyListeners();
  }

  void selectPlatform(String value) {
    if (!const ['web', 'android', 'ios'].contains(value) ||
        value == _platform) {
      return;
    }
    _platform = value;
    _revision++;
    notifyListeners();
  }
}
