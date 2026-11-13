import test from 'node:test';
import assert from 'node:assert/strict';
import { AdministrationApi, Configuration, ManagedUserResponseFromJSON, ManagedUserResponseToJSON, ManagedMembershipStateFromJSON, ManagedMembershipStateToJSON, ManagedUserCreateToJSON, ManagedUserUpdateToJSON, validateModel, ContractFailure } from '../dist/index.js';

test('generated administration models preserve nullable identity metadata and removed membership state', () => {
  const user = { userId: 'member', displayName: null, active: true, role: 'qa_tester', userRevision: 0, membershipRevision: 3 };
  const removed = { userId: 'member', role: null, membershipRevision: 4 };
  validateModel('ManagedUserResponse', user); validateModel('ManagedMembershipState', removed);
  assert.deepEqual(ManagedUserResponseToJSON(ManagedUserResponseFromJSON(user)), user);
  assert.deepEqual(ManagedMembershipStateToJSON(ManagedMembershipStateFromJSON(removed)), removed);
  assert.deepEqual(ManagedUserCreateToJSON({ userId: 'member', displayName: null, role: 'viewer' }), { userId: 'member', displayName: null, role: 'viewer' });
  for (const bad of [{ ...user, displayName: undefined }, { ...user, userRevision: -1 }, { ...user, role: 'owner' }]) assert.throws(() => validateModel('ManagedUserResponse', bad), ContractFailure);
  assert.throws(() => validateModel('ManagedMembershipState', { userId: 'member', membershipRevision: 4 }), ContractFailure);
});

test('generated administration API retains revision, explicit clearing and project-scoped encoded paths', async () => {
  const calls = [];
  const api = new AdministrationApi(new Configuration({ basePath: 'http://127.0.0.1', accessToken: 'fixture-not-secret', fetchApi: async (url, init) => {
    calls.push({ url, init });
    return Response.json({ userId: 'member', displayName: null, active: true, role: 'viewer', userRevision: 2, membershipRevision: 0 });
  } }));
  await api.updateManagedProjectUser({ projectId: 'project/a', userId: 'member', managedUserUpdate: { userRevision: 1, clearDisplayName: true } });
  assert.equal(calls[0].url, 'http://127.0.0.1/api/v1/projects/project%2Fa/administration/users/member');
  assert.equal(calls[0].init.method, 'PATCH');
  assert.deepEqual(JSON.parse(calls[0].init.body), { clearDisplayName: true, userRevision: 1 });
  assert.deepEqual(JSON.parse(JSON.stringify(ManagedUserUpdateToJSON({ active: false, userRevision: 2 }))), { active: false, userRevision: 2 });
});
