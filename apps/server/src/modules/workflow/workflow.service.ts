import { BadRequestException, ConflictException, Injectable, NotFoundException, OnModuleDestroy, ServiceUnavailableException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PlatformService } from '../platform/platform.service.js';
import { canonical, sha256 } from '../platform/platform.repository.js';
import { WorkflowRepository } from './workflow.repository.js';

@Injectable()
export class WorkflowService implements OnModuleDestroy {
  private sink?: string;
  private timer?: NodeJS.Timeout;
  private draining = false;
  private stopped = false;
  constructor(private readonly store: WorkflowRepository, private readonly platform: PlatformService) {}
  private get db() { return this.store.platform; }
  start(env: NodeJS.ProcessEnv = process.env): void {
    this.store.start(); this.stopped = false;
    if (env.QA_NOTIFICATION_URL) {
      const url = new URL(env.QA_NOTIFICATION_URL);
      if (env.NODE_ENV === 'production' || env.QA_NOTIFICATION_MODE !== 'local-test' || url.protocol !== 'http:' || !['127.0.0.1', '[::1]'].includes(url.hostname) || url.username || url.password || url.hash || url.search) throw new Error('Notifications require an explicit local-test loopback fixture');
      this.sink = url.href;
      this.timer = setInterval(() => { void this.drain(); }, 1000); this.timer.unref();
    }
  }
  status(runId: string): string { return this.db.get('SELECT status FROM work_items WHERE run_id=?', runId)?.status ?? 'todo'; }
  private run(user: string, project: string, id: string, write = false): any {
    this.platform.authorize(user, project, write ? 'qa_tester' : 'viewer');
    const run = this.db.get('SELECT * FROM runs WHERE id=? AND project_id=?', id, project);
    if (!run) throw new NotFoundException('Run not found'); return run;
  }
  work(user: string, project: string, id: string): any {
    this.run(user, project, id); const row = this.db.get('SELECT * FROM work_items WHERE run_id=?', id);
    return { runId: id, status: row?.status ?? 'todo', assigneeId: row?.assignee_id ?? null, revision: row?.revision ?? 0, updatedAt: row?.updated_at ?? null };
  }
  update(user: string, project: string, id: string, input: {status: string; assigneeId: string | null; revision: number}): any {
    return this.db.transaction(() => {
      this.run(user, project, id, true);
      if (!['todo', 'in_progress', 'done'].includes(input.status) || !Number.isSafeInteger(input.revision) || input.revision < 0) throw new BadRequestException('Invalid work state');
      if (input.assigneeId !== null && !this.db.get('SELECT u.id FROM users u JOIN memberships m ON m.user_id=u.id WHERE u.active=1 AND u.id=? AND m.project_id=?', input.assigneeId, project)) throw new BadRequestException('Assignee must be an active project member');
      if (this.work(user, project, id).revision !== input.revision) throw new ConflictException('Work revision changed');
      this.db.exec('INSERT INTO work_items VALUES(?,?,?,?,?) ON CONFLICT(run_id) DO UPDATE SET status=excluded.status,assignee_id=excluded.assignee_id,revision=excluded.revision,updated_at=excluded.updated_at', id, input.status, input.assigneeId, input.revision + 1, new Date().toISOString());
      this.db.audit(project, user, 'work.updated', id); return this.work(user, project, id);
    });
  }
  private async identity(user: string, project: string, id: string): Promise<{key?: string; reason?: string; run: any}> {
    const run = await this.platform.getRun(user, project, id);
    if (!run.terminal || run.evidenceStatus !== 'verified' || !run.resultJson) return {run, reason: 'EVIDENCE_NOT_VERIFIED'};
    const blueprint = JSON.parse(run.blueprintJson), profiles: any[] = [];
    for (const artifact of run.artifacts.filter((a: any) => a.mimeType === 'application/json')) {
      const bytes = await this.platform.download(user, project, id, artifact.artifactId), report = JSON.parse(Buffer.from(bytes.base64, 'base64').toString('utf8'));
      if (report.schemaVersion !== 'qa.checkReport/v1' || !/^sha256:[a-f0-9]{64}$/.test(report.profileHash ?? '') || !['passed','failed'].includes(report.verdict) || ['PROFILE_MISMATCH', 'REFERENCE_MISMATCH'].includes(report.reason)) return {run, reason: 'PROFILE_REFERENCE_UNVERIFIED'};
      if (report.kind !== 'ux' && !/^sha256:[a-f0-9]{64}$/.test(report.referenceHash ?? '')) return {run, reason: 'PROFILE_REFERENCE_UNVERIFIED'};
      const identity = report.kind === 'ux'
        ? {kind: 'ux', nodeId: report.nodeId, profileHash: report.profileHash}
        : {kind: 'design', profileHash: report.profileHash, referenceHash: report.referenceHash};
      if (!profiles.some(value => canonical(value) === canonical(identity))) profiles.push(identity);
    }
    if (!profiles.length) return {run, reason: 'ENVIRONMENT_EVIDENCE_ABSENT'};
    profiles.sort((a, b) => canonical(a).localeCompare(canonical(b)));
    return {run, key: sha256(canonical({snapshot: run.snapshotHash, target: blueprint.target, engine: run.engineVersion, profiles}))};
  }
  async compare(user: string, project: string, id: string, requested?: string): Promise<any> {
    const current = await this.identity(user, project, id);
    const empty = (reason: string, baselineRunId: string | null = null) => ({runId: id, baselineRunId, comparable: false, reason, classification: 'incomparable', currentOutcome: current.run.reportedOutcome, baselineOutcome: null, changedNodes: []});
    if (!current.key) return empty(current.reason!);
    const explicit = requested ?? this.db.get('SELECT baseline_id FROM run_baselines WHERE run_id=?', id)?.baseline_id;
    const candidates = explicit ? [{id: explicit}] : this.db.all('SELECT id FROM runs WHERE project_id=? AND rowid<(SELECT rowid FROM runs WHERE id=?) AND terminal=1 ORDER BY rowid DESC LIMIT 100', project, id);
    for (const candidate of candidates) {
      if (candidate.id === id) throw new BadRequestException('A run cannot be its own baseline');
      const previous = await this.identity(user, project, candidate.id);
      if (!previous.key || previous.key !== current.key) { if (explicit) return empty(previous.reason ?? 'COMPARISON_IDENTITY_MISMATCH', candidate.id); continue; }
      const nodeOutcomes = (runId: string) => new Map<string, string>(this.db.all('SELECT payload FROM events WHERE run_id=? ORDER BY sequence', runId).map(r => JSON.parse(r.payload)).filter(e => e.type === 'step.finished').map(e => [e.nodeId, e.outcome]));
      const a = nodeOutcomes(candidate.id), b = nodeOutcomes(id), changedNodes = [...new Set([...a.keys(), ...b.keys()])].filter(node => a.get(node) !== b.get(node)).map(nodeId => ({nodeId, previous: a.get(nodeId) ?? 'unrun', current: b.get(nodeId) ?? 'unrun'}));
      const currentOutcome = current.run.reportedOutcome, baselineOutcome = previous.run.reportedOutcome;
      const classification = baselineOutcome === 'passed' && currentOutcome === 'failed' ? 'regression' : baselineOutcome === 'failed' && currentOutcome === 'passed' ? 'improvement' : currentOutcome === baselineOutcome ? 'unchanged' : 'changed';
      return {runId: id, baselineRunId: candidate.id, comparable: true, reason: 'VERIFIED_IDENTITY_MATCH', classification, currentOutcome, baselineOutcome, changedNodes};
    }
    return empty('NO_COMPARABLE_RUN_WITHIN_PREVIOUS_100');
  }
  async selectBaseline(user: string, project: string, id: string, baselineId: string): Promise<any> {
    this.run(user, project, id, true); const comparison = await this.compare(user, project, id, baselineId);
    if (!comparison.comparable) throw new ConflictException(`Baseline is incomparable: ${comparison.reason}`);
    this.db.transaction(() => { this.run(user, project, id, true); this.run(user, project, baselineId); this.db.exec('INSERT INTO run_baselines VALUES(?,?,?,?) ON CONFLICT(run_id) DO UPDATE SET baseline_id=excluded.baseline_id,selected_by=excluded.selected_by,selected_at=excluded.selected_at', id, baselineId, user, new Date().toISOString()); this.db.audit(project, user, 'baseline.selected', id); });
    return comparison;
  }
  enqueue(user: string, project: string, id: string): any {
    this.platform.authorize(user, project, 'qa_manager'); const run = this.run(user, project, id);
    if (!this.sink) throw new ServiceUnavailableException('Local notification fixture is not configured');
    if (!run.terminal) throw new ConflictException('Only terminal runs can be notified');
    const work = this.work(user, project, id);
    const payload = canonical({schemaVersion: 'qa.notification/v1', projectId: project, runId: id, reportedOutcome: run.outcome, evidenceStatus: run.evidence_status, workStatus: work.status, workRevision: work.revision});
    const hash = sha256(payload);
    return this.db.transaction(() => {
      const existing = this.db.get('SELECT id FROM notification_outbox WHERE run_id=? AND payload_hash=?', id, hash);
      const deliveryId = existing?.id ?? randomUUID();
      if (!existing) { this.db.exec('INSERT INTO notification_outbox VALUES(?,?,?,?,?,?,?,?,?,?,?,?)', deliveryId, id, project, user, payload, hash, 'pending', 0, Date.now(), 0, null, new Date().toISOString()); this.db.audit(project, user, 'notification.queued', deliveryId); }
      return this.notification(deliveryId);
    });
  }
  private notification(id: string): any {
    const row = this.db.get('SELECT * FROM notification_outbox WHERE id=?', id)!;
    return {id: row.id, runId: row.run_id, state: row.state, attempts: row.attempts, nextAttemptAt: new Date(row.next_at).toISOString(), lastError: row.last_error, createdAt: row.created_at};
  }
  notifications(user: string, project: string, id: string): any { this.run(user, project, id); return {items: this.db.all('SELECT id FROM notification_outbox WHERE run_id=? ORDER BY created_at DESC LIMIT 100', id).map(r => this.notification(r.id))}; }
  async drain(): Promise<void> {
    if (!this.sink || this.draining || this.stopped) return; this.draining = true;
    try {
      const row: any = this.db.transaction(() => {
        const item = this.db.get("SELECT * FROM notification_outbox WHERE state IN ('pending','retrying','sending') AND next_at<=? AND lease_until<=? ORDER BY created_at LIMIT 1", Date.now(), Date.now());
        if (!item) return;
        this.db.exec("UPDATE notification_outbox SET state='sending',attempts=attempts+1,lease_until=? WHERE id=?", Date.now() + 15000, item.id); return {...item, attempts: item.attempts + 1};
      });
      if (!row) return;
      let error: string | null = null;
      try {
        this.platform.authorize(row.actor_id, row.project_id, 'qa_manager');
        const response = await fetch(this.sink, {method: 'POST', redirect: 'error', signal: AbortSignal.timeout(5000), headers: {'content-type': 'application/json', 'idempotency-key': row.id, 'x-payload-sha256': row.payload_hash}, body: row.payload});
        await response.body?.cancel(); if (!response.ok) error = `HTTP_${response.status}`;
      } catch { error = 'DELIVERY_UNAVAILABLE_OR_PERMISSION_REVOKED'; }
      if (!this.stopped) this.db.transaction(() => { this.db.exec('UPDATE notification_outbox SET state=?,lease_until=0,next_at=?,last_error=? WHERE id=?', error ? (row.attempts >= 5 ? 'delivery_failed' : 'retrying') : 'delivered', Date.now() + Math.min(60000, 1000 * 2 ** row.attempts), error, row.id); this.db.audit(row.project_id, row.actor_id, error ? 'notification.failed' : 'notification.delivered', row.id); });
    } finally { this.draining = false; }
  }
  onModuleDestroy(): void { this.stopped = true; if (this.timer) clearInterval(this.timer); }
}
