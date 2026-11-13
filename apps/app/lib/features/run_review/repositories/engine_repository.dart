import '../models/engine_execution.dart';
import '../services/engine_cli_service.dart';

class EngineRepository {
  EngineRepository(this._service);
  final EngineCliService _service;
  Future<Map<String, dynamic>> capabilities(
    EngineSettings settings,
    String platform,
  ) => _service.capabilities(settings, platform);
  Future<ExpandedAuthoring> expandAuthoring(
    EngineSettings settings,
    String source,
  ) => _service.expandAuthoring(settings, source);
  Future<PreparedScenario> validate(EngineSettings settings, String source) =>
      _service.prepare(settings, source);
  Stream<EngineUpdate> run(PreparedScenario scenario) => _service.run(scenario);
  Future<void> cancel() => _service.cancel();
  Future<String> expandPreset(
    EngineSettings settings,
    String id,
    String version,
    Map<String, dynamic> bindings,
  ) => _service.expandPreset(settings, id, version, bindings);
  Future<String> exportXml(EngineSettings settings, String source) =>
      _service.exportXml(settings, source);
}
