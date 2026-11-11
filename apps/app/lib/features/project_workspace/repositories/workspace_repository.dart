import '../models/workspace.dart';
import '../services/workspace_file_service.dart';

class WorkspaceRepository {
  WorkspaceRepository(this.service);
  final WorkspaceFileService service;
  Future<Workspace> load() => service.read();
  Future<Workspace> save(Workspace value, {bool Function()? canCommit}) =>
      service.write(value, canCommit: canCommit);
  String get directory => service.directory.path;
}
