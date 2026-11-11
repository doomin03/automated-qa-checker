import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/workspace.dart';
import '../repositories/workspace_repository.dart';

class WorkspaceViewModel extends ChangeNotifier {
  WorkspaceViewModel(this.repository);
  final WorkspaceRepository repository;
  Workspace _workspace = Workspace();
  Workspace get workspace => _workspace;
  String? projectId, qaId, error;
  String instructions = '', prompt = '';
  int selectionRevision = 0, promptRevision = 0;
  bool busy = false, ready = false, _disposed = false;
  QaProject? get project =>
      _workspace.projects.where((p) => p.id == projectId).firstOrNull;
  QaDocument? get qa =>
      project?.documents.where((q) => q.id == qaId).firstOrNull;
  bool get promptsDirty =>
      instructions != (project?.instructions ?? '') ||
      prompt != (qa?.prompt ?? '');
  String _id() => List.generate(
    16,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> _operation(Future<void> Function() action) async {
    if (busy || _disposed) return false;
    busy = true;
    error = null;
    _notify();
    try {
      await action();
      return !_disposed;
    } catch (e) {
      if (!_disposed) error = '작업 공간 오류: $e';
      return false;
    } finally {
      if (!_disposed) {
        busy = false;
        _notify();
      }
    }
  }

  Future<bool> initialize() => _operation(() async {
    final value = await repository.load();
    if (_disposed) return;
    _workspace = value;
    ready = true;
  });
  void select(String? projectId, String? qaId) {
    if (busy || _disposed) return;
    this.projectId = projectId;
    this.qaId = qaId;
    instructions = project?.instructions ?? '';
    prompt = qa?.prompt ?? '';
    selectionRevision++;
    promptRevision++;
    error = null;
    _notify();
  }

  void editInstructions(String value) {
    if (busy || _disposed || value == instructions) return;
    instructions = value;
    promptRevision++;
    _notify();
  }

  void editPrompt(String value) {
    if (busy || _disposed || value == prompt) return;
    prompt = value;
    promptRevision++;
    _notify();
  }

  Future<bool> createProject(String name) => _operation(() async {
    if (name.trim().isEmpty) throw const FormatException('프로젝트 이름을 입력하세요.');
    final p = QaProject(id: _id(), name: name.trim());
    final value = await repository.save(
      _workspace.copyWith(projects: [..._workspace.projects, p]),
    );
    if (_disposed) return;
    _workspace = value;
    projectId = p.id;
    qaId = null;
    instructions = '';
    prompt = '';
    selectionRevision++;
    promptRevision++;
  });
  Future<bool> createQa(String name, String source) => _operation(() async {
    final p = project;
    if (p == null || name.trim().isEmpty) {
      throw const FormatException('프로젝트와 QA 이름이 필요합니다.');
    }
    final q = QaDocument(id: _id(), name: name.trim(), source: source);
    final value = await repository.save(
      _workspace.copyWith(
        projects: _workspace.projects
            .map(
              (v) =>
                  v.id == p.id ? v.copyWith(documents: [...v.documents, q]) : v,
            )
            .toList(),
      ),
    );
    if (_disposed) return;
    _workspace = value;
    qaId = q.id;
    prompt = '';
    selectionRevision++;
    promptRevision++;
  });
  Future<bool> receiveQa(
    String destination,
    String name,
    String source, {
    required Future<void> Function(String qaId) prepare,
    required bool Function() isCurrent,
  }) => _operation(() async {
    final p = _workspace.projects.where((p) => p.id == destination).firstOrNull;
    if (p == null || name.trim().isEmpty || !isCurrent()) {
      throw const FormatException('수신할 프로젝트와 QA 이름을 다시 선택하세요.');
    }
    final q = QaDocument(
      id: _id(),
      name: name.trim(),
      source: source,
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await prepare(q.id);
    if (_disposed || !isCurrent()) {
      throw const FormatException('수신 대상이 바뀌어 QA를 만들지 않았습니다.');
    }
    final value = await repository.save(
      _workspace.copyWith(
        projects: _workspace.projects
            .map(
              (v) => v.id == destination
                  ? v.copyWith(documents: [...v.documents, q])
                  : v,
            )
            .toList(),
      ),
      canCommit: isCurrent,
    );
    if (_disposed) return;
    _workspace = value;
    projectId = destination;
    qaId = q.id;
    instructions = p.instructions;
    prompt = '';
    selectionRevision++;
    promptRevision++;
  });
  Future<bool> save(
    String source, {
    String? projectName,
    String? qaName,
    Map<String, String>? settings,
  }) => _operation(() async {
    final p = project;
    final q = qa;
    final projects = _workspace.projects
        .map(
          (v) => v.id == p?.id
              ? v.copyWith(
                  name: projectName,
                  instructions: instructions,
                  documents: v.documents
                      .map(
                        (d) => d.id == q?.id
                            ? d.copyWith(
                                name: qaName,
                                source: source,
                                prompt: prompt,
                              )
                            : d,
                      )
                      .toList(),
                )
              : v,
        )
        .toList();
    final value = await repository.save(
      _workspace.copyWith(projects: projects, settings: settings),
    );
    if (!_disposed) _workspace = value;
  });
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<bool> recordRun(String projectId, String qaId, LastRun summary) =>
      _operation(() async {
        final projects = _workspace.projects
            .map(
              (p) => p.id == projectId
                  ? p.copyWith(
                      documents: p.documents
                          .map(
                            (q) =>
                                q.id == qaId ? q.copyWith(lastRun: summary) : q,
                          )
                          .toList(),
                    )
                  : p,
            )
            .toList();
        final value = await repository.save(
          _workspace.copyWith(projects: projects),
        );
        if (!_disposed) _workspace = value;
      });
}
