import '../models/scenario_draft.dart';
import '../services/scenario_file_service.dart';

abstract interface class ScenarioRepository {
  Future<ScenarioDraft> open(String path);
  Future<ScenarioDraft> save(String path, ScenarioDraft draft);
}

class FileScenarioRepository implements ScenarioRepository {
  const FileScenarioRepository(this._files);
  final ScenarioFileService _files;
  @override
  Future<ScenarioDraft> open(String path) async =>
      ScenarioDraft(content: await _files.read(path), path: path);
  @override
  Future<ScenarioDraft> save(String path, ScenarioDraft draft) async {
    await _files.write(path, draft.content);
    return ScenarioDraft(content: draft.content, path: path);
  }
}
