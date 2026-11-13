import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../features/xml_blocks/models/xml_block_document.dart';
import '../../../features/xml_blocks/repositories/document_authoring_repository.dart';
import '../../../features/run_review/models/engine_execution.dart';
import '../../../features/xml_blocks/repositories/xml_block_repository.dart';
import '../../../features/scenario_editor/services/scenario_file_service.dart';
import '../../../features/scenario_editor/services/scenario_file_picker.dart';
import '../../../features/run_review/services/engine_cli_service.dart';
import 'desktop_workspace_view_model.dart';

class XmlBlockWorkbenchViewModel extends ChangeNotifier {
  XmlBlockWorkbenchViewModel(
    this.desktop,
    this.engine,
    this.files,
    this.repository,
    this.picker,
  ) {
    desktop.addListener(_desktopChanged);
  }
  final DesktopWorkspaceViewModel desktop;
  final EngineCliService engine;
  final ScenarioFileService files;
  final XmlBlockRepository repository;
  final ScenarioFilePicker picker;
  final List<XmlBlockAsset> assets = [];
  final List<XmlBlockInstance> instances = [];
  final List<XmlBlockLink> links = [];
  final List<Map<String, dynamic>> _undo = [], _redo = [];
  final List<String> history = [];
  String? identity, selected, error, compiledXml, compiledHash;
  Map<String, Map<String, String>> sourceMap = {};
  Map<String, Map<String, String>> runSourceMap = {};
  String? mappedRunId;
  String? _runMapOwner, _runMapHash;
  Map<String, dynamic>? _engineIdentity;
  int revision = 0, compiledRevision = -1, saveRevision = 0, _generation = 0;
  bool busy = false,
      dirty = false,
      _disposed = false,
      _synchronizing = false,
      enabled = false;
  bool _loadFailed = false;
  bool get canUndo => _undo.isNotEmpty && !busy;
  bool get canRedo => _redo.isNotEmpty && !busy;
  bool get current =>
      compiledRevision == revision &&
      compiledXml != null &&
      desktop.work.source == compiledXml;
  XmlBlockInstance? get selectedInstance =>
      instances.where((n) => n.id == selected).firstOrNull;
  XmlBlockAsset? asset(String id) =>
      assets.where((a) => a.id == id).firstOrNull;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _desktopChanged() {
    final next = desktop.workspace.qaId == null
        ? null
        : '${desktop.workspace.projectId}/${desktop.workspace.qaId}';
    if (next != identity) {
      identity = next;
      _generation++;
      assets.clear();
      instances.clear();
      links.clear();
      _undo.clear();
      _redo.clear();
      history.clear();
      selected = null;
      compiledXml = null;
      compiledHash = null;
      sourceMap = {};
      runSourceMap = {};
      mappedRunId = null;
      _runMapOwner = null;
      _runMapHash = null;
      enabled = next != null;
      busy = false;
      error = null;
      _loadFailed = false;
      dirty = false;
      saveRevision = 0;
      revision++;
      compiledRevision = -1;
      if (next != null) load();
    }
    if (!_synchronizing) {
      desktop.setRunBlock('xml-block', enabled && !current);
    }
  }

  Map<String, dynamic> _document() => {
    'mode': enabled ? 'composition' : 'direct',
    'engineIdentity': _engineIdentity,
    'compiledXml': compiledXml,
    'compiledHash': compiledHash,
    'sourceMap': sourceMap,
    'runSourceMap': runSourceMap,
    'runMapOwner': _runMapOwner,
    'runMapHash': _runMapHash,
    'mappedRunId': mappedRunId,
    'assets': assets.map((a) => a.toJson()).toList(),
    'instances': instances.map((n) => n.toJson()).toList(),
    'links': links.map((e) => e.toJson()).toList(),
  };
  Map<String, dynamic> _layoutSnapshot() => {
    'instances': instances.map((n) => n.toJson()).toList(),
    'links': links.map((e) => e.toJson()).toList(),
  };
  void _checkpoint(String label) {
    _undo.add(_layoutSnapshot());
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
    history.add(label);
    if (history.length > 100) history.removeAt(0);
  }

  void _changed({bool semantic = true}) {
    dirty = true;
    if (semantic) {
      revision++;
      compiledRevision = -1;
      desktop.work.run.invalidateValidation();
      if (enabled) desktop.setRunBlock('xml-block', true);
    }
    _notify();
  }

  void setEnabled(bool value) {
    if (busy) return;
    if (enabled != value) dirty = true;
    enabled = value;
    desktop.setRunBlock('xml-block', value && !current);
    _notify();
  }

  void select(String? id) {
    selected = id;
    _notify();
  }

  Future<String?> chooseFile({bool allowJson = false}) async {
    if (busy || desktop.busy || identity == null) return null;
    final owner = identity, ticket = _generation;
    try {
      final path = await picker.choose(allowJson: allowJson);
      return !_disposed && identity == owner && ticket == _generation
          ? path
          : null;
    } catch (e) {
      if (ticket == _generation) {
        error = '파일 선택 창을 열 수 없습니다. 경로 입력을 사용하세요. ($e)';
        _notify();
      }
      return null;
    }
  }

  Future<void> load() async {
    final id = identity;
    if (id == null) return;
    final ticket = ++_generation;
    busy = true;
    error = null;
    _notify();
    try {
      final runtime = jsonDecode(
        await rootBundle.loadString('assets/desktop-engine-runtime.json'),
      ) as Map<String, dynamic>;
      final engineIdentity = {
        for (final key in [
          'packageName',
          'engineVersion',
          'contractVersion',
          'sha256',
          'bundleSha256',
        ])
          key: runtime[key],
      };
      final data = await repository.read(
        desktop.workspace.repository.directory,
        id,
      );
      if (ticket != _generation) return;
      _engineIdentity = engineIdentity;
      if (data == null) return;
      final loaded = <XmlBlockAsset>[];
      for (final raw in data['assets']) {
        final xml = raw['xml'] as String;
        if (blockHash(xml) != raw['hash']) {
          throw const FormatException('보관 XML hash가 다릅니다.');
        }
        final prepared = await engine.prepare(
          desktop.work.settings.execution,
          xml,
        );
        loaded.add(
          XmlBlockAsset(
            id: raw['id'],
            name: raw['name'],
            path: raw['path'],
            xml: xml,
            blueprint: Map<String, dynamic>.from(prepared.plan['blueprint']),
          ),
        );
      }
      if (_disposed || ticket != _generation || identity != id) return;
      assets.addAll(loaded);
      _restore(data);
      saveRevision = data['saveRevision'];
      enabled = data['mode'] != 'direct';
      compiledXml = data['compiledXml'] as String?;
      compiledHash = data['compiledHash'] as String?;
      sourceMap = {
        for (final entry in (data['sourceMap'] as Map? ?? {}).entries)
          entry.key as String: Map<String, String>.from(entry.value),
      };
      if (data['runMapOwner'] == identity &&
          data['runMapHash'] == desktop.resultSnapshot) {
        runSourceMap = {
          for (final entry in (data['runSourceMap'] as Map? ?? {}).entries)
            entry.key as String: Map<String, String>.from(entry.value),
        };
        _runMapOwner = data['runMapOwner'];
        _runMapHash = data['runMapHash'];
        mappedRunId = data['mappedRunId'];
      }
      dirty = false;
      error = null;
    } catch (e) {
      if (ticket == _generation) {
        error = '$e';
        _loadFailed = true;
      }
    } finally {
      if (ticket == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  void _restore(Map<String, dynamic> d) {
    final ids = <String>{};
    final ns = <XmlBlockInstance>[];
    for (final v in d['instances']) {
      if (v['id'] is! String ||
          !ids.add(v['id']) ||
          asset(v['assetId']) == null ||
          v['x'] is! num ||
          v['y'] is! num ||
          !(v['x'] as num).isFinite ||
          !(v['y'] as num).isFinite ||
          v['x'] < 0 ||
          v['y'] < 0 ||
          v['x'] > 100000 ||
          v['y'] > 100000) {
        throw const FormatException('블록 인스턴스가 손상되었습니다.');
      }
      ns.add(
        XmlBlockInstance(
          v['id'],
          v['assetId'],
          (v['x'] as num).toDouble(),
          (v['y'] as num).toDouble(),
        ),
      );
    }
    final es = <XmlBlockLink>[];
    for (final v in d['links']) {
      if (!ids.contains(v['from']) || !ids.contains(v['to'])) {
        throw const FormatException('블록 연결이 손상되었습니다.');
      }
      es.add(XmlBlockLink(v['from'], v['to']));
    }
    instances
      ..clear()
      ..addAll(ns);
    links
      ..clear()
      ..addAll(es);
  }

  Future<bool> importFile(String path) async {
    if (busy || desktop.busy || identity == null) return false;
    final ticket = ++_generation,
        id = identity,
        settings = desktop.work.settings.revision;
    busy = true;
    error = null;
    _notify();
    try {
      final xml = await files.read(path);
      if (!xml.trimLeft().startsWith('<')) {
        throw const FormatException('XML 파일을 선택하세요. JSON은 직접 문서로 열 수 있습니다.');
      }
      final prepared = await engine.prepare(
        desktop.work.settings.execution,
        xml,
      );
      if (_disposed ||
          ticket != _generation ||
          identity != id ||
          settings != desktop.work.settings.revision) {
        return false;
      }
      final hash = blockHash(xml);
      if (assets.any((a) => a.hash == hash)) {
        error = '같은 내용의 XML이 라이브러리에 있습니다. 기존 파일을 배치하세요.';
        return false;
      }
      final a = XmlBlockAsset(
        id: 'asset_${hash.substring(0, 16)}',
        name: path.replaceAll('\\', '/').split('/').last,
        path: path,
        xml: xml,
        blueprint: Map<String, dynamic>.from(prepared.plan['blueprint']),
      );
      assets.add(a);
      dirty = true;
      history.add('${a.name} 가져오기');
      return true;
    } catch (e) {
      if (ticket == _generation) error = '$e';
      return false;
    } finally {
      if (ticket == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  void add(String assetId, {double? x, double? y}) {
    if (busy || desktop.work.run.running || asset(assetId) == null) return;
    _checkpoint('XML 블록 추가');
    var i = 1;
    while (instances.any((n) => n.id == 'instance_$i')) {
      i++;
    }
    final n = XmlBlockInstance(
      'instance_$i',
      assetId,
      x ?? 60 + instances.length * 300,
      y ?? 100,
    );
    instances.add(n);
    selected = n.id;
    enabled = true;
    _changed();
  }

  void move(String id, double x, double y) {
    final i = instances.indexWhere((n) => n.id == id);
    if (i < 0 || busy || desktop.work.run.running) return;
    _checkpoint('블록 위치 변경');
    instances[i] = instances[i].at(x.clamp(0, 100000), y.clamp(0, 100000));
    _changed(semantic: false);
  }

  void connect(String from, String to) {
    if (from == to || busy || desktop.work.run.running) return;
    _checkpoint('블록 연결');
    links.removeWhere((e) => e.from == from || e.to == to);
    links.add(XmlBlockLink(from, to));
    _changed();
  }

  void disconnect(String from, String to) {
    _checkpoint('연결 삭제');
    links.removeWhere((e) => e.from == from && e.to == to);
    _changed();
  }

  void removeSelected() {
    if (selected == null || busy || desktop.work.run.running) return;
    _checkpoint('블록 삭제');
    instances.removeWhere((n) => n.id == selected);
    links.removeWhere((e) => e.from == selected || e.to == selected);
    selected = null;
    _changed();
  }

  void undo() {
    if (!canUndo || desktop.work.run.running) return;
    _redo.add(_layoutSnapshot());
    final before = _semanticIdentity();
    _restore(_undo.removeLast());
    _changed(semantic: before != _semanticIdentity());
  }

  void redo() {
    if (!canRedo || desktop.work.run.running) return;
    _undo.add(_layoutSnapshot());
    final before = _semanticIdentity();
    _restore(_redo.removeLast());
    _changed(semantic: before != _semanticIdentity());
  }

  String _semanticIdentity() => jsonEncode({
    'instances': instances.map((n) => [n.id, n.assetId]).toList(),
    'links': links.map((e) => e.toJson()).toList(),
  });

  Future<bool> save() async {
    if (busy || identity == null) return false;
    if (_loadFailed) {
      error = '읽기 오류가 있는 기존 문서는 덮어쓸 수 없습니다.';
      _notify();
      return false;
    }
    final ticket = _generation, id = identity!;
    busy = true;
    _notify();
    try {
      await repository.write(
        desktop.workspace.repository.directory,
        id,
        _document(),
        saveRevision,
      );
      if (ticket == _generation) {
        saveRevision++;
        dirty = false;
        error = null;
        return true;
      }
      return false;
    } catch (e) {
      if (ticket == _generation) error = '$e';
      return false;
    } finally {
      if (ticket == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<bool> compile() async {
    if (busy || desktop.busy || identity == null) return false;
    final ticket = ++_generation,
        id = identity,
        rev = revision,
        sourceRevision = desktop.work.editor.revision,
        settings = desktop.work.settings.revision;
    busy = true;
    error = null;
    _notify();
    final inputAssets = List<XmlBlockAsset>.from(assets),
        inputInstances = List<XmlBlockInstance>.from(instances),
        inputLinks = List<XmlBlockLink>.from(links);
    final executionSettings = desktop.work.settings.execution;
    try {
      final composed = await DocumentAuthoringRepository(engine).compose(
        executionSettings,
        inputAssets,
        inputInstances,
        inputLinks,
      );
      final xml = composed['xml'] as String;
      final prepared = await engine.prepare(executionSettings, xml);
      if(prepared.plan['blueprintSnapshotHash'] != composed['blueprintSnapshotHash'] ||
          prepared.plan['flowSnapshotHash'] != composed['flowSnapshotHash']) {
        throw const EngineException('합성 후 실행 계획 snapshot이 다릅니다.');
      }
      if (_disposed ||
          ticket != _generation ||
          identity != id ||
          revision != rev ||
          sourceRevision != desktop.work.editor.revision ||
          settings != desktop.work.settings.revision) {
        if (ticket == _generation) {
          error = '문서 또는 설정이 바뀌어 이전 조합 결과를 적용하지 않았습니다.';
        }
        return false;
      }
      compiledXml = xml;
      compiledHash = prepared.plan['blueprintSnapshotHash'];
      compiledRevision = revision;
      sourceMap = composed['uiSourceMap'] as Map<String, Map<String,String>>;
      _synchronizing = true;
      desktop.work.editor.edit(xml);
      desktop.work.flow.load(
        Map<String, dynamic>.from(prepared.plan['blueprint']),
      );
      _synchronizing = false;
      desktop.setRunBlock('xml-block', false);
      history.add('XML 조합 완료');
      return true;
    } catch (e) {
      if (ticket == _generation) {
        error = '$e';
        if (e is BlockDiagnostic) selected = e.instanceId ?? selected;
        if (e is EngineAuthoringException) {
          final first=e.diagnostics.firstOrNull;
          selected=first?['instanceId'] as String? ?? selected;
          error='${e.message}\n${e.diagnostics.map((d)=>"${d['path']}: ${d['message']}").join('\n')}';
        }
      }
      return false;
    } finally {
      _synchronizing = false;
      if (ticket == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> export(String path) async {
    if (!current) {
      error = '현재 조합을 먼저 검증하세요.';
      _notify();
      return;
    }
    final ticket = _generation;
    try {
      await files.write(path, compiledXml!);
      if (ticket == _generation) error = null;
    } catch (e) {
      if (ticket == _generation) error = '$e';
    }
    _notify();
  }

  void captureRunMap() {
    _runMapOwner = identity;
    _runMapHash = compiledHash;
    mappedRunId = null;
    runSourceMap = {
      for (final e in sourceMap.entries)
        e.key: Map<String, String>.from(e.value),
    };
  }

  void finishRunMap() {
    if (_runMapOwner == identity && _runMapHash == desktop.resultSnapshot) {
      mappedRunId = desktop.work.run.result?['runId'] as String?;
      dirty = true;
      _notify();
    }
  }

  Map<String, String>? currentRunMapping(String? nodeId) {
    if (_runMapOwner != identity ||
        _runMapHash != desktop.resultSnapshot ||
        mappedRunId == null ||
        mappedRunId != desktop.work.run.result?['runId']) {
      return null;
    }
    return runSourceMap[nodeId];
  }

  void focusGenerated(String nodeId) {
    final mapping = currentRunMapping(nodeId);
    if (mapping == null) return;
    final instance = instances
        .where((n) => n.id == mapping['instanceId'])
        .firstOrNull;
    final source = instance == null ? null : asset(instance.assetId);
    if (instance == null ||
        source == null ||
        source.id != mapping['assetId'] ||
        source.hash != mapping['sourceHash']) {
      error = '실행 당시 파일 블록이 현재 조합과 다릅니다. 저장된 실행 결과를 확인하세요.';
      _notify();
      return;
    }
    selected = instance.id;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    desktop.removeListener(_desktopChanged);
    desktop.setRunBlock('xml-block', false);
    engine.dispose();
    super.dispose();
  }
}
