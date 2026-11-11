const { test } = require("node:test");
const assert = require("node:assert/strict");
const m = require("../Assets/account-management.mjs");
const safety = require("../Assets/sync-safety.mjs");
const entry = {
  score: "3/6",
  result: "solved",
  source: "manual",
  reveal: false,
  answer: "private",
  note: "note",
  shareText: "raw",
  grid: [],
};
function state() {
  return {
    account: {
      uid: "a",
      email: "a@example.test",
      provider: "Google",
      accessToken: "NEVER",
    },
    profile: { name: "A", handle: "@a" },
    games: [],
    entries: {
      "2026-11-09": {
        wordle: {
          you: entry,
          friend: { score: "1/6", shareText: "PEER SECRET" },
        },
      },
    },
    friends: [],
    cloudBase: {},
    syncConflicts: [],
  };
}
test("exports own scores and explicit account fields, never peer caches or tokens", () => {
  const data = m.makeExport(state());
  const text = JSON.stringify(data);
  assert.equal(data.scores["2026-11-09"].wordle.score, "3/6");
  assert.equal(data.coverage, "device-copy");
  assert.equal(data.cloudRecords, null);
  assert.ok(!text.includes("PEER SECRET"));
  assert.ok(!text.includes("accessToken"));
  assert.ok(!text.includes("NEVER"));
  const full = m.makeExport(state(), {
    records: { profile: { kind: "profile" } },
    coverage: "account-and-device",
  });
  assert.equal(full.cloudRecords.profile.kind, "profile");
});
test("score correction rejects occupied, future, impossible and unchanged dates", () => {
  const s = state();
  s.entries["2026-11-08"] = { wordle: { you: { ...entry, score: "5/6" } } };
  for (const date of [
    "2026-11-08",
    "2026-11-09",
    "2026-11-11",
    "2026-02-31",
    "garbage",
  ])
    assert.throws(() =>
      m.validateScoreChange(s, "wordle", "2026-11-09", date, "2026-11-10"),
    );
  assert.deepEqual(
    m.validateScoreChange(
      s,
      "wordle",
      "2026-11-09",
      "2026-11-07",
      "2026-11-10",
    ),
    entry,
  );
  assert.deepEqual(
    m.validateScoreChange(s, "wordle", "2026-11-09", "", "2026-11-10"),
    entry,
  );
});
test("sync summaries never confirm pending, offline, failed, conflicting or deleting work", () => {
  const base = { signedIn: true, online: true, ready: true };
  assert.equal(m.syncSummary(base).label, "Changes synced");
  for (const extra of [
    { pending: 1 },
    { online: false },
    { saving: true },
    { loading: true },
    { error: "network" },
    { conflicts: 1 },
    { deleting: true },
    { storageError: "quota" },
  ])
    assert.notEqual(m.syncSummary({ ...base, ...extra }).tone, "success");
  assert.equal(
    m.syncSummary({ signedIn: false }).label,
    "Saved on this device",
  );
});
test("account storage purge preserves guest, other account, config and unrelated keys", () => {
  const values = new Map([
    ["scope:guest", "guest"],
    ["scope:account:a", "a"],
    ["scope:account:a:draft:1", "draft"],
    ["scope:account:b", "b"],
    ["legacy", JSON.stringify({ account: { uid: "a" } })],
    ["otherlegacy", JSON.stringify({ account: { uid: "b" } })],
    ["firebase-config", "config"],
  ]);
  const storage = {
    get length() {
      return values.size;
    },
    key: (i) => [...values.keys()][i],
    getItem: (k) => values.get(k) || null,
    removeItem: (k) => values.delete(k),
  };
  m.purgeAccountStorage(storage, "scope", "a", ["legacy", "otherlegacy"]);
  assert.deepEqual(
    [...values.keys()],
    ["scope:guest", "scope:account:b", "otherlegacy", "firebase-config"],
  );
});
test("cleanup keeps private directory until shared records are gone and resumes after interruption", async () => {
  const values = new Map([
    [
      "privateUsers/a/records/result_2026-11-09_wordle",
      { kind: "result", gameId: "wordle" },
    ],
    ["sharedScores/a/games/wordle/results/2026-11-09", { score: "3/6" }],
    ["profiles/a", { name: "A" }],
    ["friendRequests/a__b", { fromUid: "a", toUid: "b" }],
    ["privateUsers/b/records/profile", { name: "B" }],
  ]);
  const removed = [];
  let interrupt = true;
  const f = {
    doc: (_, ...p) => p.join("/"),
    collection: (_, ...p) => p.join("/"),
    where: (field, op, value) => ({ field, value }),
    query: (path, filter) => ({ path, filter }),
    getDocsFromServer: async (input) => {
      const path = typeof input === "string" ? input : input.path;
      return {
        docs: [...values.entries()]
          .filter(
            ([key, value]) =>
              key.startsWith(path + "/") &&
              (!input.filter ||
                value[input.filter.field] === input.filter.value),
          )
          .map(([ref, value]) => ({ ref, data: () => value })),
      };
    },
    writeBatch: () => {
      const refs = [];
      return {
        delete: (ref) => refs.push(ref),
        commit: async () => {
          if (
            interrupt &&
            refs.some((ref) => ref.startsWith("sharedScores/"))
          ) {
            interrupt = false;
            throw Error("network interrupted");
          }
          refs.forEach((ref) => {
            removed.push(ref);
            values.delete(ref);
          });
        },
      };
    },
  };
  await assert.rejects(
    m.cleanupAccountData({ firestore: f, db: {}, uid: "a" }),
    /interrupted/,
  );
  assert.ok(values.has("privateUsers/a/records/result_2026-11-09_wordle"));
  await m.cleanupAccountData({ firestore: f, db: {}, uid: "a" });
  assert.deepEqual([...values.keys()], ["privateUsers/b/records/profile"]);
  assert.ok(
    removed.indexOf("sharedScores/a/games/wordle/results/2026-11-09") <
      removed.indexOf("privateUsers/a/records/result_2026-11-09_wordle"),
  );
});
test("cleanup stops immediately after an account switch", async () => {
  const f = {
    getDocsFromServer: async () => ({ docs: [] }),
    collection: () => ({}),
  };
  await assert.rejects(
    m.cleanupAccountData({ firestore: f, uid: "a", isCurrent: () => false }),
    /account changed/,
  );
});

const fs = require("node:fs");
const vm = require("node:vm");
const app = fs.readFileSync(
  require("node:path").join(__dirname, "../dist/app.js"),
  "utf8",
);
function addFunction(context, name) {
  const match = new RegExp(`(?:async )?function ${name}\\(`).exec(app);
  const tail = app.slice(match.index),
    next = /\n(?:async )?function \w+\(/.exec(tail);
  vm.runInContext(tail.slice(0, next?.index), context);
}
function deletionContext() {
  const values = new Map();
  const get = (key) => {
    if (!values.has(key))
      values.set(key, {
        value: key === "#deleteAccountConfirmation" ? "DELETE" : "",
        textContent: "",
        disabled: false,
        close: () => {},
      });
    return values.get(key);
  };
  const user = { uid: "a" };
  let reauthenticated = 0,
    authDeleted = 0,
    locked = 0;
  const c = vm.createContext({
    management: m,
    safety,
    structuredClone,
    navigator: { onLine: true },
    document: { querySelector: get },
    state: state(),
    storageOwner: "a",
    deletionTarget: { uid: "a", generation: 1 },
    accountDeletionBusy: false,
    STORAGE_KEY: "scope",
    LEGACY_STORAGE_KEY: "legacy",
    ORIGINAL_STORAGE_KEY: "old",
    localStorage: { length: 0 },
    showAppNotice: () => {},
    handleCloudAuthUser: async () => {},
    updateSyncStatus: () => {},
    cloudBackend: {
      generation: 1,
      auth: { currentUser: user },
      modules: {
        auth: {
          GoogleAuthProvider: class {},
          reauthenticateWithPopup: async () => {
            reauthenticated++;
          },
          deleteUser: async () => {
            authDeleted++;
          },
        },
        firestore: {
          doc: () => ({}),
          serverTimestamp: () => ({ server: true }),
          runTransaction: async (_, fn) =>
            fn({
              get: async () => ({ exists: () => false }),
              set: () => {
                locked++;
              },
            }),
        },
      },
    },
    blockDeletedAccount: () => {
      c.cloudBackend.deletionPending = true;
    },
  });
  for (const name of [
    "cloudSession",
    "accountSessionMatches",
    "deleteCurrentAccount",
  ])
    addFunction(c, name);
  return { c, get, counts: () => ({ reauthenticated, authDeleted, locked }) };
}
test("deletion confirmation cannot be reused after switching accounts", async () => {
  const { c, get, counts } = deletionContext();
  c.deletionTarget.uid = "another-account";
  await c.deleteCurrentAccount({ preventDefault: () => {} });
  assert.deepEqual(counts(), { reauthenticated: 0, authDeleted: 0, locked: 0 });
  assert.match(get("#deleteAccountStatus").textContent, /account changed/);
});
test("failed reauthentication starts no account cleanup", async () => {
  const { c, get, counts } = deletionContext();
  c.cloudBackend.modules.auth.reauthenticateWithPopup = async () => {
    throw Error("popup cancelled");
  };
  await c.deleteCurrentAccount({ preventDefault: () => {} });
  assert.equal(counts().locked, 0);
  assert.equal(counts().authDeleted, 0);
  assert.match(get("#deleteAccountStatus").textContent, /cancelled/);
});
test("interrupted cleanup never deletes the authentication identity or reports completion", async () => {
  const { c, get, counts } = deletionContext();
  c.cloudBackend.modules.firestore.getDocsFromServer = async () => {
    throw Error("network interrupted");
  };
  c.cloudBackend.modules.firestore.collection = () => ({});
  await c.deleteCurrentAccount({ preventDefault: () => {} });
  assert.equal(counts().locked, 1);
  assert.equal(counts().authDeleted, 0);
  assert.equal(c.cloudBackend.deletionPending, true);
  assert.match(get("#deleteAccountStatus").textContent, /incomplete.*locked/);
});
test("concurrent sync requests share one in-flight task", async () => {
  let finish,
    runs = 0;
  const c = vm.createContext({
    cloudBackend: {},
    navigator: { onLine: true },
    cloudFriendsAvailable: () => true,
    cloudSession: () => ({ uid: "a" }),
    updateSyncStatus: () => {},
    queueCloudSave: () => {},
    performCloudStateSave: async () => {
      runs++;
      await new Promise((resolve) => (finish = resolve));
      return true;
    },
  });
  addFunction(c, "persistCloudState");
  const a = c.persistCloudState(),
    b = c.persistCloudState();
  assert.equal(a, b);
  assert.equal(runs, 1);
  finish();
  await a;
  assert.equal(c.cloudBackend.saving, false);
  assert.equal(c.cloudBackend.savePromise, null);
});

test("account identity is deleted only after data cleanup and the final deletion marker", async () => {
  const { c, counts } = deletionContext();
  let lifecycle = null;
  const stages = [];
  const f = c.cloudBackend.modules.firestore;
  f.runTransaction = async (_, fn) =>
    fn({
      get: async () => ({ exists: () => !!lifecycle, data: () => lifecycle }),
      set: (_, value) => {
        lifecycle = value;
        stages.push("lock");
      },
      update: (_, value) => {
        lifecycle = { ...lifecycle, ...value };
        stages.push("completed-marker");
      },
    });
  f.collection = () => ({});
  f.query = () => ({});
  f.where = () => ({});
  f.getDocsFromServer = async () => ({ docs: [] });
  f.writeBatch = () => ({
    delete: () => {},
    commit: async () => {
      stages.push("cleanup");
    },
  });
  c.cloudBackend.modules.auth.deleteUser = async () => {
    assert.equal(lifecycle.state, "deleted");
    assert.ok(stages.includes("cleanup"));
    stages.push("identity");
    c.cloudBackend.auth.currentUser = null;
  };
  await c.deleteCurrentAccount({ preventDefault: () => {} });
  assert.equal(stages.at(-1), "identity");
  assert.ok(stages.indexOf("cleanup") < stages.indexOf("completed-marker"));
  assert.equal(c.accountDeletionBusy, false);
});

test("identity export includes profile metadata while dropping authentication credentials", () => {
  const data = m.makeExport(state(), {
    identity: {
      uid: "a",
      email: "a@example.test",
      displayName: "A",
      photoURL: "https://example.test/photo",
      providerData: [{ providerId: "google.com", accessToken: "NEVER" }],
      accessToken: "NEVER",
      refreshToken: "NEVER",
    },
  });
  assert.equal(data.identity.displayName, "A");
  assert.deepEqual(data.identity.providers, ["google.com"]);
  assert.ok(!JSON.stringify(data).includes("NEVER"));
});

test('a device export waits for account switching rather than mixing identities',async()=>{
 const {c}=deletionContext();c.cloudBackend.auth.currentUser.uid='b';addFunction(c,'exportAccountData');
 await assert.rejects(c.exportAccountData(true),/account switching/);
});
