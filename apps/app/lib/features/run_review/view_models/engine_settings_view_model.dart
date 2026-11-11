import 'package:flutter/foundation.dart';

import '../models/engine_settings.dart';

class EngineSettingsViewModel extends ChangeNotifier {
  EngineSettings _value = const EngineSettings();
  String _platform = 'web';
  int _revision = 0;
  EngineSettings get value => _value;
  EngineSettings get execution => _value.normalized;
  String get platform => _platform;
  int get revision => _revision;
  void update(EngineSettings value) {
    if (_value == value) return;
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
