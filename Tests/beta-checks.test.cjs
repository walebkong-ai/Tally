const { test } = require("node:test");
const assert = require("node:assert/strict");
const {
  inspectProjection,
  runBetaChecks,
} = require("../Assets/beta-checks.mjs");
const shared = () => ({
  schemaVersion: 2,
  revision: 1,
  ownerUid: "peer",
  gameId: "wordle",
  date: "2026-11-09",
  deleted: false,
  score: "3/6",
  result: "solved",
  source: "manual",
  reveal: false,
});
test("projection checker rejects hidden answers and any private field", () => {
  assert.equal(
    inspectProjection(shared(), "hidden", "3/6").answerIncluded,
    false,
  );
  for (const extra of [
    { answer: "PRIVATE" },
    { note: "PRIVATE" },
    { shareText: "PRIVATE" },
    { grid: ["PRIVATE"] },
  ])
    assert.throws(() => inspectProjection({ ...shared(), ...extra }, "hidden"));
  assert.throws(() => inspectProjection(shared(), "revealed"));
  assert.throws(() => inspectProjection(shared(), "hidden", "5/6"));
  const report = inspectProjection(
    { ...shared(), reveal: true, answer: "PRIVATE" },
    "revealed",
  );
  assert.ok(!JSON.stringify(report).includes("PRIVATE"));
});
function sdk({ peerAllowed = false, leak = false, allowPrivate = false } = {}) {
  const denied = () =>
    Object.assign(Error("denied"), { code: "permission-denied" });
  return {
    doc: (_, ...p) => p.join("/"),
    collection: (_, ...p) => p.join("/"),
    where: (...p) => p,
    limit: (n) => n,
    query: (path, ...filters) => ({ path, filters }),
    getDocsFromServer: async (q) => {
      if (q.path === "profiles") return { docs: [{ id: "peer" }] };
      if (typeof q === "string") throw denied();
      return { docs: [] };
    },
    getDocFromServer: async (path) => {
      if (path.startsWith("privateUsers/own/"))
        return {
          exists: () => true,
          data: () => ({ schemaVersion: 2, deleted: false }),
        };
      if (path.startsWith("sharedScores/") && peerAllowed)
        return {
          exists: () => true,
          data: () => ({
            ...shared(),
            ...(leak ? { answer: "PRIVATE SECRET" } : {}),
          }),
        };
      if (allowPrivate && path === "privateUsers/peer/records/profile")
        return {
          exists: () => true,
          data: () => ({ secret: "PRIVATE SECRET" }),
        };
      throw denied();
    },
  };
}
test("live client checks distinguish denied, accepted and leaking results without exposing values", async () => {
  for (const phase of ["unconnected", "hidden", "removed"]) {
    const result = await runBetaChecks({
      firestore: sdk({ peerAllowed: phase === "hidden" }),
      db: {},
      user: { uid: "own" },
      peerHandle: "@peer",
      date: "2026-11-09",
      phase,
      expectedScore: "3/6",
    });
    assert.equal(result.failed, 0);
    assert.equal(result.passed, 10);
  }
  const leaked = await runBetaChecks({
    firestore: sdk({ peerAllowed: true, leak: true, allowPrivate: true }),
    db: {},
    user: { uid: "own" },
    peerHandle: "@peer",
    date: "2026-11-09",
    phase: "hidden",
  });
  assert.equal(leaked.failed, 2);
  assert.ok(!JSON.stringify(leaked).includes("PRIVATE SECRET"));
});
test("a changing session aborts the report instead of mixing accounts", async () => {
  let calls = 0;
  await assert.rejects(
    runBetaChecks({
      firestore: sdk(),
      db: {},
      user: { uid: "own" },
      peerHandle: "@peer",
      date: "2026-11-09",
      phase: "hidden",
      isCurrent: () => ++calls < 3,
    }),
    /account changed/,
  );
});
