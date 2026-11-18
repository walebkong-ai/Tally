# Prompt 2 production readiness review

Reviewed November 17, 2026 (America/Toronto). Baseline: production v77, GitHub application `a85c5477bef97431713c27da1f90046d3a1a09e4`, documentation HEAD `21548e1680888f122592bf408318f1009b2012d7`, Sites source `162ec37eba4cf19fcbd22255c9ddff4f61708293`. All 21 baseline application/assets/configuration files compared between GitHub HEAD and the opened Sites checkout matched. GitHub remote main also matched the local baseline before release preparation. Existing uncommitted dashboard work was retained and reviewed.

## Assessment

| Area | Decision | Evidence / limit |
| --- | --- | --- |
| Dashboard correctness | PASS | Actual generated controllers and pure derived-data utilities reviewed; progress, misses, edits, deletion, pins and dates exercised |
| Import integration | PASS | Reuses v77 controllers/storage; single and batch browser saves update Today without reload; drafts and duplicate protections covered |
| Scoring and privacy | PASS | Existing ranking builders, validation, account and accepted-owner filters retained; scoring/import/sync/account modules and rules unchanged |
| Authentication/synchronization | CONDITIONAL PASS | Four actual Auth/Firestore emulator integration tests pass, including new dashboard account-switch/offline scenario; no fresh production Google OAuth or cross-device write check |
| Responsive usability | CONDITIONAL PASS | Chrome 320/390/768/1440 viewport widths verified, readable cards and no horizontal overflow; native iOS Simulator controls unavailable/stale, no physical-iPhone claim |
| Controlled invited release | CONDITIONAL PASS | No demonstrated code blocker remains; publication and provenance verification recorded in the deployment report after release |

## Review finding and correction

The initial dashboard preview did not explain cached/stale friend standings when connectivity or request updates were paused. Added a small status paragraph driven only by existing account readiness, `navigator.onLine`, `requestsError` and `requestsLoading`. It distinguishes offline cached data, waiting for account sync, paused updates and checking connections, and directs users to the existing Friends refresh action. The normal signed-in state also explains that these are available shared results and can be refreshed. It neither promises live peer-score streaming nor exposes error payloads.

The status refreshes during existing friend-sync rendering and online/offline events. It performs no network operation and adds no listener to Firebase. A regression exercises all availability states, guest omission and zero saves. No unrelated feature was added.

No scoring formula, score eligibility, authentication implementation, persistence schema, friendship lifecycle or production rules were changed. The dashboard module derives data from the existing visible catalogue, pins and own entries. The existing ranking builders determine places and points; Today selects up to three authorized ranked friends and displays the separately computed user row. Hidden answers, private notes and raw pastes are not passed to its rank renderer. Publicly revealed answers are also not rendered in this preview.

Missing games/retired IDs and duplicate pins are ignored safely. No pins produces onboarding. Pending means no result; a miss or unfinished attempt is recorded but not completed. Valid scored/ranked rounds have explicit labels. Deletion removes the derived completion immediately; activity remains for any other own attempts that day. Pin order uses the existing selected array, without automatic score/streak sorting or viewport truncation. Republishing does not rewrite old results.

## Verification

- Optimized Swift production build and static generation: PASS.
- Syntax checks: generated app, new dashboard module and existing importer, scoring and sync modules: PASS.
- **288 application tests passed, 0 failed** (268 v77 + 19 dashboard implementation tests + 1 review regression).
- **27 Firestore security-rule tests passed, 0 failed** against the dedicated loopback demo emulator.
- **4 Auth/Firestore integration tests passed, 0 failed** against dedicated loopback demo emulators. These are top-level tests containing multiple scenarios, not four Google OAuth tests.
- New integration coverage executes actual Auth emulator sign-out/sign-in between independent accounts with different pins/scores. It uses the generated import/sync code and actual Firestore SDK, confirms local offline progress before upload, then confirms pending changes clear after retry. After switching, Today uses the second account's 5/6 and one-game denominator, without the first account's Connections record; switching back restores 3/6, two pins and two completed results.
- Existing integration scenarios cover connected save, independent authenticated-session read, reload, disabled Firestore SDK network, retry after an injected transport error, concurrent revision conflicts and explicit resolution, all 19 parser payloads and account switching during a suspended transaction. They do not use production accounts or exercise Google OAuth.
- Midnight, foreground/background date changes, yesterday-active streaks and DST/year/leap-day/time-zone boundaries passed existing and new generated-controller/calendar regressions. No device clock was changed.
- `git diff --check`: PASS.
- Firebase CLI emits pre-existing Node deprecation/emulator API warnings; test assertions and commands exit successfully. These are not worker/browser failures.

The new integration test is in `Tests/import-sync-emulator.test.mjs`; the cache-availability regression is in `Tests/dashboard.test.cjs`. Its DOM harness is `Tests/helpers/dashboard.cjs`. Actual rendering/status wiring lives in `Sources/SolvrySite/main.swift`. Existing implementation files/evidence are listed in [TODAY_DASHBOARD_REPORT.md](../Operations/TODAY_DASHBOARD_REPORT.md).

### Browser interactions

Localhost `127.0.0.1:8201`, guest storage only, synthetic results. No production score was saved, replaced, deleted or moved.

- Zero-pin onboarding inspected, then pins selected in a deliberately different order. Cards retain that order. Unpinning removes the game from progress while preserving its result under Other results; repinning appends it through the existing control.
- Single Wordle import changes progress from 0/6 to 1/6. Connections + Mini batch changes it to 3/6. Returning to Today requires no reload.
- Edit Wordle opens the existing manual form with the correct game/day/4 guesses. Replacing with 2 guesses updates its card to 2/6.
- Unpin Wordle produces 2/5; retained history remains accessible. Deleting the synthetic Mini result through the real confirmation dialog reduces progress from 2/6 to 1/6 after Wordle was repinned.
- A new failed Wordle saves as X/6, Played · Not solved; completion stays 1/6, while help/activity show one played-without-completion attempt.
- Selecting yesterday shows its empty historical progress and does not zero the current activity streak. Returning to today restores its results.
- The Krillion publisher link opens `https://krillion.io/` in a separate tab; observed page title is `Krillion · the daily dive`. No game was played or score submitted to that publisher.
- Browser console warnings/errors during the checked local interactions: none observed.
- In-app-browser 390-pixel viewport: all twelve card actions measured 44 pixels tall, equal 71-pixel widths per card, no horizontal overflow. Its later viewport changes did not take effect, so those attempted sizes are not counted as new evidence.
- Separate desktop Chrome session: actual DOM widths **320, 390, 768 and 1440** were observed after setting each requested viewport; document scroll width equaled viewport width at each size with six visible pinned cards. Temporary overrides were reset.
- Native iPhone 17 / iOS 26.4 Simulator was inspected, but its controls returned stale Safari accessibility state versus a lock-screen screenshot and then no available window. Native Safari navigation/input could not be verified in this review. Desktop viewport testing is not substituted for native-iOS proof.

Evidence: [release mobile](today-dashboard/release-mobile.png) (in-app browser, synthetic saved/failed results) and [release desktop](today-dashboard/release-desktop.png) (Chrome, six pending pins). Earlier populated desktop/mobile screenshots remain in the implementation report.

## Performance and database traffic

Current review run, same synthetic 1,095-day history / six pins / fifty measured renders after ten warmups: median **1.448 ms**, p95 **2.113 ms**, six visible-catalog constructions per measured dashboard render. Original v77 comparison was median **16.052 ms**, p95 **16.903 ms**, 2,201 catalogue constructions. The benchmark measures VM calculation/string generation only, excluding layout, full application rendering and network I/O. Timing varies with host load; it is not production latency.

Removed repeated lifetime-history counting and catalogue-wide game-streak sorting from the Today path; the current activity-streak traversal reuses one catalogue list. Existing overall ranking rows are reused by the preview. No new Firestore reads/writes, queries or persisted derived totals. Existing friend refresh still loads available shared history through the pre-existing per-game queries; large-history scalability is an inherited concern.

Live rule read-back before release confirmed ruleset `projects/solvry-walebkong/rulesets/0ab73c61-45eb-49d0-9d8a-6d8786b5acc1`, SHA-256 `f555211b4ae54a53f672629c8b89b64a91a9203e421fd2530a564da35006b513`. Do not deploy or weaken rules for this client-only change. Site access remains the existing custom invited audience, policy revision 2.

## Release and rollback gate

The candidate is ready for controlled invited publication, not a declaration that production OAuth/cross-device/mobile verification is complete. Commit the reviewed source, keep the worktree clean, synchronize exact source files to the existing Sites checkout, rebuild/test/package through the supported source helper, and save/deploy that exact pushed Sites commit and archive. Include `assets/dashboard.mjs` with matching `app.js?v=47`, CSS `v=42` and all unchanged modules. No database migration is required.

The existing production browser session is signed in and has real history. It was inspected read-only and left unchanged; it was not used for write/delete/account-switch tests or reloaded as a test account. These production checks remain blocked on a disposable authorized account/session. Do not treat emulator success as production sign-in/sync success.

Preferred rollback is the verified **v77** saved client:

- Saved version: `appgprj_6abd6478c7a081918572401c942f954d~appgver_b3ee14ab8bc88191bbff02f62939ca67`.
- Sites source: `162ec37eba4cf19fcbd22255c9ddff4f61708293`.
- Archive: `sha256:e6d8c9ced5e8e76ce9fd7e32fa0865149924825c09120c69d1e7c62c9154678d`.

Confirm current audience and fetch that exact saved version, then deploy it with Sites `deploy_site_version`. Poll a nonterminal result until success and verify its returned version/source. Preserve current Firestore rules, account schema and all user data. Rollback is a complete website/assets publication, not a data restore. No live rollback mutation is needed to establish compatibility here: both clients use the same stored-data and rule schemas, and the exact previous saved artifact is available. Record the new saved version after publication so it can be redeployed for a fix forward.

Remaining risks: self-reported scores and publisher format drift; memory-only unsaved drafts; pre-existing friend-history query scaling and refresh freshness; full pin lineups can require scrolling; older open tabs retain their prior client until refreshed; live Google/production multi-device verification and native mobile/assistive-technology checks remain incomplete.

## Publication outcome

The reviewed candidate was published as **v78** with a conditional pass for the existing invited audience. GitHub application commit `59799a5ce68c14948ad3028b517610343f07d42e`; Sites source `44ebb902d8826dd9a81cabf6ee32c695af777f40`. Native publication succeeded and static verification, unchanged-rule read-back and worker error checks completed. Exact deployment IDs, asset/HTML verification evidence, outstanding live/native checks and rollback instructions are in [DEPLOYMENT_V78.md](DEPLOYMENT_V78.md).
