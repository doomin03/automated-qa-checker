import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_client_dart.dart';
import 'health_client.dart';
import 'src/contract_schema.dart';
export 'api_client_dart.dart';
export 'health_client.dart' show ApiFailure, ContractFailure, TransportFailure;

class PlatformClient {
  final Dio _dio;
  final CancelToken _lifetime = CancelToken();
  late final PlatformApi _api;
  late final WorkflowApi _workflow;
  late final SuiteApi _suites;
  late final SchedulerApi _scheduler;
  PlatformClient(
    String origin,
    String token, {
    Duration timeout = const Duration(seconds: 30),
    HttpClientAdapter? adapter,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: apiOrigin(origin),
           connectTimeout: timeout,
           receiveTimeout: timeout,
           sendTimeout: timeout,
           headers: {'Authorization': 'Bearer $token'},
         ),
       ) {
    if (token.isEmpty || RegExp(r'\s').hasMatch(token))
      throw ArgumentError('A local bearer token is required');
    if (timeout <= Duration.zero)
      throw ArgumentError('timeout must be positive');
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          try {
            final path = Uri.parse(response.requestOptions.path).path
                .split('/');
            final operation = responseOperations
                .cast<Map<String, dynamic>>()
                .where((op) {
                  final template = (op['path'] as String).split('/');
                  return op['method'] ==
                          response.requestOptions.method.toUpperCase() &&
                      template.length == path.length &&
                      List.generate(
                        template.length,
                        (i) =>
                            template[i].startsWith('{') ||
                            template[i] == path[i],
                      ).every((match) => match);
                })
                .firstOrNull;
            if (operation == null || operation['schema'] is! String)
              throw ContractFailure(
                'No generated response contract for operation',
              );
            validateModel(operation['schema'] as String, response.data);
            handler.next(response);
          } catch (error) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                error: error,
              ),
            );
          }
        },
      ),
    );
    _api = PlatformApi(_dio);
    _workflow = WorkflowApi(_dio);
    _suites = SuiteApi(_dio);
    _scheduler = SchedulerApi(_dio);
  }
  Future<T> call<T>(
    Future<Response<T>> Function(PlatformApi api, CancelToken cancelToken)
    action,
  ) async {
    try {
      final response = await action(_api, _lifetime);
      return response.data ??
          (throw ContractFailure('Empty platform response'));
    } on DioException catch (error) {
      if (error.error is ContractFailure) throw error.error!;
      final response = error.response;
      if (response != null &&
          response.statusCode != null &&
          response.statusCode! >= 400) {
        validateModel('ApiErrorResponse', response.data);
        throw ApiFailure(
          response.statusCode!,
          ApiErrorResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        );
      }
      if (response != null)
        throw ContractFailure('Platform response could not be decoded');
      throw TransportFailure(
        error.type == DioExceptionType.cancel
            ? 'cancelled'
            : [
                DioExceptionType.connectionTimeout,
                DioExceptionType.receiveTimeout,
                DioExceptionType.sendTimeout,
              ].contains(error.type)
            ? 'timeout'
            : 'connection',
      );
    }
  }

  void close() {
    _lifetime.cancel('Client disposed');
    _dio.close(force: true);
  }

  Future<WorkResponse> work(String projectId, String runId) => call(
    (_, cancel) => _workflow.getRunWork(
      projectId: projectId,
      runId: runId,
      cancelToken: cancel,
    ),
  );
  Future<WorkResponse> updateWork(
    String projectId,
    String runId,
    WorkInput input,
  ) => call(
    (_, cancel) => _workflow.updateRunWork(
      projectId: projectId,
      runId: runId,
      workInput: input,
      cancelToken: cancel,
    ),
  );
  Future<ComparisonResponse> compare(String projectId, String runId) => call(
    (_, cancel) => _workflow.getRunComparison(
      projectId: projectId,
      runId: runId,
      cancelToken: cancel,
    ),
  );
  Future<ComparisonResponse> selectBaseline(
    String projectId,
    String runId,
    String baselineRunId,
  ) => call(
    (_, cancel) => _workflow.selectRunBaseline(
      projectId: projectId,
      runId: runId,
      baselineInput: BaselineInput(baselineRunId: baselineRunId),
      cancelToken: cancel,
    ),
  );
  Future<NotificationPage> notifications(String projectId, String runId) =>
      call(
        (_, cancel) => _workflow.listRunNotifications(
          projectId: projectId,
          runId: runId,
          cancelToken: cancel,
        ),
      );
  Future<NotificationResponse> enqueueNotification(
    String projectId,
    String runId,
  ) => call(
    (_, cancel) => _workflow.enqueueRunNotification(
      projectId: projectId,
      runId: runId,
      cancelToken: cancel,
    ),
  );

  Future<IdentityResponse> me() =>
      call((api, cancel) => api.getIdentity(cancelToken: cancel));
  Future<SuiteDraftResponse> createSuiteDraft(
    String projectId,
    SuiteDraftInput input,
  ) => call(
    (_, cancel) => _suites.createSuiteDraft(
      projectId: projectId,
      suiteDraftInput: input,
      cancelToken: cancel,
    ),
  );
  Future<SuiteDraftPage> suiteDrafts(
    String projectId, {
    int? limit,
    String? cursor,
  }) => call(
    (_, cancel) => _suites.listSuiteDrafts(
      projectId: projectId,
      limit: limit,
      cursor: cursor,
      cancelToken: cancel,
    ),
  );
  Future<SuiteDraftResponse> reviewSuiteDraft(
    String projectId,
    String draftId,
  ) => call(
    (_, cancel) => _suites.reviewSuiteDraft(
      projectId: projectId,
      draftId: draftId,
      cancelToken: cancel,
    ),
  );
  Future<SuiteResponse> publishSuiteDraft(
    String projectId,
    String draftId,
    String version,
    String idempotencyKey,
  ) => call(
    (_, cancel) => _suites.publishSuiteDraft(
      projectId: projectId,
      draftId: draftId,
      publishInput: PublishInput(version: version),
      idempotencyKey: idempotencyKey,
      cancelToken: cancel,
    ),
  );
  Future<SuitePage> suites(
    String projectId, {
    String? packageId,
    int? limit,
    String? cursor,
  }) => call(
    (_, cancel) => _suites.listSuites(
      projectId: projectId,
      packageId: packageId,
      limit: limit,
      cursor: cursor,
      cancelToken: cancel,
    ),
  );
  Future<SuiteResponse> suite(String projectId, String versionId) => call(
    (_, cancel) => _suites.getSuite(
      projectId: projectId,
      versionId: versionId,
      cancelToken: cancel,
    ),
  );
  Future<PinResponse> pinSuite(
    String projectId,
    String versionId,
    String sha256,
  ) => call(
    (_, cancel) => _suites.pinSuite(
      projectId: projectId,
      pinInput: PinInput(versionId: versionId, sha256: sha256),
      cancelToken: cancel,
    ),
  );
  Future<ExecutionResponse> createExecution(
    String projectId,
    ExecutionInput input,
  ) => call(
    (_, cancel) => _scheduler.createExecution(
      projectId: projectId,
      executionInput: input,
      cancelToken: cancel,
    ),
  );
  Future<ExecutionPage> executions(
    String projectId, {
    int? limit,
    String? cursor,
  }) => call(
    (_, cancel) => _scheduler.listExecutions(
      projectId: projectId,
      limit: limit,
      cursor: cursor,
      cancelToken: cancel,
    ),
  );
  Future<ExecutionResponse> execution(String projectId, String executionId) =>
      call(
        (_, cancel) => _scheduler.getExecution(
          projectId: projectId,
          executionId: executionId,
          cancelToken: cancel,
        ),
      );
  Future<ExecutionResponse> cancelExecution(
    String projectId,
    String executionId,
  ) => call(
    (_, cancel) => _scheduler.cancelExecution(
      projectId: projectId,
      executionId: executionId,
      cancelToken: cancel,
    ),
  );
  Future<OperatorRecoveryResponse> recoverExecution(
    String projectId,
    String executionId,
    OperatorRecoveryInput input,
  ) => call(
    (_, cancel) => _scheduler.recoverExecution(
      projectId: projectId,
      executionId: executionId,
      operatorRecoveryInput: input,
      cancelToken: cancel,
    ),
  );
  Future<ScheduleResponse> createSchedule(
    String projectId,
    ScheduleInput input,
  ) => call(
    (_, cancel) => _scheduler.createSchedule(
      projectId: projectId,
      scheduleInput: input,
      cancelToken: cancel,
    ),
  );
  Future<SchedulePage> schedules(
    String projectId, {
    int? limit,
    String? cursor,
  }) => call(
    (_, cancel) => _scheduler.listSchedules(
      projectId: projectId,
      limit: limit,
      cursor: cursor,
      cancelToken: cancel,
    ),
  );
  Future<ScheduleResponse> setScheduleEnabled(
    String projectId,
    String scheduleId,
    bool enabled,
  ) => call(
    (_, cancel) => _scheduler.setScheduleEnabled(
      projectId: projectId,
      scheduleId: scheduleId,
      scheduleEnabledInput: ScheduleEnabledInput(enabled: enabled),
      cancelToken: cancel,
    ),
  );
  Future<ScheduleOccurrencePage> occurrences(
    String projectId,
    String scheduleId, {
    int? limit,
    String? cursor,
  }) => call(
    (_, cancel) => _scheduler.listScheduleOccurrences(
      projectId: projectId,
      scheduleId: scheduleId,
      limit: limit,
      cursor: cursor,
      cancelToken: cancel,
    ),
  );
  Future<ProjectPage> projects({int? limit, String? cursor}) => call(
    (api, cancel) =>
        api.listProjects(limit: limit, cursor: cursor, cancelToken: cancel),
  );
  Future<DraftResponse> createDraft(String projectId, DraftInput input) => call(
    (api, cancel) => api.createRegistryDraft(
      projectId: projectId,
      draftInput: input,
      cancelToken: cancel,
    ),
  );
  Future<DraftPage> drafts(String projectId, {int? limit, String? cursor}) =>
      call(
        (api, cancel) => api.listRegistryDrafts(
          projectId: projectId,
          limit: limit,
          cursor: cursor,
          cancelToken: cancel,
        ),
      );
  Future<DraftResponse> reviewDraft(String projectId, String draftId) => call(
    (api, cancel) => api.reviewRegistryDraft(
      projectId: projectId,
      draftId: draftId,
      cancelToken: cancel,
    ),
  );
  Future<VersionResponse> publishDraft(
    String projectId,
    String draftId,
    String version,
    String idempotencyKey,
  ) => call(
    (api, cancel) => api.publishRegistryDraft(
      projectId: projectId,
      draftId: draftId,
      publishInput: PublishInput(version: version),
      idempotencyKey: idempotencyKey,
      cancelToken: cancel,
    ),
  );
  Future<VersionPage> versions(
    String projectId, {
    String? packageId,
    int? limit,
    String? cursor,
  }) => call(
    (api, cancel) => api.listRegistryVersions(
      projectId: projectId,
      packageId: packageId,
      limit: limit,
      cursor: cursor,
      cancelToken: cancel,
    ),
  );
  Future<VersionResponse> version(String projectId, String versionId) => call(
    (api, cancel) => api.getRegistryVersion(
      projectId: projectId,
      versionId: versionId,
      cancelToken: cancel,
    ),
  );
  Future<PinPage> pins(String projectId, {int? limit, String? cursor}) => call(
    (api, cancel) => api.listRegistryPins(
      projectId: projectId,
      limit: limit,
      cursor: cursor,
      cancelToken: cancel,
    ),
  );
  Future<PinResponse> pin(String projectId, String versionId, String sha256) =>
      call(
        (api, cancel) => api.pinRegistryVersion(
          projectId: projectId,
          pinInput: PinInput(versionId: versionId, sha256: sha256),
          cancelToken: cancel,
        ),
      );
  Future<UpgradeDiffResponse> upgradeDiff(
    String projectId,
    String fromVersionId,
    String toVersionId,
  ) => call(
    (api, cancel) => api.getRegistryUpgradeDiff(
      projectId: projectId,
      fromVersionId: fromVersionId,
      toVersionId: toVersionId,
      cancelToken: cancel,
    ),
  );
  Future<RunResponse> createRun(
    String projectId,
    RunInput input,
    String idempotencyKey,
  ) => call(
    (api, cancel) => api.createSharedRun(
      projectId: projectId,
      runInput: input,
      idempotencyKey: idempotencyKey,
      cancelToken: cancel,
    ),
  );
  Future<RunPage> runs(String projectId, {int? limit, String? cursor}) => call(
    (api, cancel) => api.listSharedRuns(
      projectId: projectId,
      limit: limit,
      cursor: cursor,
      cancelToken: cancel,
    ),
  );
  Future<RunResponse> run(String projectId, String runId) => call(
    (api, cancel) => api.getSharedRun(
      projectId: projectId,
      runId: runId,
      cancelToken: cancel,
    ),
  );
  Future<EventsResponse> events(
    String projectId,
    String runId, {
    int? afterSequence,
    int? limit,
  }) => call(
    (api, cancel) => api.pollRunEvents(
      projectId: projectId,
      runId: runId,
      afterSequence: afterSequence,
      limit: limit,
      cancelToken: cancel,
    ),
  );
  Future<RunResponse> appendEvents(
    String projectId,
    String runId,
    List<String> eventsJson,
  ) => call(
    (api, cancel) => api.appendRunEvents(
      projectId: projectId,
      runId: runId,
      eventBatchInput: EventBatchInput(eventsJson: eventsJson),
      cancelToken: cancel,
    ),
  );
  Future<RunResponse> result(
    String projectId,
    String runId,
    String resultJson,
  ) => call(
    (api, cancel) => api.putRunResult(
      projectId: projectId,
      runId: runId,
      resultInput: ResultInput(resultJson: resultJson),
      cancelToken: cancel,
    ),
  );
  Future<ArtifactResponse> uploadArtifact(
    String projectId,
    String runId,
    ArtifactInput input,
  ) => call(
    (api, cancel) => api.uploadRunArtifact(
      projectId: projectId,
      runId: runId,
      artifactInput: input,
      cancelToken: cancel,
    ),
  );
  Future<ArtifactDownload> downloadArtifact(
    String projectId,
    String runId,
    String artifactId,
  ) => call(
    (api, cancel) => api.downloadRunArtifact(
      projectId: projectId,
      runId: runId,
      artifactId: artifactId,
      cancelToken: cancel,
    ),
  );
  Future<AuditPage> audit(String projectId, {int? limit, String? cursor}) =>
      call(
        (api, cancel) => api.listProjectAudit(
          projectId: projectId,
          limit: limit,
          cursor: cursor,
          cancelToken: cancel,
        ),
      );
}

Map<String, dynamic> _decode(String source) {
  final Object? value;
  try {
    value = jsonDecode(source);
  } catch (_) {
    throw ContractFailure('Engine envelope is not JSON');
  }
  if (value is! Map<String, dynamic>)
    throw ContractFailure('Engine envelope is not an object');
  return value;
}

List<Map<String, dynamic>> decodeEngineEvents(EventsResponse response) =>
    response.eventsJson.map(_decode).toList(growable: false);
Map<String, dynamic>? decodeEngineResult(RunResponse response) =>
    response.resultJson == null ? null : _decode(response.resultJson!);
