import 'dart:convert';

class QaDocument {
  const QaDocument({
    required this.id,
    required this.name,
    this.source = '',
    this.prompt = '',
    this.updatedAt = '',
    this.lastRun,
  });
  final String id, name, source, prompt, updatedAt;
  final LastRun? lastRun;
  QaDocument copyWith({
    String? name,
    String? source,
    String? prompt,
    LastRun? lastRun,
  }) => QaDocument(
    id: id,
    name: name ?? this.name,
    source: source ?? this.source,
    prompt: prompt ?? this.prompt,
    updatedAt: DateTime.now().toUtc().toIso8601String(),
    lastRun: lastRun ?? this.lastRun,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'source': source,
    'prompt': prompt,
    'updatedAt': updatedAt,
    if (lastRun != null) 'lastRun': lastRun!.toJson(),
  };
  factory QaDocument.fromJson(Map<String, dynamic> j) {
    keys(j, {'id', 'name', 'source', 'prompt', 'updatedAt', 'lastRun'});
    return QaDocument(
      id: text(j, 'id', 128),
      name: text(j, 'name', 512),
      source: text(j, 'source', 1024 * 1024),
      prompt: text(j, 'prompt', 65536),
      updatedAt: text(j, 'updatedAt', 64),
      lastRun: j['lastRun'] == null
          ? null
          : LastRun.fromJson(j['lastRun'] as Map<String, dynamic>),
    );
  }
}

class LastRun {
  const LastRun({
    required this.runId,
    required this.snapshotHash,
    required this.reportDirectory,
    required this.outcome,
  });
  final String runId, snapshotHash, reportDirectory, outcome;
  Map<String, dynamic> toJson() => {
    'runId': runId,
    'snapshotHash': snapshotHash,
    'reportDirectory': reportDirectory,
    'outcome': outcome,
  };
  factory LastRun.fromJson(Map<String, dynamic> j) {
    keys(j, {'runId', 'snapshotHash', 'reportDirectory', 'outcome'});
    return LastRun(
      runId: text(j, 'runId', 256),
      snapshotHash: text(j, 'snapshotHash', 128),
      reportDirectory: text(j, 'reportDirectory', 4096),
      outcome: text(j, 'outcome', 64),
    );
  }
}

class QaProject {
  QaProject({
    required this.id,
    required this.name,
    this.instructions = '',
    List<QaDocument> documents = const [],
  }) : documents = List.unmodifiable(documents);
  final String id, name, instructions;
  final List<QaDocument> documents;
  QaProject copyWith({
    String? name,
    String? instructions,
    List<QaDocument>? documents,
  }) => QaProject(
    id: id,
    name: name ?? this.name,
    instructions: instructions ?? this.instructions,
    documents: documents ?? this.documents,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'instructions': instructions,
    'documents': documents.map((q) => q.toJson()).toList(),
  };
  factory QaProject.fromJson(Map<String, dynamic> j) {
    keys(j, {'id', 'name', 'instructions', 'documents'});
    return QaProject(
      id: text(j, 'id', 128),
      name: text(j, 'name', 512),
      instructions: text(j, 'instructions', 65536),
      documents: objects(j['documents']).map(QaDocument.fromJson).toList(),
    );
  }
}

class Workspace {
  Workspace({
    this.revision = 0,
    List<QaProject> projects = const [],
    Map<String, String> settings = const {},
  }) : projects = List.unmodifiable(projects),
       settings = Map.unmodifiable(settings);
  final int revision;
  final List<QaProject> projects;
  final Map<String, String> settings;
  static const settingKeys = {
    'runtimeMode',
    'runtimeDefaultNode',
    'runtimeDefaultCli',
    'aiProvider',
    'aiExecutable',
    'nodePath',
    'cliPath',
    'reportRoot',
    'referenceRoot',
    'appiumConfig',
  };
  Workspace copyWith({
    int? revision,
    List<QaProject>? projects,
    Map<String, String>? settings,
  }) => Workspace(
    revision: revision ?? this.revision,
    projects: projects ?? this.projects,
    settings: settings ?? this.settings,
  );
  Map<String, dynamic> toJson() => {
    'version': 1,
    'revision': revision,
    'projects': projects.map((p) => p.toJson()).toList(),
    'settings': settings,
  };
  factory Workspace.fromJson(Map<String, dynamic> j) {
    keys(j, {'version', 'revision', 'projects', 'settings'});
    if (j['version'] != 1 ||
        j['revision'] is! int ||
        j['revision'] < 0 ||
        j['settings'] is! Map) {
      throw const FormatException('지원하지 않는 작업 공간 형식입니다.');
    }
    final projects = objects(j['projects']).map(QaProject.fromJson).toList();
    final ids = <String>{};
    for (final p in projects) {
      if (p.id.isEmpty || !ids.add(p.id)) {
        throw const FormatException('중복 프로젝트 ID');
      }
      for (final q in p.documents) {
        if (q.id.isEmpty || !ids.add(q.id)) {
          throw const FormatException('중복 QA ID');
        }
      }
    }
    final settings = <String, String>{};
    for (final entry in (j['settings'] as Map).entries) {
      if (!settingKeys.contains(entry.key) ||
          entry.value is! String ||
          utf8.encode(entry.value).length > 4096) {
        throw const FormatException('잘못된 연결 설정');
      }
      settings[entry.key as String] = entry.value as String;
    }
    return Workspace(
      revision: j['revision'],
      projects: projects,
      settings: settings,
    );
  }
}

String text(Map<String, dynamic> j, String key, int limit) {
  final value = j[key];
  if (value is! String || utf8.encode(value).length > limit) {
    throw FormatException('잘못된 필드: $key');
  }
  return value;
}

void keys(Map<String, dynamic> value, Set<String> allowed) {
  if (value.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('지원하지 않는 작업 공간 필드입니다. 원본은 보존됩니다.');
  }
}

List<Map<String, dynamic>> objects(dynamic value) {
  if (value is! List ||
      value.length > 10000 ||
      value.any((v) => v is! Map<String, dynamic>)) {
    throw const FormatException('잘못된 목록');
  }
  return value.cast<Map<String, dynamic>>();
}
