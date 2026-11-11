import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../models/engine_execution.dart';
import 'cli_process.dart';

abstract interface class EngineCliService {
  Future<Map<String, dynamic>> capabilities(
    EngineSettings settings,
    String platform,
  );
  Future<ExpandedAuthoring> expandAuthoring(
    EngineSettings settings,
    String source,
  );
  Future<PreparedScenario> prepare(EngineSettings settings, String source);
  Future<String> exportXml(EngineSettings settings, String source);
  Future<String> expandPreset(
    EngineSettings settings,
    String id,
    String version,
    Map<String, dynamic> bindings,
  );
  Stream<EngineUpdate> run(PreparedScenario scenario);
  Future<void> cancel();
  void dispose();
}

/// Consumes the public CLI. It does not interpret the execution DSL.
class LocalEngineCliService implements EngineCliService {
  LocalEngineCliService({
    Future<Map<String, dynamic>> Function()? loadManifest,
    this.processPolicy = const CliProcessPolicy(),
  }) : _loadManifest = loadManifest ?? _assetManifest;
  final Future<Map<String, dynamic>> Function() _loadManifest;
  final CliProcessPolicy processPolicy;
  CliProcess? _active;
  final Set<CliProcess> _commands = {};
  bool _runPending = false;
  bool _cancelRequested = false;
  bool _disposed = false;
  bool _controlStdin = false;
  static const _maxOutput = 16 * 1024 * 1024;

  static Future<Map<String, dynamic>> _assetManifest() async =>
      jsonDecode(await rootBundle.loadString('assets/desktop-engine-runtime.json'))
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> capabilities(
    EngineSettings settings,
    String platform,
  ) async {
    if (!['web', 'android', 'ios'].contains(platform)) {
      throw const EngineException('지원하지 않는 대상입니다.');
    }
    await _verify(settings);
    final value = await _command(
      settings,
      [
        'devices',
        '--json',
        '--target',
        platform,
        if (platform != 'web' && settings.appiumConfig.isNotEmpty) ...[
          '--appium-config',
          settings.appiumConfig,
        ],
      ],
      acceptedExitCodes: const {0, 4},
    );
    if (value['schemaVersion'] != 'qa.capabilities/v1' ||
        value['platforms'] is! List ||
        value['supportedActions'] is! List ||
        value['targets'] is! List) {
      throw const EngineException('잘못된 capability 응답입니다.');
    }
    return value;
  }

  Future<List<int>> _readBounded(File file, int limit) async {
    final handle = await file.open();
    try {
      final bytes = await handle.read(limit + 1);
      if (bytes.length > limit) {
        throw const EngineException('파일 크기 제한을 초과했습니다.');
      }
      return bytes;
    } finally {
      await handle.close();
    }
  }

  Future<Map<String, dynamic>> _verify(EngineSettings settings) async {
    if (_disposed) throw const EngineException('엔진 연결이 종료되었습니다.');
    final manifest = await _loadManifest();
    if ((settings.referenceRoot.isNotEmpty &&
            manifest['designChecks'] != true) ||
        (settings.appiumConfig.isNotEmpty && manifest['appium'] != true)) {
      throw const EngineException(
        'UNSUPPORTED_CAPABILITY: 고정 엔진이 해당 로컬 설정을 지원하지 않습니다.',
      );
    }
    if ((settings.referenceRoot.isNotEmpty &&
            !Directory(settings.referenceRoot).isAbsolute) ||
        (settings.appiumConfig.isNotEmpty &&
            !File(settings.appiumConfig).isAbsolute)) {
      throw const EngineException('기준 리소스 폴더와 Appium 설정은 절대 경로로 입력하세요.');
    }
    final cli = File(settings.cliPath);
    if (!cli.isAbsolute ||
        !File(settings.nodePath).isAbsolute ||
        !Directory(settings.reportRoot).isAbsolute) {
      throw const EngineException('Node, CLI, 결과 폴더는 절대 경로로 입력하세요.');
    }
    final packageRoot = cli.parent.parent.parent;
    final resolvedRoot = await packageRoot.resolveSymbolicLinks();
    final files = manifest['files'] as Map<String, dynamic>;
    for (final entry in files.entries) {
      final file = File('$resolvedRoot/${entry.key}');
      final resolved = await file.resolveSymbolicLinks();
      if (!_within(resolvedRoot, resolved) ||
          sha256.convert(await _readBounded(file, _maxOutput)).toString() !=
              entry.value) {
        throw const EngineException('설치된 엔진 파일의 SHA-256이 고정 배포판과 다릅니다.');
      }
    }
    if (await cli.resolveSymbolicLinks() !=
        await File('$resolvedRoot/${manifest['entrypoint']}')
            .resolveSymbolicLinks()) {
      throw const EngineException('등록된 엔진 CLI 진입점이 아닙니다.');
    }
    final version = await _command(settings, ['--version']);
    if (version['engineVersion'] != manifest['engineVersion']) {
      throw const EngineException('엔진 버전이 고정 배포판과 다릅니다.');
    }
    _controlStdin = manifest['controlStdin'] == true;
    return manifest;
  }

  Future<Map<String, dynamic>> _command(
    EngineSettings settings,
    List<String> arguments, {
    bool allowEmpty = false,
    Set<int> acceptedExitCodes = const {0},
  }) async {
    if (_disposed) throw const EngineException('엔진 연결이 종료되었습니다.');
    final process = await CliProcess.start(
      settings.nodePath,
      [settings.cliPath, ...arguments],
      policy: processPolicy,
      timeout: processPolicy.commandTimeout,
    );
    _commands.add(process);
    if (_disposed) await process.stop();
    final output = <int>[];
    try {
      await for (final bytes in process.stdout) {
        output.addAll(bytes);
      }
      await process.done;
      process.check();
      final code = process.exitCode;
      if (_disposed) throw const EngineException('엔진 연결이 종료되었습니다.');
      if (code == 0 && allowEmpty && output.isEmpty) return {};
      final value = _decodeObject(utf8.decode(output));
      if (!acceptedExitCodes.contains(code) || value['error'] != null) {
        final error = value['error'];
        throw EngineException(
          error is Map
              ? '${error['code']}: ${error['message']}'
              : '엔진 명령 실패: $code',
        );
      }
      return value;
    } on FormatException {
      throw const EngineException('엔진 응답이 올바른 UTF-8 JSON이 아닙니다.');
    } finally {
      await process.stop();
      _commands.remove(process);
    }
  }

  @override
  Future<ExpandedAuthoring> expandAuthoring(
    EngineSettings settings,
    String source,
  ) async {
    final manifest = await _verify(settings);
    if (manifest['authoring'] != true) {
      throw const EngineException('UNSUPPORTED_CAPABILITY: 반복 작성 미지원');
    }
    final bytes = utf8.encode(source);
    if (bytes.length > 1024 * 1024) {
      throw const EngineException('작성 문서는 1 MiB 이하여야 합니다.');
    }
    final root = Directory(settings.reportRoot);
    await root.create(recursive: true);
    final folder = await root.createTemp('authoring-');
    final ext = source.trimLeft().startsWith('<') ? 'xml' : 'json';
    final input = File('${folder.path}/source.$ext');
    await input.writeAsBytes(bytes, flush: true);
    final output = File('${folder.path}/expanded.xml');
    await _command(settings, [
      'expand',
      input.path,
      '--out',
      output.path,
      '--document-root',
      folder.path,
    ], allowEmpty: true);
    final saved = File('${output.path}.authoring.$ext');
    if (sha256.convert(await _readBounded(saved, 1024 * 1024)).toString() !=
        sha256.convert(bytes).toString()) {
      throw const EngineException('보관된 원본 bytes가 다릅니다.');
    }
    final map = jsonDecode(
      utf8.decode(
        await _readBounded(File('${output.path}.source-map.json'), 1024 * 1024),
      ),
    ) as Map<String, dynamic>;
    final check = File('${folder.path}/rechecked.xml');
    await _command(settings, [
      'expand',
      saved.path,
      '--out',
      check.path,
      '--document-root',
      folder.path,
    ], allowEmpty: true);
    final again = jsonDecode(
      utf8.decode(
        await _readBounded(File('${check.path}.source-map.json'), 1024 * 1024),
      ),
    );
    final xml = utf8.decode(await _readBounded(output, 1024 * 1024));
    final plan = await _command(settings, [
      'plan',
      output.path,
      '--document-root',
      folder.path,
    ]);
    if (map['schemaVersion'] != 'qa.authoringSourceMap/v1' ||
        jsonEncode(map) != jsonEncode(again) ||
        map['blueprintSnapshotHash'] != plan['blueprintSnapshotHash'] ||
        map['nodes'] is! List) {
      throw const EngineException('작성 원본/확장 snapshot 대응표가 다릅니다.');
    }
    return ExpandedAuthoring(xml, map, folder.path);
  }

  @override
  Future<String> expandPreset(
    EngineSettings settings,
    String id,
    String version,
    Map<String, dynamic> bindings,
  ) async {
    final manifest = await _verify(settings);
    if (manifest['designChecks'] != true) {
      throw const EngineException(
        'UNSUPPORTED_CAPABILITY: 공개 UX 팩을 지원하지 않는 엔진입니다.',
      );
    }
    final bytes = utf8.encode(jsonEncode(bindings));
    if (bytes.length > 1024 * 1024) {
      throw const EngineException('팩 매핑은 1 MiB 이하여야 합니다.');
    }
    final root = Directory(settings.reportRoot);
    await root.create(recursive: true);
    final session = await root.createTemp('preset-');
    final input = File('${session.path}/bindings.json');
    await input.writeAsBytes(bytes, flush: true);
    final output = File('${session.path}/expanded.xml');
    await _command(settings, [
      'preset',
      'expand',
      id,
      '--preset-version',
      version,
      '--bindings',
      input.path,
      '--out',
      output.path,
    ], allowEmpty: true);
    return utf8.decode(await _readBounded(output, 1024 * 1024));
  }

  @override
  Future<String> exportXml(EngineSettings settings, String source) async {
    final prepared = await prepare(settings, source);
    final output = File('${prepared.reportRoot}/export.xml');
    await _command(settings, [
      'export',
      prepared.inputPath,
      '--format',
      'xml',
      '--out',
      output.path,
    ], allowEmpty: true);
    return utf8.decode(await _readBounded(output, 1024 * 1024));
  }

  @override
  Future<PreparedScenario> prepare(
    EngineSettings settings,
    String source,
  ) async {
    final manifest = await _verify(settings);
    final bytes = utf8.encode(source);
    if (bytes.isEmpty || bytes.length > 1024 * 1024) {
      throw const EngineException('초안은 비어 있지 않은 UTF-8 1 MiB 이하 문서여야 합니다.');
    }
    final root = Directory(settings.reportRoot);
    await root.create(recursive: true);
    final session = await root.createTemp('qa-');
    final input = File(
      '${session.path}/input.${source.trimLeft().startsWith('<') ? 'xml' : 'json'}',
    );
    await input.writeAsBytes(bytes, flush: true);
    final referenceArgs = settings.referenceRoot.isEmpty
        ? <String>[]
        : ['--reference-root', settings.referenceRoot];
    await _command(settings, ['validate', input.path, ...referenceArgs]);
    final plan = await _command(settings, [
      'plan',
      input.path,
      ...referenceArgs,
    ]);
    if (plan['schemaVersion'] != 'qa.plan/v1' ||
        plan['engineVersion'] != manifest['engineVersion']) {
      throw const EngineException('실행계획 버전이 다릅니다.');
    }
    final blueprint = plan['blueprint'] as Map<String, dynamic>;
    // Freeze the engine-normalized definition; edits in the editor cannot alter it.
    final snapshot = File('${session.path}/snapshot.json');
    await snapshot.writeAsString(jsonEncode(blueprint), flush: true);
    final persisted = await _command(settings, ['plan', snapshot.path]);
    if (persisted['blueprintSnapshotHash'] != plan['blueprintSnapshotHash']) {
      throw const EngineException('저장된 실행계획 snapshot이 다릅니다.');
    }
    return PreparedScenario(
      settings: settings,
      inputPath: snapshot.path,
      reportRoot: session.path,
      plan: Map.unmodifiable(plan),
    );
  }

  @override
  Stream<EngineUpdate> run(PreparedScenario scenario) async* {
    if (_runPending) throw const EngineException('이미 실행 중입니다.');
    _runPending = true;
    _cancelRequested = false;
    try {
      yield* _execute(scenario);
    } finally {
      _runPending = false;
    }
  }

  void _checkBeforeStart() {
    if (_disposed) throw const EngineException('엔진 연결이 종료되었습니다.');
    if (_cancelRequested) {
      throw const EngineException('cancelled_before_start: 실행 전에 요청을 취소했습니다.');
    }
  }

  Stream<EngineUpdate> _execute(PreparedScenario scenario) async* {
    await _verify(scenario.settings);
    _checkBeforeStart();
    final blueprint = scenario.plan['blueprint'] as Map<String, dynamic>;
    final platform = (blueprint['target'] as Map)['platform'];
    final native = platform != 'web';
    if (native && scenario.settings.appiumConfig.isEmpty) {
      throw const EngineException('Appium 설정 파일을 명시하세요. 기기 연결은 실제 실행 때 확인합니다.');
    }
    final capabilities = await _command(scenario.settings, [
      'devices',
      '--json',
      if (native) ...[
        '--target',
        platform as String,
        '--appium-config',
        scenario.settings.appiumConfig,
      ],
    ]);
    if (!(capabilities['platforms'] as List).contains(platform) ||
        (!native && (capabilities['targets'] as List).isEmpty) ||
        !(scenario.plan['requiredActions'] as List).every(
          (action) =>
              (capabilities['supportedActions'] as List).contains(action),
        )) {
      throw const EngineException(
        'UNSUPPORTED_CAPABILITY: 대상 또는 액션을 실행할 수 없습니다.',
      );
    }
    _checkBeforeStart();
    final snapshotPlan = await _command(scenario.settings, [
      'plan',
      scenario.inputPath,
    ]);
    if (snapshotPlan['blueprintSnapshotHash'] !=
        scenario.plan['blueprintSnapshotHash']) {
      throw const EngineException('실행 snapshot이 변경되었습니다. 다시 검증하세요.');
    }
    _checkBeforeStart();
    final process = await CliProcess.start(
      scenario.settings.nodePath,
      [
        scenario.settings.cliPath,
        'run',
        scenario.inputPath,
        '--json',
        '--report',
        scenario.reportRoot,
        if (scenario.settings.referenceRoot.isNotEmpty) ...[
          '--reference-root',
          scenario.settings.referenceRoot,
        ],
        if (native) ...['--appium-config', scenario.settings.appiumConfig],
        if (_controlStdin) '--control-stdin',
        if (_controlStdin) ...['--diagnostics', 'stderr'],
      ],
      policy: processPolicy,
      timeout: processPolicy.runTimeout,
      gracefulStop: _controlStdin,
    );
    _active = process;
    if (_disposed) await process.stop();
    if (_cancelRequested) await cancel();
    final sequence = EventSequence(scenario.plan);
    try {
      await for (final line
          in process.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        final event = _decodeObject(line);
        sequence.add(event);
        yield EngineUpdate(event: Map.unmodifiable(event));
      }
      await process.done;
      process.check();
      final code = process.exitCode;
      final terminal = sequence.terminal;
      if (terminal == null) {
        throw const EngineException(
          'infra_error: 최종 결과 없이 종료되었습니다. 강제 종료는 정상 취소가 아닙니다.',
        );
      }
      final expectedCode = {
        'passed': 0,
        'failed': 1,
        'blocked': 4,
        'infra_error': 3,
        'cancelled': 5,
      }[terminal['outcome']];
      if (expectedCode != code) {
        throw const EngineException('종료 코드와 실행 결과가 다릅니다.');
      }
      final runRoot = Directory('${scenario.reportRoot}/${terminal['runId']}');
      final resolvedRoot = await runRoot.resolveSymbolicLinks();
      if (!_within(
            await Directory(scenario.reportRoot).resolveSymbolicLinks(),
            resolvedRoot,
          ) ||
          terminal['resultPath'] != 'result.json') {
        throw const EngineException('결과 경로가 실행 폴더 밖입니다.');
      }
      final resultFile = File('$resolvedRoot/result.json');
      if (!_within(resolvedRoot, await resultFile.resolveSymbolicLinks())) {
        throw const EngineException('결과 파일 경로가 잘못되었습니다.');
      }
      final result = jsonDecode(
        utf8.decode(await _readBounded(resultFile, _maxOutput)),
      ) as Map<String, dynamic>;
      if (result['schemaVersion'] != 'qa.result/v1' ||
          result['runId'] != terminal['runId'] ||
          result['attempt'] != terminal['attempt'] ||
          result['outcome'] != terminal['outcome'] ||
          (result['executed'] as Map)['engineVersion'] !=
              scenario.plan['engineVersion'] ||
          (result['executed'] as Map)['flowSnapshotHash'] !=
              scenario.plan['flowSnapshotHash'] ||
          (result['executed'] as Map)['blueprintSnapshotHash'] !=
              scenario.plan['blueprintSnapshotHash']) {
        throw const EngineException('결과와 실행 snapshot이 다릅니다.');
      }
      final images = <EvidenceImage>[];
      final checks = <Map<String, dynamic>>[];
      var totalBytes = 0;
      for (final artifact in result['artifacts'] as List) {
        final path = artifact['path'] as String;
        if (!_safeRelative(path)) {
          throw const EngineException('증거 경로가 실행 폴더 밖입니다.');
        }
        final file = File('$resolvedRoot/$path');
        if (!_within(resolvedRoot, await file.resolveSymbolicLinks())) {
          throw const EngineException('증거 파일 경로가 다릅니다.');
        }
        final bytes = await _readBounded(file, 64 * 1024 * 1024);
        totalBytes += bytes.length;
        if (totalBytes > 64 * 1024 * 1024 ||
            bytes.length != artifact['size'] ||
            sha256.convert(bytes).toString() != artifact['sha256']) {
          throw const EngineException('증거 파일 경로 또는 hash가 다릅니다.');
        }
        if (artifact['contentType'] == 'image/png') {
          images.add(EvidenceImage(path, bytes));
        }
        if (artifact['type'] == 'check-report') {
          final check = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
          if (check['schemaVersion'] != 'qa.checkReport/v1' ||
              !(scenario.plan['nodeOrder'] as List).contains(check['nodeId']) ||
              !['image', 'layout', 'ux'].contains(check['kind']) ||
              !['passed', 'failed', 'blocked'].contains(check['verdict']) ||
              check['reason'] is! String ||
              check['artifactRefs'] is! List) {
            throw const EngineException('검사 보고서 형식 또는 노드가 실행과 다릅니다.');
          }
          checks.add(Map.unmodifiable(check));
        }
      }
      final imagePaths = images.map((image) => image.path).toSet();
      for (final check in checks) {
        for (final ref in check['artifactRefs'] as List) {
          if (ref is! Map ||
              !['baseline', 'actual', 'diff'].contains(ref['role']) ||
              !imagePaths.contains(ref['path'])) {
            throw const EngineException('검사 이미지 참조가 검증된 증거에 없습니다.');
          }
        }
      }
      yield EngineUpdate(
        result: Map.unmodifiable(result),
        reportDirectory: resolvedRoot,
        images: List.unmodifiable(images),
        checks: List.unmodifiable(checks),
      );
    } on FormatException {
      throw const EngineException('엔진 이벤트 또는 결과가 올바른 UTF-8 JSON이 아닙니다.');
    } finally {
      await process.stop();
      _active = null;
    }
  }

  @override
  Future<void> cancel() async {
    if (_runPending) _cancelRequested = true;
    final process = _active;
    if (process == null) return;
    await process.cancel(controlStdin: _controlStdin);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final process in _commands) {
      unawaited(process.stop());
    }
    final active = _active;
    if (active != null) unawaited(active.stop());
  }
}

Map<String, dynamic> _decodeObject(String text) {
  final value = jsonDecode(text);
  if (value is! Map<String, dynamic>) {
    throw const EngineException('엔진 응답은 JSON object여야 합니다.');
  }
  return value;
}

bool _within(String root, String path) => path.toLowerCase().startsWith(
  '${root.toLowerCase()}${Platform.pathSeparator}',
);
bool _safeRelative(String path) =>
    path.isNotEmpty &&
    !path.contains(':') &&
    !path.startsWith('/') &&
    !path.startsWith('\\') &&
    !path.split(RegExp(r'[/\\]')).any((part) => part == '..' || part.isEmpty);

/// Checks transport ordering and snapshot identity, not execution semantics.
class EventSequence {
  EventSequence(this.plan);
  final Map<String, dynamic> plan;
  String? _run;
  int? _attempt;
  int _sequence = 0;
  String? _activeNode;
  final Set<String> _started = {};
  Map<String, dynamic>? terminal;
  void add(Map<String, dynamic> event) {
    if (event['error'] is Map) {
      throw EngineException(
        '${event['error']['code']}: ${event['error']['message']}',
      );
    }
    if (terminal != null ||
        event['schemaVersion'] != 'qa.runEvent/v1' ||
        event['sequence'] != _sequence + 1 ||
        event['runId'] is! String ||
        !RegExp(r'^[A-Za-z][A-Za-z0-9_.-]{0,127}$').hasMatch(event['runId']) ||
        event['attempt'] is! int ||
        event['attempt'] < 1) {
      throw const EngineException('이벤트 형식/순서가 잘못되었습니다.');
    }
    if (_sequence == 0) {
      if (event['type'] != 'run.started' ||
          event['blueprintSnapshotHash'] != plan['blueprintSnapshotHash']) {
        throw const EngineException('실행 snapshot이 다릅니다.');
      }
      _run = event['runId'];
      _attempt = event['attempt'];
    } else {
      if (event['runId'] != _run || event['attempt'] != _attempt) {
        throw const EngineException('다른 실행 이벤트가 섞였습니다.');
      }
      final type = event['type'];
      final node = event['nodeId'];
      if (type == 'step.started') {
        if (_activeNode != null ||
            _started.contains(node) ||
            !(plan['nodeOrder'] as List).contains(node)) {
          throw const EngineException('노드 시작 순서가 잘못되었습니다.');
        }
        _activeNode = node;
        _started.add(node);
      } else if (type == 'step.finished' || type == 'step.retrying') {
        if (_activeNode != node) throw const EngineException('실행 중인 노드와 다릅니다.');
        if (type == 'step.finished') {
          if (![
            'passed',
            'failed',
            'blocked',
            'infra_error',
            'cancelled',
            'skipped',
          ].contains(event['outcome'])) {
            throw const EngineException('잘못된 step outcome');
          }
          _activeNode = null;
        }
      } else if (type == 'run.finished') {
        if (_activeNode != null ||
            ![
              'passed',
              'failed',
              'blocked',
              'infra_error',
              'cancelled',
            ].contains(event['outcome'])) {
          throw const EngineException('실행 완료 이벤트가 잘못되었습니다.');
        }
        terminal = event;
      } else {
        throw const EngineException('알 수 없는 실행 이벤트입니다.');
      }
    }
    _sequence++;
  }
}
