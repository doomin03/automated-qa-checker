import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../features/scenario_editor/repositories/scenario_repository.dart';
import '../../features/scenario_editor/services/scenario_file_service.dart';
import '../../features/scenario_editor/view_models/scenario_editor_view_model.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({required this.child, this.repository, super.key});
  final Widget child;
  final ScenarioRepository? repository;
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<ScenarioFileService>(create: (_) => LocalScenarioFileService()),
      Provider<ScenarioRepository>(
        create: (context) =>
            repository ??
            FileScenarioRepository(context.read<ScenarioFileService>()),
      ),
      ChangeNotifierProvider(
        create: (context) =>
            ScenarioEditorViewModel(context.read<ScenarioRepository>()),
      ),
    ],
    child: child,
  );
}
