import 'package:flutter/foundation.dart';

import '../models/terminal_profile.dart';
import '../repositories/terminal_preferences_repository.dart';
import '../services/terminal_profile_service.dart';

class TerminalReadinessViewModel extends ChangeNotifier {
  TerminalReadinessViewModel(this.profiles, this.preferences);
  final TerminalProfileService profiles;
  final TerminalPreferencesRepository preferences;
  String provider = 'codex', path = '';
  String? error;
  TerminalProfile? profile;
  bool busy = false, remember = false, _disposed = false;
  int _generation = 0;
  String get installationGuide => switch (provider) {
    'codex' => 'Codex 공식 설치 안내\nhttps://learn.chatgpt.com/docs/codex/cli\n설치는 사용자가 진행합니다. 설치 후 실행 파일을 선택하거나 다시 준비 확인하세요.',
    'claude' => 'Claude Code 공식 설치 안내\nhttps://code.claude.com/docs/en/overview\n설치는 사용자가 진행합니다. 설치 후 실행 파일을 선택하거나 다시 준비 확인하세요.',
    _ => 'Windows 기본 프로그램의 실행 파일을 선택하세요. PowerShell 또는 cmd 설치/권한은 Windows 환경에서 확인합니다.',
  };
  String get readinessLabel => switch (profile?.readiness) {
    'available' => '실행 파일 확인됨',
    'missing' => '프로그램을 찾지 못함',
    'unsupported' => '필수 옵션 미지원',
    'failed' => '진단 실패',
    _ => '확인 필요',
  };
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> selectProvider(String value) async {
    if (!TerminalPreferencesRepository.providers.contains(value)) return;
    final ticket = ++_generation;
    provider = value;
    path = '';
    profile = null;
    error = null;
    busy = true;
    remember = false;
    _notify();
    try {
      final paths = await preferences.read();
      if (_disposed || ticket != _generation) return;
      path = paths[value] ?? '';
      remember = paths.containsKey(value);
    } catch (e) {
      if (!_disposed && ticket == _generation) error = '저장 경로 읽기 실패: $e';
    } finally {
      if (!_disposed && ticket == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  void changePath(String value) {
    ++_generation;
    path = value;
    profile = null;
    busy = false;
    error = null;
    _notify();
  }

  void setRemember(bool value) {
    remember = value;
    _notify();
  }

  Future<void> chooseExecutable() async {
    final ticket = ++_generation;
    busy = true;
    profile = null;
    error = null;
    _notify();
    try {
      final result = await profiles.chooseExecutable();
      if (_disposed || ticket != _generation) return;
      if (result != null) path = result;
    } catch (e) {
      if (!_disposed && ticket == _generation) error = '실행 파일 선택 실패: $e';
    } finally {
      if (!_disposed && ticket == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> inspect() async {
    if (busy) return;
    final ticket = ++_generation, selected = provider;
    final executable = path;
    busy = true;
    profile = null;
    error = null;
    _notify();
    try {
      final result = await profiles.inspect(selected, executable: executable);
      if (!_disposed && ticket == _generation) profile = result;
    } catch (e) {
      if (!_disposed && ticket == _generation) error = '준비 확인 실패: $e';
    } finally {
      if (!_disposed && ticket == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<TerminalProfile?> accept() async {
    final current = profile;
    if (busy || current?.available != true) return null;
    final ticket = ++_generation;
    final shouldRemember = remember;
    if (!shouldRemember) return current;
    busy = true;
    error = null;
    _notify();
    try {
      await preferences.remember(current!.id, current.executable);
      if (_disposed || ticket != _generation) return null;
      return current;
    } catch (e) {
      if (!_disposed && ticket == _generation) error = '경로 기억 실패: $e';
      return null;
    } finally {
      if (!_disposed && ticket == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> forget() async {
    if (busy) return;
    final ticket = ++_generation, selected = provider;
    busy = true;
    error = null;
    _notify();
    try {
      await preferences.remember(selected, null);
      if (!_disposed && ticket == _generation) remember = false;
    } catch (e) {
      if (!_disposed && ticket == _generation) error = '저장 경로 삭제 실패: $e';
    } finally {
      if (!_disposed && ticket == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    super.dispose();
  }
}
