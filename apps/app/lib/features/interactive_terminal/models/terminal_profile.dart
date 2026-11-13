class TerminalProfile {
  const TerminalProfile(this.id, this.label, this.executable, {this.readiness = 'unchecked', this.detail = ''});
  final String id, label, executable, readiness, detail;
  bool get available => readiness == 'available';
  bool get ai => id == 'codex' || id == 'claude';
  List<String> arguments(String cwd) => switch (id) {
    'codex' => ['--no-daemon', '--no-alt-screen', '-C', cwd, '-s', 'workspace-write', '-a', 'on-request'],
    'claude' => [],
    'powershell' => ['-NoLogo', '-NoProfile'],
    'cmd' => ['/D'],
    _ => throw StateError('지원하지 않는 터미널입니다.'),
  };
}
