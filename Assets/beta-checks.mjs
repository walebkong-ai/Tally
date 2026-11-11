// Read-only client probes. No administrative credentials or database writes.
export function inspectProjection(data, expectation, expectedScore = "") {
  const allowed = new Set([
    "schemaVersion",
    "revision",
    "ownerUid",
    "gameId",
    "date",
    "deleted",
    "score",
    "result",
    "source",
    "reveal",
    "answer",
    "dailyDate",
  ]);
  const extras = Object.keys(data).filter((key) => !allowed.has(key));
  if (extras.length)
    throw new Error(
      "Unexpected fields in friend-visible record: " + extras.join(", "),
    );
  if (
    data.schemaVersion !== 2 ||
    data.deleted ||
    typeof data.reveal !== "boolean"
  )
    throw new Error("Unexpected shared-result schema or deletion state.");
  if (!data.reveal && Object.hasOwn(data, "answer"))
    throw new Error("A hidden answer was returned by the database.");
  if (
    expectation === "hidden" &&
    (data.reveal || Object.hasOwn(data, "answer"))
  )
    throw new Error(
      "The peer answer is not hidden yet. Confirm the owner synced answer sharing OFF.",
    );
  if (expectation === "revealed" && (!data.reveal || !data.answer))
    throw new Error(
      "The intentionally revealed answer has not reached this client.",
    );
  if (expectedScore && data.score !== expectedScore)
    throw new Error("Peer score differs from the expected beta score.");
  return {
    fieldNames: Object.keys(data).sort(),
    answerIncluded: Object.hasOwn(data, "answer"),
    revealed: data.reveal,
    scoreMatches: !expectedScore || data.score === expectedScore,
  };
}

export async function runBetaChecks({
  firestore: f,
  db,
  user,
  peerHandle,
  date,
  phase,
  expectedScore = "",
  isCurrent = () => true,
  onResult = () => {},
}) {
  if (!user?.uid)
    throw new Error(
      "Sign in to Solvry in this browser first, then return here.",
    );
  if (!["unconnected", "hidden", "revealed", "removed"].includes(phase))
    throw new Error("Choose a valid test phase.");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date))
    throw new Error("Choose the beta score date.");
  const report = {
    format: "solvry-beta-permission-report",
    version: 1,
    checkedAt: new Date().toISOString(),
    accountSuffix: user.uid.slice(-6),
    phase,
    date,
    results: [],
  };
  const checkSession = () => {
    if (!isCurrent())
      throw new Error(
        "The account changed during the check. Discard this run and start again.",
      );
  };
  const probe = async (name, operation, expectDenied = false) => {
    checkSession();
    let result;
    try {
      const details = await operation();
      checkSession();
      result = expectDenied
        ? { name, status: "FAIL", detail: "Read unexpectedly succeeded." }
        : { name, status: "PASS", ...(details ? { details } : {}) };
    } catch (error) {
      checkSession();
      result =
        expectDenied && error.code === "permission-denied"
          ? { name, status: "PASS", detail: "permission-denied" }
          : {
              name,
              status: "FAIL",
              detail: error.code || error.message || "Unknown error",
            };
    }
    report.results.push(result);
    onResult(result);
  };
  const normalized = String(peerHandle || "")
    .trim()
    .toLowerCase()
    .replace(/^@/, "");
  if (!normalized) throw new Error("Enter the other account’s Solvry handle.");
  const peers = await f.getDocsFromServer(
    f.query(
      f.collection(db, "profiles"),
      f.where("profile.handleLower", "==", normalized),
      f.limit(2),
    ),
  );
  checkSession();
  if (peers.docs.length !== 1 || peers.docs[0].id === user.uid)
    throw new Error("Choose the unique handle of the other beta account.");
  const peerUid = peers.docs[0].id;
  report.peerSuffix = peerUid.slice(-6);
  await probe("Read own private profile", async () => {
    const snap = await f.getDocFromServer(
      f.doc(db, "privateUsers", user.uid, "records", "profile"),
    );
    if (!snap.exists() || snap.data().schemaVersion !== 2)
      throw new Error(
        "Own cloud profile is missing. Finish Solvry sync first.",
      );
  });
  await probe("Own beta score exists", async () => {
    const snap = await f.getDocFromServer(
      f.doc(
        db,
        "privateUsers",
        user.uid,
        "records",
        "result_" + date + "_wordle",
      ),
    );
    if (
      !snap.exists() ||
      snap.data().deleted ||
      snap.data().schemaVersion !== 2
    )
      throw new Error(
        "Save and sync your own tagged beta score on this date first.",
      );
  });
  await probe(
    "Read peer private profile denied",
    () =>
      f.getDocFromServer(
        f.doc(db, "privateUsers", peerUid, "records", "profile"),
      ),
    true,
  );
  await probe(
    "Read peer private score denied",
    () =>
      f.getDocFromServer(
        f.doc(
          db,
          "privateUsers",
          peerUid,
          "records",
          "result_" + date + "_wordle",
        ),
      ),
    true,
  );
  await probe(
    "Read peer deletion marker denied",
    () => f.getDocFromServer(f.doc(db, "accountLifecycle", peerUid)),
    true,
  );
  await probe(
    "Legacy mixed document denied",
    () => f.getDocFromServer(f.doc(db, "users", user.uid)),
    true,
  );
  await probe(
    "Unscoped request listing denied",
    () => f.getDocsFromServer(f.collection(db, "friendRequests")),
    true,
  );
  await probe("Own sent-request query allowed", () =>
    f
      .getDocsFromServer(
        f.query(
          f.collection(db, "friendRequests"),
          f.where("fromUid", "==", user.uid),
        ),
      )
      .then(() => null),
  );
  await probe("Own received-request query allowed", () =>
    f
      .getDocsFromServer(
        f.query(
          f.collection(db, "friendRequests"),
          f.where("toUid", "==", user.uid),
        ),
      )
      .then(() => null),
  );
  const denied = phase === "unconnected" || phase === "removed";
  await probe(
    denied
      ? "Peer score read denied in this phase"
      : "Peer score projection matches privacy expectation",
    async () => {
      const snap = await f.getDocFromServer(
        f.doc(db, "sharedScores", peerUid, "games", "wordle", "results", date),
      );
      if (!snap.exists())
        throw new Error(
          "The peer beta score is missing. Save it and confirm sync before this phase.",
        );
      return inspectProjection(snap.data(), phase, expectedScore);
    },
    denied,
  );
  checkSession();
  report.passed = report.results.filter(
    (item) => item.status === "PASS",
  ).length;
  report.failed = report.results.length - report.passed;
  return report;
}
