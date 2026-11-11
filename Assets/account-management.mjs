import * as safety from "./sync-safety.mjs";

export function syncSummary({
  signedIn,
  online = true,
  ready,
  loading,
  saving,
  pending = 0,
  conflicts = 0,
  error = "",
  storageError = "",
  deleting = false,
  lastSyncedAt = "",
}) {
  if (storageError)
    return {
      label: "Device save needs attention",
      detail: storageError,
      tone: "error",
    };
  if (deleting)
    return {
      label: "Account deletion in progress",
      detail: "Sync is locked. Resume deletion in Account if interrupted.",
      tone: "error",
    };
  if (!signedIn)
    return {
      label: "Saved on this device",
      detail:
        "Sign in to sync eligible scores. Personal custom games stay on this device.",
      tone: "local",
    };
  if (!online)
    return {
      label: "Offline · saved on device",
      detail: `${pending} change${pending === 1 ? "" : "s"} waiting for a connection. Cloud changes are not confirmed.`,
      tone: "pending",
    };
  if (conflicts)
    return {
      label: "Review competing edits",
      detail: `${conflicts} competing edit${conflicts === 1 ? "" : "s"} need a choice in Account.`,
      tone: "error",
    };
  if (error)
    return { label: "Sync needs attention", detail: error, tone: "error" };
  if (loading)
    return {
      label: "Checking account…",
      detail: "Loading the account’s cloud copy. Device saves remain separate.",
      tone: "pending",
    };
  if (saving)
    return {
      label: "Syncing…",
      detail: "Saved on this device. Waiting for cloud confirmation.",
      tone: "pending",
    };
  if (!ready)
    return {
      label: "Cloud sync unavailable",
      detail: "Your account’s device copy is kept. Retry from Account.",
      tone: "error",
    };
  if (pending)
    return {
      label: `${pending} change${pending === 1 ? "" : "s"} waiting`,
      detail:
        "Saved on this device. Cloud sync has not confirmed these changes yet.",
      tone: "pending",
    };
  return {
    label: "Changes synced",
    detail: `Eligible account data matches the last confirmed cloud copy.${lastSyncedAt ? " Last checked: " + new Date(lastSyncedAt).toLocaleString() + "." : ""} Personal custom games remain device-only.`,
    tone: "success",
  };
}

export function makeExport(
  state,
  {
    records = null,
    coverage = "device-copy",
    now = new Date().toISOString(),
    requests = null,
    diagnostics = null,
    identity = null,
  } = {},
) {
  const ownEntries = {};
  for (const [date, games] of Object.entries(state.entries || {})) {
    for (const [gameId, people] of Object.entries(games)) {
      if (people.you)
        (ownEntries[date] ||= {})[gameId] = structuredClone(people.you);
    }
  }
  return {
    format: "solvry-data-export",
    version: 1,
    exportedAt: now,
    coverage,
    account: {
      uid: state.account?.uid || "",
      email: state.account?.email || "",
      provider: state.account?.provider || "",
    },
    identity: identity
      ? {
          uid: identity.uid,
          email: identity.email || "",
          displayName: identity.displayName || "",
          photoURL: identity.photoURL || "",
          providers: (identity.providerData || []).map(
            (provider) => provider.providerId,
          ),
        }
      : null,
    profile: structuredClone(state.profile),
    scores: ownEntries,
    customGames: structuredClone(
      (state.games || []).filter((game) => game.source === "custom"),
    ),
    pinnedGameIds: [...(state.pinnedGameIds || [])],
    friends: structuredClone(state.friends || []),
    requests: structuredClone(
      state.friendRequests || { incoming: [], outgoing: [] },
    ),
    preferences: { showDemoFriends: !!state.showDemoFriends },
    localGameProgress: structuredClone(state.solvryPlays || {}),
    competingEdits: structuredClone(state.syncConflicts || []),
    cloudRecords: records === null ? null : structuredClone(records),
    cloudRequests: requests === null ? null : structuredClone(requests),
    diagnostics: diagnostics === null ? null : structuredClone(diagnostics),
    note:
      coverage === "account-and-device"
        ? "Contains a fetched account snapshot plus this device’s own scores and unsynced edits. No cached friend scores or sign-in tokens."
        : coverage === "remaining-account-data"
          ? "Account deletion is in progress. Contains only remaining cloud data and this device copy; previously deleted records are absent."
          : "This device only. Other devices or cloud records may contain additional data. No cached friend scores or sign-in tokens.",
  };
}

export function validateScoreChange(state, gameId, fromDate, toDate, today) {
  const entry = state.entries?.[fromDate]?.[gameId]?.you;
  if (!entry)
    throw new Error("That score is no longer saved. Refresh and try again.");
  if (toDate) {
    if (
      !/^\d{4}-\d{2}-\d{2}$/.test(toDate) ||
      !Number.isFinite(Date.parse(toDate + "T12:00:00Z")) ||
      new Date(toDate + "T12:00:00Z").toISOString().slice(0, 10) !== toDate ||
      toDate > today
    )
      throw new Error("Choose a valid date that is not in the future.");
    if (toDate === fromDate) throw new Error("Choose a different date.");
    if (state.entries?.[toDate]?.[gameId]?.you)
      throw new Error(
        "A score already exists on that date. It was kept. Choose another date.",
      );
  }
  return structuredClone(entry);
}

export async function moveCloudScore({
  firestore: f,
  db,
  uid,
  gameId,
  fromDate,
  toDate,
  entry,
  base,
  isCurrent = () => true,
}) {
  const fromId = safety.resultRecordId(fromDate, gameId),
    toId = safety.resultRecordId(toDate, gameId);
  const fromRef = f.doc(db, "privateUsers", uid, "records", fromId),
    toRef = f.doc(db, "privateUsers", uid, "records", toId);
  const assertCurrent = () => {
    if (!isCurrent())
      throw new Error(
        "The active account changed. The date change was stopped.",
      );
  };
  const verify = (source, target) => {
    if (
      !source ||
      source.deleted ||
      source.revision !== (base[fromId]?.revision || 0) ||
      !safety.equal(
        safety.privateEntry(source.value),
        safety.privateEntry(entry),
      )
    )
      throw new Error(
        "This score changed on another device. Retry sync before changing its date.",
      );
    if (target && !target.deleted)
      throw new Error(
        "A cloud score already exists on that date. Both scores were kept.",
      );
    if ((target?.revision || 0) !== (base[toId]?.revision || 0))
      throw new Error(
        "The destination changed on another device. Retry sync before changing dates.",
      );
  };
  try {
    return await f.runTransaction(db, async (tx) => {
      const [a, b] = await Promise.all([tx.get(fromRef), tx.get(toRef)]);
      assertCurrent();
      const source = a.exists()
        ? safety.validateRecord(fromId, a.data())
        : null;
      const target = b.exists() ? safety.validateRecord(toId, b.data()) : null;
      verify(source, target);
      const movedEntry = safety.privateEntry(entry);
      const from = {
        ...safety.tombstone(source),
        schemaVersion: 2,
        revision: source.revision + 1,
      };
      const to = {
        kind: "result",
        gameId,
        date: toDate,
        deleted: false,
        value: movedEntry,
        schemaVersion: 2,
        revision: (target?.revision || 0) + 1,
      };
      tx.set(fromRef, { ...from, updatedAt: f.serverTimestamp() });
      tx.set(toRef, { ...to, updatedAt: f.serverTimestamp() });
      tx.set(
        f.doc(db, "sharedScores", uid, "games", gameId, "results", fromDate),
        safety.sharedResult(from, uid),
      );
      tx.set(
        f.doc(db, "sharedScores", uid, "games", gameId, "results", toDate),
        safety.sharedResult(to, uid),
      );
      return { [fromId]: from, [toId]: to };
    });
  } catch (error) {
    assertCurrent();
    if (
      ["permission-denied", "aborted", "failed-precondition"].includes(
        error.code,
      )
    )
      throw new Error(
        "The account or score changed while moving it. Retry sync and review both dates.",
      );
    throw error;
  }
}

export function purgeAccountStorage(storage, prefix, uid, legacyKeys = []) {
  const key = safety.storageKey(prefix, uid),
    keys = [];
  for (let i = 0; i < storage.length; i++) {
    const name = storage.key(i);
    if (name === key || name === key + ':ops' || name?.startsWith(key + ":draft:")) keys.push(name);
  }
  for (const name of legacyKeys) {
    try {
      if (JSON.parse(storage.getItem(name) || "null")?.account?.uid === uid)
        keys.push(name);
    } catch {
      /* An unreadable unscoped archive has no verifiable owner. */
    }
  }
  for (const name of keys) storage.removeItem(name);
}

export async function cleanupAccountData({
  firestore: f,
  db,
  uid,
  isCurrent = () => true,
  progress = () => {},
}) {
  const check = () => {
    if (!isCurrent())
      throw new Error(
        "The active account changed. Deletion is paused; sign back in to resume.",
      );
  };
  const remove = async (refs) => {
    for (let i = 0; i < refs.length; i += 200) {
      check();
      const batch = f.writeBatch(db);
      refs.slice(i, i + 200).forEach((ref) => batch.delete(ref));
      await batch.commit();
      check();
    }
  };
  check();
  const records = await f.getDocsFromServer(
    f.collection(db, "privateUsers", uid, "records"),
  );
  check();
  const games = [
    ...new Set(
      records.docs
        .map((item) => item.data())
        .filter((r) => r.kind === "result")
        .map((r) => r.gameId),
    ),
  ];
  progress("Removing your profile and friend requests…");
  await remove([f.doc(db, "profiles", uid), f.doc(db, "clientHealth", uid)]);
  for (const field of ["fromUid", "toUid"]) {
    const requests = await f.getDocsFromServer(
      f.query(f.collection(db, "friendRequests"), f.where(field, "==", uid)),
    );
    check();
    await remove(requests.docs.map((item) => item.ref));
  }
  progress("Removing shared scores…");
  for (const gameId of games) {
    const shared = await f.getDocsFromServer(
      f.collection(db, "sharedScores", uid, "games", gameId, "results"),
    );
    check();
    await remove(shared.docs.map((item) => item.ref));
  }
  // Private records are removed last: they remain the directory of shared paths on retries.
  progress("Removing private account records…");
  await remove(records.docs.map((item) => item.ref));
  check();
}
