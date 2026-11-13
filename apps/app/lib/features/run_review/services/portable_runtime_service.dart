import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'portable_verifier.dart';

class PortableRuntimeService {
  PortableRuntimeService({
    String? executableDirectory,
    Future<String> Function()? loadManifest,
    this.required = const bool.fromEnvironment('QA_PORTABLE'),
    this.nativeVerification = true,
  }) : root =
           executableDirectory ?? File(Platform.resolvedExecutable).parent.path,
       _loadManifest =
           loadManifest ??
           (() =>
               rootBundle.loadString('assets/desktop-portable-runtime.json'));
  final String root;
  final bool required;
  final bool nativeVerification;
  final Future<String> Function() _loadManifest;
  String? _fingerprint;
  String? _nodeFingerprint;
  int lastVerificationMs = 0, lastNodeVerificationMs = 0;
  Map<String, int> lastNativeTiming = {};
  Map<String, String>? _verified;
  Future<Map<String, String>?>? _pending;

  Future<Map<String, String>?> verify() {
    final active = _pending;
    if (active != null) return active;
    final future = _verify();
    _pending = future;
    return future.whenComplete(() => _pending = null);
  }

  Future<Map<String, String>?> _verify() async {
    final file = File('$root/portable-runtime.json');
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound && !required) return null;
    if (type != FileSystemEntityType.file) {
      throw const FormatException('번들 runtime receipt가 없거나 일반 파일이 아닙니다.');
    }
    final expected = await _loadManifest();
    final base = root;
    final old = _fingerprint;
    final nodeOld = _nodeFingerprint;
    final native = nativeVerification;
    final watch = Stopwatch()..start();
    final result = await Isolate.run(
      () => _inspect(base, expected, old, nodeOld, native),
    );
    lastVerificationMs = watch.elapsedMilliseconds;
    lastNodeVerificationMs = int.tryParse(result.remove('_nodeMs') ?? '') ?? 0;
    lastNativeTiming = {
      for (final key in [
        '_listMs',
        '_statMs',
        '_realpathMs',
        '_hashMs',
        '_nativeMs',
      ])
        key: int.tryParse(result.remove(key) ?? '') ?? 0,
    };
    _nodeFingerprint = result.remove('_nodeFingerprint');
    _fingerprint = result.remove('_fingerprint');
    _verified = result;
    return result;
  }

  Future<Map<String, String>?> environment(String cliPath) async {
    // Do not validate or impose bundled browser settings on an external CLI.
    final file = File('$root/portable-runtime.json');
    if (!required && !await file.exists()) return null;
    final manifest = jsonDecode(await _loadManifest()) as Map<String, dynamic>;
    final bundled = _path(root, manifest['cliPath']);
    if (_normalize(bundled) != _normalize(cliPath)) return null;
    final value = await verify();
    return value == null
        ? null
        : {'PLAYWRIGHT_BROWSERS_PATH': value['browserRoot']!};
  }

  Map<String, String>? get verified => _verified;

  static String _normalize(String value) =>
      File(value).absolute.path.replaceAll('\\', '/').toLowerCase();
  static String _path(String base, dynamic relative) {
    if (relative is! String ||
        relative.isEmpty ||
        relative.contains('\\') ||
        relative.contains(':') ||
        relative.split('/').any((s) => s.isEmpty || s == '.' || s == '..')) {
      throw const FormatException('번들 상대 경로가 잘못되었습니다.');
    }
    return '$base/$relative';
  }

  static Future<Map<String, String>> _inspect(
    String base,
    String expected,
    String? oldFingerprint,
    String? nodeFingerprint,
    bool native,
  ) async {
    final receipt = File('$base/portable-runtime.json');
    if (await receipt.length() > 4 * 1024 * 1024 ||
        await receipt.readAsString() != expected) {
      throw const FormatException('번들 receipt와 내장 승인 manifest가 일치하지 않습니다.');
    }
    final manifest = jsonDecode(expected) as Map<String, dynamic>;
    if (manifest['schemaVersion'] != 'qa.desktopPortable/v1' ||
        manifest['files'] is! Map) {
      throw const FormatException('지원하지 않는 번들 manifest입니다.');
    }
    final canonical = await Directory(base).resolveSymbolicLinks();
    if (await FileSystemEntity.type('$base/runtime', followLinks: false) !=
        FileSystemEntityType.directory) {
      throw const FormatException('번들 runtime 최상위 폴더가 없거나 링크입니다.');
    }
    if (native) {
      final watch = Stopwatch()..start();
      final node = _path(base, manifest['nodePath']);
      var ancestor = Directory(base).path;
      for (final part in (manifest['nodePath'] as String).split('/')) {
        ancestor = '$ancestor/$part';
        if (await FileSystemEntity.type(ancestor, followLinks: false) ==
            FileSystemEntityType.link) {
          throw const FormatException('번들 Node 경로의 링크는 허용되지 않습니다.');
        }
      }
      final file = File(node);
      final resolved = await file.resolveSymbolicLinks();
      if (!_normalize(resolved).startsWith('${_normalize(canonical)}/')) {
        throw const FormatException('번들 Node가 배포 폴더를 벗어났습니다.');
      }
      const approvedNode =
          '9a4eb5f1c29c6a2e93852ead46b999e284a6a5ca8bab4d4e241d587d025a52de';
      final spec = (manifest['files'] as Map)[manifest['nodePath']];
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file ||
          spec is! Map ||
          spec['sha256'] != approvedNode ||
          spec['size'] != stat.size) {
        throw const FormatException('승인된 Node 24.18.0 실행 파일이 아닙니다.');
      }
      final stamp =
          '$resolved:$approvedNode:${stat.size}:${stat.modified.microsecondsSinceEpoch}:${stat.changed.microsecondsSinceEpoch}';
      if (stamp != nodeFingerprint &&
          (await sha256.bind(file.openRead()).first).toString() !=
              approvedNode) {
        throw const FormatException('번들 Node 공식 SHA-256이 일치하지 않습니다.');
      }
      final nodeMs = watch.elapsedMilliseconds;
      final result = await _nativeVerify(
        resolved,
        canonical,
        expected,
        oldFingerprint,
      );
      result['_nodeFingerprint'] = stamp;
      result['_nodeMs'] = '$nodeMs';
      return result;
    }
    final files = Map<String, dynamic>.from(manifest['files'] as Map);
    final observed = <String, File>{};
    final stamps = <String>[];
    await for (final entry in Directory(
      '$base/runtime',
    ).list(recursive: true, followLinks: false)) {
      final type = await FileSystemEntity.type(entry.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw const FormatException('번들 링크/junction은 허용되지 않습니다.');
      }
      final resolved = await entry.resolveSymbolicLinks();
      if (!_normalize(resolved).startsWith('${_normalize(canonical)}/')) {
        throw const FormatException('번들 경로가 배포 폴더를 벗어났습니다.');
      }
      if (type == FileSystemEntityType.directory) continue;
      if (type != FileSystemEntityType.file) {
        throw const FormatException('일반 파일이 아닌 번들 payload입니다.');
      }
      final name = entry.path
          .substring(Directory(base).path.length + 1)
          .replaceAll('\\', '/');
      final spec = files[name];
      final stat = await entry.stat();
      if (spec is! Map || spec['size'] != stat.size) {
        throw FormatException('번들 파일 누락/추가/크기 오류: $name');
      }
      observed[name] = File(entry.path);
      stamps.add(
        '$name:${stat.size}:${stat.modified.microsecondsSinceEpoch}:${stat.changed.microsecondsSinceEpoch}',
      );
    }
    if (observed.length != files.length) {
      throw const FormatException('번들 파일 목록이 승인 manifest와 다릅니다.');
    }
    stamps.sort();
    final fingerprint = sha256
        .convert(utf8.encode('$canonical\n$expected\n${stamps.join('\n')}'))
        .toString();
    if (fingerprint != oldFingerprint) {
      for (final item in observed.entries) {
        final digest = await sha256.bind(item.value.openRead()).first;
        if (digest.toString() != files[item.key]['sha256']) {
          throw FormatException('번들 SHA-256 오류: ${item.key}');
        }
      }
    }
    final result = <String, String>{'_fingerprint': fingerprint};
    for (final key in ['nodePath', 'cliPath', 'browserRoot']) {
      final path = _path(base, manifest[key]);
      if (key != 'browserRoot' && !observed.containsKey(manifest[key])) {
        throw const FormatException('번들 진입점이 manifest에 없습니다.');
      }
      if (key == 'browserRoot' && !await Directory(path).exists()) {
        throw const FormatException('번들 브라우저 폴더가 없습니다.');
      }
      result[key] = await FileSystemEntity.isDirectory(path)
          ? await Directory(path).resolveSymbolicLinks()
          : await File(path).resolveSymbolicLinks();
    }
    return result;
  }

  static Future<Map<String, String>> _nativeVerify(
    String node,
    String root,
    String expected,
    String? previous,
  ) async {
    final process = await Process.start(
      node,
      ['--no-addons', '--input-type=module', '-e', portableVerifier, root],
      includeParentEnvironment: false,
      environment: {
        if (Platform.environment['SystemRoot'] case final String value)
          'SystemRoot': value,
        'TEMP': Directory.systemTemp.path,
      },
      runInShell: false,
    );
    final output = <int>[];
    var outSize = 0, errSize = 0;
    final outDone = Completer<void>(), errDone = Completer<void>();
    var overflow = false;
    final stdout = process.stdout.listen(
      (bytes) {
        outSize += bytes.length;
        if (outSize > 1024 * 1024) {
          overflow = true;
          process.kill();
        } else {
          output.addAll(bytes);
        }
      },
      onDone: () {
        if (!outDone.isCompleted) outDone.complete();
      },
      onError: (Object e) {
        if (!outDone.isCompleted) outDone.completeError(e);
        process.kill();
      },
    );
    final stderr = process.stderr.listen(
      (bytes) {
        errSize += bytes.length;
        if (errSize > 1024 * 1024) {
          overflow = true;
          process.kill();
        }
      },
      onDone: () {
        if (!errDone.isCompleted) errDone.complete();
      },
      onError: (Object e) {
        if (!errDone.isCompleted) errDone.completeError(e);
        process.kill();
      },
    );
    try {
      final finished = Future.wait<Object?>([
        process.exitCode,
        outDone.future,
        errDone.future,
      ]);
      final values = await (() async {
        process.stdin.write(
          jsonEncode({'expected': expected, 'previous': previous}),
        );
        await process.stdin.close();
        return await finished;
      })().timeout(const Duration(seconds: 60));
      if (overflow) throw const FormatException('번들 검증 출력 제한 초과');
      final result = jsonDecode(utf8.decode(output));
      if (values.first != 0 || result is! Map || result['error'] != null) {
        throw FormatException(
          '번들 payload 검증 실패: ${result is Map ? result['error'] : 'INVALID_OUTPUT'}',
        );
      }
      return Map<String, String>.from(result);
    } on TimeoutException {
      throw const FormatException('번들 검증 시간 제한 초과');
    } finally {
      process.kill();
      await process.exitCode.timeout(
        const Duration(seconds: 2),
        onTimeout: () => -1,
      );
      await stdout.cancel();
      await stderr.cancel();
    }
  }
}
