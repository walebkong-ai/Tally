const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const safety = require("../Assets/sync-safety.mjs");
const app = fs.readFileSync(
  require("node:path").join(__dirname, "../dist/app.js"),
  "utf8",
);
const clone = (value) => JSON.parse(JSON.stringify(value));
function memoryStorage() {
  const map = new Map();
  return {
    get length() {
      return map.size;
    },
    key: (i) => [...map.keys()][i],
    getItem: (key) => map.get(key) ?? null,
    setItem: (key, value) => map.set(key, value),
    removeItem: (key) => map.delete(key),
    map,
  };
}
function state() {
  return {
    profile: { id: "you", name: "You", handle: "@you" },
    account: { uid: "owner" },
    games: [{ id: "wordle", source: "official", type: "guesses" }],
    entries: {},
    friends: [],
    pinnedGameIds: [],
    solvryPlays: {},
    cloudBase: {},
    syncConflicts: [],
  };
}
function addFunction(context, name) {
  const match = new RegExp(`(?:async )?function ${name}\\(`).exec(app);
  const tail = app.slice(match.index),
    next = /\n(?:async )?function \w+\(/.exec(tail);
  vm.runInContext(tail.slice(0, next?.index), context);
}
function entry(score, extra = {}) {
  return {
    score,
    result: "solved",
    source: "official-share",
    reveal: false,
    answer: "secret",
    note: "private note",
    shareText: "private raw paste",
    grid: ["private grid"],
    ...extra,
  };
}
function record(score, revision = 1, extra = {}) {
  return {
    schemaVersion: 2,
    revision,
    kind: "result",
    date: "2026-11-09",
    gameId: "wordle",
    deleted: false,
    value: safety.privateEntry(entry(score, extra)),
  };
}
function cloudContext(database = new Map()) {
  const c = vm.createContext({
    safety,
    structuredClone,
    storageOwner: "owner",
    state: state(),
    showAppNotice: () => {},
    saveState: () => {},
    parseShareText: () => ({}),
    importDateError: () => "",
    cloudBackend: {
      generation: 0,
      ready: true,
      syncReady: true,
      auth: { currentUser: { uid: "owner" } },
      modules: {
        firestore: {
          doc: (_, ...path) => path.join("/"),
          serverTimestamp: () => ({ server: true }),
          runTransaction: async (_, callback) => {
            const writes = [];
            const result = await callback({
              get: async (ref) => ({
                exists: () => database.has(ref),
                data: () => database.get(ref),
              }),
              set: (ref, value) => writes.push([ref, value]),
              delete: (ref) => writes.push([ref, null]),
            });
            for (const [key, value] of writes) {
              if (value) database.set(key, value);
              else database.delete(key);
            }
            return result;
          },
        },
      },
    },
  });
  for (const name of [
    "cloudSession",
    "currentCloudSession",
    "accountRecords",
    "commitCloudRecord",
  ])
    addFunction(c, name);
  return c;
}
test("friend projection omits notes, raw pastes, grids and hidden answers", () => {
  const shared = safety.sharedResult(record("3/6"), "owner");
  for (const key of ["answer", "note", "shareText", "grid"])
    assert.equal(shared[key], undefined);
  const visible = safety.sharedResult(
    record("3/6", 1, { reveal: true }),
    "owner",
  );
  assert.equal(visible.answer, "secret");
  assert.equal(visible.note, undefined);
  assert.equal(
    safety.sharedResult(
      { ...record("3/6"), deleted: true, value: null },
      "owner",
    ).score,
    undefined,
  );
});
test("guest and two account namespaces stay separate", () => {
  const storage = memoryStorage(),
    guest = state(),
    a = state(),
    b = state();
  guest.entries = { "2026-11-09": { wordle: { you: entry("1/6") } } };
  a.entries = { "2026-11-09": { wordle: { you: entry("3/6") } } };
  b.entries = { "2026-11-09": { wordle: { you: entry("5/6") } } };
  for (const [uid, value] of [
    ["", guest],
    ["account-a", a],
    ["account-b", b],
  ])
    safety.writeLocal(
      storage,
      safety.storageKey("v2", uid),
      uid || "guest",
      safety.localRecords(state()),
      value,
      state(),
    );
  for (const [uid, score] of [
    ["", "1/6"],
    ["account-a", "3/6"],
    ["account-b", "5/6"],
  ])
    assert.equal(
      safety.readLocal(storage, safety.storageKey("v2", uid), state()).entries[
        "2026-11-09"
      ].wordle.you.score,
      score,
    );
});
test("local saves preserve fetched request lists even when the base cache write fails", () => {
  for (const failCache of [false, true]) {
    const storage = memoryStorage(), original = state();
    original.friendRequests = { incoming: [], outgoing: [] };
    storage.setItem("scope", JSON.stringify(original));
    const current = structuredClone(original);
    current.friendRequests = {
      incoming: [{ id: "a__owner", fromUid: "a", toUid: "owner", status: "pending" }],
      outgoing: [{ id: "owner__b", fromUid: "owner", toUid: "b", status: "pending" }]
    };
    const set = storage.setItem;
    storage.setItem = (key, value) => {
      if (failCache && key === "scope") throw new Error("cache quota");
      set(key, value);
    };
    const saved = safety.writeLocal(storage, "scope", "tab", safety.localRecords(original), current, state());
    assert.deepEqual(saved.friendRequests, current.friendRequests);
    if (!failCache) assert.deepEqual(safety.readLocal(storage, "scope", state()).friendRequests, current.friendRequests);
  }
});

test("peer cache refresh and removal survive saves while concurrent own edits stay merged", () => {
  const storage = memoryStorage(), original = state();
  original.entries = { "2026-11-09": { wordle: { you: entry("3/6"), oldFriend: entry("4/6") } } };
  storage.setItem("scope", JSON.stringify(original));
  const baseline = safety.localRecords(original);
  const otherTab = structuredClone(original);
  otherTab.entries["2026-11-08"] = { wordle: { you: entry("2/6") } };
  safety.writeLocal(storage, "scope", "other", baseline, otherTab, state());
  const current = structuredClone(original);
  delete current.entries["2026-11-09"].wordle.oldFriend;
  current.entries["2026-11-09"].wordle.newFriend = { score: "5/6", result: "solved", source: "manual", reveal: false };
  const saved = safety.writeLocal(storage, "scope", "tab", baseline, current, state());
  assert.equal(saved.entries["2026-11-09"].wordle.oldFriend, undefined);
  assert.equal(saved.entries["2026-11-09"].wordle.newFriend.score, "5/6");
  assert.equal(saved.entries["2026-11-09"].wordle.you.score, "3/6");
  assert.equal(saved.entries["2026-11-08"].wordle.you.score, "2/6");
  assert.equal(safety.cloudRecords(saved)["result_2026-11-09_wordle"].value.score, "3/6");
  assert.equal(safety.cloudRecords(saved)["result_2026-11-09_wordle"].value.newFriend, undefined);
});

test("a journal recovers data after the cache write fails", () => {
  const storage = memoryStorage(),
    original = storage.setItem;
  storage.setItem = (key, value) => {
    if (key === "scope") throw Error("cache quota");
    original(key, value);
  };
  const edited = state();
  edited.entries = { "2026-11-09": { wordle: { you: entry("3/6") } } };
  safety.writeLocal(
    storage,
    "scope",
    "tab-a",
    safety.localRecords(state()),
    edited,
    state(),
  );
  assert.equal(
    safety.readLocal(storage, "scope", state()).entries["2026-11-09"].wordle.you
      .score,
    "3/6",
  );
});
test("a failed durable write leaves cache and journals unchanged", () => {
  const storage = memoryStorage();
  storage.setItem = () => {
    throw Error("quota");
  };
  assert.throws(
    () =>
      safety.writeLocal(
        storage,
        "scope",
        "tab",
        safety.localRecords(state()),
        state(),
        state(),
      ),
    /quota/,
  );
  assert.equal(storage.length, 0);
});
test("unacknowledged concurrent tab journals preserve both edits", () => {
  const storage = memoryStorage(),
    base = safety.localRecords(state());
  const a = state();
  a.entries = { "2026-11-08": { wordle: { you: entry("2/6") } } };
  const b = state();
  b.entries = { "2026-11-09": { wordle: { you: entry("4/6") } } };
  const draft = (writer, next) => ({
    writer,
    sequence: 1,
    base,
    records: safety.localRecords(next),
    cloudBase: {},
  });
  storage.setItem("scope:draft:a", JSON.stringify(draft("a", a)));
  storage.setItem("scope:draft:b", JSON.stringify(draft("b", b)));
  const restored = safety.readLocal(storage, "scope", state());
  assert.equal(restored.entries["2026-11-08"].wordle.you.score, "2/6");
  assert.equal(restored.entries["2026-11-09"].wordle.you.score, "4/6");
});
test("same-record tab conflicts retain the competing edit for review", () => {
  const storage = memoryStorage(),
    base = state();
  base.entries = { "2026-11-09": { wordle: { you: entry("3/6") } } };
  const a = structuredClone(base),
    b = structuredClone(base);
  a.entries["2026-11-09"].wordle.you.score = "2/6";
  b.entries["2026-11-09"].wordle.you.score = "5/6";
  for (const [writer, next] of [
    ["a", a],
    ["b", b],
  ])
    storage.setItem(
      "scope:draft:" + writer,
      JSON.stringify({
        writer,
        sequence: 1,
        base: safety.localRecords(base),
        records: safety.localRecords(next),
        cloudBase: {},
      }),
    );
  storage.setItem("scope", JSON.stringify(base));
  const restored = safety.readLocal(storage, "scope", base);
  assert.equal(restored.syncConflicts.length, 1);
  assert.equal(restored.syncConflicts[0].local.value.score, "5/6");
  assert.equal(restored.entries["2026-11-09"].wordle.you.score, "2/6");
});
test("two devices editing different results preserve both records", async () => {
  const database = new Map(),
    a = cloudContext(database),
    b = cloudContext(database);
  const first = safety.payload(record("3/6")),
    second = { ...safety.payload(record("5/6")), date: "2026-11-08" };
  a.state.entries = { "2026-11-09": { wordle: { you: first.value } } };
  b.state.entries = { "2026-11-08": { wordle: { you: second.value } } };
  await a.commitCloudRecord(
    "result_2026-11-09_wordle",
    first,
    a.cloudSession(),
  );
  await b.commitCloudRecord(
    "result_2026-11-08_wordle",
    second,
    b.cloudSession(),
  );
  assert.equal(
    database.get("privateUsers/owner/records/result_2026-11-09_wordle").value
      .score,
    "3/6",
  );
  assert.equal(
    database.get("privateUsers/owner/records/result_2026-11-08_wordle").value
      .score,
    "5/6",
  );
  const shared = database.get(
    "sharedScores/owner/games/wordle/results/2026-11-09",
  );
  assert.equal(shared.answer, undefined);
  assert.equal(shared.shareText, undefined);
});
test("a stale same-result write becomes a reviewable conflict and cannot overwrite", async () => {
  const id = "result_2026-11-09_wordle",
    database = new Map([
      ["privateUsers/owner/records/" + id, record("5/6", 2)],
    ]),
    c = cloudContext(database);
  c.state.cloudBase[id] = record("3/6", 1);
  c.state.entries = { "2026-11-09": { wordle: { you: entry("2/6") } } };
  assert.equal(
    await c.commitCloudRecord(
      id,
      safety.payload(record("2/6")),
      c.cloudSession(),
    ),
    false,
  );
  assert.equal(
    database.get("privateUsers/owner/records/" + id).value.score,
    "5/6",
  );
  assert.equal(c.state.entries["2026-11-09"].wordle.you.score, "5/6");
  assert.equal(c.state.syncConflicts[0].local.value.score, "2/6");
});
test("an acknowledged transaction retry does not write another revision", async () => {
  const id = "result_2026-11-09_wordle",
    database = new Map([
      ["privateUsers/owner/records/" + id, record("3/6", 4)],
    ]),
    c = cloudContext(database);
  c.state.entries = { "2026-11-09": { wordle: { you: entry("3/6") } } };
  await c.commitCloudRecord(
    id,
    safety.payload(record("3/6")),
    c.cloudSession(),
  );
  assert.equal(c.state.cloudBase[id].revision, 4);
});
test("an edit made while a transaction is pending remains dirty after acknowledgement", async () => {
  const c = cloudContext();
  let finish;
  const original = c.cloudBackend.modules.firestore.runTransaction;
  c.cloudBackend.modules.firestore.runTransaction = async (...args) => {
    await new Promise((resolve) => (finish = resolve));
    return original(...args);
  };
  c.state.entries = { "2026-11-09": { wordle: { you: entry("3/6") } } };
  const pending = c.commitCloudRecord(
    "result_2026-11-09_wordle",
    safety.payload(record("3/6")),
    c.cloudSession(),
  );
  c.state.entries["2026-11-09"].wordle.you.score = "4/6";
  finish();
  await pending;
  assert.equal(c.state.entries["2026-11-09"].wordle.you.score, "4/6");
  assert.equal(
    c.state.cloudBase["result_2026-11-09_wordle"].value.score,
    "3/6",
  );
});
test("a delayed read from account A cannot populate account B", async () => {
  const c = cloudContext();
  let finish,
    privateReads = 0;
  c.cloudBackend.modules.firestore.getDocFromServer = async () => {
    await new Promise((resolve) => (finish = resolve));
    return { exists: () => true, data: () => ({ accountDataVersion: 2 }) };
  };
  c.cloudBackend.modules.firestore.getDocsFromServer = async () => {
    privateReads++;
    return { docs: [] };
  };
  c.cloudBackend.modules.firestore.collection = () => ({});
  addFunction(c, "loadCloudState");
  const pending = c.loadCloudState("owner");
  c.storageOwner = "account-b";
  c.cloudBackend.generation++;
  c.cloudBackend.auth.currentUser.uid = "account-b";
  c.state = state();
  finish();
  await pending;
  assert.equal(privateReads, 0);
  assert.deepEqual(clone(c.state.entries), {});
});
test("a delayed transaction cannot mutate or write under the next account", async () => {
  const c = cloudContext();
  let finish;
  c.cloudBackend.modules.firestore.runTransaction = async (_, callback) =>
    callback({
      get: async () => {
        await new Promise((resolve) => (finish = resolve));
        return { exists: () => false };
      },
      set: () => assert.fail("stale write"),
      delete: () => assert.fail("stale delete"),
    });
  const pending = c.commitCloudRecord(
    "result_2026-11-09_wordle",
    safety.payload(record("3/6")),
    c.cloudSession(),
  );
  c.storageOwner = "account-b";
  c.cloudBackend.generation++;
  c.cloudBackend.auth.currentUser.uid = "account-b";
  c.state = state();
  finish();
  assert.equal(await pending, false);
  assert.deepEqual(clone(c.state.entries), {});
  assert.deepEqual(clone(c.state.cloudBase), {});
});
test("personal games stay device-local and an authoritative unshare survives a stale reload", () => {
  const s = state(),
    game = {
      id: "custom-test",
      source: "custom",
      name: "Custom",
      type: "points",
      sharing: "friends",
      officialUrl: "",
    };
  s.games.push(game);
  const id = safety.gameRecordId(game.id),
    base = { schemaVersion: 2, revision: 1, ...safety.cloudRecords(s)[id] };
  s.cloudBase[id] = base;
  const local = safety.cloudRecords(s),
    remote = {
      [id]: {
        ...base,
        revision: 2,
        value: { id: game.id, sharing: "personal" },
      },
    };
  const merged = safety.mergeEdits(s.cloudBase, local, remote);
  safety.applyRecords(s, merged.records);
  s.cloudBase = remote;
  assert.equal(s.games.find((g) => g.id === game.id).sharing, "personal");
  assert.equal(safety.cloudRecords(s)[id].value.sharing, "personal");
});

test("a rules rejection caused by a stale revision is converted to a conflict", async () => {
  const context = cloudContext();
  const id = "result_2026-11-09_wordle";
  context.state.cloudBase[id] = record("3/6", 1);
  context.state.entries = { "2026-11-09": { wordle: { you: entry("2/6") } } };
  context.cloudBackend.modules.firestore.runTransaction = async () => {
    throw Object.assign(new Error("stale write"), {
      code: "permission-denied",
    });
  };
  context.cloudBackend.modules.firestore.getDocFromServer = async () => ({
    exists: () => true,
    data: () => record("5/6", 2),
  });
  const saved = await context.commitCloudRecord(
    id,
    safety.payload(record("2/6")),
    context.cloudSession(),
  );
  assert.equal(saved, false);
  assert.equal(context.state.syncConflicts[0].local.value.score, "2/6");
  assert.equal(context.state.entries["2026-11-09"].wordle.you.score, "5/6");
});
test("the guest namespace cannot collide with an account named guest", () => {
  assert.notEqual(safety.storageKey("v2"), safety.storageKey("v2", "guest"));
});

test("remote deletions remove unchanged local scores and pins", () => {
  const previous = state();
  previous.entries = { "2026-11-09": { wordle: { you: entry("3/6") } } };
  previous.pinnedGameIds = ["wordle"];
  const current = state();
  const merged = safety.mergeEdits(
    safety.localRecords(previous),
    safety.localRecords(previous),
    safety.localRecords(current),
  );
  safety.applyRecords(previous, merged.records);
  assert.equal(previous.entries["2026-11-09"].wordle.you, undefined);
  assert.deepEqual(previous.pinnedGameIds, []);
});

test("cloud conflicts survive journal-only storage and chosen resolution stays resolved", () => {
  const storage = memoryStorage();
  const setItem = storage.setItem;
  storage.setItem = (key, value) => {
    if (key === "scope") throw Error("cache quota");
    setItem(key, value);
  };
  const current = state();
  const conflict = {
    id: "result_2026-11-09_wordle",
    scope: "cloud",
    local: safety.payload(record("2/6")),
    remote: record("5/6", 2),
  };
  current.entries = { "2026-11-09": { wordle: { you: entry("5/6") } } };
  current.syncConflicts = [conflict];
  safety.writeLocal(
    storage,
    "scope",
    "a",
    safety.localRecords(state()),
    current,
    state(),
  );
  const restored = safety.readLocal(storage, "scope", state());
  assert.equal(restored.syncConflicts.length, 1);
  restored.resolvedConflicts = restored.syncConflicts.map(safety.conflictKey);
  restored.syncConflicts = [];
  safety.applyRecord(restored, conflict.local);
  safety.writeLocal(
    storage,
    "scope",
    "b",
    safety.localRecords(safety.readLocal(storage, "scope", state())),
    restored,
    state(),
  );
  const resolved = safety.readLocal(storage, "scope", state());
  assert.equal(resolved.syncConflicts.length, 0);
  assert.equal(resolved.entries["2026-11-09"].wordle.you.score, "2/6");
});

test("missing security marker stops before reading or writing account data", async () => {
  const c = cloudContext();
  c.cloudBackend.modules.firestore.getDocFromServer = async () => ({
    exists: () => false,
  });
  c.cloudBackend.modules.firestore.getDocsFromServer = async () =>
    assert.fail("private read before safety configuration");
  addFunction(c, "loadCloudState");
  await assert.rejects(
    c.loadCloudState("owner"),
    /configured before cloud sync/,
  );
  assert.deepEqual(clone(c.state.entries), {});
});

test("cloud revision acknowledgments survive a failed cache write", () => {
  const storage = memoryStorage();
  const current = state();
  current.entries = { "2026-11-09": { wordle: { you: entry("3/6") } } };
  let baseline = safety.localRecords(state());
  safety.writeLocal(storage, "scope", "a", baseline, current, state());
  const saved = safety.readLocal(storage, "scope", state());
  baseline = safety.localRecords(saved);
  saved.cloudBase["result_2026-11-09_wordle"] = record("3/6", 2);
  const original = storage.setItem;
  storage.setItem = (key, value) => {
    if (key === "scope") throw Error("quota");
    original(key, value);
  };
  safety.writeLocal(storage, "scope", "a", baseline, saved, state());
  assert.equal(
    safety.readLocal(storage, "scope", state()).cloudBase[
      "result_2026-11-09_wordle"
    ].revision,
    2,
  );
});

test("choosing the account copy replaces later edits and records the conflict decision", () => {
  const c = cloudContext();
  const conflict = { id: "result_2026-11-09_wordle", scope: "cloud", local: safety.payload(record("2/6")), remote: record("5/6", 2) };
  c.state.entries = { "2026-11-09": { wordle: { you: entry("1/6") } } };
  c.state.syncConflicts = [conflict];
  c.render = () => {};
  c.updateAccountStatus = () => {};
  addFunction(c, "resolveSyncConflicts");
  c.resolveSyncConflicts(false);
  assert.equal(c.state.entries["2026-11-09"].wordle.you.score, "5/6");
  assert.equal(c.state.syncConflicts.length, 0);
  assert.equal(c.state.resolvedConflicts[0], safety.conflictKey(conflict));
});
