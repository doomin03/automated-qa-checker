import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { randomBytes } from 'node:crypto';
import { PlatformRepository, sha256, type Row } from '../platform/platform.repository.js';
import { PlatformService } from '../platform/platform.service.js';
import { roles, type PageQuery, type Role } from '../platform/platform.dto.js';
import { IdentityStorageNotManaged } from './administration.errors.js';
import type { AdministrationStatus, ManagedUserCreate, ManagedUserPage, ManagedUserResponse, ManagedUserUpdate, ManagedMembershipUpdate, ManagedMembershipState } from './administration.dto.js';

@Injectable()
export class AdministrationService {
  constructor(private readonly db: PlatformRepository, private readonly platform: PlatformService) {}

  status(actor: string, project: string): AdministrationStatus {
    this.platform.authorize(actor, project, 'qa_manager');
    const identityStorage = this.db.identityStorage;
    return { identityStorage, mutationSupported: identityStorage === 'managed' };
  }
  private writable(actor: string, project: string, minimum: Role = 'qa_manager'): Role {
    const role = this.platform.authorize(actor, project, minimum);
    if (this.db.identityStorage !== 'managed') throw new IdentityStorageNotManaged();
    return role;
  }
  private cursor(value?: string): number {
    if (value === undefined) return 0;
    const text = Buffer.from(value, 'base64url').toString('utf8');
    const number = Number(text);
    if (!/^[1-9]\d*$/.test(text) || !Number.isSafeInteger(number) || Buffer.from(text).toString('base64url') !== value) throw new BadRequestException('Invalid administration cursor');
    return number;
  }
  private row(project: string, user: string): Row {
    const row = this.db.get('SELECT u.id,u.active,a.display_name,a.revision AS user_revision,m.role,h.revision AS membership_revision FROM memberships m JOIN users u ON u.id=m.user_id JOIN managed_users a ON a.user_id=u.id JOIN managed_memberships h ON h.user_id=m.user_id AND h.project_id=m.project_id WHERE m.project_id=? AND m.user_id=?', project, user);
    if (!row) throw new NotFoundException('Project member not found');
    return row;
  }
  private response(row: Row): ManagedUserResponse {
    return { userId: row.id, displayName: row.display_name, active: row.active === 1, role: row.role, userRevision: row.user_revision, membershipRevision: row.membership_revision };
  }
  list(actor: string, project: string, query: PageQuery): ManagedUserPage {
    this.platform.authorize(actor, project, 'qa_manager');
    const limit = query.limit ?? 50;
    const rows = this.db.all('SELECT h.rowid,h.user_id FROM managed_memberships h JOIN memberships m ON m.user_id=h.user_id AND m.project_id=h.project_id WHERE h.project_id=? AND h.rowid>? ORDER BY h.rowid LIMIT ?', project, this.cursor(query.cursor), limit + 1);
    const selected = rows.slice(0, limit);
    return { items: selected.map(r => this.response(this.row(project, r.user_id))), nextCursor: rows.length > limit ? Buffer.from(String(selected.at(-1)!.rowid)).toString('base64url') : null };
  }
  membership(actor: string, project: string, user: string): ManagedMembershipState {
    this.platform.authorize(actor, project, 'qa_manager');
    const record = this.db.get('SELECT h.revision,m.role FROM managed_memberships h LEFT JOIN memberships m ON m.project_id=h.project_id AND m.user_id=h.user_id WHERE h.project_id=? AND h.user_id=?', project, user);
    if (!record) throw new NotFoundException('Project membership history not found');
    return { userId: user, role: record.role ?? null, membershipRevision: record.revision };
  }
  private revision(actual: number, expected: number): number {
    if (!Number.isSafeInteger(expected) || actual !== expected || actual >= Number.MAX_SAFE_INTEGER) throw new ConflictException('Administrative revision conflict');
    return actual + 1;
  }
  private administratorCounts(project: string): { system: number; manager: number } {
    const rows = this.db.all("SELECT m.role FROM memberships m JOIN users u ON u.id=m.user_id WHERE m.project_id=? AND u.active=1 AND m.role IN ('qa_manager','system_admin')", project);
    return { system: rows.filter(r => r.role === 'system_admin').length, manager: rows.length };
  }
  private preserveAdministrators(project: string, previous: { system: number; manager: number }): void {
    const next = this.administratorCounts(project);
    if ((previous.system > 0 && next.system === 0) || (previous.manager > 0 && next.manager === 0)) throw new ConflictException('The last active administrator cannot be removed');
  }
  create(actor: string, project: string, input: ManagedUserCreate, key: string): ManagedUserResponse {
    return this.db.transaction(() => {
      this.writable(actor, project, 'system_admin');
      return this.db.idempotent(`${project}:managed-user:${actor}`, key, input, () => {
      if (this.db.get('SELECT id FROM users WHERE id=?', input.userId)) throw new ConflictException('User identifier is unavailable');
      // Non-recoverable random credential: this API never issues authentication secrets.
      this.db.exec('INSERT INTO users VALUES(?,?,1)', input.userId, sha256(randomBytes(32)));
      this.db.exec('INSERT INTO managed_users VALUES(?,?,0)', input.userId, input.displayName);
      this.db.exec('INSERT INTO memberships VALUES(?,?,?)', input.userId, project, input.role);
      this.db.exec('INSERT INTO managed_memberships VALUES(?,?,0)', input.userId, project);
      this.db.audit(project, actor, 'administration.user.created.r0', input.userId);
      return this.response(this.row(project, input.userId));
      });
    });
  }
  updateUser(actor: string, project: string, user: string, input: ManagedUserUpdate): ManagedUserResponse {
    return this.db.transaction(() => {
      this.writable(actor, project, 'system_admin');
      if (actor === user) throw new ForbiddenException('Self administration is not allowed');
      if (input.displayName !== undefined && input.clearDisplayName !== undefined) throw new BadRequestException('Display name and clear intent are mutually exclusive');
      if (input.active === undefined && input.displayName === undefined && input.clearDisplayName !== true) throw new BadRequestException('No administrative change supplied');
      const current = this.row(project, user);
      const revision = this.revision(current.user_revision, input.userRevision);
      const projects = this.db.all('SELECT project_id FROM memberships WHERE user_id=?', user).map(r => String(r.project_id));
      const counts = new Map(projects.map(p => {
        this.platform.authorize(actor, p, 'system_admin');
        return [p, this.administratorCounts(p)] as const;
      }));
      if (input.active !== undefined) this.db.exec('UPDATE users SET active=? WHERE id=?', input.active ? 1 : 0, user);
      this.db.exec('UPDATE managed_users SET display_name=?,revision=? WHERE user_id=?', input.clearDisplayName === true ? null : input.displayName === undefined ? current.display_name : input.displayName, revision, user);
      for (const [p, count] of counts) this.preserveAdministrators(p, count);
      if (input.active === false) {
        for (const table of ['auth_sessions', 'desktop_codes']) if (this.db.get("SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", table)) this.db.exec(`DELETE FROM ${table} WHERE user_id=?`, user);
      }
      for (const p of projects) this.db.audit(p, actor, `administration.user.updated.r${revision}`, user);
      return this.response(this.row(project, user));
    });
  }
  updateMembership(actor: string, project: string, user: string, input: ManagedMembershipUpdate): ManagedUserResponse {
    return this.db.transaction(() => {
      const actorRole = this.writable(actor, project);
      if (actor === user) throw new ForbiddenException('Self administration is not allowed');
      const previous = this.db.get('SELECT role FROM memberships WHERE project_id=? AND user_id=?', project, user);
      if (actorRole !== 'system_admin' && (!previous || roles.indexOf(previous.role) >= roles.indexOf('qa_manager') || roles.indexOf(input.role) >= roles.indexOf('qa_manager'))) throw new ForbiddenException('Only lower roles may be managed');
      if (!this.db.get('SELECT id FROM users WHERE id=?', user)) throw new NotFoundException('User identifier is unavailable');
      const recorded = this.db.get('SELECT revision FROM managed_memberships WHERE project_id=? AND user_id=?', project, user);
      const revision = this.revision(recorded?.revision ?? 0, input.membershipRevision);
      const count = this.administratorCounts(project);
      this.db.exec('INSERT INTO memberships VALUES(?,?,?) ON CONFLICT(user_id,project_id) DO UPDATE SET role=excluded.role', user, project, input.role);
      this.db.exec('INSERT INTO managed_memberships VALUES(?,?,?) ON CONFLICT(user_id,project_id) DO UPDATE SET revision=excluded.revision', user, project, revision);
      this.preserveAdministrators(project, count);
      this.db.audit(project, actor, `administration.membership.updated.r${revision}`, user);
      return this.response(this.row(project, user));
    });
  }
  removeMembership(actor: string, project: string, user: string, expected: number): ManagedMembershipState {
    return this.db.transaction(() => {
      const actorRole = this.writable(actor, project);
      if (actor === user) throw new ForbiddenException('Self administration is not allowed');
      const current = this.row(project, user);
      if (actorRole !== 'system_admin' && roles.indexOf(current.role) >= roles.indexOf('qa_manager')) throw new ForbiddenException('Only lower roles may be managed');
      const revision = this.revision(current.membership_revision, expected);
      const count = this.administratorCounts(project);
      this.db.exec('DELETE FROM memberships WHERE project_id=? AND user_id=?', project, user);
      this.db.exec('UPDATE managed_memberships SET revision=? WHERE project_id=? AND user_id=?', revision, project, user);
      this.preserveAdministrators(project, count);
      this.db.audit(project, actor, `administration.membership.removed.r${revision}`, user);
      return { userId: user, role: null, membershipRevision: revision };
    });
  }
}
