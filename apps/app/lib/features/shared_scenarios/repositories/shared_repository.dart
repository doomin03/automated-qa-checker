import 'dart:convert';

import 'package:api_client_dart/platform_client.dart';

import '../services/shared_file_service.dart';

class SharedRepository {
  SharedRepository(this.files);
  final SharedFileService files;
  PlatformClient? _client;
  int _generation = 0;
  bool _disposed = false;
  int get connectionGeneration => _generation;
  void _same(int generation, PlatformClient captured) {
    if (_disposed ||
        generation != _generation ||
        !identical(captured, _client)) {
      throw const FormatException('공유 연결이 바뀌었습니다. 다시 선택하세요.');
    }
  }

  PlatformClient get client => _client ?? (throw StateError('공유 서버에 연결하세요.'));
  String origin = '', project = '', cacheFolder = '';
  Map<String, dynamic>? receivedVersion;
  String? receivedOrigin, receivedProject;
  String? activeDocument, receivedDocument;
  void activateDocument(String? identity) {
    activeDocument = identity;
  }

  void restoreDocumentReceipt(
    String identity,
    Map<String, dynamic>? version,
    String? address,
    String? projectId,
  ) {
    if (activeDocument != identity) return;
    receivedDocument = identity;
    receivedVersion = version;
    receivedOrigin = address;
    receivedProject = projectId;
  }

  Future<IdentityResponse> discover(String address, String token) async {
    final candidate = PlatformClient(address, token);
    try {
      return await candidate.me();
    } finally {
      candidate.close();
    }
  }

  String? versionFor(Map<String, dynamic> plan) {
    final version = receivedVersion;
    if (version != null &&
        receivedDocument == activeDocument &&
        receivedOrigin == origin &&
        receivedProject == project &&
        version['blueprintSnapshotHash'] == plan['blueprintSnapshotHash']) {
      return version['id'] as String;
    }
    return null;
  }

  Future<IdentityResponse> connect(
    String address,
    String token,
    String projectId,
    String folder,
  ) async {
    if (_disposed) throw StateError('Repository is disposed');
    final generation = ++_generation;
    final candidate = PlatformClient(address, token);
    late IdentityResponse me;
    try {
      me = await candidate.me();
      if (!me.projects.any((p) => p.id == projectId)) {
        throw const FormatException('프로젝트 membership이 없습니다.');
      }
      if (_disposed || generation != _generation) {
        throw const FormatException('공유 연결 요청이 변경되었습니다.');
      }
    } catch (_) {
      candidate.close();
      rethrow;
    }
    _client?.close();
    _client = candidate;
    origin = address;
    project = projectId;
    cacheFolder = folder;
    return me;
  }

  Future<VersionPage> versions({String? cursor}) async {
    final api = client, generation = _generation;
    final page = await api.versions(project, cursor: cursor);
    _same(generation, api);
    return page;
  }

  Future<ProjectContextResponse> context() async {
    final api = client, generation = _generation, id = project;
    final value = await api.context(id);
    _same(generation, api);
    if (value.projectId != id) {
      throw const FormatException('프로젝트 context 소속이 다릅니다.');
    }
    return value;
  }

  Future<PinPage> suitePins({String? cursor}) async {
    final api = client, generation = _generation;
    final page = await api.suitePins(project, cursor: cursor);
    _same(generation, api);
    return page;
  }

  Future<Map<String, dynamic>> preview(String id) async {
    final api = client, generation = _generation;
    final v = await api.version(project, id);
    _same(generation, api);
    if (v.id != id || v.projectId != project) {
      throw const FormatException('요청한 원본 버전과 응답 소속이 다릅니다.');
    }
    final json = v.toJson();
    files.verifyXml(json);
    return json;
  }

  Future<Map<String, dynamic>?> offline(
    String folder,
    String address,
    String projectId,
  ) async {
    final owner = activeDocument, generation = _generation;
    final value = await files.cached(folder, address, projectId);
    if (owner != activeDocument || generation != _generation || _disposed) {
      throw const FormatException('문서 또는 연결이 변경되었습니다.');
    }
    if (value != null) {
      receivedVersion = value;
      receivedOrigin = address;
      receivedProject = projectId;
      receivedDocument = activeDocument;
    }
    return value;
  }

  Future<void> accept(
    Map<String, dynamic> version, {
    bool attachToDocument = true,
  }) async {
    final owner = activeDocument;
    final api = client,
        generation = _generation,
        address = origin,
        projectId = project,
        folder = cacheFolder;
    files.verifyXml(version);
    if (version['projectId'] != project) {
      throw const FormatException('수신 버전의 프로젝트가 다릅니다.');
    }
    final remote = await preview(version['id']);
    _same(generation, api);
    if (remote['sha256'] != version['sha256'] ||
        remote['blueprintSnapshotHash'] != version['blueprintSnapshotHash']) {
      throw const FormatException('수신 버전의 서버 정본이 다릅니다.');
    }
    await api.pin(projectId, version['id'], version['sha256']);
    _same(generation, api);
    await files.cache(folder, address, projectId, version);
    _same(generation, api);
    if (!attachToDocument) return;
    if (owner != activeDocument) {
      throw const FormatException('수신 중 문서가 변경되었습니다.');
    }
    receivedVersion = version;
    receivedOrigin = origin;
    receivedProject = project;
    receivedDocument = activeDocument;
  }

  Future<SuitePage> suites({String? cursor}) async {
    final api = client, generation = _generation;
    final page = await api.suites(project, cursor: cursor);
    _same(generation, api);
    return page;
  }

  Future<Map<String, dynamic>> suite(String id) async {
    final api = client, generation = _generation;
    final value = (await api.suite(project, id)).toJson();
    _same(generation, api);
    if (value['projectId'] != project || value['id'] != id) {
      throw const FormatException('요청한 Suite 버전 또는 프로젝트가 다릅니다.');
    }
    return value;
  }

  Future<void> pinSuite(Map<String, dynamic> version) async {
    final api = client, generation = _generation, projectId = project;
    final remote = await suite(version['id']);
    _same(generation, api);
    if (remote['sha256'] != version['sha256']) {
      throw const FormatException('Suite 고정 hash가 다릅니다.');
    }
    await api.pinSuite(projectId, version['id'], version['sha256']);
    _same(generation, api);
  }

  Future<String> diff(Map<String, dynamic> next) async {
    final api = client, generation = _generation, projectId = project;
    final old = await files.cached(cacheFolder, origin, project);
    _same(generation, api);
    if (old == null || old['id'] == next['id']) return '새 고정 버전입니다.';
    if (old['packageId'] != next['packageId']) {
      return '다른 패키지입니다. 이전 ${old['packageId']} ${old['version']} → ${next['packageId']} ${next['version']}';
    }
    final d = await api.upgradeDiff(projectId, old['id'], next['id']);
    _same(generation, api);
    return '${old['version']} → ${next['version']}\nXML 변경: ${d.xmlChanged} · dependency 변경: ${d.dependenciesChanged}\n이전 XML:\n${old['xml']}\n새 XML:\n${next['xml']}';
  }

  Future<RunResponse> createRun(
    Map<String, dynamic> plan,
    Map<String, dynamic> start, {
    String? versionId,
  }) async {
    final api = client, generation = _generation, projectId = project;
    final response = await api.createRun(
      projectId,
      RunInput(
        attempt: start['attempt'],
        blueprintJson: jsonEncode(plan['blueprint']),
        engineRunId: start['runId'],
        engineVersion: plan['engineVersion'],
        snapshotHash: plan['blueprintSnapshotHash'],
        startedEventJson: jsonEncode(start),
        versionId: versionId,
      ),
      '${start['runId']}.${start['attempt']}',
    );
    _same(generation, api);
    return response;
  }

  Future<void> append(String id, List<Map<String, dynamic>> events) async {
    final api = client, generation = _generation, projectId = project;
    for (var i = 0; i < events.length; i += 100) {
      _same(generation, api);
      await api.appendEvents(
        projectId,
        id,
        events.skip(i).take(100).map(jsonEncode).toList(),
      );
      _same(generation, api);
    }
  }

  Future<RunResponse> finish(
    String id,
    Map<String, dynamic> result,
    String directory,
  ) async {
    final api = client, generation = _generation, projectId = project;
    var remote = await api.result(projectId, id, jsonEncode(result));
    _same(generation, api);
    for (final artifact in remote.artifacts) {
      if (artifact.uploaded) continue;
      final bytes = await files.evidence(
        directory,
        artifact.name,
        artifact.sha256,
        artifact.size,
      );
      _same(generation, api);
      await api.uploadArtifact(
        projectId,
        id,
        ArtifactInput(
          artifactId: artifact.artifactId,
          sha256: artifact.sha256,
          mimeType: ArtifactInputMimeTypeEnum.values.firstWhere(
            (v) => v.value == artifact.mimeType,
          ),
          base64: base64Encode(bytes),
        ),
      );
      _same(generation, api);
    }
    remote = await api.run(projectId, id);
    _same(generation, api);
    return remote;
  }

  void disconnect() {
    _generation++;
    _client?.close();
    _client = null;
  }

  void dispose() {
    _disposed = true;
    disconnect();
  }
}
