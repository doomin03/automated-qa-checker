import 'dart:convert';
import 'dart:io';

import '../../../../core/errors/draft_file_exception.dart';

abstract interface class ScenarioFileService {
  Future<String> read(String path);
  Future<void> write(String path, String content);
}

class LocalScenarioFileService implements ScenarioFileService {
  static const maxBytes = 1024 * 1024;
  File _file(String path) {
    if (path.trim().isEmpty) throw const DraftFileException('파일 경로를 입력하세요.');
    final lower = path.toLowerCase();
    if (!lower.endsWith('.xml') && !lower.endsWith('.json')) {
      throw const DraftFileException('.xml 또는 .json 파일 경로를 사용하세요.');
    }
    return File(path);
  }

  void _checkSize(int size) {
    if (size > maxBytes) {
      throw const DraftFileException('UTF-8 파일 크기는 1 MiB 이하여야 합니다.');
    }
  }

  @override
  Future<String> read(String path) async {
    final file = _file(path);
    try {
      final handle = await file.open();
      try {
        // Bound memory even if another process grows the file during the read.
        final bytes = await handle.read(maxBytes + 1);
        _checkSize(bytes.length);
        return utf8.decode(bytes);
      } finally {
        await handle.close();
      }
    } on FileSystemException {
      throw const DraftFileException('파일을 읽을 수 없습니다. 경로와 권한을 확인하세요.');
    } on FormatException {
      throw const DraftFileException('올바른 UTF-8 파일이 아닙니다.');
    }
  }

  @override
  Future<void> write(String path, String content) async {
    final file = _file(path);
    final bytes = utf8.encode(content);
    _checkSize(bytes.length);
    Directory? staging;
    File? temporary;
    try {
      // Stage on the same volume. Failed writes never truncate the destination.
      staging = await file.parent.createTemp('.qa-draft-');
      temporary = File('${staging.path}${Platform.pathSeparator}draft');
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.absolute.path);
    } on FileSystemException {
      throw const DraftFileException('파일을 저장할 수 없습니다. 폴더와 권한을 확인하세요.');
    } finally {
      try {
        if (temporary != null && await temporary.exists()) {
          await temporary.delete();
        }
        if (staging != null && await staging.exists()) await staging.delete();
      } on FileSystemException {
        // Keep the operation result; never remove the destination during cleanup.
      }
    }
  }
}
