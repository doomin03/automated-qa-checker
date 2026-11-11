import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../run_review/services/engine_cli_service.dart';
import '../../run_review/models/engine_execution.dart';

class LiveDocument {
  LiveDocument(this.path, this.source)
    : hash = sha256.convert(utf8.encode(source)).toString();
  final String path, source, hash;
}

/// Owns a dedicated compile service, never the service currently running QA.
class LiveDocumentRepository {
  LiveDocumentRepository(this.compiler);
  final EngineCliService compiler;
  final Map<String, String> _roots = {};
  static const maxBytes = 1024 * 1024;
  Future<Directory> createSession(
    String workspace,
    String project,
    String qa,
    String source,
    String context,
  ) async {
    final root = Directory(
      '$workspace/terminal-sessions/${sha256.convert(utf8.encode('$project/$qa'))}',
    );
    await root.create(recursive: true);
    final session = await root.createTemp('session-');
    _roots[session.path] = await session.resolveSymbolicLinks();
    final ext = source.trimLeft().startsWith('<') ? 'xml' : 'json';
    await File('${session.path}/scenario.$ext')
        .writeAsString(source, flush: true);
    await writeContext(session, context);
    return session;
  }

  Future<void> ensureSessionRoot(Directory session) async {
    if (await FileSystemEntity.type(session.path, followLinks: false) !=
            FileSystemEntityType.directory ||
        _roots[session.path] != await session.resolveSymbolicLinks()) {
      throw const FormatException('세션 폴더가 교체되었습니다.');
    }
  }

  Future<void> writeContext(Directory session, String context) =>
      writeAuxiliary(session, 'QA-CONTEXT.md', context);
  Future<void> writeAuxiliary(
    Directory session,
    String name,
    String content,
  ) async {
    if (!['QA-CONTEXT.md', 'engine-contract.json'].contains(name)) {
      throw const FormatException('허용되지 않는 문맥 파일입니다.');
    }
    await ensureSessionRoot(session);
    final stage = await session.createTemp('.context-');
    try {
      final file = File('${stage.path}/$name');
      await file.writeAsString(content, flush: true);
      await ensureSessionRoot(session);
      await file.rename('${session.path}/$name');
    } finally {
      await stage.delete(recursive: true);
    }
  }

  Future<LiveDocument?> read(Directory session, String format) async {
    if (!['xml', 'json'].contains(format)) {
      throw const FormatException('지원하지 않는 원문 형식입니다.');
    }
    await ensureSessionRoot(session);
    final file = File('${session.path}/scenario.$format');
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw const FormatException('QA 파일은 일반 파일이어야 합니다.');
    }
    final root = await session.resolveSymbolicLinks();
    final path = await file.resolveSymbolicLinks();
    if (File(path).parent.path.toLowerCase() != root.toLowerCase()) {
      throw const FormatException('세션 밖 QA 경로는 허용하지 않습니다.');
    }
    final handle = await file.open();
    try {
      final bytes = await handle.read(maxBytes + 1);
      if (bytes.isEmpty || bytes.length > maxBytes) {
        throw const FormatException('QA 파일은 UTF-8 1 MiB 이하이며 비어 있지 않아야 합니다.');
      }
      final source = utf8.decode(bytes);
      if ((format == 'xml') != source.trimLeft().startsWith('<')) {
        throw const FormatException('파일 확장자와 XML/JSON 원문 형식이 다릅니다.');
      }
      return LiveDocument(file.path, source);
    } finally {
      await handle.close();
    }
  }

  Future<PreparedScenario> compile(
    EngineSettings settings,
    LiveDocument file,
  ) => compiler.prepare(settings, file.source);
  Future<String> exportXml(EngineSettings settings, String source) =>
      compiler.exportXml(settings, source);
  Future<void> replace(
    Directory session,
    String format,
    String source,
    String? expected,
  ) async {
    final current = await read(session, format);
    if (current?.hash != expected) {
      throw const FormatException('파일이 다시 변경되었습니다. 새 내용을 확인하세요.');
    }
    final stage = await session.createTemp('.save-');
    try {
      final temporary = File('${stage.path}/scenario.$format');
      await temporary.writeAsString(source, flush: true);
      if ((await read(session, format))?.hash != expected) {
        throw const FormatException('저장 중 파일 충돌입니다.');
      }
      await temporary.rename('${session.path}/scenario.$format');
    } finally {
      await stage.delete(recursive: true);
    }
  }

  Future<void> preserveCopy(Directory session, String source) async {
    await ensureSessionRoot(session);
    final copy = await session.createTemp('gui-copy-');
    await ensureSessionRoot(session);
    await File(
      '${copy.path}/scenario.${source.trimLeft().startsWith('<') ? 'xml' : 'json'}',
    ).writeAsString(source, flush: true);
  }

  void dispose() => compiler.dispose();
}
