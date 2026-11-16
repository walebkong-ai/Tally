# Correctness and safety release — prepared November 16, 2026

Base inspected: `722e1914744f433c265d3cd1051f335a3c54e21c`, clean working tree.
This change set is prepared in the Tally checkout for GitHub. Publishing the source does not deploy the
application or rules; no production data has been changed.
Swift static generation, vanilla JavaScript, Google authentication, storage namespaces, private/shared
score projections, and the cream/teal visual design remain in place. No new runtime dependency.

## Root causes and changes

### Friendship authorization

Previously either accepted pair document (`A__B` or `B__A`) authorized reads independently, and the
client removed only one document. It could also re-add the other accepted copy to the local roster.

The rules now honor an explicit `removed` record in either orientation as a veto on shared-score
reads in both directions. A single accepted legacy orientation, or two accepted legacy orientations
with no removal, remains accepted. Arbitrary document IDs cannot authorize score reads.

The client reads both pair documents in each lifecycle transaction, reuses a lone legacy orientation,
removes both accepted copies atomically, and purges the revoked peer's cached scores from the UI.
New requests cannot introduce a second active opposite document. The recipient alone can accept;
neither a stale pending request nor a leftover accepted document can undo a removal.

On an explicit new invitation, the client reopens a closed record and atomically marks a closed or
already-revoked duplicate `superseded`. Both documents remain stored. The rules require the opposite
record to transition from absent/closed to a new sender-owned pending invitation in the same atomic
operation. Superseding by itself, accepting a superseded record, or merely touching an old pending
request is denied. A new recipient acceptance is still required before access resumes.

Request field/participant checks, status-only updates, private-record isolation, deletion locks,
and participant-scoped request queries remain enforced. New invitation fields have explicit bounds.

### Score eligibility

Legacy score readers accepted zero completion times and numeric substrings. Placement eligibility
was separate from performance eligibility, allowing impossible results to receive placement points.

`Assets/game-scoring.mjs` now provides shared `timeSeconds` and `isRankable` gates. Both leaderboard
modes reject zero/malformed times, invalid units/denominators, out-of-range scores, missed attempts,
and unfinished solve puzzles. Manual Mini/time entry and Mini paste validation reject zero times.
Real zero-point rounds and valid signed custom scores remain eligible. Completed Strands `No hints`
results now read correctly as zero hints; unverified pasted Strands results remain unranked.

Stored results are not rewritten or deleted. Invalid historical entries remain visible but unranked.
Valid historical times, including imported hour formats, rank labels, guesses, bounds, and real
zero-point results are covered by regression tests. Derived totals may change where the prior reader
incorrectly awarded points; scoring formulas and placement schedules are unchanged.

### Date and streaks

The old current-date constant never advanced, and the dashboard streak required an entry today.
The day is now checked every 30 seconds while visible, on focus, pageshow, visibility return, online
recovery, and before a manual save. Date bounds and derived views refresh on a day change.

- **Activity streak:** consecutive local calendar days with any recorded personal attempt, including
  a miss. An empty today still permits a streak ending yesterday. Future/friend-only records do not count.
- **Completion streak:** consecutive days with a valid completed puzzle or scored round (including
  a valid Spelling Bee rank). Missed/unfinished solve attempts do not count. A miss today breaks this
  streak; an unfinished attempt leaves yesterday's opportunity active until today's day expires.

Both use local calendar arithmetic at noon across DST/month/year changes. The selected historical
date does not determine the current streak. A clean current-day view follows the new day; historical
views, manual drafts, paste drafts, separately selected entry dates, and inactive-game paste drafts
keep their original dates. An outstanding clipboard read is invalidated when the default date advances.
Rollover does not write scores, trigger cloud synchronization, or change an existing result's date.

## Release sequencing and compatibility — required before deployment

1. Review the diff and run the build and tests below. Inspect a current encrypted backup and confirm
   recovery access. Do not use a production write as a test.
2. With authorized operator access, inventory legacy pair states read-only. Ordinary single accepted
   records need no migration. Duplicate accepted records remain authorized until either is removed.
   An ambiguous `accepted` + `removed` pair is intentionally treated as revoked; require an explicit
   new invitation and recipient acceptance rather than trusting client-written timestamp strings.
   No bulk deletion, automatic acceptance, or forced canonical-ID rewrite is needed.
3. Deploy **Firestore rules first**, retaining `system/security.accountDataVersion = 2`. This is an
   additive `superseded` request status; there are no new collections, record fields, or indexes.
   Review and verify the prototype rules before broadly sharing the application.
4. Publish the matching generated client **and** `Assets/game-scoring.mjs` together. Cache versions
   are `app.js?v=44` and `game-scoring.mjs?v=2`. Do not deploy the client ahead of the rules: duplicate
   cleanup needs the new status transition. The separate Sites checkout has not been synchronized
   by this local-only task; package these reviewed source changes when preparing that release.
5. Refresh existing tabs. Old clients can still read ordinary connections and remove a friend;
   the new server veto protects removal even if they update only one copy. Old clients may get a
   permission error re-inviting a duplicate pair; refresh to use the updated atomic flow.
6. In a controlled beta, verify two-account request/accept/remove/reconnect, denied peer reads after
   removal, hidden-answer isolation, a valid/zero Mini result, and mobile date rollover with a draft.
   Emulator and isolated guest browser checks do not replace this post-deployment smoke check.

**Rollback:** retain these revocation rules even if the client is rolled back. Do not restore the old
OR-only friendship authorization. The schema-2 fallback in `Operations/rollback.json` can read the
unchanged score schema, but older clients retain their old scoring/date bugs and duplicate re-invites
can fail safely. Prefer a client fix forward. Application rollback is not a database restore.

## Verification

Run from the Tally checkout after a fresh build:

```sh
swift run solvry-site
node --check dist/app.js
node --check Assets/game-scoring.mjs
npm test
npm run test:rules
git diff --check
```

Verified November 16, 2026: the Swift package built and generated `dist/`, both JavaScript syntax
checks passed, **192 application tests passed** (175 original + 17 added), and **27 Firestore tests
passed** (20 original + 7 added). `git diff --check` passed. The package build used a temporary
SwiftPM scratch directory and compiler cache; source generation ran from this checkout.

The rules command uses only the local `demo-solvry-safety` emulator and requires Java 21+.
Tests exercise the actual client transactions against that emulator as well as direct adversarial writes.
Test fixture migration calls that seed legacy duplicates use disabled rules only inside the emulator.

Application coverage adds duplicate-cache ordering, atomic removal/re-invitation, noncanonical reuse,
malicious path rejection, zero/malformed/boundary scores, valid-history preservation, midnight and
suspended-tab rollover, draft/clipboard protection, activity/completion distinctions, DST and date gaps.
Rules coverage adds legacy preservation, duplicate revocation in both directions, query revocation,
fresh consent, stale-request resurrection attempts, double-invitation batches, impersonation, oversized
requests, arbitrary paths, and unauthorized reads.

An isolated localhost browser check (guest only, no production writes) observed zero-time Mini
rejection, valid `00:54` saving, automatic November 16→17 rollover with activity streak retained,
and November 17→18 visibility-return rollover preserving unsaved Wordle guesses and their original
entry date while updating the date limit.

## Remaining limits

Previously downloaded/cached friend information cannot be recalled from another person's device.
Rule checks prevent new authorized server reads after removal. Scores remain self-reported; format
and bounds validation does not verify publisher results. Unique handle reservations and request
rate limiting remain separate follow-up work. The wider audit's importing/dashboard/social/history
redesigns and backup improvements are outside this patch.

## Exact source files changed

- `Sources/SolvrySite/main.swift`
- `Assets/game-scoring.mjs`
- `firestore.rules`
- `Tests/firestore-rules.test.mjs`
- `Tests/friends-leaderboard.test.cjs`
- `Tests/game-organization.test.cjs`
- `Tests/parser-audit.test.cjs`
- `Tests/performance-scoring.test.cjs`
- `Tests/share-import.test.cjs`
- `Tests/date-rollover.test.cjs` (new)
- `Operations/CORRECTNESS_SAFETY_RELEASE.md` (this document, new)

`dist/` is regenerated, ignored build output. Tests that execute extracted browser functions now supply
its scoring-module dependency and use realistic score fixtures; they continue exercising the original
features as well as the new regression cases.
