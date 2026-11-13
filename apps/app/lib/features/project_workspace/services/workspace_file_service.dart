import 'dart:convert';
import 'dart:io';

import '../models/workspace.dart';

class WorkspaceFileService {
  WorkspaceFileService({Directory? directory, this.beforeCommit})
    : directory =
          directory ??
          Directory(
            '${Platform.environment['APPDATA'] ?? Directory.current.path}${Platform.pathSeparator}AutomatedQA${Platform.pathSeparator}workspace-v1',
          );
  final Directory directory;
  final Future<void> Function()? beforeCommit;
  static const maxBytes = 16 * 1024 * 1024;
  File get file =>
      File('${directory.path}${Platform.pathSeparator}workspace.json');
  Future<Workspace> read() async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return Workspace();
    if (type != FileSystemEntityType.file) {
      throw const FormatException('작업 공간은 일반 JSON 파일이어야 합니다.');
    }
    final handle = await file.open();
    try {
      final bytes = await handle.read(maxBytes + 1);
      if (bytes.length > maxBytes) {
        throw const FormatException('작업 공간은 16 MiB 이하여야 합니다.');
      }
      return Workspace.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      );
    } finally {
      await handle.close();
    }
  }

  Future<Workspace> write(Workspace value, {bool Function()? canCommit}) async {
    await directory.create(recursive: true);
    final lock = await File(
      '${directory.path}${Platform.pathSeparator}workspace.lock',
    ).open(mode: FileMode.append);
    Directory? stage;
    var locked = false;
    try {
      await lock.lock(FileLock.exclusive);
      locked = true;
      final current = await read();
      if (current.revision != value.revision) {
        throw const FormatException(
          '다른 앱이 저장했습니다. 다시 열기 전에 현재 초안을 별도 내보내기 하세요.',
        );
      }
      final next = Workspace.fromJson(
        value.copyWith(revision: value.revision + 1).toJson(),
      );
      final bytes = utf8.encode(jsonEncode(next.toJson()));
      if (bytes.length > maxBytes) {
        throw const FormatException('작업 공간은 16 MiB 이하여야 합니다.');
      }
      stage = await directory.createTemp('.save-');
      final temporary = File(
        '${stage.path}${Platform.pathSeparator}workspace.json',
      );
      await temporary.writeAsBytes(bytes, flush: true);
      await beforeCommit?.call();
      if (canCommit != null && !canCommit()) {
        throw const FormatException('작업 대상이 바뀌어 저장하지 않았습니다.');
      }
      await temporary.rename(file.path);
      return next;
    } finally {
      if (stage != null && await stage.exists()) {
        try {
          await stage.delete(recursive: true);
        } on FileSystemException {
          /* Original remains untouched. */
        }
      }
      if (locked) await lock.unlock();
      await lock.close();
    }
  }
}
