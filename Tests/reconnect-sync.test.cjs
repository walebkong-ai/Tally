const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const app = fs.readFileSync(path.join(__dirname, '../dist/app.js'), 'utf8');

function setup() {
  const counts = { reads: 0, writes: 0, renders: 0, delays: [] };
  const c = vm.createContext({
    storageOwner: 'b', navigator: { onLine: true },
    state: { pendingNote: 'local beta note', syncConflicts: [] },
    cloudBackend: { generation: 1, syncReady: true, error: 'old offline error', auth: { currentUser: { uid: 'b' } } },
    updateSyncStatus: () => {}, updateAccountStatus: () => {},
    saveState: () => {}, render: () => { counts.renders++; },
    window: { setTimeout: (callback, ms) => { counts.delays.push(ms); callback(); } },
    loadCloudState: async () => { counts.reads++; },
    persistCloudState: async () => { counts.writes++; return true; }
  });
  for (const name of ['cloudSession', 'accountSessionMatches', 'currentCloudSession', 'recoverAccountConnection', 'retryAccountSync', 'performAccountSyncRetry']) {
    const match = new RegExp(`(?:async )?function ${name}\\(`).exec(app);
    if (!match) continue;
    const tail = app.slice(match.index), next = /\n(?:async )?function \w+\(/.exec(tail);
    vm.runInContext(tail.slice(0, next?.index), c);
  }
  return { c, counts };
}
const unavailable = () => Object.assign(new Error('Failed to get document because the client is offline.'), { code: 'unavailable' });

test('reconnect retries temporary offline reads and clears the old error after confirmation', async () => {
  const { c, counts } = setup();
  c.loadCloudState = async () => { if (++counts.reads < 3) throw unavailable(); };
  assert.equal(await c.retryAccountSync(), true);
  assert.equal(counts.reads, 3);
  assert.equal(counts.writes, 1);
  assert.equal(counts.delays.length, 2);
  assert.equal(c.cloudBackend.error, '');
  assert.equal(c.cloudBackend.loading, false);
  assert.equal(c.cloudBackend.syncReady, true);
  assert.equal(c.state.pendingNote, 'local beta note');
});

test('overlapping reconnect events share one recovery task', async () => {
  const { c, counts } = setup();
  let finish;
  c.loadCloudState = async () => { counts.reads++; await new Promise(resolve => { finish = resolve; }); };
  const first = c.recoverAccountConnection();
  assert.equal(c.cloudBackend.syncReady, false);
  const second = c.recoverAccountConnection();
  assert.equal(first, second);
  assert.equal(counts.reads, 1);
  finish();
  await first;
  assert.equal(counts.writes, 1);
  assert.equal(c.cloudBackend.retryPromise, null);
});

test('a rejected earlier upload cannot prevent a fresh recovery read', async () => {
  const { c, counts } = setup();
  const old = Promise.reject(unavailable());
  old.catch(() => {});
  c.cloudBackend.savePromise = old;
  assert.equal(await c.retryAccountSync(), true);
  assert.equal(counts.reads, 1);
  assert.equal(counts.writes, 1);
  assert.equal(c.cloudBackend.error, '');
});

test('permission errors remain visible and are not retried as connection failures', async () => {
  const { c, counts } = setup();
  c.loadCloudState = async () => { counts.reads++; throw Object.assign(new Error('Permission denied'), { code: 'permission-denied' }); };
  await assert.rejects(c.retryAccountSync(), { code: 'permission-denied' });
  assert.equal(counts.reads, 1);
  assert.equal(counts.writes, 0);
  assert.equal(counts.delays.length, 0);
  assert.equal(c.cloudBackend.error, 'Permission denied');
  assert.equal(c.state.pendingNote, 'local beta note');
});

test('connection retries are bounded and do not confirm unsynced work', async () => {
  const { c, counts } = setup();
  c.loadCloudState = async () => { counts.reads++; throw unavailable(); };
  await assert.rejects(c.retryAccountSync(), { code: 'unavailable' });
  assert.equal(counts.reads, 4);
  assert.equal(counts.delays.length, 3);
  assert.equal(counts.writes, 0);
  assert.equal(c.cloudBackend.syncReady, false);
  assert.equal(c.cloudBackend.loading, false);
  assert.match(c.cloudBackend.error, /offline/);
});

test('account switching during a reconnect delay discards the old recovery', async () => {
  const { c, counts } = setup();
  let wake;
  c.window.setTimeout = callback => { wake = callback; };
  c.loadCloudState = async () => { counts.reads++; throw unavailable(); };
  const recovery = c.retryAccountSync();
  await new Promise(resolve => setImmediate(resolve));
  assert.equal(typeof wake, 'function');
  c.storageOwner = 'a'; c.cloudBackend.auth.currentUser.uid = 'a'; c.cloudBackend.generation++;
  c.cloudBackend.error = 'new account status'; c.cloudBackend.loading = false;
  const newerRecovery = {}; c.cloudBackend.retryPromise = newerRecovery;
  wake();
  assert.equal(await recovery, false);
  assert.equal(counts.reads, 1);
  assert.equal(counts.writes, 0);
  assert.equal(counts.renders, 0);
  assert.equal(c.cloudBackend.error, 'new account status');
  assert.equal(c.cloudBackend.retryPromise, newerRecovery);
});
