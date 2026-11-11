import 'dart:convert';
import 'dart:io';

import '../models/xml_block_document.dart';

class XmlBlockRepository {
  File _file(String root, String identity) =>
      File('$root/xml-blocks-v1/${blockHash(identity)}.json');
  Future<Map<String, dynamic>?> read(String root, String identity) async {
    final file = _file(root, identity);
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw const FormatException('블록 문서는 일반 파일이어야 합니다.');
    }
    final handle = await file.open();
    try {
      final bytes = await handle.read(16 * 1024 * 1024 + 1);
      if (bytes.length > 16 * 1024 * 1024) {
        throw const FormatException('블록 문서가 16 MiB를 넘습니다.');
      }
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map<String, dynamic> ||
          value['version'] != 1 ||
          value['identity'] != identity ||
          value['assets'] is! List ||
          value['instances'] is! List ||
          value['links'] is! List) {
        throw const FormatException('블록 문서 형식이 잘못되었습니다.');
      }
      return value;
    } finally {
      await handle.close();
    }
  }

  Future<void> write(
    String root,
    String identity,
    Map<String, dynamic> data,
    int expected,
  ) async {
    final file = _file(root, identity);
    await file.parent.create(recursive: true);
    final lock = await File('${file.path}.lock').open(mode: FileMode.append);
    Directory? stage;
    try {
      await lock.lock(FileLock.blockingExclusive);
      final current = await read(root, identity);
      if ((current?['saveRevision'] ?? 0) != expected) {
        throw const FormatException('다른 창에서 블록 문서가 바뀌었습니다. 다시 여세요.');
      }
      final bytes = utf8.encode(
        jsonEncode({
          ...data,
          'version': 1,
          'identity': identity,
          'saveRevision': expected + 1,
        }),
      );
      if (bytes.length > 16 * 1024 * 1024) {
        throw const FormatException('블록 문서가 16 MiB를 넘습니다.');
      }
      stage = await file.parent.createTemp('.stage-');
      final temp = File('${stage.path}/document.json');
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);
    } finally {
      await lock.unlock();
      await lock.close();
      if (stage != null) await stage.delete(recursive: true);
    }
  }
}
