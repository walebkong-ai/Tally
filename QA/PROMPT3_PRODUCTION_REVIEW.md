# Prompt 3 production readiness review

Review date: November 17, 2026 (America/Toronto). Inspected GitHub base `44427521a62913bb26e2d7af616e59df88982e48`; deployed application baseline is v76, GitHub application `7fbee187f8adf608de03740ccb4027f698363758`, Sites source `78bc7f3acf4aade910ffe8e79e7a93b6293e4c3a`. Native Sites confirmed v76 and its saved archive/source before this review. Existing work was preserved; no unrelated redesign or new game support was added.

This supersedes the initial local-only readiness decision in `Operations/FRICTIONLESS_IMPORT_REPORT.md`. Final publication identifiers and production smoke results are recorded separately in `QA/DEPLOYMENT_V77.md` after an authorized release.

## Decision by area

| Area | Decision | Evidence and limits |
|---|---|---|
| Batch importing | **PASS after fixes** | Independent success/error cards; retry without duplicate; explicit replacement; account binding; durable first-card recovery when the cache fails, reload occurs, and remaining cards retry. |
| Synchronization | **PASS in isolated emulators; CONDITIONAL PASS for production** | Actual Firebase Auth and Firestore SDK sessions cover connected/offline saves, journal reload, recovery, injected transport failure/retry, independent authenticated retrieval, conflict choice, idempotent revisions and account change during a transaction. Fresh production Google/cross-device verification still requires authorized isolated accounts and is not inferred from emulator success. |
| Mobile / clipboard | **CONDITIONAL PASS** | Safari in a real **iOS 26.4 Simulator runtime, iPhone 17** loaded the local app, accepted direct input and native copy/paste, and detected the fixture. This is not a physical iPhone test or desktop viewport emulation. Simulator coordinate clicks failed and web buttons were not exposed in its accessibility tree, so native programmatic clipboard permission/denial was not verified. Both a rejected clipboard API and missing API are covered by controller regressions; direct paste remains usable and drafts stay intact. |
| Parser correctness | **PASS after fixes** | All 19 source-derived fixtures: game detection, normalized equivalent duplicate, malformed outcome, mixed-game ambiguity; additional score/date/identifier/edition/failure boundaries. All 19 parsed payloads were accepted by unchanged schema-2 emulator rules. No live gameplay or publisher authentication is claimed. |
| Controlled release | **CONDITIONAL PASS** | No remaining demonstrated code blocker after the fixes below. Ready for the existing custom-audience controlled release. Production authenticated sync and native physical-device clipboard checks remain release-verification limits, not completed checks. Do not widen access or claim a general public launch. |

## Blockers reproduced and fixed

1. **Date correction regression (introduced by Prompt 3).** A pasted `existingPuzzleDate` guard referred to undefined `item` variables inside `submitScoreManagement`. The generated controller returned `item is not defined`, preventing ordinary date changes. Removed only the stray statement; existing printed-date, occupied-date, owner and transaction safeguards remain. A generated-controller regression moves a real-shaped undated Wordle entry and separately rejects an incompatible Color Daily date and occupied destination.
2. **Journal overwrite after cache failure (inherited v76 defect exposed by batch/reload testing).** A writer could replace its only durable journal with a delta based on the recovered state while the base cache still lacked the earlier score. Replaying the replacement journal could drop that unchanged earlier score. `writeLocal` now checkpoints the recovered old journal before replacing it when its sequence is not yet present in the cache. If that checkpoint fails, the next edit fails before the old journal is replaced. The prior successful save remains recoverable and the failed card stays available to retry. No key format, account namespace, record schema or cloud protocol changed.
3. **Legacy malformed scalar parsing (inherited v76).** Mini accepted negative or competing times; Krillion could extract a valid-looking integer from a fractional value or pick one of competing totals; Spelling Bee could choose a stronger rank from competing ranks. These inputs now require correction rather than silently becoming ranking data. All previously valid baseline fixtures continue to pass; existing stored results are not rewritten.
4. **Missing puzzle identity in legacy Connections header variants (Prompt 3 normalization gap).** Both regular and Sports Edition header variants now retain their printed number. Different puzzle numbers no longer compare as an equivalent duplicate simply because score/status match.
5. **Recaps larger than the unchanged private-record limit (new parser/cloud boundary).** More than 100 grid rows could parse locally but permanently fail the existing Firestore entry schema. Such recaps now receive a retained-text/manual-entry fallback before saving. The rules were not loosened.

The first reproduction run failed on the date-correction, journal-reload and malformed-scalar cases. These are observed failures with new regressions, not speculative concerns. Recommended code fixes are limited to the above blockers and are included in the reviewed release candidate.

## Tests and environments

- macOS, existing Swift 6 static generator and vanilla JavaScript; optimized `swift run -c release ... solvry-site` completed.
- Generated `app.js`, `importers.mjs`, `sync-safety.mjs` and existing scoring module passed `node --check`.
- Application suite: **268 passed / 0 failed**. Includes all 192 v76 baseline tests, the initial 49 Prompt 3 tests, and 27 readiness regressions. `Tests/import-readiness.test.cjs` is the additional controller/parser/reload/clipboard matrix.
- Existing rule suite: **27 passed / 0 failed**, project `demo-solvry-safety`, loopback Firestore 8089. Expected adversarial permission denials are asserted successes.
- Added Auth + Firestore integration suite: **3 passed / 0 failed**, project `demo-solvry-import-readiness`, Auth `127.0.0.1:9097`, Firestore `127.0.0.1:8097`. Test code refuses any other endpoint/project configuration. Each test contains multiple independently asserted scenarios; the three top-level test counts are not presented as a count of scenarios.
- Emulator accounts use synthetic `example.test` identities and a test-only password. Independent Firebase apps sign in through the actual Auth emulator, not only rules-unit-test auth claims. They do not exercise Google OAuth. No real account or user record was changed.
- The transport failure is injected at the SDK boundary; offline tests also disable the actual Firestore SDK network and verify another authenticated session cannot yet read the pending score. Recovery then confirms the server record and revision.
- Concurrent authenticated devices produce one winner and one explicit losing edit; choosing the losing local edit advances the server to revision 3, and another retry leaves revision 3 unchanged.
- All 19 format payloads were sent through the actual generated import controller and sync transaction against the unchanged rule file. A separate authenticated account was denied private-record access.
- Local Safari iOS Simulator evidence: `/private/tmp/solvry-review-ios-safari.png`. Hardware keyboard entry/copy/paste worked; the native permission sheet path was not completed. No desktop viewport screenshot is used as native-iOS proof.
- The previous temporary Java runtime had missing configuration files. A temporary Eclipse Adoptium JRE 21.0.13+9 was downloaded from its official GitHub release and SHA-256 verified (`225bab0a09491ef06835488cd942f5d2befa9a0410a2484f0c8bbcf7506ec09a`). Pinned Firebase CLI/SDK dependencies were not upgraded. CLI deprecation warnings are recorded separately from asserted test failures.

Reproduce from the repository root after generation:

```sh
npm test
npm run test:rules
npm run test:import-sync
```

Emulator tests require Java 21 on PATH. `firebase.import-tests.json` is a dedicated loopback demo configuration; production continues to use the unchanged `firebase.json`.

## Data, compatibility and remaining risk

- No Firestore migration, rule/index deployment, new collection or privilege change. Live rule read-back matched v76 exactly: ruleset `projects/solvry-walebkong/rulesets/0ab73c61-45eb-49d0-9d8a-6d8786b5acc1`, source SHA-256 `f555211b4ae54a53f672629c8b89b64a91a9203e421fd2530a564da35006b513`.
- The local journal repair uses the same format and namespaces that v76 understands. Under continued cache failure it rejects later edits safely instead of replacing the only recovery copy. Refresh participating tabs/devices after release so they use the repaired writer.
- Unsaved review text/cards are still memory-only. Reload loses unsaved drafts; already committed scores remain recoverable. The partial-save reload test verifies data integrity and retry after re-pasting, not persistent recovery of unsaved textarea content. This documented limit remains.
- Batch saves are independent commits, not one atomic cross-device transaction. Sync conflict controls remain necessary.
- Pasted scores remain self-reported; parser validation is not anti-cheat verification. Publisher format drift and undocumented variants remain risks; manual fallback is preserved.
- No new scoring formulas, friendship lifecycle, account design or data-sharing policy was introduced. Existing hidden-answer/raw-result separation remains enforced by unchanged rules.

## Controlled release and rollback

1. Preserve all work, review the diff, commit the tested source and confirm a clean worktree. Check current remote HEAD before pushing; do not force-push or discard other work.
2. Use the existing Sites source helper and preserve the current **custom** audience. Byte-compare every changed source file between the GitHub and Sites checkouts. Build and test the matching generated client and all modules before packaging.
3. Save the exact pushed Sites source SHA plus its deployment archive, then deploy that saved version. Cache versions are `app.js?v=46`, CSS `v=41`, `importers.mjs?v=2` and repaired `sync-safety.mjs?v=37`; `game-scoring.mjs?v=2` is unchanged. A script-only upload without the importer module is incomplete.
4. Verify the saved source/archive provenance, deployment success, live module/script versions and non-destructive UI validation. Inspect recent worker/browser errors. Preserve rules and avoid authenticated production writes to real accounts.
5. If no authorized isolated production accounts are available, stop that part of production verification and report it explicitly. Emulator success does not substitute for completed production Google/cross-device verification.

**Preferred rollback is the exact prior v76 client**, whose saved provenance was confirmed during this review:

- Saved version: `appgprj_6abd6478c7a081918572401c942f954d~appgver_d8879f726fc481919f2e1e3e61f9a55d`.
- Sites source: `78bc7f3acf4aade910ffe8e79e7a93b6293e4c3a`.
- Archive: `sha256:c42217a39f961bdac6302106dae72c68dbf66b6929bd68150ac05fa7c9525b4e`.

Call Sites `get_site` and `get_site_version` to reconfirm current audience and that saved version, then `deploy_site_version` with that exact ID. Poll only a nonterminal deployment and confirm the returned version/provenance. Smoke-check read-only views, Add Score validation and sign-in state. Keep current Firestore rules, account schema and user data. Application rollback is not a data restore. v76 contains the inherited journal/parser defects described above, so prefer a targeted fix forward where feasible. The older v65 emergency fallback in `Operations/rollback.json` remains documented for disaster recovery but is not the preferred rollback for this importer release.
