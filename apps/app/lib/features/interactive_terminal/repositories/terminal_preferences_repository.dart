import 'dart:convert';
import 'dart:io';

/// Machine-local executable paths only. Never stores authentication or readiness.
class TerminalPreferencesRepository {
  TerminalPreferencesRepository(this.directory);
  final String directory;
  static const providers = {'codex', 'claude', 'powershell', 'cmd'};
  File get file => File('$directory/terminal-programs.json');

  Future<Map<String, String>> read() async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return {};
    if (type != FileSystemEntityType.file) {
      throw const FormatException('프로그램 설정이 일반 파일이 아닙니다.');
    }
    final bytes = await file
        .openRead(0, 32769)
        .fold<List<int>>([], (a, b) => a..addAll(b));
    if (bytes.length > 32768) throw const FormatException('프로그램 설정 크기 초과');
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map ||
        data.length != 2 ||
        data['version'] != 1 ||
        data['paths'] is! Map) {
      throw const FormatException('지원하지 않는 프로그램 설정');
    }
    final result = <String, String>{};
    for (final entry in (data['paths'] as Map).entries) {
      if (!providers.contains(entry.key) ||
          entry.value is! String ||
          !_validPath(entry.value as String)) {
        throw const FormatException('잘못된 프로그램 경로 설정');
      }
      result[entry.key as String] = entry.value as String;
    }
    return result;
  }

  bool _validPath(String path) =>
      path.length <= 4096 &&
      !path.contains(RegExp(r'[\x00\r\n]')) &&
      File(path).isAbsolute;

  Future<void> remember(String provider, String? executable) async {
    if (!providers.contains(provider) ||
        (executable != null && !_validPath(executable))) {
      throw const FormatException('절대 실행 파일 경로를 선택하세요.');
    }
    await Directory(directory).create(recursive: true);
    final lockFile = File('$directory/terminal-programs.lock');
    final lockType = await FileSystemEntity.type(
      lockFile.path,
      followLinks: false,
    );
    if (lockType != FileSystemEntityType.notFound &&
        lockType != FileSystemEntityType.file) {
      throw const FormatException('프로그램 설정 잠금 파일 오류');
    }
    final lock = await lockFile.open(mode: FileMode.append);
    Directory? stage;
    var locked = false;
    try {
      await lock.lock(FileLock.exclusive);
      locked = true;
      final paths =
          await read(); // Invalid existing files must not be overwritten.
      if (executable == null) {
        paths.remove(provider);
      } else {
        paths[provider] = executable;
      }
      stage = await Directory(directory).createTemp('.terminal-programs-');
      final pending = File('${stage.path}/settings.json');
      await pending.writeAsString(
        jsonEncode({'version': 1, 'paths': paths}),
        flush: true,
      );
      final targetType = await FileSystemEntity.type(
        file.path,
        followLinks: false,
      );
      if (targetType != FileSystemEntityType.notFound &&
          targetType != FileSystemEntityType.file) {
        throw const FormatException('프로그램 설정 파일이 교체되었습니다.');
      }
      await pending.rename(file.path);
    } finally {
      if (locked) await lock.unlock();
      await lock.close();
      if (stage != null && await stage.exists()) {
        await stage.delete(recursive: true);
      }
    }
  }
}
