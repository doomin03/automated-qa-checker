import 'dart:io';
import 'package:automated_qa_desktop/features/project_workspace/services/workspace_file_service.dart';
import 'package:automated_qa_desktop/features/project_workspace/models/workspace.dart';

Future<void> main(List<String> args) async {
  final service = WorkspaceFileService(directory: Directory(args[0]), beforeCommit: () async {
    stdout.writeln('locked');
    await Future<void>.delayed(Duration(milliseconds: int.parse(args[1])));
  });
  try {
    await service.write(Workspace(revision: int.parse(args[2]), projects: [QaProject(id: 'project', name: 'Saved')]));
    stdout.writeln('saved');
  } catch (_) { exitCode = 2; }
}
