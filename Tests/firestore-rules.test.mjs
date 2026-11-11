import { before, after, beforeEach, test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import * as firestore from "firebase/firestore";
import * as safety from "../Assets/sync-safety.mjs";
import * as management from "../Assets/account-management.mjs";
import * as operations from "../Assets/launch-ops.mjs";

const projectId = "demo-solvry-safety";
const date = "2026-11-09";
let environment;
const resultId = (game) => safety.resultRecordId(date, game);
const path = (uid, game = "wordle") =>
  `sharedScores/${uid}/games/${game}/results/${date}`;
const body = (score, revision = 1, extra = {}) => ({
  schemaVersion: 2,
  revision,
  kind: "result",
  date,
  gameId: "wordle",
  deleted: false,
  value: safety.privateEntry({
    score,
    result: "solved",
    source: "official-share",
    reveal: false,
    answer: "PRIVATE ANSWER",
    note: "PRIVATE NOTE",
    shareText: "PRIVATE RAW PASTE",
    grid: ["PRIVATE GRID"],
    ...extra,
  }),
});
const request = {
  fromUid: "owner",
  toUid: "friend",
  fromProfile: { name: "Owner", handle: "@owner" },
  toProfile: { name: "Friend", handle: "@friend" },
  status: "accepted",
  createdAt: "2026-11-09",
  updatedAt: "2026-11-09",
};
const databases = new Map();
const db = (uid) => {
  if (!databases.has(uid)) {
    const context = uid
      ? environment.authenticatedContext(uid, {
          auth_time: Math.floor(Date.now() / 1000),
        })
      : environment.unauthenticatedContext();
    databases.set(uid, context.firestore());
  }
  return databases.get(uid);
};

async function seed(records) {
  await environment.withSecurityRulesDisabled(async (context) => {
    const database = context.firestore();
    await Promise.all(
      Object.entries(records).map(([key, value]) =>
        firestore.setDoc(firestore.doc(database, key), value),
      ),
    );
  });
}
async function publish(database, record, uid = "owner") {
  const batch = firestore.writeBatch(database);
  batch.set(
    firestore.doc(
      database,
      `privateUsers/${uid}/records/${safety.resultRecordId(record.date, record.gameId)}`,
    ),
    { ...record, updatedAt: firestore.serverTimestamp() },
  );
  batch.set(
    firestore.doc(database, path(uid, record.gameId)),
    safety.sharedResult(record, uid),
  );
  return batch.commit();
}
before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        new URL("../firestore.rules", import.meta.url),
        "utf8",
      ),
    },
  });
});
after(async () => {
  await environment.cleanup();
});
beforeEach(async () => {
  await environment.clearFirestore();
  await seed({ "system/security": { accountDataVersion: 2 } });
});

const health = () => ({schemaVersion:1,release:operations.RELEASE,updatedAt:firestore.serverTimestamp(),counts:operations.emptyCounts(),lastError:{area:'app',code:'unknown',route:'today'}});
test('operational reports are owner-only and unavailable to peers or anonymous users', async()=>{
  const ref=firestore.doc(db('owner'),'clientHealth/owner');
  await assertSucceeds(firestore.setDoc(ref,health()));
  await assertSucceeds(firestore.getDoc(ref));
  for(const uid of ['friend','stranger',null]) {
    await assertFails(firestore.getDoc(firestore.doc(db(uid),'clientHealth/owner')));
    await assertFails(firestore.setDoc(firestore.doc(db(uid),'clientHealth/owner'),health()));
  }
  await assertFails(firestore.getDocs(firestore.collection(db('owner'),'clientHealth')));
});
test('operational schema rejects PII, arbitrary fields, invalid types and forged timestamps', async()=>{
  for(const body of [
    {...health(),message:'PRIVATE'}, {...health(),lastError:{area:'app',code:'SECRET ANSWER',route:'today'}},
    {...health(),release:'x'.repeat(10000)}, {...health(),lastError:{area:'app',code:'unknown',route:'today',email:'PRIVATE'}},
    {...health(),counts:{...operations.emptyCounts(),error:-1}}, {...health(),counts:{...operations.emptyCounts(),error:1000001}},
    {...health(),counts:{...operations.emptyCounts(),error:'1'}}, {...health(),updatedAt:firestore.Timestamp.fromMillis(0)},
    {...health(),schemaVersion:undefined}
  ]) await assertFails(firestore.setDoc(firestore.doc(db('owner'),'clientHealth/owner'),Object.fromEntries(Object.entries(body).filter(([,v])=>v!==undefined))));
});
test('operational updates enforce validation and a five-minute minimum interval', async()=>{
  const ref=firestore.doc(db('owner'),'clientHealth/owner');
  await assertSucceeds(firestore.setDoc(ref,health()));
  await assertFails(firestore.setDoc(ref,health()));
  await seed({'clientHealth/owner':{...health(),updatedAt:firestore.Timestamp.fromMillis(Date.now()-301000)}});
  await assertFails(firestore.setDoc(ref,{...health(),note:'PRIVATE'}));
  await assertSucceeds(firestore.setDoc(ref,{...health(),counts:{...operations.emptyCounts(),error:1},lastError:{area:'sync',code:'unavailable',route:'import'}}));
});
test('account deletion locks new operational writes and permits cleanup', async()=>{
  const ref=firestore.doc(db('owner'),'clientHealth/owner');
  await assertSucceeds(firestore.setDoc(ref,health()));
  await seed({'accountLifecycle/owner':{schemaVersion:1,state:'deleting',startedAt:firestore.Timestamp.now()}});
  await assertFails(firestore.setDoc(ref,health()));
  await assertSucceeds(firestore.deleteDoc(ref));
  await assertFails(firestore.setDoc(ref,health()));
});

test("only the owner can read private records, including accepted friends", async () => {
  await seed({ "friendRequests/friend__owner": request });
  await assertSucceeds(publish(db("owner"), body("3/6")));
  const key = `privateUsers/owner/records/${resultId("wordle")}`;
  await assertSucceeds(firestore.getDoc(firestore.doc(db("owner"), key)));
  for (const uid of ["friend", "stranger", null])
    await assertFails(firestore.getDoc(firestore.doc(db(uid), key)));
  await assertFails(
    firestore.getDocs(
      firestore.collection(db("friend"), "privateUsers/owner/records"),
    ),
  );
});
test("shared projections contain only allowed fields and require an accepted relationship", async () => {
  await seed({ "friendRequests/friend__owner": request });
  await publish(db("owner"), body("3/6"));
  const score = (
    await assertSucceeds(
      firestore.getDoc(firestore.doc(db("friend"), path("owner"))),
    )
  ).data();
  for (const key of [
    "answer",
    "note",
    "shareText",
    "grid",
    "friends",
    "pinnedGameIds",
  ])
    assert.equal(score[key], undefined);
  for (const uid of ["stranger", null])
    await assertFails(firestore.getDoc(firestore.doc(db(uid), path("owner"))));
  const list = await assertSucceeds(
    firestore.getDocs(
      firestore.query(
        firestore.collection(
          db("friend"),
          "sharedScores/owner/games/wordle/results",
        ),
        firestore.where("deleted", "==", false),
      ),
    ),
  );
  assert.equal(list.size, 1);
  await assertFails(
    firestore.setDoc(firestore.doc(db("owner"), path("owner")), {
      ...score,
      shareText: "SECRET",
    }),
  );
  await assertFails(
    firestore.setDoc(firestore.doc(db("owner"), path("owner")), {
      ...score,
      answer: "SECRET",
      reveal: false,
    }),
  );
  await assertFails(
    firestore.setDoc(firestore.doc(db("friend"), path("owner")), score),
  );
});
test("revealed answers can be shared and are removed atomically when hidden", async () => {
  await seed({ "friendRequests/friend__owner": request });
  await publish(db("owner"), body("3/6", 1, { reveal: true }));
  assert.equal(
    (await firestore.getDoc(firestore.doc(db("friend"), path("owner")))).data()
      .answer,
    "PRIVATE ANSWER",
  );
  await publish(db("owner"), body("3/6", 2));
  assert.equal(
    (await firestore.getDoc(firestore.doc(db("friend"), path("owner")))).data()
      .answer,
    undefined,
  );
});
test("private result changes require the matching atomic public update and increasing revision", async () => {
  const owner = db("owner"),
    record = body("3/6");
  await assertFails(
    firestore.setDoc(
      firestore.doc(owner, `privateUsers/owner/records/${resultId("wordle")}`),
      { ...record, updatedAt: firestore.serverTimestamp() },
    ),
  );
  await assertSucceeds(publish(owner, record));
  await assertFails(publish(owner, body("2/6", 1)));
  await assertFails(publish(owner, body("2/6", 4)));
  await assertSucceeds(publish(owner, body("2/6", 2)));
  await assertFails(
    firestore.deleteDoc(
      firestore.doc(owner, `privateUsers/owner/records/${resultId("wordle")}`),
    ),
  );
});
test("profile discovery exposes only the directory projection", async () => {
  const owner = db("owner"),
    profile = { name: "Owner", handle: "@owner", handleLower: "owner" },
    batch = firestore.writeBatch(owner);
  batch.set(firestore.doc(owner, "privateUsers/owner/records/profile"), {
    schemaVersion: 2,
    revision: 1,
    kind: "profile",
    deleted: false,
    value: profile,
    updatedAt: firestore.serverTimestamp(),
  });
  batch.set(firestore.doc(owner, "profiles/owner"), {
    schemaVersion: 2,
    profile,
  });
  await assertSucceeds(batch.commit());
  const matches = await assertSucceeds(
    firestore.getDocs(
      firestore.query(
        firestore.collection(db("stranger"), "profiles"),
        firestore.where("profile.handleLower", "==", "owner"),
      ),
    ),
  );
  assert.deepEqual(Object.keys(matches.docs[0].data()).sort(), [
    "profile",
    "schemaVersion",
  ]);
  await assertFails(
    firestore.setDoc(firestore.doc(owner, "profiles/owner"), {
      schemaVersion: 2,
      profile,
      entries: { private: "data" },
    }),
  );
  await assertFails(
    firestore.getDoc(firestore.doc(db(null), "profiles/owner")),
  );
});
test("custom scores require matching explicit membership and revoke access immediately", async () => {
  const game = {
    id: "custom-test",
    name: "Test",
    type: "points",
    officialUrl: "",
    sharing: "friends",
    definitionKey: "same",
  };
  const setting = (value) => ({
    schemaVersion: 2,
    revision: 1,
    kind: "game",
    gameId: game.id,
    deleted: false,
    value,
  });
  await seed({
    "friendRequests/friend__owner": request,
    "privateUsers/owner/records/game_custom-test": setting(game),
    "privateUsers/friend/records/game_custom-test": setting({
      ...game,
      sharing: "personal",
    }),
  });
  await publish(db("owner"), { ...body("42"), gameId: game.id });
  await assertFails(
    firestore.getDoc(firestore.doc(db("friend"), path("owner", game.id))),
  );
  await seed({ "privateUsers/friend/records/game_custom-test": setting(game) });
  await assertSucceeds(
    firestore.getDoc(firestore.doc(db("friend"), path("owner", game.id))),
  );
  await assertSucceeds(
    firestore.setDoc(
      firestore.doc(db("owner"), "privateUsers/owner/records/game_custom-test"),
      {
        ...setting({ id: game.id, sharing: "personal" }),
        revision: 2,
        updatedAt: firestore.serverTimestamp(),
      },
    ),
  );
  await assertFails(
    firestore.getDoc(firestore.doc(db("friend"), path("owner", game.id))),
  );
  await assertFails(
    firestore.setDoc(
      firestore.doc(db("owner"), "privateUsers/owner/records/game_custom-test"),
      { ...setting(game), revision: 2, updatedAt: firestore.serverTimestamp() },
    ),
  );
});
test("request actions enforce actor, immutable participants and status transitions", async () => {
  const pending = { ...request, status: "pending" };
  await assertSucceeds(
    firestore.setDoc(
      firestore.doc(db("owner"), "friendRequests/friend__owner"),
      pending,
    ),
  );
  await assertFails(
    firestore.updateDoc(
      firestore.doc(db("owner"), "friendRequests/friend__owner"),
      { status: "accepted", updatedAt: "now" },
    ),
  );
  await assertFails(
    firestore.updateDoc(
      firestore.doc(db("stranger"), "friendRequests/friend__owner"),
      { status: "accepted", updatedAt: "now" },
    ),
  );
  await assertSucceeds(
    firestore.updateDoc(
      firestore.doc(db("friend"), "friendRequests/friend__owner"),
      { status: "accepted", updatedAt: "now" },
    ),
  );
  await publish(db("owner"), body("3/6"));
  await assertSucceeds(
    firestore.getDoc(firestore.doc(db("friend"), path("owner"))),
  );
  await assertSucceeds(
    firestore.updateDoc(
      firestore.doc(db("friend"), "friendRequests/friend__owner"),
      { status: "removed", updatedAt: "later" },
    ),
  );
  await assertFails(
    firestore.getDoc(firestore.doc(db("friend"), path("owner"))),
  );
  await assertFails(
    firestore.setDoc(
      firestore.doc(db("stranger"), "friendRequests/friend__owner"),
      { ...pending, fromUid: "stranger" },
    ),
  );
  await assertSucceeds(
    firestore.getDocs(
      firestore.query(
        firestore.collection(db("owner"), "friendRequests"),
        firestore.where("fromUid", "==", "owner"),
      ),
    ),
  );
});
test("legacy mixed documents and security marker are inaccessible for client writes", async () => {
  await seed({ "users/owner": { entries: { secret: "raw paste" } } });
  await assertFails(
    firestore.getDoc(firestore.doc(db("owner"), "users/owner")),
  );
  await assertFails(
    firestore.setDoc(firestore.doc(db("owner"), "system/security"), {
      accountDataVersion: 2,
    }),
  );
  await assertFails(
    firestore.setDoc(firestore.doc(db("owner"), "users/owner"), {
      entries: {},
    }),
  );
});

const appSource = fs.readFileSync(
  new URL("../dist/app.js", import.meta.url),
  "utf8",
);
function plainValue(value) {
  if (Array.isArray(value)) return value.map(plainValue);
  if (value && value.constructor?.name === "Object")
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, plainValue(item)]),
    );
  return value;
}
function controller(database, score, base) {
  const state = {
    profile: { id: "you", name: "Owner", handle: "@owner" },
    account: { uid: "owner" },
    games: [{ id: "wordle", source: "official", type: "guesses" }],
    entries: {
      [date]: {
        wordle: {
          you: safety.privateEntry({
            score,
            result: "solved",
            source: "manual",
          }),
        },
      },
    },
    friends: [],
    pinnedGameIds: [],
    cloudBase: { [resultId("wordle")]: base },
    syncConflicts: [],
  };
  const c = vm.createContext({
    safety,
    structuredClone,
    state,
    storageOwner: "owner",
    saveState: () => {},
    showAppNotice: () => {},
    parseShareText: () => ({}),
    importDateError: () => "",
    cloudBackend: {
      db: database,
      auth: { currentUser: { uid: "owner" } },
      generation: 0,
      modules: {
        firestore: {
          ...firestore,
          runTransaction: (database, callback) =>
            firestore.runTransaction(database, (transaction) =>
              callback({
                get: (ref) => transaction.get(ref),
                set: (ref, value) => {
                  const data = plainValue(value);
                  return transaction.set(ref, data);
                },
                delete: (ref) => transaction.delete(ref),
              }),
            ),
        },
      },
    },
  });
  for (const name of [
    "cloudSession",
    "currentCloudSession",
    "accountRecords",
    "commitCloudRecord",
  ]) {
    const match = new RegExp(`(?:async )?function ${name}\\(`).exec(appSource),
      tail = appSource.slice(match.index),
      next = /\n(?:async )?function \w+\(/.exec(tail);
    vm.runInContext(tail.slice(0, next.index), c);
  }
  return c;
}
test("the shipped sync transaction resolves real concurrent edits without lost updates", async () => {
  const original = body("3/6");
  await publish(db("owner"), original);
  const a = controller(db("owner"), "2/6", original),
    b = controller(db("owner"), "5/6", original);
  await Promise.all([
    a.commitCloudRecord(
      resultId("wordle"),
      safety.payload(body("2/6", 1, { source: "manual" })),
      a.cloudSession(),
    ),
    b.commitCloudRecord(
      resultId("wordle"),
      safety.payload(body("5/6", 1, { source: "manual" })),
      b.cloudSession(),
    ),
  ]);
  const saved = (
    await firestore.getDoc(
      firestore.doc(
        db("owner"),
        `privateUsers/owner/records/${resultId("wordle")}`,
      ),
    )
  ).data();
  assert.equal(saved.revision, 2);
  assert.ok(["2/6", "5/6"].includes(saved.value.score));
  assert.equal(a.state.syncConflicts.length + b.state.syncConflicts.length, 1);
  assert.equal(
    (await firestore.getDoc(firestore.doc(db("owner"), path("owner")))).data()
      .score,
    saved.value.score,
  );
});

test("a first friend request can transactionally check absence before creating", async () => {
  const database = db("owner"),
    ref = firestore.doc(database, "friendRequests/friend__owner");
  await assertSucceeds(
    firestore.runTransaction(database, async (transaction) => {
      const snapshot = await transaction.get(ref);
      assert.equal(snapshot.exists(), false);
      transaction.set(ref, { ...request, status: "pending" });
    }),
  );
  await assertFails(
    firestore.getDoc(
      firestore.doc(db("stranger"), "friendRequests/friend__owner"),
    ),
  );
});

test("account writes fail closed without the admin security marker", async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    await firestore.deleteDoc(
      firestore.doc(context.firestore(), "system/security"),
    );
  });
  await assertFails(publish(db("owner"), body("3/6")));
});

test("score date correction commits source deletion and destination score atomically", async () => {
  const database = db("owner"),
    record = body("3/6");
  await publish(database, record);
  const moved = await management.moveCloudScore({
    firestore,
    db: database,
    uid: "owner",
    gameId: "wordle",
    fromDate: date,
    toDate: "2026-11-08",
    entry: record.value,
    base: { [resultId("wordle")]: record },
  });
  const source = (
    await firestore.getDoc(
      firestore.doc(
        database,
        `privateUsers/owner/records/${resultId("wordle")}`,
      ),
    )
  ).data();
  const target = (
    await firestore.getDoc(
      firestore.doc(
        database,
        "privateUsers/owner/records/result_2026-11-08_wordle",
      ),
    )
  ).data();
  assert.equal(source.deleted, true);
  assert.equal(source.value, null);
  assert.equal(target.value.score, "3/6");
  assert.equal(target.value.shareText, "PRIVATE RAW PASTE");
  const shared = (
    await firestore.getDoc(
      firestore.doc(
        database,
        "sharedScores/owner/games/wordle/results/2026-11-08",
      ),
    )
  ).data();
  assert.equal(shared.shareText, undefined);
  assert.equal(shared.answer, undefined);
  assert.equal(moved["result_2026-11-08_wordle"].value.score, "3/6");
});

test("a stale date correction cannot overwrite another device or an occupied destination", async () => {
  const database = db("owner"),
    original = body("3/6");
  await publish(database, original);
  await publish(database, body("5/6", 2));
  await assert.rejects(
    management.moveCloudScore({
      firestore,
      db: database,
      uid: "owner",
      gameId: "wordle",
      fromDate: date,
      toDate: "2026-11-08",
      entry: original.value,
      base: { [resultId("wordle")]: original },
    }),
    /changed on another device/,
  );
  assert.equal(
    (
      await firestore.getDoc(
        firestore.doc(
          database,
          `privateUsers/owner/records/${resultId("wordle")}`,
        ),
      )
    ).data().value.score,
    "5/6",
  );
  assert.equal(
    (
      await firestore.getDoc(
        firestore.doc(
          database,
          "privateUsers/owner/records/result_2026-11-08_wordle",
        ),
      )
    ).exists(),
    false,
  );
  const target = { ...body('2/6'), date: '2026-11-08' };
  await seed({
    'privateUsers/owner/records/result_2026-11-08_wordle': target,
    'sharedScores/owner/games/wordle/results/2026-11-08': safety.sharedResult(target,'owner')
  });
  const latest = body('5/6', 2);
  await assert.rejects(management.moveCloudScore({firestore,db:database,uid:'owner',gameId:'wordle',fromDate:date,toDate:'2026-11-08',entry:latest.value,base:{[resultId('wordle')]:latest}}), /already exists/);
  assert.equal((await firestore.getDoc(firestore.doc(database,'privateUsers/owner/records/result_2026-11-08_wordle'))).data().value.score,'2/6');

});

test("account deletion locks old sessions, revokes friend reads, permits only owner cleanup and cannot be undone", async () => {
  const database = db("owner"),
    record = body("3/6");
  await seed({ "friendRequests/friend__owner": request });
  await publish(database, record);
  const lifecycle = firestore.doc(database, "accountLifecycle/owner");
  await assertFails(
    firestore.setDoc(firestore.doc(db("friend"), "accountLifecycle/owner"), {
      schemaVersion: 1,
      state: "deleting",
      startedAt: firestore.serverTimestamp(),
    }),
  );
  const stale = environment
    .authenticatedContext("owner", { auth_time: 1 })
    .firestore();
  await assertFails(
    firestore.setDoc(firestore.doc(stale, "accountLifecycle/owner"), {
      schemaVersion: 1,
      state: "deleting",
      startedAt: firestore.serverTimestamp(),
    }),
  );
  await assertSucceeds(
    firestore.setDoc(lifecycle, {
      schemaVersion: 1,
      state: "deleting",
      startedAt: firestore.serverTimestamp(),
    }),
  );
  await assertFails(publish(database, body("1/6", 2)));
  await assertFails(
    firestore.getDoc(firestore.doc(db("friend"), path("owner"))),
  );
  await assertFails(
    firestore.deleteDoc(
      firestore.doc(
        db("friend"),
        `privateUsers/owner/records/${resultId("wordle")}`,
      ),
    ),
  );
  await assertFails(firestore.updateDoc(lifecycle, { state: "active" }));
  await assertFails(firestore.deleteDoc(lifecycle));
  await assertSucceeds(
    management.cleanupAccountData({ firestore, db: database, uid: "owner" }),
  );
  assert.equal(
    (
      await firestore.getDocs(
        firestore.collection(database, "privateUsers/owner/records"),
      )
    ).size,
    0,
  );
  assert.equal(
    (
      await firestore.getDocs(
        firestore.collection(
          database,
          "sharedScores/owner/games/wordle/results",
        ),
      )
    ).size,
    0,
  );
  await assertSucceeds(
    firestore.updateDoc(lifecycle, {
      state: "deleted",
      completedAt: firestore.serverTimestamp(),
    }),
  );
  await assertFails(firestore.updateDoc(lifecycle, { state: "deleting" }));
  await assertFails(publish(database, record));
});

test("a deletion lock and data resurrection in the same batch is denied", async () => {
  const database = db("owner"),
    record = body("3/6"),
    batch = firestore.writeBatch(database);
  batch.set(firestore.doc(database, "accountLifecycle/owner"), {
    schemaVersion: 1,
    state: "deleting",
    startedAt: firestore.serverTimestamp(),
  });
  batch.set(
    firestore.doc(database, `privateUsers/owner/records/${resultId("wordle")}`),
    { ...record, updatedAt: firestore.serverTimestamp() },
  );
  batch.set(
    firestore.doc(database, path("owner")),
    safety.sharedResult(record, "owner"),
  );
  await assertFails(batch.commit());
});

test("account cleanup spans multiple batches without dropping the private path directory early", async () => {
  const records = {};
  for (let i = 0; i < 205; i++) {
    const d = new Date(Date.UTC(2026, 0, 1 + i)).toISOString().slice(0, 10);
    const record = { ...body("3/6"), date: d };
    records[`privateUsers/owner/records/result_${d}_wordle`] = record;
    records[`sharedScores/owner/games/wordle/results/${d}`] =
      safety.sharedResult(record, "owner");
  }
  records["accountLifecycle/owner"] = {
    schemaVersion: 1,
    state: "deleting",
    startedAt: firestore.Timestamp.now(),
  };
  await seed(records);
  await management.cleanupAccountData({
    firestore,
    db: db("owner"),
    uid: "owner",
  });
  assert.equal(
    (
      await firestore.getDocs(
        firestore.collection(db("owner"), "privateUsers/owner/records"),
      )
    ).size,
    0,
  );
  assert.equal(
    (
      await firestore.getDocs(
        firestore.collection(
          db("owner"),
          "sharedScores/owner/games/wordle/results",
        ),
      )
    ).size,
    0,
  );
});
