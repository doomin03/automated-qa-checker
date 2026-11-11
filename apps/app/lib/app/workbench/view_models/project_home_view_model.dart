import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../features/shared_scenarios/models/qa_receipt.dart';
import '../../../features/shared_scenarios/repositories/qa_receipt_repository.dart';
import '../../../features/shared_scenarios/view_models/shared_view_model.dart';
import '../../../features/organization_login/view_models/organization_view_model.dart';
import '../../../features/xml_blocks/repositories/xml_block_repository.dart';
import 'desktop_workspace_view_model.dart';

class ProjectHomeViewModel extends ChangeNotifier {
  ProjectHomeViewModel(
    this.desktop,
    this.shared,
    this.auth,
    this.receipts,
    this.blocks,
  ) {
    desktop.workspace.addListener(_workspaceChanged);
    shared.addListener(_changed);
    auth.addListener(_changed);
  }
  final DesktopWorkspaceViewModel desktop;
  final SharedViewModel shared;
  final OrganizationViewModel auth;
  final QaReceiptRepository receipts;
  final XmlBlockRepository blocks;
  String section = 'projects', query = '', origin = '', _token = '';
  int queryResetRevision = 0;
  String? serverProject, destination, selectedLocalQa, error;
  String message = '';
  List<Map<String, dynamic>> projects = [];
  Map<String, QaReceipt> received = {};
  bool working = false, _disposed = false, localMode = false;
  int _generation = 0, _loadedRevision = -1, _loadGeneration = 0;
  bool get busy => working || shared.busy || auth.busy;
  bool get canReceive =>
      shared.connected &&
      !busy &&
      shared.preview != null &&
      projects.where((p) => p['id'] == serverProject).firstOrNull?['role'] !=
          'viewer';
  String get cacheFolder =>
      '${desktop.workspace.repository.directory}/shared-cache';
  String key(String project, String qa) => '$project/$qa';
  QaReceipt? receipt(String project, String qa) => received[key(project, qa)];
  List<QaReceipt> get duplicates => received.values
      .where(
        (r) =>
            r.origin == shared.repository.origin &&
            r.serverProjectId == shared.repository.project &&
            r.versionId == shared.preview?['id'],
      )
      .toList();
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _workspaceChanged() {
    _restoreSource();
    if (desktop.workspace.ready &&
        _loadedRevision != desktop.workspace.workspace.revision) {
      _loadedRevision = desktop.workspace.workspace.revision;
      refreshReceipts();
    }
    _changed();
  }

  Future<void> refreshReceipts() async {
    final ticket = ++_loadGeneration;
    final found = <String, QaReceipt>{};
    final failures = <String>[];
    for (final p in desktop.workspace.workspace.projects) {
      for (final q in p.documents) {
        try {
          final r = await receipts.read(p.id, q.id);
          if (r != null) found[key(p.id, q.id)] = r;
        } catch (_) {
          failures.add(q.name);
        }
      }
    }
    if (_disposed || ticket != _loadGeneration) return;
    received = found;
    _restoreSource();
    if (failures.isNotEmpty) {
      error = '출처를 읽지 못한 QA: ${failures.join(', ')}. 로컬 문서는 열 수 있습니다.';
    }
    _changed();
  }

  void _restoreSource() {
    final ws = desktop.workspace;
    final identity = ws.qaId == null ? null : key(ws.projectId!, ws.qaId!);
    shared.repository.activateDocument(identity);
    if (identity != null) {
      final r = received[identity];
      shared.repository.restoreDocumentReceipt(
        identity,
        r?.version,
        r?.origin,
        r?.serverProjectId,
      );
    }
  }

  void navigate(String value) {
    if (busy) return;
    section = value;
    query = '';
    queryResetRevision++;
    selectedLocalQa = null;
    _changed();
  }

  void search(String value) {
    query = value;
    _changed();
  }

  void chooseLocalQa(String? value) {
    if (busy) return;
    selectedLocalQa = value;
    _changed();
  }

  void chooseDestination(String? value) {
    if (busy) return;
    destination = value;
    _generation++;
    _changed();
  }

  bool matches(String value) =>
      value.toLowerCase().contains(query.trim().toLowerCase());
  Future<void> discover(
    String address, {
    String token = '',
    bool organization = false,
  }) async {
    if (busy || desktop.busy) return;
    final ticket = ++_generation;
    working = true;
    error = null;
    _changed();
    try {
      if (organization) await desktop.work.login(address);
      if (_disposed || ticket != _generation) return;
      final credential = auth.identity == null
          ? token
          : auth.credentialFor(address);
      final me = await shared.repository.discover(address, credential);
      if (_disposed || ticket != _generation) return;
      shared.disconnect();
      origin = address;
      _token = credential;
      localMode = me.localMode;
      projects = me.projects.map((p) => p.toJson()).toList();
      serverProject = null;
      message = projects.isEmpty ? '접근 가능한 서버 프로젝트가 없습니다.' : '서버 프로젝트를 선택하세요.';
    } catch (_) {
      if (ticket == _generation) {
        error = '서버 연결을 확인할 수 없습니다. 주소와 로그인 권한을 확인하세요.';
      }
    } finally {
      if (!_disposed && ticket == _generation) {
        working = false;
        _changed();
      }
    }
  }

  Future<void> connectProject(String value) async {
    if (busy || !projects.any((p) => p['id'] == value)) return;
    final ticket = ++_generation;
    working = true;
    error = null;
    serverProject = value;
    _changed();
    try {
      await shared.connect(origin, _token, value, cacheFolder);
      if (_disposed || ticket != _generation) return;
      if (shared.connected) await shared.loadSuites();
      message = shared.message;
    } finally {
      if (!_disposed && ticket == _generation) {
        working = false;
        _changed();
      }
    }
  }

  void disconnect() {
    _generation++;
    working = false;
    shared.disconnect();
    projects = [];
    serverProject = null;
    _token = '';
    message = '서버 연결을 해제했습니다. 가져온 QA는 계속 사용할 수 있습니다.';
    _changed();
  }

  Future<void> logout() async {
    disconnect();
    await auth.logout();
  }

  Future<bool> receive(String projectId, String name) async {
    if (!canReceive || desktop.busy) return false;
    final preview = shared.preview;
    if (preview == null) return false;
    final version = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(preview)) as Map,
    );
    final address = shared.repository.origin,
        remoteProject = shared.repository.project;
    final connection = shared.repository.connectionGeneration;
    final selection = desktop.workspace.selectionRevision;
    final ticket = ++_generation;
    final suite =
        shared.suitePinned &&
            shared.selectedSuite != null &&
            (shared.selectedSuite!['cases'] as List).any(
              (m) =>
                  m['versionId'] == version['id'] &&
                  m['sha256'] == version['sha256'],
            )
        ? Map<String, dynamic>.from(
            jsonDecode(jsonEncode(shared.selectedSuite)) as Map,
          )
        : null;
    bool current() =>
        !_disposed &&
        ticket == _generation &&
        connection == shared.repository.connectionGeneration &&
        shared.repository.origin == address &&
        shared.repository.project == remoteProject &&
        shared.preview?['id'] == version['id'] &&
        desktop.workspace.selectionRevision == selection;
    working = true;
    error = null;
    _changed();
    try {
      await shared.repository.accept(version, attachToDocument: false);
      if (!current()) return false;
      final ok = await desktop.workspace.receiveQa(
        projectId,
        name,
        version['xml'] as String,
        isCurrent: current,
        prepare: (qaId) async {
          final r = QaReceipt(
            projectId: projectId,
            qaId: qaId,
            origin: address,
            serverProjectId: remoteProject,
            version: version,
            receivedAt: DateTime.now().toUtc().toIso8601String(),
            suite: suite,
          );
          await receipts.write(r);
          if (!current()) throw const FormatException('수신 연결이 변경되었습니다.');
          await blocks.write(
            desktop.workspace.repository.directory,
            '$projectId/$qaId',
            {'mode': 'direct', 'assets': [], 'instances': [], 'links': []},
            0,
          );
        },
      );
      if (!ok) {
        error = desktop.workspace.error;
        return false;
      }
      desktop.select(projectId, desktop.workspace.qaId);
      await refreshReceipts();
      message = '새 로컬 QA로 가져왔습니다. 검증 후 실행하세요.';
      return true;
    } catch (_) {
      error = 'QA를 가져오지 못했습니다. 연결·권한·원본 버전과 저장 공간을 확인하세요.';
      return false;
    } finally {
      if (!_disposed && ticket == _generation) {
        working = false;
        _changed();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _loadGeneration++;
    desktop.workspace.removeListener(_workspaceChanged);
    shared.removeListener(_changed);
    auth.removeListener(_changed);
    super.dispose();
  }
}
