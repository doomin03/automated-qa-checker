import { Configuration, PlatformApi, WorkflowApi, SuiteApi, SchedulerApi, ApiErrorResponseFromJSON, type EventsResponse, type RunResponse, type WorkInput, type SuiteDraftInput, type ExecutionInput, type ScheduleInput, type OperatorRecoveryInput } from './generated/index.js';
import { responseOperations } from './generated/contract-schema.js';
import { apiOrigin, ApiFailure, TransportFailure } from './health-client.js';
import { validateModel, ContractFailure } from './schema-validation.js';
import type { DraftInput, RunInput, ArtifactInput } from './generated/index.js';
export type RequestOptions = { signal?: AbortSignal };
export type Pagination = { limit?: number; cursor?: string };
export type ClientOptions = { timeoutMs?: number; fetch?: typeof fetch; session?: boolean; csrfToken?: string };

export function responseSchema(method: string, pathname: string): string {
  const actual = pathname.split('/');
  const operation = responseOperations.find(op => op.method === method.toUpperCase() && op.path.split('/').length === actual.length && op.path.split('/').every((part, i) => part.startsWith('{') || part === actual[i]));
  if (!operation?.schema) throw new ContractFailure('No generated response contract for operation');
  return operation.schema;
}

export class JsonTransport {
  private readonly lifetime = new AbortController();
  readonly configuration: Configuration;
  constructor(origin: string, token: string, options: ClientOptions = {}) {
    if ((!token && !options.session) || /\s/.test(token)) throw new TypeError('A bearer token or explicit cookie session is required');
    const timeout = options.timeoutMs ?? 30000;
    if (!Number.isFinite(timeout) || timeout <= 0) throw new TypeError('timeoutMs must be positive');
    this.configuration = new Configuration({ basePath: apiOrigin(origin), ...(token ? { accessToken: token } : {}), fetchApi: async (url, init) => {
      const timerController = new AbortController();
      const timer = setTimeout(() => timerController.abort(), timeout);
      const signal = AbortSignal.any([timerController.signal, this.lifetime.signal, ...(init?.signal ? [init.signal] : [])]);
      let body: string; let response: Response;
      const headers = new Headers(init?.headers);
      if (token) headers.set('Authorization', `Bearer ${token}`);
      if (options.session && !['GET', 'HEAD', 'OPTIONS'].includes((init?.method ?? 'GET').toUpperCase()) && options.csrfToken) headers.set('X-CSRF-Token', options.csrfToken);
      try { response = await (options.fetch ?? globalThis.fetch)(url, { ...init, headers, signal, ...(options.session ? { credentials: 'include' } : {}) }); body = await response.text(); }
      catch (error) { throw new TransportFailure(this.lifetime.signal.aborted || init?.signal?.aborted ? 'cancelled' : timerController.signal.aborted ? 'timeout' : 'connection', error); }
      finally { clearTimeout(timer); }
      let json: unknown; try { json = JSON.parse(body); } catch { throw new ContractFailure('Platform response was not JSON'); }
      if (!response.ok) { validateModel('ApiErrorResponse', json); throw new ApiFailure(response.status, ApiErrorResponseFromJSON(json)); }
      validateModel(responseSchema(init?.method ?? 'GET', new URL(String(url)).pathname), json);
      return new Response(body, { status: response.status, headers: response.headers });
    } });
  }
  close(): void { this.lifetime.abort(); }
}

export class PlatformClient {
  private readonly api: PlatformApi;
  private readonly workflow: WorkflowApi;
  private readonly suiteApi: SuiteApi;
  private readonly scheduler: SchedulerApi;
  private readonly transport: JsonTransport;
  constructor(origin: string, token: string, options: ClientOptions = {}) {
    this.transport = new JsonTransport(origin, token, options);
    this.api = new PlatformApi(this.transport.configuration);
    this.workflow = new WorkflowApi(this.transport.configuration);
    this.suiteApi = new SuiteApi(this.transport.configuration);
    this.scheduler = new SchedulerApi(this.transport.configuration);
  }
  async call<T>(action: (api: PlatformApi, signal?: AbortSignal) => Promise<T>, options: { signal?: AbortSignal } = {}): Promise<T> {
    try { return await action(this.api, options.signal); }
    catch (error) {
      if (error instanceof ApiFailure || error instanceof TransportFailure || error instanceof ContractFailure) throw error;
      if (error instanceof Error && (error.cause instanceof ApiFailure || error.cause instanceof TransportFailure || error.cause instanceof ContractFailure)) throw error.cause;
      throw new ContractFailure('Platform response could not be decoded', { cause: error });
    }
  }
  close(): void { this.transport.close(); }
  me(options: RequestOptions = {}) { return this.call(api => api.getIdentity(options)); }
  projects(query: Pagination = {}, options: RequestOptions = {}) { return this.call(api => api.listProjects(query, options)); }
  createDraft(projectId: string, draftInput: DraftInput, options: RequestOptions = {}) { return this.call(api => api.createRegistryDraft({ projectId, draftInput }, options)); }
  drafts(projectId: string, query: Pagination = {}, options: RequestOptions = {}) { return this.call(api => api.listRegistryDrafts({ projectId, ...query }, options)); }
  reviewDraft(projectId: string, draftId: string, options: RequestOptions = {}) { return this.call(api => api.reviewRegistryDraft({ projectId, draftId }, options)); }
  publishDraft(projectId: string, draftId: string, version: string, idempotencyKey: string, options: RequestOptions = {}) { return this.call(api => api.publishRegistryDraft({ projectId, draftId, publishInput: { version }, idempotencyKey }, options)); }
  versions(projectId: string, query: Pagination & { packageId?: string } = {}, options: RequestOptions = {}) { return this.call(api => api.listRegistryVersions({ projectId, ...query }, options)); }
  version(projectId: string, versionId: string, options: RequestOptions = {}) { return this.call(api => api.getRegistryVersion({ projectId, versionId }, options)); }
  pins(projectId: string, query: Pagination = {}, options: RequestOptions = {}) { return this.call(api => api.listRegistryPins({ projectId, ...query }, options)); }
  pin(projectId: string, versionId: string, sha256: string, options: RequestOptions = {}) { return this.call(api => api.pinRegistryVersion({ projectId, pinInput: { versionId, sha256 } }, options)); }
  upgradeDiff(projectId: string, fromVersionId: string, toVersionId: string, options: RequestOptions = {}) { return this.call(api => api.getRegistryUpgradeDiff({ projectId, fromVersionId, toVersionId }, options)); }
  createRun(projectId: string, runInput: RunInput, idempotencyKey: string, options: RequestOptions = {}) { return this.call(api => api.createSharedRun({ projectId, runInput, idempotencyKey }, options)); }
  runs(projectId: string, query: Pagination = {}, options: RequestOptions = {}) { return this.call(api => api.listSharedRuns({ projectId, ...query }, options)); }
  run(projectId: string, runId: string, options: RequestOptions = {}) { return this.call(api => api.getSharedRun({ projectId, runId }, options)); }
  events(projectId: string, runId: string, query: { afterSequence?: number; limit?: number } = {}, options: RequestOptions = {}) { return this.call(api => api.pollRunEvents({ projectId, runId, ...query }, options)); }
  appendEvents(projectId: string, runId: string, eventsJson: string[], options: RequestOptions = {}) { return this.call(api => api.appendRunEvents({ projectId, runId, eventBatchInput: { eventsJson } }, options)); }
  result(projectId: string, runId: string, resultJson: string, options: RequestOptions = {}) { return this.call(api => api.putRunResult({ projectId, runId, resultInput: { resultJson } }, options)); }
  uploadArtifact(projectId: string, runId: string, artifactInput: ArtifactInput, options: RequestOptions = {}) { return this.call(api => api.uploadRunArtifact({ projectId, runId, artifactInput }, options)); }
  downloadArtifact(projectId: string, runId: string, artifactId: string, options: RequestOptions = {}) { return this.call(api => api.downloadRunArtifact({ projectId, runId, artifactId }, options)); }
  audit(projectId: string, query: Pagination = {}, options: RequestOptions = {}) { return this.call(api => api.listProjectAudit({ projectId, ...query }, options)); }
  work(projectId: string, runId: string, options: RequestOptions = {}) { return this.call(() => this.workflow.getRunWork({ projectId, runId }, options)); }
  updateWork(projectId: string, runId: string, workInput: WorkInput, options: RequestOptions = {}) { return this.call(() => this.workflow.updateRunWork({ projectId, runId, workInput }, options)); }
  compare(projectId: string, runId: string, options: RequestOptions = {}) { return this.call(() => this.workflow.getRunComparison({ projectId, runId }, options)); }
  selectBaseline(projectId: string, runId: string, baselineRunId: string, options: RequestOptions = {}) { return this.call(() => this.workflow.selectRunBaseline({ projectId, runId, baselineInput: { baselineRunId } }, options)); }
  notifications(projectId: string, runId: string, options: RequestOptions = {}) { return this.call(() => this.workflow.listRunNotifications({ projectId, runId }, options)); }
  enqueueNotification(projectId: string, runId: string, options: RequestOptions = {}) { return this.call(() => this.workflow.enqueueRunNotification({ projectId, runId }, options)); }
  createSuiteDraft(projectId: string, suiteDraftInput: SuiteDraftInput, options: RequestOptions = {}) { return this.call(() => this.suiteApi.createSuiteDraft({ projectId, suiteDraftInput }, options)); }
  suiteDrafts(projectId: string, query: Pagination = {}, options: RequestOptions = {}) { return this.call(() => this.suiteApi.listSuiteDrafts({ projectId, ...query }, options)); }
  reviewSuiteDraft(projectId: string, draftId: string, options: RequestOptions = {}) { return this.call(() => this.suiteApi.reviewSuiteDraft({ projectId, draftId }, options)); }
  publishSuiteDraft(projectId: string, draftId: string, version: string, idempotencyKey: string, options: RequestOptions = {}) { return this.call(() => this.suiteApi.publishSuiteDraft({ projectId, draftId, publishInput: { version }, idempotencyKey }, options)); }
  suites(projectId: string, query: Pagination & {packageId?:string} = {}, options: RequestOptions = {}) { return this.call(() => this.suiteApi.listSuites({ projectId, ...query }, options)); }
  suite(projectId: string, versionId: string, options: RequestOptions = {}) { return this.call(() => this.suiteApi.getSuite({ projectId, versionId }, options)); }
  pinSuite(projectId: string, versionId: string, sha256: string, options: RequestOptions = {}) { return this.call(() => this.suiteApi.pinSuite({ projectId, pinInput: {versionId,sha256} }, options)); }
  createExecution(projectId: string, executionInput: ExecutionInput, options: RequestOptions = {}) { return this.call(() => this.scheduler.createExecution({ projectId, executionInput }, options)); }
  executions(projectId: string, query: Pagination = {}, options: RequestOptions = {}) { return this.call(() => this.scheduler.listExecutions({ projectId, ...query }, options)); }
  execution(projectId: string, executionId: string, options: RequestOptions = {}) { return this.call(() => this.scheduler.getExecution({ projectId, executionId }, options)); }
  cancelExecution(projectId: string, executionId: string, options: RequestOptions = {}) { return this.call(() => this.scheduler.cancelExecution({ projectId, executionId }, options)); }
  recoverExecution(projectId: string, executionId: string, operatorRecoveryInput: OperatorRecoveryInput, options: RequestOptions = {}) { return this.call(() => this.scheduler.recoverExecution({ projectId, executionId, operatorRecoveryInput }, options)); }
  createSchedule(projectId: string, scheduleInput: ScheduleInput, options: RequestOptions = {}) { return this.call(() => this.scheduler.createSchedule({ projectId, scheduleInput }, options)); }
  schedules(projectId: string, query: Pagination = {}, options: RequestOptions = {}) { return this.call(() => this.scheduler.listSchedules({ projectId, ...query }, options)); }
  setScheduleEnabled(projectId: string, scheduleId: string, enabled: boolean, options: RequestOptions = {}) { return this.call(() => this.scheduler.setScheduleEnabled({ projectId, scheduleId, scheduleEnabledInput: { enabled } }, options)); }
  occurrences(projectId: string, scheduleId: string, query: Pagination = {}, options: RequestOptions = {}) { return this.call(() => this.scheduler.listScheduleOccurrences({ projectId, scheduleId, ...query }, options)); }
}

function decodeObject(json: string): Record<string, unknown> {
  let value: unknown; try { value = JSON.parse(json); } catch { throw new ContractFailure('Engine envelope is not JSON'); }
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new ContractFailure('Engine envelope is not an object');
  return value as Record<string, unknown>;
}
export const decodeEngineEvents = (response: EventsResponse): Record<string, unknown>[] => response.eventsJson.map(decodeObject);
export const decodeEngineResult = (response: RunResponse): Record<string, unknown> | null => response.resultJson === null ? null : decodeObject(response.resultJson);
