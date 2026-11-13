import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PlatformRepository, canonical, sha256, type Row } from '../platform/platform.repository.js';
import { PlatformService } from '../platform/platform.service.js';
import { EngineContractService } from '../platform/engine-contract.service.js';
import { roles, type PageQuery, type VersionQuery } from '../platform/platform.dto.js';
import { type SuiteDraftInput, type SuiteCase } from './suite.dto.js';

@Injectable()
export class SuiteService {
  constructor(private readonly db: PlatformRepository, private readonly platform: PlatformService, private readonly engine: EngineContractService) {}
  start(): void {
    if(this.db.get('SELECT version FROM migrations WHERE version=6')) return;
    this.db.transaction(()=>{
      this.db.exec('CREATE TABLE suite_drafts(id TEXT PRIMARY KEY,project_id TEXT NOT NULL REFERENCES projects(id),package_id TEXT NOT NULL,title TEXT NOT NULL,stop_on_failure INTEGER NOT NULL,cases_json TEXT NOT NULL,author_id TEXT NOT NULL,state TEXT NOT NULL,reviewer_id TEXT,engine_version TEXT NOT NULL,contract_version TEXT NOT NULL,created_at TEXT NOT NULL)');
      this.db.exec('CREATE TABLE suite_versions(id TEXT PRIMARY KEY,project_id TEXT NOT NULL REFERENCES projects(id),package_id TEXT NOT NULL,version TEXT NOT NULL,title TEXT NOT NULL,stop_on_failure INTEGER NOT NULL,cases_json TEXT NOT NULL,hash TEXT NOT NULL,author_id TEXT NOT NULL,reviewer_id TEXT NOT NULL,engine_version TEXT NOT NULL,contract_version TEXT NOT NULL,created_at TEXT NOT NULL,draft_id TEXT NOT NULL UNIQUE REFERENCES suite_drafts(id),UNIQUE(project_id,package_id,version))');
      this.db.exec("CREATE TRIGGER immutable_suites_update BEFORE UPDATE ON suite_versions BEGIN SELECT RAISE(ABORT,'Immutable published Suite'); END");
      this.db.exec("CREATE TRIGGER immutable_suites_delete BEFORE DELETE ON suite_versions BEGIN SELECT RAISE(ABORT,'Immutable published Suite'); END");
      this.db.exec('CREATE TABLE suite_pins(user_id TEXT NOT NULL REFERENCES users(id),project_id TEXT NOT NULL REFERENCES projects(id),package_id TEXT NOT NULL,version_id TEXT NOT NULL REFERENCES suite_versions(id),hash TEXT NOT NULL,PRIMARY KEY(user_id,project_id,package_id))');
      this.db.exec('INSERT INTO migrations VALUES(6)');
    });
  }
  private row(table: 'suite_drafts'|'suite_versions',project:string,id:string):Row {
    const row=this.db.get(`SELECT * FROM ${table} WHERE project_id=? AND id=?`,project,id);if(!row)throw new NotFoundException('Suite not found');return row;
  }
  private inputs(project:string,cases:SuiteCase[]):Array<{caseId:string;versionId:string;sha256:string;xml:string}> {
    if(!Array.isArray(cases)||cases.length<1||cases.length>32||new Set(cases.map(c=>c.caseId)).size!==cases.length)throw new BadRequestException('Suite cases must have unique IDs and count 1..32');
    return cases.map(c=>{const v=this.db.get('SELECT * FROM versions WHERE project_id=? AND id=?',project,c.versionId);if(!v)throw new BadRequestException('Suite case is not a published project version');if(v.hash!==c.sha256||sha256(v.xml)!==c.sha256)throw new ConflictException('Suite case hash mismatch');if(v.engine_version!==this.engine.version)throw new ConflictException('Suite case requires explicit publication for the current Engine pin');return{caseId:c.caseId,versionId:c.versionId,sha256:c.sha256,xml:v.xml};});
  }
  private compatible(row:Row):void {if(row.engine_version!==this.engine.version||row.contract_version!==this.engine.contractVersion)throw new ConflictException('Suite Engine/contract pin is incompatible');}
  private response(row:Row):any {return{id:row.id,projectId:row.project_id,packageId:row.package_id,title:row.title,stopOnFailure:row.stop_on_failure===1,cases:JSON.parse(row.cases_json),authorId:row.author_id,reviewerId:row.reviewer_id,engineVersion:row.engine_version,contractVersion:row.contract_version,createdAt:row.created_at,...(row.version?{version:row.version,sha256:row.hash}:{state:row.state})};}
  create(user:string,project:string,input:SuiteDraftInput):any {
    return this.db.transaction(()=>{this.platform.authorize(user,project,'qa_editor');this.inputs(project,input.cases);const id=randomUUID();this.db.exec('INSERT INTO suite_drafts VALUES(?,?,?,?,?,?,?,?,?,?,?,?)',id,project,input.packageId,input.title,input.stopOnFailure?1:0,canonical(input.cases),user,'draft',null,this.engine.version,this.engine.contractVersion,new Date().toISOString());this.db.audit(project,user,'suite.draft.created',id);return this.response(this.row('suite_drafts',project,id));});
  }
  review(user:string,project:string,id:string):any {return this.db.transaction(()=>{this.platform.authorize(user,project,'qa_manager');const d=this.row('suite_drafts',project,id);if(d.author_id===user)throw new ForbiddenException('A different manager must review');if(d.state!=='draft')throw new ConflictException('Only drafts can be reviewed');this.compatible(d);this.inputs(project,JSON.parse(d.cases_json));this.db.exec("UPDATE suite_drafts SET state='reviewed',reviewer_id=? WHERE id=?",user,id);this.db.audit(project,user,'suite.reviewed',id);return this.response(this.row('suite_drafts',project,id));});}
  publish(user:string,project:string,id:string,version:string,key:string):any {
    this.platform.authorize(user,project,'qa_manager');
    return this.db.idempotent(`${project}:suite-publish:${user}`,key,{id,version},()=>{
      this.platform.authorize(user,project,'qa_manager');const d=this.row('suite_drafts',project,id);this.compatible(d);this.inputs(project,JSON.parse(d.cases_json));
      const reviewer=this.db.get('SELECT m.role FROM memberships m JOIN users u ON u.id=m.user_id WHERE u.active=1 AND m.user_id=? AND m.project_id=?',d.reviewer_id,project);
      if(d.state!=='reviewed'||d.author_id===d.reviewer_id||!reviewer||roles.indexOf(reviewer.role)<roles.indexOf('qa_manager'))throw new ConflictException('Independent active review is required');
      if(this.db.get('SELECT id FROM suite_versions WHERE project_id=? AND package_id=? AND version=?',project,d.package_id,version))throw new ConflictException('Suite version exists');
      const hash=sha256(canonical({packageId:d.package_id,version,title:d.title,cases:JSON.parse(d.cases_json),stopOnFailure:d.stop_on_failure===1,engineVersion:d.engine_version,contractVersion:d.contract_version})),published=randomUUID();
      this.db.exec('INSERT INTO suite_versions VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)',published,project,d.package_id,version,d.title,d.stop_on_failure,d.cases_json,hash,d.author_id,d.reviewer_id,d.engine_version,d.contract_version,new Date().toISOString(),id);
      this.db.exec("UPDATE suite_drafts SET state='published' WHERE id=?",id);this.db.audit(project,user,'suite.published',published);return this.response(this.row('suite_versions',project,published));
    });
  }
  get(user:string,project:string,id:string):any {this.platform.authorize(user,project);return this.response(this.row('suite_versions',project,id));}
  private page(user:string,project:string,q:VersionQuery,table:'suite_drafts'|'suite_versions'):any {
    this.platform.authorize(user,project);let cursor=0;if(q.cursor){const s=Buffer.from(q.cursor,'base64url').toString('utf8');cursor=Number(s);if(!/^[1-9]\d*$/.test(s)||!Number.isSafeInteger(cursor)||Buffer.from(s).toString('base64url')!==q.cursor)throw new BadRequestException('Invalid Suite cursor');}
    const limit=q.limit??50,rows=this.db.all(`SELECT rowid,* FROM ${table} WHERE project_id=? AND rowid>? AND (? IS NULL OR package_id=?) ORDER BY rowid LIMIT ?`,project,cursor,q.packageId??null,q.packageId??null,limit+1),selected=rows.slice(0,limit);return{items:selected.map(r=>this.response(r)),nextCursor:rows.length>limit?Buffer.from(String(selected.at(-1)!.rowid)).toString('base64url'):null};
  }
  drafts(user:string,project:string,q:PageQuery):any{return this.page(user,project,q,'suite_drafts');}
  versions(user:string,project:string,q:VersionQuery):any{return this.page(user,project,q,'suite_versions');}
  pins(user: string, project: string, query: PageQuery): any {
    this.platform.authorize(user, project);
    let cursor = 0;
    if (query.cursor) {
      const decoded = Buffer.from(query.cursor, 'base64url').toString('utf8');
      cursor = Number(decoded);
      if (!/^[1-9]\d*$/.test(decoded) || !Number.isSafeInteger(cursor) || Buffer.from(decoded).toString('base64url') !== query.cursor) throw new BadRequestException('Invalid Suite cursor');
    }
    const limit = query.limit ?? 50;
    const rows = this.db.all('SELECT rowid,package_id,version_id,hash FROM suite_pins WHERE user_id=? AND project_id=? AND rowid>? ORDER BY rowid LIMIT ?', user, project, cursor, limit + 1);
    const selected = rows.slice(0, limit);
    return { items: selected.map(row => ({ packageId: row.package_id, versionId: row.version_id, sha256: row.hash })), nextCursor: rows.length > limit ? Buffer.from(String(selected.at(-1)!.rowid)).toString('base64url') : null };
  }
  pin(user:string,project:string,id:string,hash:string):any{return this.db.transaction(()=>{this.platform.authorize(user,project,'qa_tester');const v=this.row('suite_versions',project,id);this.compatible(v);if(v.hash!==hash)throw new ConflictException('Suite pin hash mismatch');this.db.exec('INSERT INTO suite_pins VALUES(?,?,?,?,?) ON CONFLICT(user_id,project_id,package_id) DO UPDATE SET version_id=excluded.version_id,hash=excluded.hash',user,project,v.package_id,id,hash);this.db.audit(project,user,'suite.pinned',id);return{packageId:v.package_id,versionId:id,sha256:hash};});}
  resolvePublished(user:string,projectId:string,suiteVersionId:string,hash?:string):any {
    this.platform.authorize(user,projectId);const v=this.row('suite_versions',projectId,suiteVersionId);this.compatible(v);if(hash&&v.hash!==hash)throw new ConflictException('Suite version hash mismatch');
    return{suitePolicy:{stopOnFailure:v.stop_on_failure===1,publishedVersionId:v.id,publishedSha256:v.hash},cases:this.inputs(projectId,JSON.parse(v.cases_json))};
  }
}
