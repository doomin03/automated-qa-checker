import '../workbench/view_models/workbench_view_model.dart';
import '../workbench/view_models/project_home_view_model.dart';
import '../../features/shared_scenarios/services/qa_receipt_file_service.dart';
import '../../features/shared_scenarios/repositories/qa_receipt_repository.dart';
import '../workbench/view_models/xml_block_workbench_view_model.dart';
import '../../features/xml_blocks/repositories/xml_block_repository.dart';
import '../workbench/view_models/document_template_view_model.dart';
import '../workbench/view_models/terminal_workbench_view_model.dart';
import '../workbench/view_models/canvas_layout_view_model.dart';
import '../../features/scenario_editor/repositories/canvas_layout_repository.dart';
import '../../features/interactive_terminal/services/terminal_service.dart';
import '../../features/interactive_terminal/services/terminal_profile_service.dart';
import '../../features/interactive_terminal/repositories/terminal_preferences_repository.dart';
import '../../features/interactive_terminal/view_models/terminal_readiness_view_model.dart';
import '../../features/interactive_terminal/repositories/live_document_repository.dart';
import '../workbench/view_models/desktop_workspace_view_model.dart';
import '../../features/project_workspace/services/workspace_file_service.dart';
import '../../features/project_workspace/services/desktop_defaults_service.dart';
import '../../features/project_workspace/repositories/workspace_repository.dart';
import '../../features/project_workspace/view_models/workspace_view_model.dart';
import '../../features/ai_authoring/services/ai_cli_service.dart';
import '../../features/ai_authoring/repositories/ai_repository.dart';
import '../../features/ai_authoring/view_models/ai_authoring_view_model.dart';
import '../../features/run_review/view_models/engine_settings_view_model.dart';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../features/scenario_editor/repositories/scenario_repository.dart';
import '../../features/scenario_editor/services/scenario_file_service.dart';
import '../../features/scenario_editor/services/scenario_file_picker.dart';
import '../../features/scenario_editor/view_models/scenario_editor_view_model.dart';
import '../../features/run_review/services/engine_cli_service.dart';
import '../../features/run_review/services/portable_runtime_service.dart';
import '../../features/run_review/repositories/engine_repository.dart';
import '../../features/run_review/view_models/run_view_model.dart';
import '../../features/scenario_editor/repositories/blueprint_catalog.dart';
import '../../features/scenario_editor/view_models/flow_editor_view_model.dart';
import '../../features/server_connection/repositories/server_repository.dart';
import '../../features/server_connection/view_models/server_view_model.dart';
import '../../features/design_baselines/services/reference_file_service.dart';
import '../../features/design_baselines/repositories/reference_repository.dart';
import '../../features/design_baselines/view_models/design_view_model.dart';
import '../../features/shared_scenarios/services/shared_file_service.dart';
import '../../features/shared_scenarios/repositories/shared_repository.dart';
import '../../features/shared_scenarios/view_models/shared_view_model.dart';
import '../../features/organization_login/services/organization_service.dart';
import '../../features/organization_login/repositories/organization_repository.dart';
import '../../features/organization_login/view_models/organization_view_model.dart';

/// Dependencies are fixed for this provider scope. Use a new key/scope to
/// replace injections. Passed instances are borrowed; factories are owned.
class AppProviders extends StatelessWidget {
  const AppProviders({
    required this.child,
    this.repository,
    this.engineService,
    this.engineServiceFactory,
    this.blueprintCatalog,
    this.organizationService,
    this.workspaceFileService,
    this.desktopDefaultsService,
    this.portableRuntime,
    this.aiService,
    this.terminalService,
    this.terminalServiceFactory,
    this.liveDocuments,
    this.filePicker,
    super.key,
  }) : assert(engineService == null || engineServiceFactory == null);
  final Widget child;
  final ScenarioRepository? repository;
  final EngineCliService? engineService;
  final EngineCliService Function()? engineServiceFactory;
  final BlueprintCatalog? blueprintCatalog;
  final OrganizationService? organizationService;
  final WorkspaceFileService? workspaceFileService;
  final DesktopDefaultsService? desktopDefaultsService;
  final PortableRuntimeService? portableRuntime;
  final AiCliService? aiService;
  final TerminalService? terminalService;
  final TerminalService Function()? terminalServiceFactory;
  final LiveDocumentRepository? liveDocuments;
  final ScenarioFilePicker? filePicker;
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider(create: (_) => portableRuntime ?? PortableRuntimeService()),
      Provider<ScenarioFilePicker>(
        create: (_) => filePicker ?? NativeScenarioFilePicker(),
      ),
      Provider<OrganizationService>(
        create: (_) => organizationService ?? OrganizationService(),
        dispose: (_, value) {
          if (organizationService == null) value.dispose();
        },
      ),
      Provider(
        create: (context) =>
            OrganizationRepository(context.read<OrganizationService>()),
        dispose: (_, value) => value.dispose(),
      ),
      ChangeNotifierProvider(
        create: (context) =>
            OrganizationViewModel(context.read<OrganizationRepository>()),
      ),
      Provider<ServerRepository>(
        create: (_) => ServerRepository(),
        dispose: (_, value) => value.dispose(),
      ),
      ChangeNotifierProvider(
        create: (context) => ServerViewModel(context.read<ServerRepository>()),
      ),
      Provider<BlueprintCatalog>(
        create: (_) => blueprintCatalog ?? BlueprintCatalog(),
      ),
      ChangeNotifierProvider(
        create: (context) =>
            FlowEditorViewModel(context.read<BlueprintCatalog>())..initialize(),
      ),
      Provider<EngineCliService>(
        create: (context) =>
            engineService ??
            engineServiceFactory?.call() ??
            LocalEngineCliService(
              portableRuntime: context.read<PortableRuntimeService>(),
            ),
        dispose: (_, value) {
          if (engineService == null) value.dispose();
        },
      ),
      Provider<EngineRepository>(
        create: (context) => EngineRepository(context.read<EngineCliService>()),
      ),
      ChangeNotifierProvider(
        create: (context) => RunViewModel(context.read<EngineRepository>()),
      ),
      Provider(create: (_) => ReferenceFileService()),
      Provider(create: (_) => SharedFileService()),
      Provider(
        create: (context) =>
            SharedRepository(context.read<SharedFileService>()),
        dispose: (_, value) => value.dispose(),
      ),
      ChangeNotifierProvider(
        create: (context) => SharedViewModel(
          context.read<SharedRepository>(),
          context.read<RunViewModel>(),
          loadLocalRuntime: context.read<BlueprintCatalog>().runtime,
        ),
      ),
      Provider(
        create: (context) =>
            ReferenceRepository(context.read<ReferenceFileService>()),
      ),
      ChangeNotifierProvider(
        create: (context) => DesignViewModel(
          context.read<ReferenceRepository>(),
          context.read<EngineRepository>(),
        ),
      ),
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
      ChangeNotifierProvider(create: (_) => EngineSettingsViewModel()),
      ChangeNotifierProvider(
        create: (context) => WorkbenchViewModel(
          editor: context.read<ScenarioEditorViewModel>(),
          settings: context.read<EngineSettingsViewModel>(),
          run: context.read<RunViewModel>(),
          design: context.read<DesignViewModel>(),
          flow: context.read<FlowEditorViewModel>(),
          shared: context.read<SharedViewModel>(),
          auth: context.read<OrganizationViewModel>(),
        ),
      ),
      Provider(create: (_) => workspaceFileService ?? WorkspaceFileService()),
      Provider(
        create: (context) =>
            desktopDefaultsService ??
            DesktopDefaultsService(
              portableRuntime: context.read<PortableRuntimeService>(),
            ),
      ),
      Provider(
        create: (context) =>
            WorkspaceRepository(context.read<WorkspaceFileService>()),
      ),
      ChangeNotifierProvider(
        create: (context) =>
            WorkspaceViewModel(context.read<WorkspaceRepository>()),
      ),
      Provider<AiCliService>(
        create: (_) => aiService ?? LocalAiCliService(),
        dispose: (_, value) {
          if (aiService == null) value.dispose();
        },
      ),
      Provider(create: (context) => AiRepository(context.read<AiCliService>())),
      ChangeNotifierProvider(
        create: (context) => AiAuthoringViewModel(
          context.read<AiRepository>(),
          context.read<EngineRepository>(),
        ),
      ),
      ChangeNotifierProvider(
        create: (context) => DesktopWorkspaceViewModel(
          context.read<WorkspaceViewModel>(),
          context.read<WorkbenchViewModel>(),
          context.read<AiAuthoringViewModel>(),
          context.read<BlueprintCatalog>(),
          context.read<DesktopDefaultsService>(),
        ),
      ),
      Provider(
        create: (_) => terminalService ?? TerminalService(),
        dispose: (_, value) {
          if (terminalService == null) value.dispose();
        },
      ),
      Provider(
        create: (context) => QaReceiptRepository(
          QaReceiptFileService(context.read<WorkspaceRepository>().directory),
        ),
      ),
      ChangeNotifierProvider(
        create: (context) => ProjectHomeViewModel(
          context.read<DesktopWorkspaceViewModel>(),
          context.read<SharedViewModel>(),
          context.read<OrganizationViewModel>(),
          context.read<QaReceiptRepository>(),
          XmlBlockRepository(),
        ),
      ),
      ChangeNotifierProvider(
        create: (context) => XmlBlockWorkbenchViewModel(
          context.read<DesktopWorkspaceViewModel>(),
          LocalEngineCliService(
            portableRuntime: context.read<PortableRuntimeService>(),
          ),
          context.read<ScenarioFileService>(),
          XmlBlockRepository(),
          context.read<ScenarioFilePicker>(),
        ),
      ),
      Provider(create: (_) => CanvasLayoutRepository()),
      ChangeNotifierProvider(
        create: (context) => CanvasLayoutViewModel(
          context.read<DesktopWorkspaceViewModel>(),
          context.read<CanvasLayoutRepository>(),
        ),
      ),
      Provider(
        create: (context) =>
            liveDocuments ??
            LiveDocumentRepository(
              LocalEngineCliService(
                portableRuntime: context.read<PortableRuntimeService>(),
              ),
            ),
        dispose: (_, value) {
          if (liveDocuments == null) value.dispose();
        },
      ),
      ChangeNotifierProvider(
        create: (context) => TerminalWorkbenchViewModel(
          context.read<DesktopWorkspaceViewModel>(),
          context.read<TerminalService>(),
          context.read<LiveDocumentRepository>(),
          serviceFactory: terminalServiceFactory,
          composition: context.read<XmlBlockWorkbenchViewModel>(),
        ),
      ),
      Provider(create: (_) => TerminalProfileService()),
      Provider(
        create: (context) => TerminalPreferencesRepository(
          context.read<WorkspaceRepository>().directory,
        ),
      ),
      ChangeNotifierProvider(
        create: (context) => TerminalReadinessViewModel(
          context.read<TerminalProfileService>(),
          context.read<TerminalPreferencesRepository>(),
        ),
      ),
      Provider<EngineDocumentAuthoring>(
        create: (context) => LocalEngineCliService(
          portableRuntime: context.read<PortableRuntimeService>(),
        ),
        dispose: (_, value) => (value as EngineCliService).dispose(),
      ),
      ChangeNotifierProvider(
        create: (context) => DocumentTemplateViewModel(
          context.read<DesktopWorkspaceViewModel>(),
          context.read<EngineDocumentAuthoring>() as EngineCliService,
        ),
      ),
    ],
    child: child,
  );
}
