// Account-scoped persistence and explicit, revisioned sync records.
export function equal(a, b) {
  return canonical(a) === canonical(b);
}

function canonical(value) {
  if (Array.isArray(value))
    return JSON.stringify(value.map((item) => JSON.parse(canonical(item))));
  if (value && typeof value === "object") {
    return JSON.stringify(
      Object.fromEntries(
        Object.keys(value)
          .sort()
          .filter((key) => value[key] !== undefined)
          .map((key) => [key, JSON.parse(canonical(value[key]))]),
      ),
    );
  }
  return JSON.stringify(value ?? null);
}

export function storageKey(prefix, uid = "") {
  return `${prefix}:${uid ? "account:" + encodeURIComponent(uid) : "guest"}`;
}

export function payload(record) {
  if (!record) return null;
  const { revision, updatedAt, schemaVersion, ...value } = record;
  return value;
}

export function tombstone(record) {
  return { ...payload(record), deleted: true, value: null };
}

export function gameRecordId(id) {
  return `game_${id}`;
}
export function resultRecordId(date, gameId) {
  return `result_${date}_${gameId}`;
}

export function definitionKey(game) {
  return canonical({
    id: game.id,
    name: game.name,
    type: game.type,
    officialUrl: game.officialUrl || "",
  });
}

export function localRecords(state) {
  const records = {
    profile: {
      kind: "profile",
      deleted: false,
      value: {
        name: state.profile?.name || "You",
        handle: state.profile?.handle || "@solvry",
      },
    },
  };
  for (const [date, games] of Object.entries(state.entries || {})) {
    for (const [gameId, entries] of Object.entries(games || {})) {
      if (entries?.you)
        records[resultRecordId(date, gameId)] = {
          kind: "result",
          date,
          gameId,
          deleted: false,
          value: entries.you,
        };
    }
  }
  for (const game of state.games || []) {
    if (game.source === "custom")
      records[gameRecordId(game.id)] = {
        kind: "game",
        gameId: game.id,
        deleted: false,
        value: { ...game, definitionKey: definitionKey(game) },
      };
  }
  for (const friend of state.friends || []) {
    if (
      friend.status !== "demo" &&
      !["mira", "jay", "nolan"].includes(friend.id)
    )
      records[`friend_${encodeURIComponent(friend.id)}`] = {
        kind: "friend",
        personId: friend.id,
        deleted: false,
        value: friend,
      };
  }
  for (const gameId of state.pinnedGameIds || [])
    records[`pin_${gameId}`] = {
      kind: "pin",
      gameId,
      deleted: false,
      value: true,
    };
  records.preferences = {
    kind: "preferences",
    deleted: false,
    value: { showDemoFriends: !!state.showDemoFriends },
  };
  records.plays = {
    kind: "plays",
    deleted: false,
    value: state.solvryPlays || {},
  };
  return structuredClone(records);
}

export function cloudRecords(state, colorDate = () => "") {
  const records = localRecords(state);
  const base = state.cloudBase || {};
  const games = new Map((state.games || []).map((game) => [game.id, game]));
  delete records.preferences;
  delete records.plays;
  for (const [id, record] of Object.entries(records)) {
    const game = games.get(record.gameId);
    if (record.kind === "profile") {
      record.value.handleLower = String(record.value.handle)
        .trim()
        .toLowerCase()
        .replace(/^@/, "");
    }
    if (record.kind === "game") {
      if (game.sharing !== "friends") {
        if (!base[id]) {
          delete records[id];
          continue;
        }
        record.value = { id: game.id, sharing: "personal" };
      } else {
        record.value = {
          id: game.id,
          name: game.name,
          type: game.type,
          officialUrl: game.officialUrl || "",
          sharing: "friends",
          definitionKey: definitionKey(game),
        };
      }
    }
    if (record.kind === "result") {
      if (!game || (game.source === "custom" && game.sharing !== "friends")) {
        if (base[id]) records[id] = payload(base[id]);
        else delete records[id];
        continue;
      }
      record.value = privateEntry(record.value);
      const dailyDate =
        record.gameId === "color" ? colorDate(record.value, record.date) : "";
      if (dailyDate) record.value.dailyDate = dailyDate;
    }
    if (
      record.kind === "pin" &&
      game?.source === "custom" &&
      game.sharing !== "friends"
    )
      delete records[id];
  }
  for (const [id, record] of Object.entries(base)) {
    if (!records[id])
      records[id] = record.deleted ? payload(record) : tombstone(record);
  }
  return records;
}

export function privateEntry(entry) {
  if (
    !["solved", "played", "missed"].includes(entry.result) ||
    typeof entry.score !== "string"
  )
    throw new Error(
      "A saved result has an unsupported format. Review it before syncing.",
    );
  return {
    score: entry.score,
    result: entry.result,
    source: entry.source === "manual" ? "manual" : "official-share",
    reveal: entry.reveal === true,
    answer: typeof entry.answer === "string" ? entry.answer : "",
    note: typeof entry.note === "string" ? entry.note : "",
    shareText: typeof entry.shareText === "string" ? entry.shareText : "",
    grid: Array.isArray(entry.grid)
      ? entry.grid.filter((line) => typeof line === "string")
      : [],
  };
}

export function sharedResult(record, uid) {
  const shared = {
    schemaVersion: 2,
    revision: record.revision,
    ownerUid: uid,
    gameId: record.gameId,
    date: record.date,
    deleted: !!record.deleted,
  };
  if (record.deleted) return shared;
  const entry = record.value;
  Object.assign(shared, {
    score: entry.score,
    result: entry.result,
    source: entry.source,
    reveal: entry.reveal === true,
  });
  if (entry.reveal === true && entry.answer) shared.answer = entry.answer;
  if (entry.dailyDate === record.date && record.gameId === "color")
    shared.dailyDate = record.date;
  return shared;
}

export function validateRecord(id, record) {
  if (
    !record ||
    record.schemaVersion !== 2 ||
    !Number.isInteger(record.revision) ||
    record.revision < 1 ||
    typeof record.deleted !== "boolean"
  )
    throw new Error("Account data uses an unsupported sync format.");
  const expected = {
    profile: "profile",
    preferences: "preferences",
    plays: "plays",
    game: gameRecordId(record.gameId),
    result: resultRecordId(record.date, record.gameId),
    pin: `pin_${record.gameId}`,
    friend: `friend_${encodeURIComponent(record.personId)}`,
  }[record.kind];
  if (id !== expected || ["preferences", "plays"].includes(record.kind))
    throw new Error("Account data contains an invalid record.");
  if (
    record.kind === "result" &&
    (!/^\d{4}-\d{2}-\d{2}$/.test(record.date) ||
      !/^[a-z0-9-]{1,180}$/.test(record.gameId))
  )
    throw new Error("Account data contains an invalid result key.");
  return structuredClone(record);
}

export function mergeEdits(base, local, remote) {
  const records = structuredClone(remote);
  const conflicts = [];
  for (const [id, record] of Object.entries(base)) {
    if (!remote[id]) records[id] = tombstone(record);
  }
  for (const id of new Set([...Object.keys(base), ...Object.keys(local)])) {
    const previous = payload(base[id]);
    const edited = local[id]
      ? payload(local[id])
      : base[id]
        ? tombstone(base[id])
        : null;
    const current = payload(remote[id]);
    if (equal(edited, previous)) continue;
    if (!equal(current, previous) && !equal(current, edited)) {
      conflicts.push({ id, local: edited, remote: remote[id] || null });
    } else if (edited) {
      records[id] = edited;
    }
  }
  return { records, conflicts };
}

export function applyRecord(state, record) {
  if (!record) return;
  const value = record.deleted ? null : record.value;
  if (record.kind === "profile" && value)
    state.profile = { id: "you", name: value.name, handle: value.handle };
  if (record.kind === "result") {
    state.entries[record.date] ||= {};
    state.entries[record.date][record.gameId] ||= {};
    if (value)
      state.entries[record.date][record.gameId].you = structuredClone(value);
    else delete state.entries[record.date][record.gameId].you;
  }
  if (record.kind === "game") {
    const game = state.games.find((item) => item.id === record.gameId);
    if (!value || value.sharing !== "friends") {
      if (game) game.sharing = "personal";
    } else {
      const definition = {
        ...value,
        source: "custom",
        dailyRanked: false,
        logo: "custom",
      };
      if (game) Object.assign(game, definition);
      else state.games.push(definition);
    }
  }
  if (record.kind === "friend") {
    state.friends = state.friends.filter(
      (friend) => friend.id !== record.personId,
    );
    if (value) state.friends.push(structuredClone(value));
  }
  if (record.kind === "pin") {
    state.pinnedGameIds = state.pinnedGameIds.filter(
      (id) => id !== record.gameId,
    );
    if (value) state.pinnedGameIds.push(record.gameId);
  }
  if (record.kind === "preferences" && value)
    state.showDemoFriends = !!value.showDemoFriends;
  if (record.kind === "plays" && value)
    state.solvryPlays = structuredClone(value);
}

export function applyRecords(state, records) {
  // Definitions precede results so a newly joined custom game's data stays usable.
  const ordered = Object.values(records).sort(
    (a, b) => Number(b.kind === "game") - Number(a.kind === "game"),
  );
  for (const record of ordered) applyRecord(state, record);
  return state;
}

export function conflictKey(conflict) {
  return canonical(conflict);
}

export function combineConflicts(...groups) {
  return [
    ...new Map(
      groups
        .flat()
        .map((conflict) => [`${conflict.scope}:${conflict.id}`, conflict]),
    ).values(),
  ];
}

export function readLocal(storage, key, fallback) {
  const raw = storage.getItem(key);
  let state = raw ? JSON.parse(raw) : structuredClone(fallback);
  state.localWriters ||= {};
  state.syncConflicts ||= [];
  state.cloudBase ||= {};
  state.resolvedConflicts ||= [];
  const drafts = [];
  for (let index = 0; index < storage.length; index++) {
    const name = storage.key(index);
    if (name?.startsWith(key + ":draft:"))
      drafts.push(JSON.parse(storage.getItem(name)));
  }
  for (const draft of drafts) {
    state.syncConflicts = combineConflicts(
      state.syncConflicts,
      draft.syncConflicts || [],
    );
    state.resolvedConflicts = [
      ...new Set([
        ...state.resolvedConflicts,
        ...(draft.resolvedConflicts || []),
      ]),
    ];
    for (const [id, record] of Object.entries(draft.cloudBase || {})) {
      if ((record.revision || 0) > (state.cloudBase[id]?.revision || 0))
        state.cloudBase[id] = record;
    }
    if (state.localWriters[draft.writer] >= draft.sequence) continue;
    const merged = mergeEdits(draft.base, draft.records, localRecords(state));
    applyRecords(state, merged.records);
    state.syncConflicts = combineConflicts(
      state.syncConflicts,
      merged.conflicts.map((conflict) => ({ ...conflict, scope: "device" })),
    );
    for (const [id, record] of Object.entries(draft.records)) {
      if (
        !equal(payload(record), payload(draft.base[id])) &&
        equal(payload(merged.records[id]), payload(record))
      ) {
        if (draft.cloudBase[id]) state.cloudBase[id] = draft.cloudBase[id];
        else delete state.cloudBase[id];
      }
    }
    state.localWriters[draft.writer] = draft.sequence;
  }
  state.syncConflicts = state.syncConflicts.filter(
    (conflict) => !state.resolvedConflicts.includes(conflictKey(conflict)),
  );
  return state;
}

export function writeLocal(storage, key, writer, baseline, state, fallback) {
  const stored = readLocal(storage, key, fallback);
  const edits = mergeEdits(baseline, localRecords(state), localRecords(stored));
  if (edits.conflicts.length)
    throw new Error(
      "Another tab changed the same data. Reload before saving this edit.",
    );
  const next = structuredClone(state);
  applyRecords(next, edits.records);
  next.localWriters = { ...stored.localWriters, ...state.localWriters };
  const sequence =
    Math.max(
      next.localWriters[writer] || 0,
      JSON.parse(storage.getItem(key + ":draft:" + writer) || "null")
        ?.sequence || 0,
    ) + 1;
  const draft = {
    writer,
    sequence,
    base: localRecords(stored),
    records: localRecords(next),
    cloudBase: next.cloudBase || {},
    syncConflicts: next.syncConflicts || [],
    resolvedConflicts: next.resolvedConflicts || [],
  };
  // This single durable write is the commit point. A failed cache write can be recovered.
  storage.setItem(key + ":draft:" + writer, JSON.stringify(draft));
  const recovered = readLocal(storage, key, fallback);
  recovered.cloudBase = next.cloudBase || {};
  recovered.resolvedConflicts = [
    ...new Set([
      ...recovered.resolvedConflicts,
      ...(next.resolvedConflicts || []),
    ]),
  ];
  recovered.syncConflicts = combineConflicts(
    recovered.syncConflicts,
    next.syncConflicts || [],
  ).filter(
    (conflict) => !recovered.resolvedConflicts.includes(conflictKey(conflict)),
  );
  recovered.account = next.account;
  recovered.selectedDate = next.selectedDate;
  recovered.activeGameId = next.activeGameId;
  // Official definitions come from the current release, not the older cache.
  // Custom definitions remain merged editable records, including other tabs' edits.
  if (Array.isArray(next.games)) {
    const builtins = next.games.filter((game) => game.source !== "custom");
    const builtinIds = new Set(builtins.map((game) => game.id));
    recovered.games = [
      ...structuredClone(builtins),
      ...(recovered.games || []).filter(
        (game) => game.source === "custom" && !builtinIds.has(game.id),
      ),
    ];
  }
  // Server-derived social caches are not editable records in the journal.
  // Keep this tab's fetched view while retaining the merged own-score records.
  recovered.friendRequests = structuredClone(
    next.friendRequests || { incoming: [], outgoing: [] },
  );
  recovered.entries ||= {};
  for (const day of Object.values(recovered.entries)) {
    for (const game of Object.values(day)) {
      for (const person of Object.keys(game)) if (person !== "you") delete game[person];
    }
  }
  for (const [date, day] of Object.entries(next.entries || {})) {
    for (const [gameId, game] of Object.entries(day)) {
      for (const [person, entry] of Object.entries(game)) {
        if (person === "you") continue;
        recovered.entries[date] ||= {};
        recovered.entries[date][gameId] ||= {};
        recovered.entries[date][gameId][person] = structuredClone(entry);
      }
    }
  }
  try {
    storage.setItem(key, JSON.stringify(recovered));
  } catch {
    /* The journal remains durable. */
  }
  return recovered;
}
