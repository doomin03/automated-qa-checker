import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { mkdir, open, readFile, readdir, rename, rm, stat } from 'node:fs/promises';
import { join } from 'node:path';
import { PlatformRepository, canonical, sha256, type Row } from './platform.repository.js';
import { EngineContractService } from './engine-contract.service.js';
import { type PlatformConfig } from './platform.config.js';
import { roles, projectActions, projectActionRoles, type ProjectContextResponse, type ProjectMemberPage, type Role, type DraftInput, type PageQuery, type VersionQuery, type RunInput, type ArtifactInput, type DependencyPin } from './platform.dto.js';

const now = () => new Date().toISOString();
const missing = (): never => { throw new NotFoundException('Resource not found'); };
const conflict = (message: string): never => { throw new ConflictException(message); };
const safeName = (name: unknown) => typeof name === 'string' && /^[A-Za-z0-9_-][A-Za-z0-9_.-]{0,250}\.(png|json)$/.test(name) && !name.includes('..');

@Injectable()
export class PlatformService {
  private config?: PlatformConfig;
  private workStatusResolver?: (runId: string) => string;
  registerWorkStatusResolver(resolver: (runId: string) => string): void { this.workStatusResolver = resolver; }
  private identityResolver?: (header?: string, cookie?: string, csrf?: string, method?: string, origin?: string) => string | null;
  registerIdentityResolver(resolver: (header?: string, cookie?: string, csrf?: string, method?: string, origin?: string) => string | null): void { this.identityResolver = resolver; }
  constructor(private readonly repo: PlatformRepository, private readonly engine: EngineContractService) {}
  async start(config: PlatformConfig): Promise<void> {
    await this.engine.start(config.engineCli, config.engineManifest);
    this.repo.start(config.dataDir, config.identities, config.identityStorage); this.config = config;
    await mkdir(join(config.dataDir, 'artifacts'), { recursive: true });
    // Only server-created staging names are removed. Published bytes are reconciled against their manifests.
    for (const entry of await readdir(join(config.dataDir, 'artifacts'), { withFileTypes: true })) {
      if (entry.isFile() && /^upload-[0-9a-f-]+\.tmp$/.test(entry.name)) await rm(join(config.dataDir, 'artifacts', entry.name));
    }
    for (const run of this.repo.all('SELECT id FROM runs WHERE result_json IS NOT NULL')) await this.reconcile(run.id);
  }
  authenticate(header?: string, cookie?: string, csrf?: string, method?: string, origin?: string): string {
    const resolved = this.identityResolver?.(header, cookie, csrf, method, origin);
    if (resolved) return resolved;
    if (this.config && ['oidc', 'oidc-test'].includes(this.config.mode)) throw new UnauthorizedException('Organization session required');
    const token = header?.match(/^Bearer ([^\s]{24,256})$/)?.[1];
    if (!token) throw new UnauthorizedException('Registered local identity required');
    const user = this.repo.get('SELECT id FROM users WHERE token_hash=? AND active=1', sha256(token));
    if (!user) { this.repo.audit('', '', 'identity.denied'); throw new UnauthorizedException('Identity is unavailable'); }
    return user.id;
  }
  authorize(user: string, project: string, minimum: Role = 'viewer'): Role {
    const member = this.repo.get('SELECT m.role FROM memberships m JOIN users u ON u.id=m.user_id WHERE m.user_id=? AND m.project_id=? AND u.active=1', user, project);
    if (!member || roles.indexOf(member.role) < roles.indexOf(minimum)) {
      this.repo.audit(project, user, 'access.denied'); throw new ForbiddenException('Project role is insufficient');
    }
    return member.role;
  }
  me(user: string): any { return { userId: user, localMode: !!this.config && ['local', 'test'].includes(this.config.mode), projects: this.projects(user, { limit: 100 }).items }; }
  context(user: string, project: string): ProjectContextResponse {
    const role = this.authorize(user, project);
    return {
      projectId: project, role,
      allowedActions: projectActions.filter(action => roles.indexOf(role) >= roles.indexOf(projectActionRoles[action])),
      engine: { engineVersion: this.engine.version, contractVersion: this.engine.contractVersion, contractSha256: this.engine.contractSha256, archiveSha256: this.engine.archiveSha256 },
    };
  }
  members(user: string, project: string, query: PageQuery): ProjectMemberPage {
    this.authorize(user, project, 'qa_manager');
    const rows = this.repo.all('SELECT u.rowid,u.id,m.role FROM users u JOIN memberships m ON m.user_id=u.id WHERE m.project_id=? AND u.active=1 AND u.rowid>? ORDER BY u.rowid LIMIT ?', project, this.offset(query), (query.limit ?? 50) + 1);
    return this.page(rows, query, row => ({ userId: row.id, displayName: null, role: row.role }));
  }
  private page(rows: Row[], query: PageQuery, map: (row: Row) => any): any {
    const limit = query.limit ?? 50; const more = rows.length > limit; const selected = rows.slice(0, limit);
    return { items: selected.map(map), nextCursor: more ? Buffer.from(String(selected.at(-1)!.rowid)).toString('base64url') : null };
  }
  private offset(query: PageQuery): number {
    if (!query.cursor) return 0;
    const decoded = Buffer.from(query.cursor, 'base64url').toString('utf8');
    if (!/^[1-9]\d*$/.test(decoded) || !Number.isSafeInteger(Number(decoded)) || Buffer.from(decoded).toString('base64url') !== query.cursor) throw new BadRequestException('Invalid pagination cursor');
    return Number(decoded);
  }
  projects(user: string, query: PageQuery): any {
    return this.page(this.repo.all('SELECT p.rowid,p.id,p.name,m.role FROM projects p JOIN memberships m ON m.project_id=p.id WHERE m.user_id=? AND p.rowid>? ORDER BY p.rowid LIMIT ?', user, this.offset(query), (query.limit ?? 50) + 1), query, row => ({ id: row.id, name: row.name, role: row.role }));
  }
  private dependencies(project: string, deps: DependencyPin[]): void {
    if (new Set(deps.map(d => d.versionId)).size !== deps.length) throw new BadRequestException('Duplicate dependency');
    for (const dependency of deps) { const version = this.versionRow(project, dependency.versionId); if (version.hash !== dependency.sha256) conflict('Dependency hash mismatch'); }
  }
  async createDraft(user: string, project: string, input: DraftInput): Promise<any> {
    this.authorize(user, project, 'qa_editor');
    await this.engine.plan(input.xml);
    return this.repo.transaction(() => {
      this.authorize(user, project, 'qa_editor'); this.dependencies(project, input.dependencies);
      const id = randomUUID();
      this.repo.exec('INSERT INTO drafts VALUES(?,?,?,?,?,?,?,?,?,?,?)', id, project, input.packageId, input.title, input.xml, sha256(input.xml), canonical(input.dependencies), user, 'draft', null, now());
      this.repo.audit(project, user, 'draft.created', id); return this.draft(project, id);
    });
  }
  private draft(project: string, id: string): any {
    const row = this.repo.get('SELECT * FROM drafts WHERE id=? AND project_id=?', id, project) ?? missing();
    return { id: row.id, projectId: row.project_id, packageId: row.package_id, title: row.title, xml: row.xml, sha256: row.hash, dependencies: JSON.parse(row.dependencies), authorId: row.author_id, state: row.state, reviewerId: row.reviewer_id, createdAt: row.created_at };
  }
  listDrafts(user: string, project: string, query: PageQuery): any {
    this.authorize(user, project);
    return this.page(this.repo.all('SELECT rowid,* FROM drafts WHERE project_id=? AND rowid>? ORDER BY rowid LIMIT ?', project, this.offset(query), (query.limit ?? 50) + 1), query, row => this.draft(project, row.id));
  }
  review(user: string, project: string, id: string): any {
    this.authorize(user, project, 'qa_manager');
    return this.repo.transaction(() => {
      const draft = this.draft(project, id);
      if (draft.authorId === user) throw new ForbiddenException('A different manager must review the author draft');
      if (draft.state !== 'draft') conflict('Only draft state can be reviewed');
      this.repo.exec('UPDATE drafts SET state=?,reviewer_id=? WHERE id=?', 'reviewed', user, id);
      this.repo.audit(project, user, 'draft.reviewed', id); return this.draft(project, id);
    });
  }
  async publish(user: string, project: string, id: string, version: string, key: string): Promise<any> {
    this.authorize(user, project, 'qa_manager');
    const draft = this.draft(project, id); const plan = await this.engine.plan(draft.xml);
    return this.repo.idempotent(`${project}:publish:${user}`, key, { draftId: id, version }, () => {
      this.authorize(user, project, 'qa_manager'); const current = this.draft(project, id);
      if (current.state !== 'reviewed' || !current.reviewerId || current.reviewerId === current.authorId) conflict('Independent review is required');
      const reviewer = this.repo.get('SELECT m.role FROM memberships m JOIN users u ON u.id=m.user_id WHERE u.active=1 AND m.user_id=? AND m.project_id=?', current.reviewerId, project);
      if (!reviewer || roles.indexOf(reviewer.role) < roles.indexOf('qa_manager')) conflict('Reviewing manager is no longer authorized');
      this.dependencies(project, current.dependencies);
      if (this.repo.get('SELECT id FROM versions WHERE project_id=? AND package_id=? AND version=?', project, current.packageId, version)) conflict('Published version already exists');
      const versionId = randomUUID();
      this.repo.exec('INSERT INTO versions VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)', versionId, project, current.packageId, version, id, current.title, current.xml, current.sha256, canonical(current.dependencies), this.engine.version, plan.blueprintSnapshotHash, plan.flowSnapshotHash, JSON.stringify(plan.nodeOrder), now());
      this.repo.exec('UPDATE drafts SET state=? WHERE id=?', 'published', id); this.repo.audit(project, user, 'version.published', versionId);
      return this.versionResponse(this.versionRow(project, versionId));
    });
  }
  private versionRow(project: string, id: string): Row { return this.repo.get('SELECT * FROM versions WHERE project_id=? AND id=?', project, id) ?? missing(); }
  private versionResponse(row: Row): any {
    return { id: row.id, projectId: row.project_id, packageId: row.package_id, version: row.version, title: row.title, xml: row.xml, sha256: row.hash, dependencies: JSON.parse(row.dependencies), engineVersion: row.engine_version, blueprintSnapshotHash: row.blueprint_hash, flowSnapshotHash: row.flow_hash, createdAt: row.created_at };
  }
  getVersion(user: string, project: string, id: string): any { this.authorize(user, project); return this.versionResponse(this.versionRow(project, id)); }
  versions(user: string, project: string, query: VersionQuery): any {
    this.authorize(user, project);
    const rows = this.repo.all('SELECT rowid,* FROM versions WHERE project_id=? AND rowid>? AND (? IS NULL OR package_id=?) ORDER BY rowid LIMIT ?', project, this.offset(query), query.packageId ?? null, query.packageId ?? null, (query.limit ?? 50) + 1);
    return this.page(rows, query, row => this.versionResponse(row));
  }
  pin(user: string, project: string, id: string, hash: string): any {
    this.authorize(user, project, 'qa_tester'); const version = this.versionRow(project, id);
    if (version.hash !== hash) conflict('Pin hash mismatch');
    return this.repo.transaction(() => {
      this.repo.exec('INSERT INTO pins VALUES(?,?,?,?,?) ON CONFLICT(user_id,project_id,package_id) DO UPDATE SET version_id=excluded.version_id,hash=excluded.hash', user, project, version.package_id, id, hash);
      this.repo.audit(project, user, 'version.pinned', id); return { packageId: version.package_id, versionId: id, sha256: hash };
    });
  }
  pins(user: string, project: string, query: PageQuery): any {
    this.authorize(user, project);
    return this.page(this.repo.all('SELECT rowid,* FROM pins WHERE user_id=? AND project_id=? AND rowid>? ORDER BY rowid LIMIT ?', user, project, this.offset(query), (query.limit ?? 50) + 1), query, row => ({ packageId: row.package_id, versionId: row.version_id, sha256: row.hash }));
  }
  diff(user: string, project: string, fromId: string, toId: string): any {
    const from = this.getVersion(user, project, fromId), to = this.getVersion(user, project, toId);
    if (from.packageId !== to.packageId) conflict('Upgrade must compare the same package');
    return { from, to, xmlChanged: from.sha256 !== to.sha256, dependenciesChanged: canonical(from.dependencies) !== canonical(to.dependencies) };
  }
  async createRun(user: string, project: string, input: RunInput, key: string): Promise<any> {
    this.authorize(user, project, 'qa_tester');
    const plan = await this.engine.plan(input.blueprintJson, 'json');
    const start = this.engine.validate(input.startedEventJson, 'event');
    if (start.type !== 'run.started' || start.sequence !== 1 || start.runId !== input.engineRunId || start.attempt !== input.attempt || start.blueprintSnapshotHash !== input.snapshotHash || input.engineVersion !== this.engine.version) conflict('Run identity or start snapshot mismatch');
    if (plan.blueprintSnapshotHash !== input.snapshotHash || plan.engineVersion !== input.engineVersion) conflict('Run blueprint is not the reported snapshot');
    if (input.versionId) { const version = this.versionRow(project, input.versionId); if (version.blueprint_hash !== input.snapshotHash) conflict('Published snapshot mismatch'); }
    return this.repo.idempotent(`${project}:run:${user}`, key, { ...input, startedEventJson: canonical(start) }, () => {
      if (this.repo.get('SELECT id FROM runs WHERE project_id=? AND engine_run_id=? AND attempt=?', project, input.engineRunId, input.attempt)) conflict('Engine attempt is already registered');
      const id = randomUUID();
      this.authorize(user, project, 'qa_tester');
      this.repo.exec('INSERT INTO runs(id,project_id,owner_id,engine_run_id,attempt,snapshot_hash,engine_version,version_id,blueprint_json,flow_hash,node_ids,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)', id, project, user, input.engineRunId, input.attempt, input.snapshotHash, input.engineVersion, input.versionId ?? null, canonical(plan.blueprint), plan.flowSnapshotHash, JSON.stringify(plan.nodeOrder), now());
      this.appendValidated(id, [start]); this.repo.audit(project, user, 'run.created', id); return this.runResponse(this.runRow(project, id));
    });
  }
  private runRow(project: string, id: string): Row { return this.repo.get('SELECT * FROM runs WHERE project_id=? AND id=?', project, id) ?? missing(); }
  // Trusted module boundary. AgentService owns credential/lease/fence authorization;
  // public user routes never call these helpers before their usual role/owner guard.
  recordExternalStart(project: string, actor: string, start: any, plan: any, versionId: string | null = null): string {
    if (start.type !== 'run.started' || start.sequence !== 1 || start.blueprintSnapshotHash !== plan.blueprintSnapshotHash) conflict('External start snapshot mismatch');
    if (this.repo.get('SELECT id FROM runs WHERE project_id=? AND engine_run_id=? AND attempt=?', project, start.runId, start.attempt)) conflict('Engine attempt is already registered');
    const id = randomUUID();
    this.repo.exec('INSERT INTO runs(id,project_id,owner_id,engine_run_id,attempt,snapshot_hash,engine_version,version_id,blueprint_json,flow_hash,node_ids,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)', id, project, actor, start.runId, start.attempt, plan.blueprintSnapshotHash, plan.engineVersion, versionId, canonical(plan.blueprint), plan.flowSnapshotHash, JSON.stringify(plan.nodeOrder), now());
    this.appendValidated(id, [start]); this.repo.audit(project, actor, 'agent.run.created', id); return id;
  }
  appendExternalEvents(id: string, events: any[]): void { this.appendValidated(id, events); }
  externalRun(id: string): any { return this.runResponse(this.repo.get('SELECT * FROM runs WHERE id=?', id) ?? missing()); }
  async refreshEvidence(id: string): Promise<void> { await this.reconcile(id); }
  private ownedRun(user: string, project: string, id: string): Row {
    this.authorize(user, project, 'qa_tester'); const run = this.runRow(project, id);
    if (run.owner_id !== user) { this.repo.audit(project, user, 'run.write.denied', id); throw new ForbiddenException('Only the registered run owner can append evidence'); }
    return run;
  }
  private artifactResponse(row: Row): any { return { artifactId: row.id, name: row.name, sha256: row.hash, size: row.size, mimeType: row.mime, uploaded: row.uploaded === 1 }; }
  private runResponse(row: Row): any {
      return { id: row.id, projectId: row.project_id, ownerId: row.owner_id, blueprintJson: row.blueprint_json, engineRunId: row.engine_run_id, attempt: row.attempt, snapshotHash: row.snapshot_hash, engineVersion: row.engine_version, versionId: row.version_id, lastSequence: row.last_sequence, terminal: row.terminal === 1, reportedOutcome: row.outcome, evidenceStatus: row.evidence_status, workStatus: this.workStatusResolver?.(row.id) ?? 'todo', resultJson: row.result_json, artifacts: this.repo.all('SELECT * FROM artifacts WHERE run_id=? ORDER BY name', row.id).map(a => this.artifactResponse(a)), createdAt: row.created_at };
  }
  async getRun(user: string, project: string, id: string): Promise<any> { this.authorize(user, project); this.runRow(project, id); await this.reconcile(id); return this.runResponse(this.runRow(project, id)); }
  runs(user: string, project: string, query: PageQuery): any {
    this.authorize(user, project);
    return this.page(this.repo.all('SELECT rowid,* FROM runs WHERE project_id=? AND rowid>? ORDER BY rowid LIMIT ?', project, this.offset(query), (query.limit ?? 50) + 1), query, row => this.runResponse(row));
  }
  private appendValidated(id: string, events: any[]): void {
    const run = this.repo.get('SELECT * FROM runs WHERE id=?', id)!;
    const blueprint = JSON.parse(run.blueprint_json);
    const nodes = new Map<string, any>(blueprint.flow.nodes.map((node: any) => [node.id, node]));
    const states = new Map<string, { finished: boolean; retries: number }>();
    let active: string | undefined;
    const transition = (event: any): void => {
      if (event.nodeId && !nodes.has(event.nodeId)) conflict('Event references an unknown snapshot node');
      const state = states.get(event.nodeId);
      if (event.type === 'step.started') {
        if (active || state) conflict('DAG node cannot start twice or overlap another node');
        states.set(event.nodeId, { finished: false, retries: 0 }); active = event.nodeId;
      } else if (event.type === 'step.retrying') {
        if (!state || state.finished || active !== event.nodeId || ++state.retries > (nodes.get(event.nodeId)?.retry?.maxRetries ?? 0) || !['ASSERTION_FAILED', 'ELEMENT_NOT_FOUND'].includes(event.failure?.code)) conflict('Invalid node retry');
      } else if (event.type === 'step.finished') {
        if (!state || state.finished || active !== event.nodeId) conflict('Node finish has no active start');
        state!.finished = true; active = undefined;
      } else if (event.type === 'run.finished' && active) conflict('Run cannot finish while a node is active');
    };
    for (const row of this.repo.all('SELECT payload FROM events WHERE run_id=? ORDER BY sequence', id)) transition(JSON.parse(row.payload));
    for (const event of events) {
      if (event.runId !== run.engine_run_id || event.attempt !== run.attempt || (event.blueprintSnapshotHash && event.blueprintSnapshotHash !== run.snapshot_hash)) conflict('Event identity mismatch');
      const payload = canonical(event), hash = sha256(payload);
      const previous = this.repo.get('SELECT hash FROM events WHERE run_id=? AND sequence=?', id, event.sequence);
      if (previous) { if (previous.hash !== hash) conflict('Conflicting event payload'); continue; }
      if (run.terminal || event.sequence !== run.last_sequence + 1) conflict('Event gap or terminal append');
      if ((event.sequence === 1) !== (event.type === 'run.started')) conflict('Invalid start event position');
      transition(event);
      this.repo.exec('INSERT INTO events VALUES(?,?,?,?)', id, event.sequence, payload, hash);
      run.last_sequence = event.sequence;
      if (event.type === 'run.finished') { run.terminal = 1; run.outcome = event.outcome; }
    }
    this.repo.exec('UPDATE runs SET last_sequence=?,terminal=?,outcome=? WHERE id=?', run.last_sequence, run.terminal, run.outcome, id);
  }
  appendEvents(user: string, project: string, id: string, json: string[]): any {
    this.ownedRun(user, project, id);
    if (json.length === 0 || json.reduce((n, value) => n + Buffer.byteLength(value), 0) > 2097152) throw new BadRequestException('Invalid event batch size');
    const events = json.map(value => this.engine.validate(value, 'event'));
    return this.repo.transaction(() => { this.appendValidated(id, events); this.repo.audit(project, user, 'events.appended', id); return this.runResponse(this.runRow(project, id)); });
  }
  events(user: string, project: string, id: string, after = 0, limit = 50): any {
    this.authorize(user, project); const run = this.runRow(project, id);
    if (after > run.last_sequence) conflict('Cursor exceeds run sequence');
    const rows = this.repo.all('SELECT * FROM events WHERE run_id=? AND sequence>? ORDER BY sequence LIMIT ?', id, after, limit + 1); const page = rows.slice(0, limit);
    return { runId: id, engineRunId: run.engine_run_id, attempt: run.attempt, snapshotHash: run.snapshot_hash, eventsJson: page.map(r => r.payload), nextSequence: page.at(-1)?.sequence ?? after, hasMore: rows.length > limit, terminal: run.terminal === 1 };
  }
  async putResult(user: string, project: string, id: string, text: string): Promise<any> {
    this.ownedRun(user, project, id);
    this.acceptExternalResult(id, text, user);
    await this.reconcile(id); return this.runResponse(this.runRow(project, id));
  }
  acceptExternalResult(id: string, text: string, actor: string): void {
    const run = this.repo.get('SELECT * FROM runs WHERE id=?', id) ?? missing(); const result = this.engine.validate(text, 'result'); const json = canonical(result);
    if (!run.terminal || result.runId !== run.engine_run_id || result.attempt !== run.attempt || result.executed.blueprintSnapshotHash !== run.snapshot_hash || result.executed.engineVersion !== run.engine_version || result.outcome !== run.outcome) conflict('Result does not match the terminal run identity');
    if (run.result_json && run.result_json !== json) conflict('Accepted result is immutable');
    const visited = new Set(result.visitedNodes), unvisited = new Set(result.unvisitedNodes);
    if (visited.size !== result.visitedNodes.length || unvisited.size !== result.unvisitedNodes.length || [...visited].some(node => unvisited.has(node))) conflict('Invalid visited/unvisited sets');
    const events = this.repo.all('SELECT payload FROM events WHERE run_id=?', id).map(r => JSON.parse(r.payload));
    if ((result.status === 'cancelled') !== (result.outcome === 'cancelled')) conflict('Result status does not match the terminal outcome');
    const startedNodes = new Set(events.filter(e => e.type === 'step.started').map(e => e.nodeId));
    if (startedNodes.size !== visited.size || [...visited].some(node => !startedNodes.has(node))) conflict('Result visited nodes do not match accepted starts');
    const nodes = JSON.parse(run.node_ids);
    if (run.flow_hash !== result.executed.flowSnapshotHash || [...visited, ...unvisited].length !== nodes.length || nodes.some((n: string) => !visited.has(n) && !unvisited.has(n))) conflict('Result node/snapshot mismatch');
    const artifacts = result.artifacts as any[];
    if (artifacts.some(a => !safeName(a.path) || a.size > 10485760) || new Set(artifacts.map(a => a.path)).size !== artifacts.length || artifacts.reduce((n, a) => n + a.size, 0) > 67108864) throw new BadRequestException('Artifact manifest exceeds limits or contains unsafe names');
    for (const event of events) for (const artifact of event.artifacts ?? []) {
      if (!artifacts.some(a => canonical(a) === canonical(artifact))) conflict('Event artifact is absent or different in result');
    }
    this.repo.transaction(() => {
      if (!run.result_json) {
        this.repo.exec('UPDATE runs SET result_json=?,evidence_status=? WHERE id=?', json, 'missing', id);
        for (const artifact of artifacts) this.repo.exec('INSERT INTO artifacts VALUES(?,?,?,?,?,?,?)', randomUUID(), id, artifact.path, artifact.sha256, artifact.size, artifact.contentType, 0);
        this.repo.audit(run.project_id, actor, 'result.received', id);
      }
    });
  }
  private artifactFile(id: string): string { return join(this.config!.dataDir, 'artifacts', id); }
  private async reconcile(id: string): Promise<void> {
    const run = this.repo.get('SELECT * FROM runs WHERE id=?', id); if (!run?.result_json || !this.config) return;
    const rows = this.repo.all('SELECT * FROM artifacts WHERE run_id=?', id); let complete = true;
    const reports: any[] = [];
    for (const artifact of rows) {
      let valid = false;
      try {
        const info = await stat(this.artifactFile(artifact.id));
        if (info.isFile() && info.size === artifact.size && info.size <= 10485760) {
          const bytes = await readFile(this.artifactFile(artifact.id)); valid = sha256(bytes) === artifact.hash;
          if (valid && artifact.mime === 'application/json') {
            const report = this.engine.validate(bytes.toString('utf8'), 'checkReport');
            if (report.artifactRefs.some((ref: any) => !safeName(ref.path) || !rows.some(a => a.name === ref.path && a.mime === 'image/png'))) valid = false;
            else reports.push(report);
          }
        }
      } catch { valid = false; }
      this.repo.exec('UPDATE artifacts SET uploaded=? WHERE id=?', valid ? 1 : 0, artifact.id); if (!valid) complete = false;
    }
    const result = JSON.parse(run.result_json);
    if (reports.some(report => !result.visitedNodes.includes(report.nodeId) || (result.outcome === 'passed' && report.verdict !== 'passed'))) complete = false;
    this.repo.exec('UPDATE runs SET evidence_status=? WHERE id=?', complete ? 'verified' : 'missing', id);
  }
  async upload(user: string, project: string, id: string, input: ArtifactInput): Promise<any> {
    return this.writeExternalArtifact(id, input, () => { this.ownedRun(user, project, id); }, user);
  }
  async writeExternalArtifact(id: string, input: ArtifactInput, assertPermission: () => void, actor: string): Promise<any> {
    assertPermission();
    const artifact = this.repo.get('SELECT * FROM artifacts WHERE run_id=? AND id=?', id, input.artifactId) ?? missing();
    const bytes = Buffer.from(input.base64, 'base64');
    if (bytes.length > 10485760 || bytes.length !== artifact.size || bytes.toString('base64') !== input.base64 || sha256(bytes) !== input.sha256 || artifact.hash !== input.sha256 || artifact.mime !== input.mimeType) throw new BadRequestException('Artifact bytes do not match the registered result');
    if (input.mimeType === 'image/png' && (bytes.length < 8 || bytes.subarray(0, 8).toString('hex') !== '89504e470d0a1a0a')) throw new BadRequestException('Artifact is not PNG');
    if (input.mimeType === 'application/json') {
      const report = this.engine.validate(bytes.toString('utf8'), 'checkReport');
      const manifest = this.repo.all('SELECT * FROM artifacts WHERE run_id=?', id);
      if (report.artifactRefs.some((ref: any) => !safeName(ref.path) || !manifest.some(a => a.name === ref.path && a.mime === 'image/png'))) throw new BadRequestException('Check report contains unregistered artifact references');
    }
    const temp = join(this.config!.dataDir, 'artifacts', `upload-${randomUUID()}.tmp`);
    try {
      const handle = await open(temp, 'wx'); try { await handle.writeFile(bytes); await handle.sync(); } finally { await handle.close(); }
      assertPermission(); // Permission may have been revoked during asynchronous IO.
      await rename(temp, this.artifactFile(artifact.id));
      const run = this.repo.get('SELECT project_id FROM runs WHERE id=?', id) ?? missing();
      this.repo.audit(run.project_id, actor, 'artifact.uploaded', artifact.id); await this.reconcile(id);
      return this.artifactResponse(this.repo.get('SELECT * FROM artifacts WHERE id=?', artifact.id)!);
    } finally { await rm(temp, { force: true }); }
  }
  async download(user: string, project: string, runId: string, artifactId: string): Promise<any> {
    this.authorize(user, project); this.runRow(project, runId); await this.reconcile(runId);
    const artifact = this.repo.get('SELECT * FROM artifacts WHERE run_id=? AND id=?', runId, artifactId) ?? missing();
    if (!artifact.uploaded) conflict('Artifact evidence is missing or invalid');
    const bytes = await readFile(this.artifactFile(artifactId));
    if (sha256(bytes) !== artifact.hash) conflict('Artifact changed during download');
    return { ...this.artifactResponse(artifact), base64: bytes.toString('base64') };
  }
  audit(user: string, project: string, query: PageQuery): any {
    this.authorize(user, project, 'qa_manager');
    return this.page(this.repo.all('SELECT id AS rowid,* FROM audit WHERE project_id=? AND id>? ORDER BY id LIMIT ?', project, this.offset(query), (query.limit ?? 50) + 1), query, row => ({ id: String(row.id), actorId: row.actor_id, action: row.action, resourceId: row.resource_id, createdAt: row.created_at }));
  }
}
