import 'dart:async';
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
  Future<void>? _queue;
  bool _failedCompiler = false;
  static const guideVersion = 'qa-authoring-guide/1';
  Future<T> _serialized<T>(Future<T> Function() operation) {
    Future<T> execute() async {
      if (_failedCompiler) throw StateError('작성 검증 연결을 다시 시작하세요.');
      try {
        return await operation().timeout(const Duration(seconds: 60));
      } on TimeoutException {
        _failedCompiler = true;
        compiler.dispose();
        rethrow;
      }
    }

    final pending = _queue;
    final result = pending == null ? execute() : pending.then((_) => execute());
    final tail = result.then<void>((_) {}, onError: (Object _) {});
    _queue = tail;
    unawaited(
      tail.then((_) {
        if (identical(_queue, tail)) _queue = null;
      }),
    );
    return result;
  }

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

  Future<String> describeEnvironment(Directory session) async {
    Future<String> readLocal(String relative) async {
      await ensureSessionRoot(session);
      final file = File('${session.path}/$relative');
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
              FileSystemEntityType.file ||
          (await file.resolveSymbolicLinks())
                  .replaceAll('\\', '/')
                  .toLowerCase() !=
              file.absolute.path.replaceAll('\\', '/').toLowerCase()) {
        throw const FormatException('작성 환경 파일 경로가 교체되었습니다.');
      }
      final bytes = await file
          .openRead(0, 32769)
          .fold<List<int>>([], (a, b) => a..addAll(b));
      if (bytes.length > 32768) throw const FormatException('작성 환경 파일 크기 초과');
      await ensureSessionRoot(session);
      return utf8.decode(bytes);
    }

    final data = jsonDecode(
      await readLocal('authoring-environment.json'),
    ) as Map<String, dynamic>;
    final provider = data['provider'];
    if (!['codex', 'claude', 'powershell', 'cmd'].contains(provider)) {
      throw const FormatException('지원하지 않는 작성 환경');
    }
    String? guidePath;
    if (provider == 'codex' || provider == 'claude') {
      guidePath =
          '${provider == 'codex' ? '.agents' : '.claude'}/skills/qa-authoring/SKILL.md';
      final guide = await readLocal(guidePath);
      if (sha256.convert(utf8.encode(guide)).toString() != data['guideSha256']) {
        throw const FormatException('작성 가이드 hash가 달라졌습니다.');
      }
    }
    return '프로그램: $provider\n시작 폴더: ${session.path}\nEngine: ${data['engineVersion']}\n실행 계약: ${data['contractVersion']}\n작성 계약: ${data['authoringContractVersion']}\n'
        '${guidePath == null ? '일반 셸 · AI 가이드 적용 없음' : '가이드 준비 확인: $guidePath\n가이드 버전: ${data['guideVersion']}\n가이드 SHA256: ${data['guideSha256']}\nCLI 발견·실제 모델 사용: 별도 확인 필요'}\n'
        '문맥: QA-CONTEXT.md\n계약: engine-contract.json\n예제: example.json';
  }

  Future<void> prepareEnvironment(
    Directory session,
    String provider,
    Map<String, dynamic>? contract, {
    Map<String, dynamic>? authoringContract,
  }) async {
    await ensureSessionRoot(session);
    final serialized = jsonEncode(contract);
    await writeAuxiliary(
      session,
      'example.json',
      jsonEncode(contract?['example']),
    );
    if (authoringContract != null) {
      await writeAuxiliary(
        session,
        'authoring-contract.json',
        jsonEncode(authoringContract),
      );
    }
    String? guideSha256;
    if (['codex', 'claude'].contains(provider)) {
      guideSha256 = await _prepareGuide(session, provider);
    }
    await writeAuxiliary(
      session,
      'authoring-environment.json',
      jsonEncode({
        'guideVersion': guideVersion,
        'engineVersion': contract?['engineVersion'],
        'contractVersion': contract?['contractVersion'],
        'authoringContractVersion':
            authoringContract?['authoringContractVersion'],
        'sessionContractSha256': sha256
            .convert(utf8.encode(serialized))
            .toString(),
        'provider': provider,
        'guidePrepared': ['codex', 'claude'].contains(provider),
        'guideSha256': guideSha256,
        'providerDiscoveryVerified': false,
      }),
    );
  }

  Future<String> _prepareGuide(Directory session, String provider) async {
    var parent = session;
    final directories = <Directory>[];
    for (final part in [
      provider == 'codex' ? '.agents' : '.claude',
      'skills',
      'qa-authoring',
    ]) {
      await ensureSessionRoot(session);
      final child = Directory('${parent.path}/$part');
      final type = await FileSystemEntity.type(child.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) await child.create();
      if (await FileSystemEntity.type(child.path, followLinks: false) !=
              FileSystemEntityType.directory ||
          (await child.resolveSymbolicLinks())
                  .replaceAll('\\', '/')
                  .toLowerCase() !=
              child.absolute.path.replaceAll('\\', '/').toLowerCase()) {
        throw const FormatException('작성 가이드 경로가 교체되었습니다.');
      }
      parent = child;
      directories.add(child);
    }
    final guide = File('${parent.path}/SKILL.md');
    if (await FileSystemEntity.type(guide.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw const FormatException('기존 작성 가이드를 덮어쓰지 않습니다.');
    }
    Future<void> checkDirectories() async {
      await ensureSessionRoot(session);
      for (final directory in directories) {
        if (await FileSystemEntity.type(directory.path, followLinks: false) !=
                FileSystemEntityType.directory ||
            (await directory.resolveSymbolicLinks())
                    .replaceAll('\\', '/')
                    .toLowerCase() !=
                directory.absolute.path.replaceAll('\\', '/').toLowerCase()) {
          throw const FormatException('작성 가이드 경로가 교체되었습니다.');
        }
      }
    }

    const content = '''---
name: qa-authoring
description: Edit this QA session scenario.xml or scenario.json using the pinned public Engine contract.
---
Read QA-CONTEXT.md, engine-contract.json and example.json in the session root.
If authoring-contract.json is present, it supplies public templates/compose schemas and catalog.
Edit only the requested QA definition; preserve unrelated nodes, references and secrets.
Do not run tests or modify the original workspace. The user explicitly runs QA in the app.
Only the app-designated writer can update the GUI draft after public Engine validation.
Do not change authentication, global CLI configuration or files outside this session.
''';
    await checkDirectories();
    await guide.writeAsString(content, flush: true);
    await checkDirectories();
    return sha256.convert(utf8.encode(content)).toString();
  }

  Future<void> writeAuxiliary(
    Directory session,
    String name,
    String content,
  ) async {
    if (![
      'QA-CONTEXT.md',
      'engine-contract.json',
      'example.json',
      'authoring-environment.json',
      'authoring-contract.json',
    ].contains(name)) {
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
  ) => _serialized(() => compiler.prepare(settings, file.source));
  Future<String> exportXml(EngineSettings settings, String source) =>
      _serialized(() => compiler.exportXml(settings, source));
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
