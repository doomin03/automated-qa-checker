import { randomBytes } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

export async function demoIdentities(directory, managerToken) {
  const file = join(directory, 'reviewer-token.txt'); let reviewerToken;
  try { reviewerToken = (await readFile(file, 'utf8')).trim(); }
  catch (error) { if (error.code !== 'ENOENT') throw error; reviewerToken = randomBytes(32).toString('base64url'); try { await writeFile(file, reviewerToken, { flag: 'wx', mode: 0o600 }); } catch (e) { if (e.code !== 'EEXIST') throw e; reviewerToken = (await readFile(file, 'utf8')).trim(); } }
  return { users: [{ id: 'demo-manager', token: managerToken, active: true }, { id: 'demo-reviewer', token: reviewerToken, active: true }], projects: [{ id: 'demo', name: 'Agent local demo' }], memberships: ['demo-manager', 'demo-reviewer'].map(userId => ({ userId, projectId: 'demo', role: 'qa_manager' })) };
}
