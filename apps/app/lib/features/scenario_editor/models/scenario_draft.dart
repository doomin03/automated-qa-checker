/// Editor state only; the engine owns all QA execution schemas.
class ScenarioDraft {
  const ScenarioDraft({this.content = '', this.path});
  final String content;
  final String? path;
  ScenarioDraft withContent(String value) =>
      ScenarioDraft(content: value, path: path);
}
