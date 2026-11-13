import { Injectable } from '@nestjs/common';
import { PlatformRepository, canonical, sha256 } from '../platform/platform.repository.js';

@Injectable()
export class AgentRepository {
  constructor(readonly db: PlatformRepository) {}
  migrate(): void {
    if (this.db.get('SELECT version FROM migrations WHERE version=2')) return;
    this.db.transaction(() => {
      for (const sql of [
        `CREATE TABLE agents(id TEXT PRIMARY KEY,token_hash TEXT NOT NULL UNIQUE,active INTEGER NOT NULL,projects TEXT NOT NULL,capabilities TEXT NOT NULL,resource_keys TEXT NOT NULL,engine_version TEXT NOT NULL,contract_version TEXT NOT NULL,contract_hash TEXT NOT NULL,owner_instance TEXT,quarantined INTEGER NOT NULL DEFAULT 0)`,
        `CREATE TABLE agent_instances(agent_id TEXT NOT NULL REFERENCES agents(id),instance_id TEXT NOT NULL,state TEXT NOT NULL,created_at TEXT NOT NULL,PRIMARY KEY(agent_id,instance_id))`,
        `CREATE TABLE agent_resources(resource_key TEXT PRIMARY KEY,fence INTEGER NOT NULL DEFAULT 0,lease_id TEXT)`,
        `CREATE TABLE agent_jobs(id TEXT PRIMARY KEY,project_id TEXT NOT NULL REFERENCES projects(id),job_attempt INTEGER NOT NULL,state TEXT NOT NULL,resource_key TEXT NOT NULL REFERENCES agent_resources(resource_key),policy TEXT NOT NULL,cases_json TEXT NOT NULL,plans_json TEXT NOT NULL,suite_policy TEXT NOT NULL,lease_id TEXT,created_at TEXT NOT NULL,deadline_at TEXT)`,
        `CREATE TABLE agent_leases(id TEXT PRIMARY KEY,agent_id TEXT NOT NULL REFERENCES agents(id),instance_id TEXT NOT NULL,execution_id TEXT NOT NULL UNIQUE REFERENCES agent_jobs(id),fence INTEGER NOT NULL,state TEXT NOT NULL,expires_at INTEGER NOT NULL,cleanup_state TEXT NOT NULL DEFAULT 'unknown',accepted_through INTEGER NOT NULL DEFAULT 0,cancel_requested INTEGER NOT NULL DEFAULT 0,completion_json TEXT,completion_hash TEXT,completion_receipt TEXT,receipt_acked INTEGER NOT NULL DEFAULT 0,created_at TEXT NOT NULL)`,
        `CREATE TABLE agent_claims(agent_id TEXT NOT NULL REFERENCES agents(id),claim_id TEXT NOT NULL,instance_id TEXT NOT NULL,hash TEXT NOT NULL,lease_id TEXT REFERENCES agent_leases(id),PRIMARY KEY(agent_id,claim_id))`,
        `CREATE TABLE agent_deliveries(lease_id TEXT NOT NULL REFERENCES agent_leases(id),sequence INTEGER NOT NULL,case_id TEXT NOT NULL,payload TEXT NOT NULL,hash TEXT NOT NULL,PRIMARY KEY(lease_id,sequence))`,
        `CREATE TABLE agent_case_runs(lease_id TEXT NOT NULL REFERENCES agent_leases(id),case_id TEXT NOT NULL,run_id TEXT NOT NULL REFERENCES runs(id),PRIMARY KEY(lease_id,case_id))`,
        `CREATE TABLE agent_resource_bytes(id TEXT PRIMARY KEY,job_id TEXT NOT NULL REFERENCES agent_jobs(id),case_id TEXT NOT NULL,name TEXT NOT NULL,hash TEXT NOT NULL,size INTEGER NOT NULL,mime TEXT NOT NULL,bytes BLOB NOT NULL,UNIQUE(job_id,case_id,name))`,
        `CREATE TABLE agent_history(id TEXT PRIMARY KEY,lease_id TEXT NOT NULL REFERENCES agent_leases(id),request_id TEXT NOT NULL,hash TEXT NOT NULL,owner_instance TEXT NOT NULL,reporting_instance TEXT NOT NULL,payload TEXT NOT NULL,created_at TEXT NOT NULL,UNIQUE(lease_id,request_id))`,
        `INSERT INTO migrations(version) VALUES(2)`,
      ]) this.db.exec(sql);
    });
  }
  recoverAfterRestart(): void {
    this.db.transaction(() => {
      this.db.exec("UPDATE agent_leases SET state='quarantined' WHERE state IN ('active','reporting')");
      this.db.exec("UPDATE agents SET quarantined=1 WHERE EXISTS(SELECT 1 FROM agent_leases l WHERE l.agent_id=agents.id AND l.state IN ('expired','quarantined'))");
    });
  }
  migrateHistory(): void {
    if (this.db.get('SELECT version FROM migrations WHERE version=5')) return;
    this.db.transaction(() => {
      this.db.exec('CREATE TABLE agent_history_artifacts(lease_id TEXT NOT NULL REFERENCES agent_leases(id),case_id TEXT NOT NULL,path TEXT NOT NULL,hash TEXT NOT NULL,size INTEGER NOT NULL,mime TEXT NOT NULL,bytes BLOB NOT NULL,PRIMARY KEY(lease_id,case_id,path))');
      for (const history of this.db.all('SELECT id,lease_id,payload FROM agent_history')) {
        const body = JSON.parse(history.payload), artifact = body.artifact;
        if (!artifact?.base64) continue;
        const bytes = Buffer.from(artifact.base64,'base64');
        if (bytes.length !== artifact.size || sha256(bytes) !== artifact.sha256) throw new Error('Historical artifact migration integrity mismatch');
        const previous = this.db.get('SELECT hash FROM agent_history_artifacts WHERE lease_id=? AND case_id=? AND path=?',history.lease_id,artifact.caseId,artifact.path);
        if (previous && previous.hash !== artifact.sha256) throw new Error('Historical artifact migration identity conflict');
        if (!previous) this.db.exec('INSERT INTO agent_history_artifacts VALUES(?,?,?,?,?,?,?)',history.lease_id,artifact.caseId,artifact.path,artifact.sha256,artifact.size,artifact.mimeType,bytes);
        delete artifact.base64; this.db.exec('UPDATE agent_history SET payload=? WHERE id=?',canonical(body),history.id);
      }
      this.db.exec('INSERT INTO migrations(version) VALUES(5)');
    });
  }
  migrateRecovery(): void {
    if (this.db.get('SELECT version FROM migrations WHERE version=8')) return;
    this.db.transaction(() => {
      this.db.exec('CREATE TABLE operator_recoveries(id TEXT PRIMARY KEY,project_id TEXT NOT NULL,request_id TEXT NOT NULL,payload_hash TEXT NOT NULL,lease_id TEXT NOT NULL UNIQUE REFERENCES agent_leases(id),actor_id TEXT NOT NULL,reason TEXT NOT NULL,resource_key TEXT NOT NULL,prior_fence INTEGER NOT NULL,new_fence INTEGER NOT NULL,confirmed_at TEXT NOT NULL,UNIQUE(project_id,request_id))');
      this.db.exec('INSERT INTO migrations(version) VALUES(8)');
    });
  }
  migrateJobPins(): void {
    if (this.db.get('SELECT version FROM migrations WHERE version=9')) return;
    this.db.transaction(() => {
      for (const column of ['engine_version','contract_version','contract_hash','block_reason']) this.db.exec(`ALTER TABLE agent_jobs ADD COLUMN ${column} TEXT`);
      for (const job of this.db.all('SELECT j.id,j.plans_json,a.engine_version,a.contract_version,a.contract_hash FROM agent_jobs j JOIN agent_leases l ON l.id=j.lease_id JOIN agents a ON a.id=l.agent_id')) {
        if ((Object.values(JSON.parse(job.plans_json)) as any[]).every(plan => plan.engineVersion === job.engine_version)) this.db.exec('UPDATE agent_jobs SET engine_version=?,contract_version=?,contract_hash=? WHERE id=?',job.engine_version,job.contract_version,job.contract_hash,job.id);
      }
      this.db.exec("UPDATE agent_jobs SET state='blocked',block_reason='legacy_contract_pin_missing' WHERE state='queued' AND contract_hash IS NULL");
      this.db.exec('INSERT INTO migrations(version) VALUES(9)');
    });
  }
}
