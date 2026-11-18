# Prompt 2 — Today dashboard local implementation

Reviewed and implemented November 17, 2026. Repository started clean at `21548e1680888f122592bf408318f1009b2012d7`, following v77 application commit `a85c5477bef97431713c27da1f90046d3a1a09e4`. This is an uncommitted, local-only candidate: **no push, deployment, production-record modification, or security-rule update was performed.**

## Before and after

| Area | v77 baseline inspected | Local candidate |
| --- | --- | --- |
| Summary | Three large metrics: selected-day results, activity streak, lifetime results | One compact pinned-game progress summary, completion bar, not-completed count and clearly labeled current activity streak |
| Game shortcuts | Catalogue sorted by pins/streaks, limited to 6/10/12 by viewport; one Open action | All visible pinned games in existing stored pin order, status, score, direct publisher Play and Add/Edit Result actions |
| Attention | Automatic sorting can change shortcut order | Explicit Not played filter; order stays stable in either view |
| Results | Separate list repeats saved game information | Pinned results live in cards; unpinned saved results remain in a collapsed Other results this day section |
| Competition | Top three group rows can include self and omit own position; preview uses daily period | Up to three ranked friends plus own group position/total; selected placement/performance method and daily/seven-day period are displayed |
| Activity | Five days labeled Recorded or empty | Seven local calendar days distinguish completions/scored rounds, played-only days and empty days, with focus/hover explanations |
| Empty state | Unpinned catalogue shortcuts appear by default | Choose games onboarding and an actionable Friends empty state |

The cream backgrounds, teal controls, pastel game states, serif title, logo, illustrations, primary navigation, account controls and existing scoring formulas remain in use. The desktop layout puts the game lineup beside competition/activity. Tablet and mobile stack these sections; mobile uses two card columns, falling back to one at 350 pixels and below. Dashboard action targets are 44 pixels tall.

## Reused features and new implementation

Reused:

- Existing Games pin controls and `state.pinnedGameIds`; its array order is authoritative. Users customize through Games. There is no new reorder workflow.
- Existing `scoreEntryForGame` and `game-scoring.mjs.isRankable` validation; no new scoring formula or parser.
- v77 Paste → Review → Save, batch review, duplicate protection, manual form, draft handling and durable local save/sync paths. The global Add score still opens the same importer. Game-specific Add preselects the game/date where safe; Edit opens the existing manual form with the saved entry. An unfinished manual draft is preserved before switching games.
- Existing shared-score projections, `visibleFriends`, account/owner checks, leaderboard builders and row renderer. The home preview consumes the ranking rows already computed by `renderScoreboards`, including existing ties and comparison-group places.
- Existing full render calls after imports, manual saves, corrections, deletions and cloud state changes; progress is derived afresh. Existing rollover timer/focus/pageshow/visibility handlers refresh the new views too.
- Current activity streak semantics: any own recorded attempt, including a miss; yesterday's streak stays active while today remains open. Selecting history does not redefine the current streak. Individual game completion streak logic remains unchanged.
- The global sync strip and Account sync detail. Dashboard progress includes device saves and explicitly refers users to that strip for cloud status.

New:

- Small pure `Assets/dashboard.mjs` module for tracked pins, result status, progress, seven-day activity, friend-row selection and safe publisher URLs.
- Dashboard card/progress markup and scoped CSS in the existing Swift generator.
- Ephemeral Not played filter and delegated card actions. The filter does not reorder or persist additional user data.
- Focusable activity descriptions, progressbar values and game/date-specific action labels.
- Focused generated-controller/module regression tests and a synthetic before/after dashboard benchmark.

## Status definitions

Only visible, non-retired pinned games count toward the daily denominator. Unknown pins are ignored; duplicates are counted once. Unpinned catalogue games and friend results do not affect this progress.

- **Completed:** an eligible validated result explicitly marked solved.
- **Scored / Rank recorded:** a valid points, depth, signed-score, grid or rank round whose existing scoring rules permit participation. This counts toward progress; it does not claim a solve.
- **Played · Not solved:** a recorded miss. Counts as activity, not completion.
- **Played:** a recorded attempt without verified completion. For example, an imported Strands recap retains v77's unverified-completion treatment until explicitly confirmed through manual entry.
- **Check result:** an invalid claimed completion; retained for correction, not counted as complete.
- **Not played:** no own result for the selected day.

The summary labels its numerator **completed or scored**. **Not completed** includes failed/unverified/invalid attempts as well as absent results; the separate **Not played** count/filter includes only absent results. This avoids claiming a failed daily puzzle is still unsaved. Pinning RNGdle or a custom game can include its valid round in personal progress even though existing combined-leaderboard rules exclude it; progress and competition are separate measures.

Zero pins shows onboarding and no misleading percentage. Historical progress uses the selected date; current streak uses today's local date. Future results are excluded from progress/activity. Activity counts all visible own games, including unpinned results, for the seven days ending on the selected date. A day with both a completion and a miss is shown as a completed day, with both counts in its accessible description.

## Files changed

Application:

- `Sources/SolvrySite/main.swift` — Today HTML/CSS, module import, cards/actions/progress/activity/friend preview; reuse scoreboard rows and cache the visible game list during activity-streak traversal. Generated cache keys: app `v=47`, CSS `v=42`, dashboard module `v=1`.
- `Assets/dashboard.mjs` — new derived-data utilities; imports the existing scoring module `v=2`.

Tests and evidence:

- `Tests/dashboard.test.cjs` — 19 focused regression tests.
- `Tests/helpers/dashboard.cjs` — VM harness extracting the actual generated controllers and using existing importer/storage/scoring modules.
- `Tests/dashboard-benchmark.cjs` — synthetic generated-dashboard benchmark; manually invoked, not part of correctness test timing.
- `Tests/date-rollover.test.cjs` — update the visible activity-streak label assertion to the clearer day activity streak label.
- `Tests/import-navigation.test.cjs` — supply real score entries and the new activity utility to the existing east-of-UTC history/streak test.
- `Operations/TODAY_DASHBOARD_REPORT.md` — this report.
- `QA/today-dashboard/before-desktop.png`, `before-mobile.png`, `after-desktop.png`, `after-mobile.png`, `zero-pins.png` — browser evidence.

`dist/` was regenerated locally and is ignored by Git, following the existing process. Firestore rules, Firebase configuration, authentication modules, sync/account-management modules, scoring module and importer module were not modified. No dependencies were added.

## Verification results

| Check | Result |
| --- | --- |
| Swift release build and generation | PASS |
| Generated `dist/app.js` syntax | PASS |
| Source and generated `dashboard.mjs` syntax | PASS |
| Full application suite | **287 passed, 0 failed** (268 existing + 19 new) |
| Firestore emulator rules suite | **27 passed, 0 failed** |
| Auth + Firestore importer sync suite | **3 passed, 0 failed** |
| Git whitespace/error check | PASS |
| Local browser desktop/mobile/tablet checks | PASS within scope below |

New coverage includes pin-only counts, duplicate/retired/unknown pins, stable order without truncation, zero pins, misses/unverified/invalid results, zero times, valid scored/ranked rounds, excluded/custom game tracking, historical and future dates, midnight refresh, DST/year/leap/calendar boundaries in Toronto/Tokyo/Honolulu/Kiritimati, actual v77 batch saves and duplicate retries, actual score-date correction/deletion controllers, importer game/date selection, unfinished manual/paste draft preservation, top three friends plus own rank and ties, accepted/removed/pending/foreign-owner visibility and suppression before account sync is ready, selected scoring period/method, offline/pending/error/synced badges, safe publisher URLs, private-field omission and read-only rendering.

Commands used from the repository:

```sh
CLANG_MODULE_CACHE_PATH=/private/tmp/solvry-correctness-module-cache swift run -c release --scratch-path /private/tmp/solvry-correctness-swiftpm solvry-site
node --check dist/app.js
node --check Assets/dashboard.mjs
node --check dist/assets/dashboard.mjs
npm test
npm run test:rules
npm run test:import-sync
node Tests/dashboard-benchmark.cjs
git diff --check
```

Emulator commands used the existing locally available Java 21 runtime at `/private/tmp/solvry-java-review/jdk-21.0.13+9-jre/Contents/Home`; the scripts target only `demo-solvry-safety` and `demo-solvry-import-readiness`. Logs showed successful exits and emulator shutdowns. These tests include existing permission revocation and private/shared-data restrictions; the rules themselves are unchanged.

### Browser environment and observed flows

Tested the generated site on localhost port 8199 in the Codex in-app browser, as a guest. Synthetic public-format results were saved only in that origin's guest storage; sample players were enabled through the existing Friends control. No production account was used.

Observed:

- Zero-pin onboarding and customization through Games.
- Six pins shown in the order pinned, with direct publisher links and Add/Edit controls.
- Dashboard Add opens the v77 importer. Saving Wordle + Connections as a reviewed batch updates both cards, 2/6 progress and activity without reloading.
- Edit Wordle opens the existing manual form showing 3/6 and the selected date.
- A failed Wordle on the prior date shows 0/6 complete, 1 played, no completion checkmark, and a played-only activity day. Returning to today restores its progress while retaining the current two-day activity streak.
- Reload retains saved data. Not played hides saved cards and preserves the relative order of the others; disabling it restores the full lineup.
- Sample friend results show their group positions and the user's own position, explicitly labeled as samples.
- Keyboard Tab reaches an activity day and exposes its full date/count tooltip.
- No horizontal page overflow at 320, 390, 768 or 1920 pixels. At 390 pixels, all card Play and Add/Edit controls measured 44 pixels tall and equal widths within each card. The 1440×1000 desktop preview shows the entire six-card lineup and sidebar within one screen.
- No warnings/errors in the browser console log during the checked interactions. A low-contrast secondary Play label found during visual review was corrected before the final screenshots.

This is **desktop responsive viewport testing, not native iOS Safari testing**. Native clipboard permission behavior, live Google sign-in, real-account cross-device sync and production network/permission smoke tests were not repeated in this local UI task. Their existing code paths were retained and emulator/application regressions passed.

## Performance inspection

Before and after used the same VM harness with 1,095 days of synthetic history, six pins, three local friend identities, ten warmups and fifty measured dashboard renders. It invokes generated dashboard calculation and HTML string rendering, not browser layout, Firebase I/O, the full application render or startup.

| Metric | Baseline | Local candidate |
| --- | ---: | ---: |
| Median | 16.052 ms | 1.267 ms |
| p95 | 16.903 ms | 1.433 ms |
| Visible-catalog constructions per measured render | 2,201 | 6 |

The main savings come from removing the full-history lifetime count from every dashboard render, avoiding catalogue-wide game-streak sorting for pinned cards, and constructing the visible catalogue once during the activity-streak traversal. Main application renders also share already-computed overall leaderboard rows with Today instead of recomputing them for the preview. These figures are synthetic comparative evidence, not a production latency guarantee. Rendering many pinned games still scales with the number selected and may require scrolling.

## Data, security and release considerations

No persistent progress totals, new schema, collections, indexes or database migration are required. Existing private answers, notes and raw pasted results stay in their existing storage; Today shows score summaries only. Existing friendship authorization and revocation, account-scoped storage, conflict resolution, offline journals and score history are preserved. No new Firestore reads/writes are introduced by the dashboard.

For a later authorized controlled deployment, commit/review this local work, rerun checks and generate/package the website with **`assets/dashboard.mjs` and all existing assets**. Keep the existing production security rules. Do not deploy only `app.js`, because the new module must be present. Follow the existing deployment and rollback procedures; rollback is the previous complete matching website/assets (v77), not a data restore or security-rule downgrade.

**Decision: ready for controlled-deployment review as a local candidate.** No known blocker was found in this scope. Production remains v77. A fresh authorized production preview/account smoke test should precede broader rollout. Physical mobile/assistive-technology behavior remains an unverified environment, and pin order is the existing stored order rather than a new drag-to-reorder feature. There is no monthly calendar or unrelated dashboard/social redesign in this change.

## Screenshots

Before: [Desktop](../QA/today-dashboard/before-desktop.png) · [Mobile viewport](../QA/today-dashboard/before-mobile.png)

After: [Desktop](../QA/today-dashboard/after-desktop.png) · [Mobile viewport](../QA/today-dashboard/after-mobile.png) · [Zero pins](../QA/today-dashboard/zero-pins.png)

## Subsequent production review

The local implementation record above describes the original development phase. A later authorized review added the friend-cache availability notice and regression, plus actual emulator account-switch/offline dashboard coverage. The candidate was committed and published as **v78**: 288 application, 27 security-rule and 4 Auth/Firestore integration tests passed. See [production review](../QA/TODAY_DASHBOARD_PRODUCTION_REVIEW.md) and [v78 deployment/provenance and rollback](../QA/DEPLOYMENT_V78.md) for the current release state and the remaining production/native verification limits.
