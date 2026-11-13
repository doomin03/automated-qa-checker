import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { randomBytes, randomUUID } from 'node:crypto';
import { AgentRepository } from './agent.repository.js';
import { PlatformService } from '../platform/platform.service.js';
import { EngineContractService } from '../platform/engine-contract.service.js';
import { canonical, sha256, type Row } from '../platform/platform.repository.js';
import type * as D from './agent.dto.js';

const protocolVersion = '0.1.0-draft.1';
const conflict = (message: string): never => { throw new ConflictException(message); };
const missing = (): never => { throw new NotFoundException('Agent resource not found'); };
const now = () => new Date().toISOString();
export type PreparedExecution = { projectId: string; policy: D.AgentExecutionPolicyDto; cases: any[]; plans: Record<string, any>; suitePolicy: D.AgentSuitePolicyDto; engineVersion: string; engineContractVersion: string; engineContractSha256: string };

@Injectable()
export class AgentService {
  private enabled = false;
  private readonly deadlines = new Map<string, number>();
  private suiteResolver?: (user: string, projectId: string, versionId: string, sha256?: string) => any;
  registerSuiteResolver(resolver: (user: string, projectId: string, versionId: string, sha256?: string) => any): void { this.suiteResolver = resolver; }
  monotonic: () => number = () => performance.now();
  constructor(private readonly repository: AgentRepository, private readonly platform: PlatformService, private readonly engine: EngineContractService) {}
  private get db() { return this.repository.db; }
  start(recover = true): void { this.repository.migrate(); this.repository.migrateHistory(); this.repository.migrateRecovery(); this.repository.migrateJobPins(); if (recover) this.repository.recoverAfterRestart(); this.enabled = true; }
  cancel(user: string, projectId: string, executionId: string): any {
    this.platform.authorize(user, projectId, 'qa_tester');
    return this.db.transaction(() => {
      const job = this.db.get('SELECT * FROM agent_jobs WHERE id=? AND project_id=?', executionId, projectId) ?? missing();
      if (job.state === 'queued') this.db.exec("UPDATE agent_jobs SET state='cancelled' WHERE id=?", executionId);
      else if (job.state === 'claimed') this.db.exec("UPDATE agent_leases SET cancel_requested=1 WHERE id=? AND state IN ('active','reporting')", job.lease_id);
      this.db.audit(projectId, user, 'agent.execution.cancel.requested', executionId);
      return { executionId, state: job.state === 'queued' ? 'cancelled' : job.state, cancelRequested: job.state === 'claimed' };
    });
  }
  authenticate(header?: string): string {
    if (!this.enabled) throw new ServiceUnavailableException('Agent service is not configured');
    const token = header?.match(/^Bearer ([^\s]{24,256})$/)?.[1];
    const agent = token && this.db.get('SELECT id FROM agents WHERE token_hash=? AND active=1', sha256(token));
    if (!agent) throw new UnauthorizedException('Registered Agent identity required');
    return agent.id;
  }
  private identity(agentId: string, supplied: string): Row {
    if (agentId !== supplied) throw new ForbiddenException('Agent identity mismatch');
    return this.db.get('SELECT * FROM agents WHERE id=? AND active=1', agentId) ?? missing();
  }
  /** Trusted local management boundary. Caller supplies an authenticated organization/local user. */
  provision(user: string, input: { agentId: string; projectIds: string[]; resourceKeys: string[]; capabilities: D.AgentCapabilitySetDto }): { agentId: string; token: string } {
    if (!/^[A-Za-z0-9_.:-]{1,128}$/.test(input.agentId) || !input.projectIds.length || !input.resourceKeys.length) throw new BadRequestException('Agent provisioning scope is required');
    input.projectIds.forEach(project => this.platform.authorize(user, project, 'qa_manager'));
    const token = randomBytes(32).toString('base64url');
    this.db.transaction(() => {
      if (this.db.get('SELECT id FROM agents WHERE id=?', input.agentId)) conflict('Agent is already provisioned');
      this.db.exec('INSERT INTO agents(id,token_hash,active,projects,capabilities,resource_keys,engine_version,contract_version,contract_hash) VALUES(?,?,?,?,?,?,?,?,?)', input.agentId, sha256(token), 1, canonical(input.projectIds), canonical(input.capabilities), canonical(input.resourceKeys), this.engine.version, this.engine.contractVersion, this.engine.contractSha256);
      for (const key of input.resourceKeys) this.db.exec('INSERT OR IGNORE INTO agent_resources(resource_key) VALUES(?)', key);
      input.projectIds.forEach(project => this.db.audit(project, user, 'agent.provisioned', input.agentId));
    });
    return { agentId: input.agentId, token };
  }
  async enqueue(user: string, input: { projectId: string; blueprintJson: string; caseId: string; executionPolicy: D.AgentExecutionPolicyDto; deadlineAt?: string; resources?: Array<{ name: string; bytes: Uint8Array; sha256: string; mimeType: string }> }): Promise<string> {
    this.platform.authorize(user, input.projectId, 'qa_tester');
    const blueprint = this.engine.validate(input.blueprintJson, 'blueprint');
    const resources = input.resources ?? [];
    const extensions: Record<string, string[]> = { 'image/png': ['png'], 'application/json': ['json'], 'font/woff': ['woff'], 'font/woff2': ['woff2'], 'font/ttf': ['ttf'], 'font/otf': ['otf'] };
    for (const resource of resources) if (!extensions[resource.mimeType]?.includes(resource.name.split('.').at(-1)!.toLowerCase())) throw new BadRequestException('Resource MIME and extension mismatch');
    const plan = await this.engine.plan(input.blueprintJson, 'json', resources);
    const policy = input.executionPolicy;
    if (!policy || policy.resourceKey.length > 256 || policy.platform !== blueprint.target.platform || typeof policy.allowProduction !== 'boolean') throw new BadRequestException('Explicit matching execution policy required');
    if ((blueprint.target.allowedOrigins ?? []).some((origin: string) => !policy.allowedOrigins.includes(origin))) throw new ForbiddenException('Blueprint exceeds execution origin scope');
    if (blueprint.target.environment === 'production' && !policy.allowProduction) throw new ForbiddenException('Production execution is not enabled');
    for (const origin of policy.allowedOrigins) { const parsed = new URL(origin); if (!['http:', 'https:'].includes(parsed.protocol) || parsed.origin !== origin) throw new BadRequestException('Execution origins must be exact origins'); }
    if (!/^[A-Za-z0-9_.:-]{1,128}$/.test(input.caseId)) throw new BadRequestException('Invalid case ID');
    if (input.deadlineAt && !Number.isFinite(Date.parse(input.deadlineAt))) throw new BadRequestException('Invalid deadline');
    const id = randomUUID();
    const manifests = resources.map(resource => ({ resourceId: randomUUID(), name: resource.name, sha256: resource.sha256, size: resource.bytes.length, mimeType: resource.mimeType }));
    const cases = [{ caseId: input.caseId, blueprintJson: canonical(plan.blueprint), blueprintSnapshotHash: plan.blueprintSnapshotHash, resources: manifests, publishedVersion: null }];
    if (Buffer.byteLength(canonical(cases)) > 7 * 1024 * 1024 - 16384) throw new BadRequestException('Job exceeds lease byte budget');
    this.db.transaction(() => {
      this.platform.authorize(user, input.projectId, 'qa_tester');
      if (!this.db.get('SELECT resource_key FROM agent_resources WHERE resource_key=?', policy.resourceKey)) conflict('Provision the canonical resource first');
      this.db.exec('INSERT INTO agent_jobs(id,project_id,job_attempt,state,resource_key,policy,cases_json,plans_json,suite_policy,created_at,deadline_at) VALUES(?,?,?,?,?,?,?,?,?,?,?)', id, input.projectId, 1, 'queued', policy.resourceKey, canonical(policy), canonical(cases), canonical({ [input.caseId]: plan }), canonical({ stopOnFailure: true, publishedVersionId: null, publishedSha256: null }), now(), input.deadlineAt ?? null);
      this.db.exec('UPDATE agent_jobs SET engine_version=?,contract_version=?,contract_hash=? WHERE id=?',this.engine.version,this.engine.contractVersion,this.engine.contractSha256,id);
      resources.forEach((resource, index) => { const manifest = manifests[index]; this.db.exec('INSERT INTO agent_resource_bytes VALUES(?,?,?,?,?,?,?,?)', manifest.resourceId, id, input.caseId, manifest.name, manifest.sha256, manifest.size, manifest.mimeType, resource.bytes); });
      this.db.audit(input.projectId, user, 'agent.job.queued', id);
    });
    return id;
  }
  async preparePublished(user: string, projectId: string, input: { versionId: string | null; suiteVersionId: string | null; sha256: string; executionPolicy: D.AgentExecutionPolicyDto }): Promise<PreparedExecution> {
    this.platform.authorize(user, projectId, 'qa_tester');
    if (!!input.versionId === !!input.suiteVersionId) throw new BadRequestException('Select exactly one published Blueprint or Suite version');
    let source: any;
    if (input.suiteVersionId) {
      if (!this.suiteResolver) throw new ServiceUnavailableException('Published Suite service is unavailable');
      source = await this.suiteResolver(user, projectId, input.suiteVersionId, input.sha256);
    } else {
      const version = this.platform.getVersion(user, projectId, input.versionId!);
      if (version.sha256 !== input.sha256 || version.engineVersion !== this.engine.version) conflict('Published Blueprint hash or Engine pin mismatch');
      source = { suitePolicy: { stopOnFailure: true, publishedVersionId: null, publishedSha256: null }, cases: [{ caseId: 'case-1', versionId: version.id, sha256: version.sha256, xml: version.xml }] };
    }
    if (!source.cases.length || source.cases.length > 32 || new Set(source.cases.map((item: any) => item.caseId)).size !== source.cases.length) throw new BadRequestException('Published Suite case count or identity is invalid');
    const plans: Record<string, any> = Object.create(null), cases: any[] = [];
    for (const entry of source.cases) {
      const version = this.platform.getVersion(user, projectId, entry.versionId);
      if (version.sha256 !== entry.sha256 || version.engineVersion !== this.engine.version) conflict('Published Suite child pin mismatch');
      const plan = await this.engine.plan(version.xml);
      const policy = input.executionPolicy, blueprint = plan.blueprint;
      if (policy.platform !== blueprint.target.platform || (blueprint.target.allowedOrigins ?? []).some((origin: string) => !policy.allowedOrigins.includes(origin))) throw new ForbiddenException('Published snapshot exceeds execution scope');
      if (blueprint.target.environment === 'production' && !policy.allowProduction) throw new ForbiddenException('Production execution is not enabled');
      for (const origin of policy.allowedOrigins) { const parsed = new URL(origin); if (!['http:', 'https:'].includes(parsed.protocol) || parsed.origin !== origin) throw new BadRequestException('Execution origin must be exact'); }
      plans[entry.caseId] = plan; cases.push({ caseId: entry.caseId, blueprintJson: canonical(plan.blueprint), blueprintSnapshotHash: plan.blueprintSnapshotHash, resources: [], publishedVersion: { versionId: version.id, sha256: version.sha256 } });
    }
    this.platform.authorize(user, projectId, 'qa_tester');
    if (!this.db.get('SELECT resource_key FROM agent_resources WHERE resource_key=?', input.executionPolicy.resourceKey)) conflict('Provision the canonical resource first');
    if (Buffer.byteLength(canonical(cases)) > 7 * 1024 * 1024 - 16384) throw new BadRequestException('Published execution exceeds lease byte budget');
    return { projectId, policy: input.executionPolicy, plans, cases, suitePolicy: source.suitePolicy, engineVersion:this.engine.version,engineContractVersion:this.engine.contractVersion,engineContractSha256:this.engine.contractSha256 };
  }
  compatible(prepared: PreparedExecution): boolean { return prepared.engineVersion === this.engine.version && prepared.engineContractVersion === this.engine.contractVersion && prepared.engineContractSha256 === this.engine.contractSha256 && Object.values(prepared.plans).every(plan => plan.engineVersion === prepared.engineVersion); }
  /** Local integration fixture only; product clients select independently published versions. */
  async enqueueFixtureCases(user: string, input: { projectId: string; cases: Array<{caseId:string;blueprintJson:string}>; stopOnFailure: boolean; executionPolicy: D.AgentExecutionPolicyDto }): Promise<string> {
    this.platform.authorize(user,input.projectId,'qa_manager');
    if (!Array.isArray(input.cases) || input.cases.length < 1 || input.cases.length > 32 || typeof input.stopOnFailure !== 'boolean' || new Set(input.cases.map(c=>c.caseId)).size !== input.cases.length) throw new BadRequestException('Invalid ordered fixture cases');
    const plans: Record<string,any> = Object.create(null), cases: any[] = [], policy = input.executionPolicy;
    for (const entry of input.cases) {
      if (!/^[A-Za-z0-9_.:-]{1,128}$/.test(entry.caseId)) throw new BadRequestException('Invalid case ID');
      const blueprint = this.engine.validate(entry.blueprintJson,'blueprint');
      if (blueprint.target.platform !== policy.platform || (blueprint.target.allowedOrigins ?? []).some((origin: string)=>!policy.allowedOrigins.includes(origin)) || blueprint.target.environment === 'production' && !policy.allowProduction) throw new ForbiddenException('Fixture exceeds execution policy');
      const plan = await this.engine.plan(entry.blueprintJson,'json');plans[entry.caseId]=plan;
      cases.push({caseId:entry.caseId,blueprintJson:canonical(plan.blueprint),blueprintSnapshotHash:plan.blueprintSnapshotHash,resources:[],publishedVersion:null});
    }
    if (Buffer.byteLength(canonical(cases)) > 7*1024*1024-16384) throw new BadRequestException('Fixture exceeds lease budget');
    return this.db.transaction(()=>{this.platform.authorize(user,input.projectId,'qa_manager');return this.queuePrepared(user,{projectId:input.projectId,policy,cases,plans,suitePolicy:{stopOnFailure:input.stopOnFailure,publishedVersionId:null,publishedSha256:null},engineVersion:this.engine.version,engineContractVersion:this.engine.contractVersion,engineContractSha256:this.engine.contractSha256});});
  }
  /** Called only after authenticated snapshot preparation; safe inside the scheduler transaction. */
  queuePrepared(actor: string, prepared: PreparedExecution, deadlineAt: string | null = null): string {
    if (!this.compatible(prepared)) conflict('Frozen execution Engine pin is incompatible');
    const id = randomUUID();
    this.db.exec('INSERT INTO agent_jobs(id,project_id,job_attempt,state,resource_key,policy,cases_json,plans_json,suite_policy,created_at,deadline_at) VALUES(?,?,?,?,?,?,?,?,?,?,?)', id, prepared.projectId, 1, 'queued', prepared.policy.resourceKey, canonical(prepared.policy), canonical(prepared.cases), canonical(prepared.plans), canonical(prepared.suitePolicy), now(), deadlineAt);
    this.db.exec('UPDATE agent_jobs SET engine_version=?,contract_version=?,contract_hash=? WHERE id=?',prepared.engineVersion,prepared.engineContractVersion,prepared.engineContractSha256,id);
    this.db.audit(prepared.projectId, actor, 'agent.job.queued', id); return id;
  }
  private expire(): void {
    for (const [id, deadline] of this.deadlines) if (deadline <= this.monotonic()) {
      this.db.transaction(() => {
        this.db.exec("UPDATE agent_leases SET state='expired' WHERE id=? AND state IN ('active','reporting')", id);
        this.db.exec("UPDATE agents SET quarantined=1 WHERE id IN (SELECT agent_id FROM agent_leases WHERE id=? AND state='expired')", id);
      }); this.deadlines.delete(id);
    }
  }
  private remaining(row: Row): number { return ['active', 'reporting'].includes(row.state) ? Math.max(0, Math.floor((this.deadlines.get(row.id) ?? 0) - this.monotonic())) : 0; }
  private lease(id: string): any {
    const row = this.db.get('SELECT * FROM agent_leases WHERE id=?', id) ?? missing();
    const job = this.db.get('SELECT * FROM agent_jobs WHERE id=?', row.execution_id)!;
    const agent = this.db.get('SELECT * FROM agents WHERE id=?', row.agent_id)!;
    return { agentId: row.agent_id, instanceId: row.instance_id, leaseId: id, executionId: job.id, projectId: job.project_id, jobAttempt: job.job_attempt, fence: row.fence, resourceKey: job.resource_key, cases: JSON.parse(job.cases_json), engineVersion: job.engine_version, engineContractVersion: job.contract_version, engineContractSha256: job.contract_hash, protocolVersion, state: row.state, validForMs: this.remaining(row), heartbeatIntervalMs: 5000, requestTimeoutMs: 5000, safetyMarginMs: 5000, cancelRequested: !!row.cancel_requested, acceptedThrough: row.accepted_through, executionPolicy: JSON.parse(job.policy), suitePolicy: JSON.parse(job.suite_policy) };
  }
  private held(agentId: string, id: string, input: { agentId: string; instanceId: string; fence: number }, allowClosed = false, expire = true): Row {
    if (expire) this.expire(); const agent = this.identity(agentId, input.agentId);
    const row = this.db.get('SELECT * FROM agent_leases WHERE id=? AND agent_id=?', id, agentId) ?? missing();
    if (row.instance_id !== input.instanceId || row.fence !== input.fence) conflict('Lease owner or fence mismatch');
    if (allowClosed && row.state === 'closed') return row;
    if (agent.owner_instance !== input.instanceId || agent.quarantined || !['active', 'reporting'].includes(row.state) || this.remaining(row) <= 0) conflict('Lease no longer permits execution or live evidence');
    return row;
  }
  claim(agentId: string, input: D.AgentClaimRequestDto): any | null {
    this.expire(); const agent = this.identity(agentId, input.agentId);
    if (input.protocolVersion !== protocolVersion || input.engineVersion !== agent.engine_version || input.engineContractVersion !== agent.contract_version || input.engineContractSha256 !== agent.contract_hash) conflict('Pinned protocol or Engine contract mismatch');
    if (this.db.get("SELECT instance_id FROM agent_instances WHERE agent_id=? AND instance_id=? AND state='retired'", agentId, input.instanceId)) conflict('Instance is permanently retired');
    if (agent.quarantined || (agent.owner_instance && agent.owner_instance !== input.instanceId)) conflict('Agent owner must reconcile and release before another instance can claim');
    const hash = sha256(canonical(input));
    return this.db.transaction(() => {
      const prior = this.db.get('SELECT * FROM agent_claims WHERE agent_id=? AND claim_id=?', agentId, input.claimRequestId);
      if (prior) { if (prior.instance_id !== input.instanceId || prior.hash !== hash) conflict('Claim request identity or payload conflict'); return prior.lease_id ? { claimRequestId: input.claimRequestId, lease: this.lease(prior.lease_id) } : null; }
      if (this.db.get("SELECT id FROM agent_leases WHERE agent_id=? AND state NOT IN ('closed','recovered')", agentId)) conflict('Agent already owns an unresolved lease');
      const registered = JSON.parse(agent.capabilities);
      const projects: string[] = JSON.parse(agent.projects), resources: string[] = JSON.parse(agent.resource_keys);
      const candidates = this.db.all("SELECT j.* FROM agent_jobs j JOIN agent_resources r ON r.resource_key=j.resource_key WHERE j.state='queued' AND r.lease_id IS NULL ORDER BY j.rowid");
      const job = candidates.find(row => {
        if (row.engine_version !== this.engine.version || row.contract_version !== this.engine.contractVersion || row.contract_hash !== this.engine.contractSha256) { this.db.exec("UPDATE agent_jobs SET state='blocked',block_reason='engine_pin_incompatible' WHERE id=?",row.id); return false; }
        if (row.engine_version !== agent.engine_version || row.contract_version !== agent.contract_version || row.contract_hash !== agent.contract_hash) return false;
        if (row.deadline_at && Date.parse(row.deadline_at) <= Date.now()) { this.db.exec("UPDATE agent_jobs SET state='missed' WHERE id=?", row.id); return false; }
        const policy = JSON.parse(row.policy), plans = Object.values(JSON.parse(row.plans_json)) as any[];
        const actions = plans.flatMap(p => p.blueprint.flow.nodes.map((n: any) => n.action).filter(Boolean));
        return projects.includes(row.project_id) && input.projectIds.includes(row.project_id) && resources.includes(row.resource_key) && input.resourceKeys.includes(row.resource_key) && registered.platforms.includes(policy.platform) && input.capabilities.platforms.includes(policy.platform) && actions.every(action => registered.actions.includes(action) && input.capabilities.actions.includes(action));
      });
      this.db.exec('INSERT OR IGNORE INTO agent_instances VALUES(?,?,?,?)', agentId, input.instanceId, 'active', now());
      this.db.exec('UPDATE agents SET owner_instance=? WHERE id=?', input.instanceId, agentId);
      let leaseId: string | null = null;
      if (job) {
        leaseId = randomUUID(); const resource = this.db.get('SELECT * FROM agent_resources WHERE resource_key=?', job.resource_key)!;
        this.db.exec('INSERT INTO agent_leases(id,agent_id,instance_id,execution_id,fence,state,expires_at,created_at) VALUES(?,?,?,?,?,?,?,?)', leaseId, agentId, input.instanceId, job.id, resource.fence + 1, 'active', Date.now() + 30000, now());
        this.db.exec('UPDATE agent_resources SET fence=fence+1,lease_id=? WHERE resource_key=?', leaseId, job.resource_key);
        this.db.exec("UPDATE agent_jobs SET state='claimed',lease_id=? WHERE id=?", leaseId, job.id);
        this.deadlines.set(leaseId, this.monotonic() + 30000);
        this.db.audit(job.project_id, agentId, 'agent.lease.claimed', leaseId);
      }
      this.db.exec('INSERT INTO agent_claims VALUES(?,?,?,?,?)', agentId, input.claimRequestId, input.instanceId, hash, leaseId);
      return leaseId ? { claimRequestId: input.claimRequestId, lease: this.lease(leaseId) } : null;
    });
  }
  heartbeat(agentId: string, id: string, input: D.AgentHeartbeatRequestDto): any {
    const row = this.held(agentId, id, input);
    if (input.lastAcknowledgedSequence > row.accepted_through) conflict('Acknowledgement exceeds server cursor');
    this.deadlines.set(id, this.monotonic() + 30000); this.db.exec('UPDATE agent_leases SET expires_at=? WHERE id=?', Date.now() + 30000, id);
    return { leaseId: id, fence: row.fence, validForMs: this.remaining({ ...row, state: row.state }), cancelRequested: !!row.cancel_requested, state: row.state, acceptedThrough: row.accepted_through };
  }
  reconcile(agentId: string, input: D.AgentReconcileRequestDto, cursor?: string): any {
    this.expire(); const agent = this.identity(agentId, input.agentId);
    let offset = 0;
    if (cursor) { const text = Buffer.from(cursor, 'base64url').toString(); if (!/^[1-9]\d*$/.test(text) || Buffer.from(text).toString('base64url') !== cursor) throw new BadRequestException('Invalid cursor'); offset = Number(text); }
    const known = new Set(input.knownLeases.map(item => item.leaseId));
    const rows = this.db.all('SELECT rowid,* FROM agent_leases WHERE agent_id=? AND rowid>? ORDER BY rowid', agentId, offset).filter(row => row.state !== 'closed' || !row.receipt_acked || known.has(row.id));
    const decisions: any[] = []; let bytes = 1024; let last = offset;
    for (const row of rows) {
      const lease = this.lease(row.id);
      const sameOwner = row.instance_id === input.instanceId && agent.owner_instance === input.instanceId;
      const decision = { lease, directive: ['closed','recovered'].includes(row.state) ? 'observe' : !sameOwner || !['active', 'reporting'].includes(row.state) ? 'quarantine' : row.cancel_requested ? 'cancel' : 'resume', reason: row.state === 'closed' ? 'delivery_closed' : sameOwner ? row.state : 'different_instance_owner', cleanupState: row.cleanup_state, completionReceipt: row.completion_receipt, deliveryClosed: row.state === 'closed', evidenceStatus: this.evidenceStatus(row.id), operatorRecovery: this.operatorRecovery(row.id) };
      const size = Buffer.byteLength(JSON.stringify(decision)); if (decisions.length >= 100 || bytes + size > 8 * 1024 * 1024 - 1024) break;
      decisions.push(decision); bytes += size; last = row.rowid;
    }
    const hasMore = decisions.length < rows.length;
    const retired = this.db.get("SELECT instance_id FROM agent_instances WHERE agent_id=? AND instance_id=? AND state='retired'", agentId, input.instanceId);
    return { agentId, instanceId: input.instanceId, instanceState: retired ? 'released' : agent.quarantined ? 'quarantined' : agent.owner_instance && agent.owner_instance !== input.instanceId ? 'observer' : 'active', decisions, hasMore, nextCursor: hasMore ? Buffer.from(String(last)).toString('base64url') : null };
  }
  events(agentId: string, id: string, input: D.AgentEventsRequestDto): any {
    this.held(agentId, id, input);
    if (Buffer.byteLength(canonical(input)) > 2097152) throw new BadRequestException('Event batch exceeds byte budget');
    return this.db.transaction(() => {
      const row = this.held(agentId, id, input, false, false); if (row.completion_json) conflict('Completion already accepted');
      const job = this.db.get('SELECT * FROM agent_jobs WHERE id=?', row.execution_id)!;
      const cases = JSON.parse(job.cases_json), plans = JSON.parse(job.plans_json); let cursor = row.accepted_through;
      for (const delivery of input.events) {
        const snapshot = cases.find((item: any) => item.caseId === delivery.caseId); if (!snapshot) conflict('Delivery case was not assigned');
        const event = this.engine.validate(delivery.engineEventJson, 'event');
        const payload = canonical({ caseId: delivery.caseId, engineEvent: event }), hash = sha256(payload);
        const previous = this.db.get('SELECT hash FROM agent_deliveries WHERE lease_id=? AND sequence=?', id, delivery.deliverySequence);
        if (previous) { if (previous.hash !== hash) conflict('Delivery sequence payload conflict'); continue; }
        if (delivery.deliverySequence !== cursor + 1) conflict('Delivery sequence gap');
        let mapping = this.db.get('SELECT run_id FROM agent_case_runs WHERE lease_id=? AND case_id=?', id, delivery.caseId);
        if (!mapping) {
          if (event.type !== 'run.started' || event.sequence !== 1 || event.attempt !== 1) conflict('First case delivery must be the actual Engine start');
          const index = cases.findIndex((item: any) => item.caseId === delivery.caseId);
          for (const preceding of cases.slice(0, index)) {
            const prior = this.db.get('SELECT r.* FROM agent_case_runs c JOIN runs r ON r.id=c.run_id WHERE c.lease_id=? AND c.case_id=?', id, preceding.caseId);
            if (!prior?.terminal || (JSON.parse(job.suite_policy).stopOnFailure && prior.outcome !== 'passed')) conflict('Case order or stopOnFailure policy forbids start');
          }
          const runId = this.platform.recordExternalStart(job.project_id, agentId, event, plans[delivery.caseId], snapshot.publishedVersion?.versionId ?? null);
          this.db.exec('INSERT INTO agent_case_runs VALUES(?,?,?)', id, delivery.caseId, runId); mapping = { run_id: runId };
        } else this.platform.appendExternalEvents(mapping.run_id, [event]);
        this.db.exec('INSERT INTO agent_deliveries VALUES(?,?,?,?,?)', id, delivery.deliverySequence, delivery.caseId, payload, hash); cursor++;
      }
      this.db.exec('UPDATE agent_leases SET accepted_through=? WHERE id=?', cursor, id);
      return { leaseId: id, fence: row.fence, acceptedThrough: cursor };
    });
  }
  private receipts(id: string): any[] {
    return this.db.all('SELECT c.case_id,a.* FROM agent_case_runs c JOIN artifacts a ON a.run_id=c.run_id WHERE c.lease_id=? ORDER BY c.rowid,a.name', id).map(row => ({ caseId: row.case_id, path: row.name, sha256: row.hash, size: row.size, mimeType: row.mime, artifactId: row.id, uploaded: !!row.uploaded }));
  }
  private completion(id: string): any {
    const row = this.db.get('SELECT * FROM agent_leases WHERE id=?', id)!;
    return { leaseId: id, fence: row.fence, accepted: !!row.completion_json, acceptedThrough: row.accepted_through, completionReceipt: row.completion_receipt, deliveryClosed: row.state === 'closed', evidenceStatus: this.evidenceStatus(id), cleanupState: row.cleanup_state, quarantined: ['expired', 'quarantined'].includes(row.state), artifacts: this.receipts(id) };
  }
  async complete(agentId: string, id: string, input: D.AgentCompleteRequestDto): Promise<any> {
    const row = this.held(agentId, id, input, true), hash = sha256(canonical(input));
    if (row.completion_hash && row.completion_hash !== hash) conflict('Completion is immutable');
    if (row.state === 'closed') return this.completion(id);
    this.db.transaction(() => {
      const job = this.db.get('SELECT * FROM agent_jobs WHERE id=?', row.execution_id)!;
      const cases = JSON.parse(job.cases_json), policy = JSON.parse(job.suite_policy);
      const mappings = this.db.all('SELECT c.case_id,r.* FROM agent_case_runs c JOIN runs r ON r.id=c.run_id WHERE c.lease_id=? ORDER BY c.rowid', id);
      if (input.caseResults.length !== mappings.length || input.caseResults.some((item, index) => item.caseId !== cases[index]?.caseId || mappings[index]?.case_id !== item.caseId)) conflict('Completion must contain the actual ordered execution prefix');
      if (input.executionStatus === 'finished' && input.caseResults.length !== cases.length) {
        const last = mappings.at(-1); if (!policy.stopOnFailure || !last?.terminal || last.outcome === 'passed') conflict('Unexecuted cases require a justified stop');
      }
      if (!mappings.length && !['blocked', 'infra_error', 'cancelled'].includes(input.executionStatus)) conflict('Preflight cannot fabricate a finished execution');
      for (const result of input.caseResults) {
        const mapping = mappings.find(item => item.case_id === result.caseId)!;
        this.platform.acceptExternalResult(mapping.id, result.resultJson, agentId);
      }
      const actual = this.receipts(id).map(({ artifactId, uploaded, ...manifest }) => manifest);
      const sorted = (items: any[]) => [...items].sort((a, b) => `${a.caseId}:${a.path}`.localeCompare(`${b.caseId}:${b.path}`));
      if (canonical(sorted(actual)) !== canonical(sorted(input.artifactManifest)) || input.artifactManifest.reduce((sum, item) => sum + item.size, 0) > 67108864) conflict('Execution artifact manifest mismatch or quota exceeded');
      this.db.exec("UPDATE agent_leases SET completion_json=?,completion_hash=?,cleanup_state=?,state=? WHERE id=?", canonical(input), hash, input.cleanupState, input.cleanupState === 'confirmed' ? 'reporting' : 'quarantined', id);
      if (input.cleanupState !== 'confirmed') this.db.exec('UPDATE agents SET quarantined=1 WHERE id=?', agentId);
    });
    for (const mapping of this.db.all('SELECT run_id FROM agent_case_runs WHERE lease_id=?', id)) await this.platform.refreshEvidence(mapping.run_id);
    if (input.cleanupState !== 'confirmed') return this.completion(id);
    const refreshed = this.held(agentId, id, input, true);
    if (refreshed.state === 'closed') { if (refreshed.completion_hash !== hash) conflict('Completion is immutable'); return this.completion(id); }
    this.db.transaction(() => {
      if (this.evidenceStatus(id) !== 'verified') return;
      this.db.exec("UPDATE agent_leases SET state='closed',completion_receipt=? WHERE id=?", randomUUID(), id);
      this.db.exec('UPDATE agent_resources SET lease_id=NULL WHERE lease_id=?', id);
      this.db.exec("UPDATE agent_jobs SET state='completed' WHERE id=?", row.execution_id);
      this.deadlines.delete(id);
    });
    return this.completion(id);
  }
  async upload(agentId: string, id: string, input: D.AgentArtifactUploadRequestDto): Promise<any> {
    this.held(agentId, id, input);
    const mapping = this.db.get('SELECT run_id FROM agent_case_runs WHERE lease_id=? AND case_id=?', id, input.caseId) ?? missing();
    await this.platform.writeExternalArtifact(mapping.run_id, input, () => { this.held(agentId, id, input); }, agentId);
    return this.receipts(id).find(item => item.artifactId === input.artifactId) ?? missing();
  }
  resource(agentId: string, id: string, resourceId: string, input: { agentId: string; instanceId: string; fence: number }): any {
    const row = this.held(agentId, id, input);
    const resource = this.db.get('SELECT * FROM agent_resource_bytes WHERE id=? AND job_id=?', resourceId, row.execution_id) ?? missing();
    const bytes = Buffer.from(resource.bytes);
    if (bytes.length !== resource.size || sha256(bytes) !== resource.hash) conflict('Pinned resource integrity mismatch');
    return { resourceId: resource.id, name: resource.name, sha256: resource.hash, size: resource.size, mimeType: resource.mime, base64: bytes.toString('base64') };
  }
  historical(agentId: string, id: string, input: D.AgentHistoricalEvidenceRequestDto): any {
    this.expire(); this.identity(agentId, input.agentId);
    const row = this.db.get('SELECT * FROM agent_leases WHERE id=? AND agent_id=?', id, agentId) ?? missing();
    if (row.instance_id !== input.ownerInstanceId || row.fence !== input.fence || !['expired', 'quarantined', 'closed', 'recovered'].includes(row.state)) conflict('Historical evidence requires the original fenced ledger');
    const hash = sha256(canonical(input)), prior = this.db.get('SELECT * FROM agent_history WHERE lease_id=? AND request_id=?', id, input.evidenceRequestId);
    if (prior) { if (prior.hash !== hash) conflict('Historical evidence request payload conflict'); return { receiptId: prior.id, leaseId: id, recorded: true, executionPermission: false, resourceReleased: false, disposition: 'historical_quarantine' }; }
    const job = this.db.get('SELECT * FROM agent_jobs WHERE id=?', row.execution_id)!; const plans = JSON.parse(job.plans_json);
    const previousBodies = this.db.all('SELECT payload FROM agent_history WHERE lease_id=?', id).map(item => JSON.parse(item.payload));
    const identities = new Map<string, { runId: string; attempt: number }>();
    for (const mapping of this.db.all('SELECT c.case_id,r.engine_run_id,r.attempt FROM agent_case_runs c JOIN runs r ON r.id=c.run_id WHERE c.lease_id=?', id)) identities.set(mapping.case_id, { runId: mapping.engine_run_id, attempt: mapping.attempt });
    for (const body of [...previousBodies, input]) for (const delivery of body.events) {
      const event = this.engine.validate(delivery.engineEventJson, 'event');
      if (event.type !== 'run.started') continue;
      const known = identities.get(delivery.caseId);
      if (known && (known.runId !== event.runId || known.attempt !== event.attempt)) conflict('Historical case identity is immutable');
      if (event.attempt !== 1 || event.sequence !== 1) conflict('Historical start identity invalid');
      identities.set(delivery.caseId, { runId: event.runId, attempt: event.attempt });
    }
    for (const delivery of input.events) {
      const event = this.engine.validate(delivery.engineEventJson, 'event'), plan = Object.hasOwn(plans,delivery.caseId) ? plans[delivery.caseId] : undefined;
      if (!plan || (event.blueprintSnapshotHash && event.blueprintSnapshotHash !== plan.blueprintSnapshotHash) || (event.nodeId && !plan.nodeOrder.includes(event.nodeId))) conflict('Historical event snapshot mismatch');
      const identity = identities.get(delivery.caseId);
      if (!identity || event.runId !== identity.runId || event.attempt !== identity.attempt) conflict('Historical event is orphaned or has a different Engine identity');
    }
    for (const entry of input.caseResults) {
      const result = this.engine.validate(entry.resultJson, 'result'), plan = Object.hasOwn(plans,entry.caseId) ? plans[entry.caseId] : undefined;
      const identity = identities.get(entry.caseId);
      if (!plan || !identity || result.runId !== identity.runId || result.attempt !== identity.attempt || result.executed.flowSnapshotHash !== plan.flowSnapshotHash || result.executed.blueprintSnapshotHash !== plan.blueprintSnapshotHash || result.executed.engineVersion !== plan.engineVersion) conflict('Historical result identity or snapshot mismatch');
    }
    if (input.artifact) {
      const artifact = input.artifact, bytes = Buffer.from(artifact.base64, 'base64');
      if (!Object.hasOwn(plans,artifact.caseId) || !/^[A-Za-z0-9_-][A-Za-z0-9_.-]*\.(png|json)$/.test(artifact.path) || artifact.path.includes('..') || bytes.length > 10485760 || bytes.length !== artifact.size || sha256(bytes) !== artifact.sha256 || bytes.toString('base64') !== artifact.base64) throw new BadRequestException('Historical artifact invalid');
      const manifests = new Map<string, any>();
      for (const body of [...previousBodies, input]) if (body.artifact) {
        const item = body.artifact, key = `${item.caseId}:${item.path}`, previous = manifests.get(key);
        if (previous && (previous.sha256 !== item.sha256 || previous.size !== item.size || previous.mimeType !== item.mimeType)) conflict('Historical artifact path is immutable');
        manifests.set(key, item);
      }
      if ([...manifests.values()].reduce((total, item) => total + item.size, 0) > 67108864) throw new BadRequestException('Historical execution artifact quota exceeded');
    }
    if (Buffer.byteLength(canonical(input)) > 16 * 1024 * 1024) throw new BadRequestException('Historical evidence exceeds byte budget');
    const receipt = randomUUID();
    const stored = { ...input, ...(input.artifact ? { artifact: { ...input.artifact, base64: undefined } } : {}) };
    const payload = canonical(stored);
    this.db.transaction(() => {
      const used = this.db.get('SELECT COALESCE(SUM(length(CAST(payload AS BLOB))),0) AS total FROM agent_history WHERE lease_id=?', id)!.total;
      if (used + Buffer.byteLength(payload) > 8 * 1024 * 1024) throw new BadRequestException('Historical metadata storage quota exceeded');
      if (input.artifact) {
        const a = input.artifact;
        const previous = this.db.get('SELECT hash,size,mime FROM agent_history_artifacts WHERE lease_id=? AND case_id=? AND path=?', id, a.caseId, a.path);
        if (previous && (previous.hash !== a.sha256 || previous.size !== a.size || previous.mime !== a.mimeType)) conflict('Historical artifact bytes are immutable');
        const bytesUsed = this.db.get('SELECT COALESCE(SUM(size),0) AS total FROM agent_history_artifacts WHERE lease_id=?', id)!.total;
        if (!previous && bytesUsed + a.size > 67108864) throw new BadRequestException('Historical artifact storage quota exceeded');
        if (!previous) this.db.exec('INSERT INTO agent_history_artifacts VALUES(?,?,?,?,?,?,?)', id, a.caseId, a.path, a.sha256, a.size, a.mimeType, Buffer.from(a.base64, 'base64'));
      }
      this.db.exec('INSERT INTO agent_history VALUES(?,?,?,?,?,?,?,?)', receipt, id, input.evidenceRequestId, hash, input.ownerInstanceId, input.reportingInstanceId, payload, now());
    });
    return { receiptId: receipt, leaseId: id, recorded: true, executionPermission: false, resourceReleased: false, disposition: 'historical_quarantine' };
  }
  release(agentId: string, input: D.AgentInstanceReleaseRequestDto): any {
    this.expire(); this.identity(agentId, input.agentId);
    return this.db.transaction(() => {
      const owner = this.db.get('SELECT * FROM agent_instances WHERE agent_id=? AND instance_id=?', agentId, input.ownerInstanceId) ?? missing();
      if (!input.ownerStopped) conflict('Owner children and claims must have stopped');
      for (const receipt of input.receipts) {
        const lease = this.db.get('SELECT * FROM agent_leases WHERE id=? AND agent_id=? AND instance_id=?', receipt.leaseId, agentId, input.ownerInstanceId) ?? missing();
        if (lease.state !== 'closed' || lease.completion_receipt !== receipt.completionReceipt || lease.accepted_through !== receipt.acceptedThrough) conflict('Completion receipt mismatch');
        this.db.exec('UPDATE agent_leases SET receipt_acked=1 WHERE id=?', lease.id);
      }
      const leases = this.db.all('SELECT * FROM agent_leases WHERE agent_id=? AND instance_id=?', agentId, input.ownerInstanceId);
      const recovered = (row: Row) => row.state === 'recovered' && this.operatorRecovery(row.id)?.priorFence === row.fence;
      const remainingReceipts = leases.filter(row => !row.receipt_acked && !recovered(row)).length;
      const releasable = !remainingReceipts && leases.every(row => recovered(row) || row.state === 'closed' && row.cleanup_state === 'confirmed' && this.evidenceStatus(row.id) === 'verified');
      if (releasable) {
        this.db.exec("UPDATE agent_instances SET state='retired' WHERE agent_id=? AND instance_id=?", agentId, owner.instance_id);
        this.db.exec('UPDATE agents SET owner_instance=NULL,quarantined=0 WHERE id=? AND owner_instance=?', agentId, owner.instance_id);
      }
      return { agentId, reportingInstanceId: input.reportingInstanceId, ownerInstanceId: input.ownerInstanceId, released: releasable, remainingReceipts };
    });
  }
  private evidenceStatus(id: string): string {
    if (!this.db.get('SELECT completion_json FROM agent_leases WHERE id=?', id)?.completion_json) return 'pending';
    const runs = this.db.all('SELECT r.evidence_status FROM agent_case_runs c JOIN runs r ON r.id=c.run_id WHERE c.lease_id=?', id);
    return runs.every(run => run.evidence_status === 'verified') ? 'verified' : 'pending';
  }
  private operatorRecovery(id: string): any | null {
    const row = this.db.get('SELECT * FROM operator_recoveries WHERE lease_id=?',id);
    return row ? { id:row.id,confirmedAt:row.confirmed_at,priorFence:row.prior_fence,newFence:row.new_fence } : null;
  }
  recover(user: string, project: string, executionId: string, input: { requestId: string; resourceKey: string; fence: number; reason: string; ownerProcessesStopped: boolean; externalSessionsStopped: boolean }): any {
    this.platform.authorize(user,project,'qa_manager'); this.expire();
    if (!input.ownerProcessesStopped || !input.externalSessionsStopped || !input.reason.trim()) throw new BadRequestException('Explicit stopped process/session confirmations and reason are required');
    const payloadHash = sha256(canonical({ executionId,...input }));
    return this.db.transaction(() => {
      const previous = this.db.get('SELECT * FROM operator_recoveries WHERE project_id=? AND request_id=?',project,input.requestId);
      if (previous) { if (previous.payload_hash !== payloadHash) conflict('Recovery request payload conflict'); return { executionId,leaseId:previous.lease_id,resourceKey:previous.resource_key,recovery:this.operatorRecovery(previous.lease_id) }; }
      const job = this.db.get('SELECT * FROM agent_jobs WHERE id=? AND project_id=?',executionId,project) ?? missing();
      const lease = this.db.get('SELECT * FROM agent_leases WHERE id=?',job.lease_id) ?? missing();
      const resource = this.db.get('SELECT * FROM agent_resources WHERE resource_key=?',input.resourceKey) ?? missing();
      if (!['expired','quarantined'].includes(lease.state) || lease.fence !== input.fence || job.resource_key !== input.resourceKey || resource.lease_id !== lease.id || resource.fence !== lease.fence) conflict('Recovery requires the exact quarantined resource owner and fence');
      const id = randomUUID(); this.db.exec('INSERT INTO operator_recoveries VALUES(?,?,?,?,?,?,?,?,?,?,?)',id,project,input.requestId,payloadHash,lease.id,user,input.reason,input.resourceKey,lease.fence,lease.fence+1,now());
      this.db.exec("UPDATE agent_leases SET state='recovered' WHERE id=?",lease.id);
      this.db.exec("UPDATE agent_jobs SET state='recovered' WHERE id=?",executionId);
      this.db.exec('UPDATE agent_resources SET lease_id=NULL,fence=fence+1 WHERE resource_key=?',input.resourceKey);
      this.db.exec("UPDATE agent_instances SET state='retired' WHERE agent_id=? AND instance_id=?",lease.agent_id,lease.instance_id);
      this.db.exec('UPDATE agents SET owner_instance=NULL,quarantined=0 WHERE id=? AND owner_instance=?',lease.agent_id,lease.instance_id);
      this.db.audit(project,user,'agent.operator.recovery',id); this.deadlines.delete(lease.id);
      return { executionId,leaseId:lease.id,resourceKey:input.resourceKey,recovery:this.operatorRecovery(lease.id) };
    });
  }
}
