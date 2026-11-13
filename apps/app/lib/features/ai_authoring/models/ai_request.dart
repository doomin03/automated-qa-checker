class AiSettings {
  const AiSettings({this.provider = 'codex', this.executable = ''});
  final String provider, executable;
}

enum AiScope { whole, selected, before, after }

extension AiScopeLabel on AiScope {
  String get label => switch (this) {
    AiScope.whole => '전체 흐름',
    AiScope.selected => '선택 수정',
    AiScope.before => '선택 앞 삽입',
    AiScope.after => '선택 뒤 삽입',
  };
}

class AiAnswer {
  const AiAnswer(this.summary, this.xml, this.sessionDirectory);
  final String summary, xml, sessionDirectory;
}

class AiFailure implements Exception {
  const AiFailure(this.message, {this.cleanupUnknown = false});
  final String message;
  final bool cleanupUnknown;
  @override
  String toString() => message;
}

class AiStamp {
  const AiStamp(
    this.projectId,
    this.qaId,
    this.document,
    this.selection,
    this.prompt,
    this.settings,
    this.generation,
  );
  final String projectId, qaId;
  final int document, selection, prompt, settings, generation;
  @override
  bool operator ==(Object other) =>
      other is AiStamp &&
      projectId == other.projectId &&
      qaId == other.qaId &&
      document == other.document &&
      selection == other.selection &&
      prompt == other.prompt &&
      settings == other.settings &&
      generation == other.generation;
  @override
  int get hashCode => Object.hash(
    projectId,
    qaId,
    document,
    selection,
    prompt,
    settings,
    generation,
  );
}
