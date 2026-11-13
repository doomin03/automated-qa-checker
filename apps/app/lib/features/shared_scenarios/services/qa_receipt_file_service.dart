import 'dart:convert';
import 'dart:io';

import '../models/qa_receipt.dart';

class QaReceiptFileService {
  QaReceiptFileService(this.workspaceDirectory);
  final String workspaceDirectory;
  static const limit = 2 * 1024 * 1024;
  Directory get directory => Directory('$workspaceDirectory/received-qa');
  String _name(String project, String qa) {
    final valid = RegExp(r'^[a-f0-9]{32}$');
    if (!valid.hasMatch(project) || !valid.hasMatch(qa)) {
      throw const FormatException('잘못된 로컬 QA 식별자입니다.');
    }
    return '$project-$qa.json';
  }

  Future<bool> _directory({bool create = false}) async {
    var type = await FileSystemEntity.type(directory.path, followLinks: false);
    if (type == FileSystemEntityType.notFound && create) {
      await directory.create(recursive: true);
      type = await FileSystemEntity.type(directory.path, followLinks: false);
    }
    if (type == FileSystemEntityType.notFound) return false;
    if (type != FileSystemEntityType.directory) {
      throw const FormatException('수신 출처 폴더가 일반 폴더가 아닙니다.');
    }
    return true;
  }

  Future<QaReceipt?> read(String project, String qa) async {
    final name = _name(project, qa);
    if (!await _directory()) return null;
    final file = File('${directory.path}/$name');
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw const FormatException('수신 출처가 일반 파일이 아닙니다.');
    }
    final h = await file.open();
    late List<int> bytes;
    try {
      bytes = await h.read(limit + 1);
    } finally {
      await h.close();
    }
    if (bytes.length > limit) {
      throw const FormatException('수신 출처 파일 크기 제한을 초과했습니다.');
    }
    final receipt = QaReceipt.fromJson(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
    );
    if (receipt.projectId != project || receipt.qaId != qa) {
      throw const FormatException('다른 QA의 출처 파일입니다.');
    }
    return receipt;
  }

  Future<void> write(QaReceipt value) async {
    final checked = QaReceipt.fromJson(value.toJson());
    final name = _name(checked.projectId, checked.qaId);
    final bytes = utf8.encode(jsonEncode(checked.toJson()));
    if (bytes.length > limit) {
      throw const FormatException('수신 출처 파일 크기 제한을 초과했습니다.');
    }
    await _directory(create: true);
    final target = File('${directory.path}/$name');
    final lockFile = File('${target.path}.lock');
    final lockType = await FileSystemEntity.type(
      lockFile.path,
      followLinks: false,
    );
    if (lockType != FileSystemEntityType.notFound &&
        lockType != FileSystemEntityType.file) {
      throw const FormatException('수신 잠금 파일이 잘못되었습니다.');
    }
    final lock = await lockFile.open(mode: FileMode.append);
    Directory? stage;
    try {
      await lock.lock(FileLock.blockingExclusive);
      if (await FileSystemEntity.type(target.path, followLinks: false) !=
          FileSystemEntityType.notFound) {
        throw const FormatException('이미 저장된 수신 출처를 덮어쓸 수 없습니다.');
      }
      stage = await directory.createTemp('.receive-');
      final temporary = File('${stage.path}/receipt.json');
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } finally {
      await lock.unlock();
      await lock.close();
      if (stage != null) {
        final temporary = File('${stage.path}/receipt.json');
        if (await temporary.exists()) await temporary.delete();
        await stage.delete();
      }
    }
  }
}
