import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class SharedFileService {
  Future<Map<String, dynamic>> report(String folder) async {
    if (!Directory(folder).isAbsolute) {
      throw const FormatException('실행 폴더는 절대 경로여야 합니다.');
    }
    Future<dynamic> json(String name) async => jsonDecode(
      utf8.decode(await readBounded(File('$folder/$name'), 2 * 1024 * 1024)),
    );
    final result = await json('result.json') as Map<String, dynamic>;
    final blueprint = await json('blueprint.json') as Map<String, dynamic>;
    final lines = utf8
        .decode(
          await readBounded(File('$folder/events.jsonl'), 16 * 1024 * 1024),
        )
        .split(RegExp(r'\r?\n'))
        .where((s) => s.trim().isNotEmpty);
    final events = lines
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .toList();
    if (events.isEmpty ||
        events.first['type'] != 'run.started' ||
        events.last['type'] != 'run.finished' ||
        result['runId'] != events.first['runId'] ||
        result['attempt'] != events.first['attempt']) {
      throw const FormatException('저장된 실행 identity가 다릅니다.');
    }
    return {
      'plan': {
        'blueprint': blueprint,
        'engineVersion': result['executed']['engineVersion'],
        'blueprintSnapshotHash': result['executed']['blueprintSnapshotHash'],
      },
      'events': events,
      'result': result,
    };
  }

  Future<List<int>> readBounded(File file, int limit) async {
    final h = await file.open();
    try {
      final b = await h.read(limit + 1);
      if (b.length > limit) throw const FormatException('공유 파일 크기 제한 초과');
      return b;
    } finally {
      await h.close();
    }
  }

  String _key(String origin, String project) =>
      sha256.convert(utf8.encode('$origin\n$project')).toString();
  Future<File> _cache(String folder, String origin, String project) async {
    final d = Directory(folder);
    if (!d.isAbsolute) throw const FormatException('캐시 폴더는 절대 경로여야 합니다.');
    await d.create(recursive: true);
    return File('${d.path}/pin-${_key(origin, project)}.json');
  }

  Future<void> cache(
    String folder,
    String origin,
    String project,
    Map<String, dynamic> version,
  ) async {
    verifyXml(version);
    final target = await _cache(folder, origin, project);
    final bytes = utf8.encode(
      jsonEncode({'origin': origin, 'project': project, 'version': version}),
    );
    final archive = File(
      '$folder/version-${_key(origin, project)}-${version['sha256']}.json',
    );
    if (await archive.exists()) {
      final saved = jsonDecode(
        utf8.decode(await readBounded(archive, 2 * 1024 * 1024)),
      ) as Map<String, dynamic>;
      verifyXml(saved['version'] as Map<String, dynamic>);
      if (saved['version']['xml'] != version['xml']) {
        throw const FormatException('고정 snapshot 충돌');
      }
    } else {
      await archive.writeAsBytes(bytes, flush: true);
    }
    final temporary = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<Map<String, dynamic>?> cached(
    String folder,
    String origin,
    String project,
  ) async {
    final file = await _cache(folder, origin, project);
    if (!await file.exists()) return null;
    final value = jsonDecode(
      utf8.decode(await readBounded(file, 2 * 1024 * 1024)),
    ) as Map<String, dynamic>;
    if (value['origin'] != origin || value['project'] != project) {
      throw const FormatException('캐시 소속이 다릅니다.');
    }
    final version = value['version'] as Map<String, dynamic>;
    verifyXml(version);
    return version;
  }

  void verifyXml(Map<String, dynamic> version) {
    if (version['xml'] is! String ||
        sha256.convert(utf8.encode(version['xml'])).toString() !=
            version['sha256']) {
      throw const FormatException('수신 XML hash가 다릅니다.');
    }
  }

  Future<List<int>> evidence(
    String root,
    String relative,
    String expected,
    int size,
  ) async {
    if (relative.isEmpty ||
        relative.contains(':') ||
        relative.startsWith('/') ||
        relative.startsWith('\\') ||
        relative.split(RegExp(r'[/\\]')).any((p) => p == '..' || p.isEmpty)) {
      throw const FormatException('증거 경로가 잘못되었습니다.');
    }
    final resolved = await Directory(root).resolveSymbolicLinks();
    final file = File('$resolved/$relative');
    if (!(await file.resolveSymbolicLinks()).toLowerCase().startsWith(
      '${resolved.toLowerCase()}${Platform.pathSeparator}',
    )) {
      throw const FormatException('증거 경로 이탈');
    }
    final bytes = await readBounded(file, 10 * 1024 * 1024);
    if (bytes.length != size || sha256.convert(bytes).toString() != expected) {
      throw const FormatException('게시 증거 size/hash가 다릅니다.');
    }
    return bytes;
  }
}
