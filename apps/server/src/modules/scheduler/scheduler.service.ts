import { BadRequestException, Injectable, NotFoundException, OnModuleDestroy } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PlatformRepository, canonical, type Row } from '../platform/platform.repository.js';
import { PlatformService } from '../platform/platform.service.js';
import { AgentService, type PreparedExecution } from '../agent/agent.service.js';
import type { PageQuery } from '../platform/platform.dto.js';
import type { ExecutionInput, ScheduleInput } from './scheduler.dto.js';
import { localDate, localInstants } from './weekly-time.js';

@Injectable()
export class SchedulerService implements OnModuleDestroy {
  private timer?: NodeJS.Timeout;
  clock: () => number = () => Date.now();
  constructor(private readonly db: PlatformRepository, private readonly platform: PlatformService, private readonly agents: AgentService) {}
  start(timer = true): void {
    if (!this.db.get('SELECT version FROM migrations WHERE version=7')) this.db.transaction(() => {
      this.db.exec('CREATE TABLE schedules(id TEXT PRIMARY KEY,project_id TEXT NOT NULL REFERENCES projects(id),creator_id TEXT NOT NULL,config TEXT NOT NULL,prepared TEXT NOT NULL,enabled INTEGER NOT NULL,created_at INTEGER NOT NULL,last_scanned_at INTEGER NOT NULL)');
      this.db.exec('CREATE TABLE schedule_occurrences(id TEXT PRIMARY KEY,schedule_id TEXT NOT NULL REFERENCES schedules(id),local_date TEXT NOT NULL,occurrence_at TEXT,execution_id TEXT REFERENCES agent_jobs(id),state TEXT NOT NULL,reason TEXT,UNIQUE(schedule_id,local_date),UNIQUE(schedule_id,occurrence_at))');
      this.db.exec('INSERT INTO migrations(version) VALUES(7)');
    });
    this.tick(); if (timer) { this.timer = setInterval(() => { try { this.tick(); } catch { /* A failed DB tick remains due and is retried; never advance its cursor. */ } }, 1000); this.timer.unref(); }
  }
  onModuleDestroy(): void { clearInterval(this.timer); }
  private row(user: string, project: string, id: string, write = false): Row { this.platform.authorize(user, project, write ? 'qa_tester' : 'viewer'); return this.db.get('SELECT * FROM schedules WHERE id=? AND project_id=?', id, project) ?? (() => { throw new NotFoundException('Schedule not found'); })(); }
  private response(row: Row): any { return { ...JSON.parse(row.config), id: row.id, projectId: row.project_id, createdBy: row.creator_id, enabled: !!row.enabled, createdAt: new Date(row.created_at).toISOString(), lastScannedAt: new Date(row.last_scanned_at).toISOString() }; }
  private offset(cursor?: string): number { if (!cursor) return 0; const text = Buffer.from(cursor,'base64url').toString(); if (!/^[1-9]\d*$/.test(text) || Buffer.from(text).toString('base64url') !== cursor) throw new BadRequestException('Invalid cursor'); return Number(text); }
  private page(rows: Row[], query: PageQuery, map: (row: Row) => any): any { const limit = query.limit ?? 50, selected = rows.slice(0,limit); return { items: selected.map(map), nextCursor: rows.length > limit ? Buffer.from(String(selected.at(-1)!.rowid)).toString('base64url') : null }; }
  async create(user: string, project: string, input: ScheduleInput): Promise<any> {
    try { new Intl.DateTimeFormat('en', { timeZone: input.timezone }).format(); } catch { throw new BadRequestException('Unknown IANA timezone'); }
    const prepared = await this.agents.preparePublished(user, project, input); const id = randomUUID(), time = this.clock();
    this.db.transaction(() => { this.platform.authorize(user, project, 'qa_tester'); this.db.exec('INSERT INTO schedules VALUES(?,?,?,?,?,?,?,?)', id,project,user,canonical(input),canonical(prepared),input.enabled ? 1 : 0,time,time); this.db.audit(project,user,'schedule.created',id); });
    return this.response(this.row(user,project,id));
  }
  list(user: string, project: string, query: PageQuery): any { this.platform.authorize(user,project); return this.page(this.db.all('SELECT rowid,* FROM schedules WHERE project_id=? AND rowid>? ORDER BY rowid LIMIT ?',project,this.offset(query.cursor),(query.limit ?? 50)+1),query,row => this.response(row)); }
  setEnabled(user: string, project: string, id: string, enabled: boolean): any {
    const previous = this.row(user,project,id,true);
    if (!!previous.enabled === enabled) return this.response(previous);
    return this.db.transaction(() => {
      this.db.exec('UPDATE schedules SET enabled=?,last_scanned_at=? WHERE id=?',enabled ? 1 : 0,this.clock(),id);
      if (!enabled) for (const occurrence of this.db.all('SELECT execution_id FROM schedule_occurrences WHERE schedule_id=? AND execution_id IS NOT NULL',id)) this.agents.cancel(user,project,occurrence.execution_id);
      this.db.audit(project,user,enabled ? 'schedule.enabled' : 'schedule.disabled',id); return this.response(this.row(user,project,id));
    });
  }
  occurrences(user: string, project: string, id: string, query: PageQuery): any {
    this.row(user,project,id);
    return this.page(this.db.all('SELECT rowid,* FROM schedule_occurrences WHERE schedule_id=? AND rowid>? ORDER BY rowid LIMIT ?',id,this.offset(query.cursor),(query.limit ?? 50)+1),query,row => {
      const job = row.execution_id ? this.db.get('SELECT state FROM agent_jobs WHERE id=?',row.execution_id) : null;
      return { id: row.id,scheduleId: id,localDate: row.local_date,occurrenceAt: row.occurrence_at,executionId: row.execution_id,state: job?.state ?? row.state,reason: job?.state === 'missed' ? 'no_eligible_agent_or_resource' : row.reason };
    });
  }
  tick(): void {
    const time = this.clock();
    this.db.transaction(() => {
      this.db.exec("UPDATE agent_jobs SET state='missed' WHERE state='queued' AND deadline_at IS NOT NULL AND deadline_at<=?",new Date(time).toISOString());
      for (const schedule of this.db.all('SELECT * FROM schedules WHERE enabled=1')) {
        try { this.db.transaction(() => {
        if (time <= schedule.last_scanned_at) return;
        const input = JSON.parse(schedule.config), prepared = JSON.parse(schedule.prepared) as PreparedExecution;
        const from = Math.max(schedule.last_scanned_at,time - 7*86400000);
        if (from > schedule.last_scanned_at) this.db.audit(schedule.project_id,schedule.creator_id,'schedule.catchup.older_interval_missed',schedule.id);
        let date = localDate(from,input.timezone); const end = localDate(time,input.timezone);
        for (; date <= end; date = new Date(Date.parse(`${date}T00:00:00Z`) + 86400000).toISOString().slice(0,10)) {
          const weekday = new Date(`${date}T00:00:00Z`).getUTCDay() || 7; if (!input.weekdays.includes(weekday)) continue;
          const instants = localInstants(date,input.localTime,input.timezone), instant = instants[0];
          if (instant !== undefined && (instant <= from || instant > time)) continue;
          // For a gap, record after the missing local minute would have elapsed; never move it forward.
          if (instant === undefined) {
            const format = new Intl.DateTimeFormat('en-GB',{timeZone:input.timezone,hour:'2-digit',minute:'2-digit',hourCycle:'h23'});
            if (date === end && format.format(time) < input.localTime) continue;
            if (date === localDate(from,input.timezone) && format.format(from) >= input.localTime) continue;
          }
          if (this.db.get('SELECT id FROM schedule_occurrences WHERE schedule_id=? AND local_date=?',schedule.id,date)) continue;
          const deadline = instant === undefined ? null : instant + input.latenessSeconds*1000;
          let reason: string | null = instant === undefined ? 'dst_nonexistent_time' : deadline! <= time ? 'scheduler_late' : !this.agents.compatible(prepared) ? 'engine_pin_incompatible' : null;
          // A removed creator cannot continue enqueueing privileged work.
          try { this.platform.authorize(schedule.creator_id,schedule.project_id,'qa_tester'); } catch { reason = 'creator_membership_revoked'; }
          const executionId = reason ? null : this.agents.queuePrepared(schedule.creator_id,prepared,new Date(deadline!).toISOString());
          this.db.exec('INSERT INTO schedule_occurrences VALUES(?,?,?,?,?,?,?)',randomUUID(),schedule.id,date,instant === undefined ? null : new Date(instant).toISOString(),executionId,reason ? 'missed' : 'queued',reason);
        }
        this.db.exec('UPDATE schedules SET last_scanned_at=? WHERE id=?',time,schedule.id);
        }); } catch { this.db.audit(schedule.project_id,schedule.creator_id,'schedule.tick.failed',schedule.id); }
      }
    });
  }
  async createExecution(user: string, project: string, input: ExecutionInput): Promise<any> { const prepared = await this.agents.preparePublished(user,project,input); const id = this.db.transaction(() => { this.platform.authorize(user,project,'qa_tester'); return this.agents.queuePrepared(user,prepared); }); return this.execution(user,project,id); }
  execution(user: string, project: string, id: string): any {
    const role = this.platform.authorize(user,project); const job = this.db.get('SELECT * FROM agent_jobs WHERE id=? AND project_id=?',id,project); if (!job) throw new NotFoundException('Execution not found');
    const lease = job.lease_id ? this.db.get('SELECT * FROM agent_leases WHERE id=?',job.lease_id) : null;
    const completion = lease?.completion_json ? JSON.parse(lease.completion_json) : null;
    const manager = role === 'qa_manager' || role === 'system_admin';
    const recovery = manager && lease ? this.db.get('SELECT * FROM operator_recoveries WHERE lease_id=?',lease.id) : null;
    const operational = { resourceKey:manager ? job.resource_key : null,fence:manager ? lease?.fence ?? null : null,cleanupState:manager ? lease?.cleanup_state ?? null : null,operatorRecovery:recovery ? {id:recovery.id,confirmedAt:recovery.confirmed_at,priorFence:recovery.prior_fence,newFence:recovery.new_fence} : null };
    const caseRuns = lease ? this.db.all('SELECT case_id,run_id FROM agent_case_runs WHERE lease_id=? ORDER BY rowid',lease.id).map(r => ({caseId:r.case_id,runId:r.run_id})) : [];
    return { id:job.id,projectId:project,...operational,state:lease && ['expired','quarantined','reporting'].includes(lease.state) ? lease.state : job.state,reason:job.block_reason ?? (job.state==='missed' ? 'no_eligible_agent_or_resource' : completion?.reason ?? null),leaseId:job.lease_id,cancelRequested:!!lease?.cancel_requested,reportedExecutionStatus:completion?.executionStatus ?? null,evidenceStatus:lease ? lease.state==='closed' ? 'verified' : 'pending' : null,cases:JSON.parse(job.cases_json),caseRuns,createdAt:job.created_at,deadlineAt:job.deadline_at };
  }
  executions(user: string, project: string, query: PageQuery): any { this.platform.authorize(user,project); return this.page(this.db.all('SELECT rowid,* FROM agent_jobs WHERE project_id=? AND rowid>? ORDER BY rowid LIMIT ?',project,this.offset(query.cursor),(query.limit ?? 50)+1),query,row => this.execution(user,project,row.id)); }
  cancelExecution(user: string, project: string, id: string): any { this.agents.cancel(user,project,id); return this.execution(user,project,id); }
}
