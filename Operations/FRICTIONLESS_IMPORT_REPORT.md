# Prompt 3 — frictionless result importing

**Historical implementation snapshot.** The subsequent [production readiness review](../QA/PROMPT3_PRODUCTION_REVIEW.md) supersedes the readiness decision below. That review found and fixed release blockers, added integration coverage, and records the final release outcome. The original local-only test counts below describe the initial implementation, not the reviewed release.

Prepared locally against clean base `44427521a62913bb26e2d7af616e59df88982e48` in `/Users/kalebwong/Documents/ChatGPT/Game/Tally` (v76 release baseline). **No commit, GitHub push, Sites publication, Firebase deployment or production data modification was performed for this task.** Changes remain available in the worktree for review.

## 1. Preserved functionality

Swift 6 static generation, vanilla JavaScript, existing routes and catalog, cream/teal/pastel/serif visual identity, clipboard/direct paste, manual entry, both leaderboard scoring modes, game bounds, daily rollover, account isolation, local journaling, cloud revisions/conflict handling and private/shared projections remain in place. All 192 baseline application tests and 27 baseline Firestore tests pass. No game scoring formula, friendship rule or authentication flow was redesigned.

Existing Strands paste completion is still explicitly unverified and unranked; it can be confirmed manually. Color challenges retain their existing separate-board treatment. Retired Immaculate games remain unavailable for new scores while historical parsing is preserved.

## 2. Implemented flow

**Paste → Review → Save** now supports one or several results. The single-result path keeps one prominent field, automatic detection/preselection, a visible played-on date and one save action. Review cards show game, score, completion status, puzzle identity when available, date provenance, duplicate/error/saved state, and a collapsed raw recap. The existing manual tab remains available; a recognized unsupported or malformed game has a targeted manual fallback.

Batches support up to 10 results / 12,000 characters. Known share headings split automatically; `---` is available for uncertain boundaries. Each card has a date, removal action and independent replacement consent. Identical duplicates save once; conflicting same-game/date or same-puzzle/different-date cards are blocked. Partial local success keeps error cards and their dates/text available to retry.

Replacements show old/new score, result, source and known puzzle identifier. A checkbox is required and is invalidated by changes to the card, date or existing record. Answers, notes (including an intentionally empty note) and sharing choices are preserved. The commit path rechecks account ownership and the reviewed entry and uses the existing same-account, multi-tab journal conflict guard.

Printed dates are suggested when unambiguous, future dates are blocked, and uncertain puzzle-number dates stay selected by the user. Costcodle uses a verified publisher calendar; no Wordle-style calendar is guessed. Yearless Color Daily recaps require a year. Manual and batch draft dates survive in-tab navigation/rollover; saving a paste does not discard an unfinished manual form. Account changes clear the private review queue.

## 3. New automatic formats

**19 of 43 active games now support paste**, up from 14. Newly supported:

| Game | What is imported |
|---|---|
| Contexto | English Daily printed date, guesses and solved/gave-up status; hinted solves require unranked manual entry. |
| Costcodle Classic | Classic puzzle number, 1–6 or failed result, arrow recap if present, and publisher-mapped date. |
| Squirdle Daily | Normal /9 result, five-column mosaic, puzzle number and solved/failed status. |
| Poople | Actual moves and daily puzzle number; best solution is shown separately, not treated as an attempt limit. |
| Chainle | Five-round Daily total with color-band consistency; percentile does not affect score. |

Publisher source evidence, supported editions, full 43-game audit, per-format boundaries and source digests are documented in [IMPORT_FORMATS.md](IMPORT_FORMATS.md). Fixtures are synthetic examples generated from observed official share-builder grammar, not claimed results from playing publisher accounts.

## 4. Games remaining manual (24)

Fine Print Daily; Minute Cryptic; Categories (CleverGoat); RNGdle; DSMdle Classic; Quordle (quordlewordle.io); Flagle; Terradle; Spotle; NYT Daily Crossword; Brandle; PricePoint; Metazooa; Travle; Unwordle; Feetle; LoLdle Classic; Murdle; Noillirk; MapTap; Fibble; Minecraftle; Enclose Horse; Genshindle Daily Normal.

These retain their existing manual validation and scoring. Some publisher pages returned 403; other retrieved sources did not establish a reliable compatible final-result format in this pass. Minecraftle’s final-turn win/loss ambiguity and Genshindle edition identification are specifically left unresolved rather than guessed. This is not a claim that those games have no share function.

## 5. Interface changes

Changes are confined to Add Score and catalog paste-capability metadata/labels. Responsive review cards use cream surfaces, teal actions, pastel status accents and existing serif headings. Status is conveyed in text as well as color. Date/score confirmation and explicit replacement consent remain visible; no popup, animation or new route was added. Cloud success is never inferred from local save feedback.

## 6. Exact source files changed

Paths below are relative to `/Users/kalebwong/Documents/ChatGPT/Game/Tally`.

| File | Change |
|---|---|
| `Sources/SolvrySite/main.swift` | Targeted markup/styles, parser-module import/wrapper, 5 paste-capability flags/examples, review queue and handlers, date/duplicate/replacement checks, draft preservation and cache versions. |
| `Assets/importers.mjs` (new) | Extracted existing pure parsers; five evidence-based parsers; date, semantic duplicate, puzzle identity and batch helpers. No DOM/storage/network/auth dependency. |
| `Tests/importers.test.cjs` (new) | Parser fixtures/boundaries, editions, failures, dates/time zones, duplicates, catalog compatibility and splitting/limits. |
| `Tests/import-review.test.cjs` (new) | Real generated review/save-controller tests with actual local journaling: consent, owner/auth mismatch, concurrent edits, storage faults/retry, partial success, draft retention, fallback and cached-catalog compatibility. |
| `Tests/helpers/import-review.cjs` (new) | Small DOM harness and complete in-memory storage API for exercising the generated controller and unchanged `saveState`/sync-safety module. |
| `Tests/fixtures/shares/representative.json` (new) | Representative fixtures for all 19 paste-supported games. |
| `Tests/fixtures/shares/publisher-evidence.json` (new) | Official new-parser source URLs and observed SHA-256 hashes. |
| `Tests/friends-leaderboard.test.cjs` | Parser-module dependency added to existing VM harness. |
| `Tests/import-navigation.test.cjs` | Parser-module dependency added to existing VM harness. |
| `Tests/parser-audit.test.cjs` | Parser-module dependency added to existing VM harness. |
| `Tests/performance-scoring.test.cjs` | Parser-module dependency added to existing VM harness. |
| `Tests/share-import.test.cjs` | Parser-module dependency added to existing VM harness. |
| `Tests/game-organization.test.cjs` | Retired-game test exercises the new review controller; original retirement assertions remain, including preventing detection from activating a retired game. |
| `Operations/IMPORT_FORMATS.md` (new) | Catalog audit, publisher evidence and parsing/maintenance constraints. |
| `Operations/FRICTIONLESS_IMPORT_REPORT.md` (new) | This implementation and verification report. |

`dist/` was regenerated (ignored generated output), including `index.html`, `styles.css`, `app.js` and `assets/importers.mjs`. No dependency manifest, Firestore rule, index, scoring module, auth module or sync-safety module was edited.

## 7. Verification

| Check | Result |
|---|---|
| Swift generator (`swift run ... solvry-site`) | PASS; generated static site successfully. |
| `node --check dist/app.js` | PASS. |
| `node --check dist/assets/importers.mjs` and `game-scoring.mjs` | PASS. |
| `npm test` | **241 passed, 0 failed**: all 192 baseline tests plus 49 new tests. |
| `npm run test:rules` | **27 passed, 0 failed**, Firestore emulator with demo project; expected permission-denial cases logged by SDK. Rules/tests unchanged. |
| `git diff --check` | PASS. |
| Generated importer asset vs source | Matching SHA-256; no missing module in the generated site. |

The Swift and emulator commands needed execution outside the nested OS sandbox to compile the existing generator/start localhost ports. The tests used the local demo emulator, not production Firebase.

Local browser verification used an isolated localhost guest origin in the in-app browser:

- Single Wordle preview/save; explicit replacement; persistence after reload; equivalent formatted paste reports Already saved.
- Mixed Wordle/Connections/unsupported result: eligible score saved, unsupported card retained.
- All five new share formats detected together with independent printed/mapped/selected dates and saved locally together.
- Minecraftle error preserves text and selects Minecraftle manual entry.
- Zero Mini time and future dates block saving.
- Desktop 1440×1000 and narrow 390×844 layouts: no horizontal overflow. Console warning/error log was empty during the checked interactions.
- Captured previews: `/private/tmp/solvry-import-desktop.png` and `/private/tmp/solvry-import-mobile.png`.

Browser tests used synthetic public-format scores in localhost guest storage. No live Google login, production cloud write, real-account switch, native Safari/Chrome clipboard permission prompt, physical mobile keyboard or production cross-device test was performed in this task. Those paths are covered by existing/new regression tests and unchanged security rules, but are not claimed as fresh live verification.

## 8. Remaining limitations

- Only the documented editions/locales are automatic; unknown formats stay unsaved with manual fallback.
- Publisher format drift needs representative fixtures and tests before relaxing a parser. Self-reported exports are not anti-cheat evidence.
- Unsaved review drafts are in-memory; reload/closing the tab loses unsaved text. Saved data remains durable. No new persistent-draft storage was introduced.
- Batch boundaries cannot identify every score-only or renamed header. Use `---` when needed. A batch is not atomic across devices/cloud; individual cards may save while others remain blocked.
- Duplicate puzzle identity can only be recovered from retained, parseable official share text. Manual records and legacy unparseable shares cannot safely be assigned a guessed puzzle identity.
- `manualOnly` remains overloaded internally as a strict scoring switch; `pasteSupported` deliberately overrides only import capability. A broad metadata refactor is deferred.

## 9. Database and security implications

**No database migration, new collection, index, schema version or security-rule change is required.** Existing stored scores are not rewritten. Puzzle/date provenance metadata is derived from existing private share text or kept in the review session; no new persistent puzzle-ID field is introduced. Color Daily uses the existing `dailyDate` field consistently; it is cleared when intentionally replacing a Daily result with a challenge.

Entries still use the existing private result shape and local journal. Only the established shared score projection reaches accepted friends. Raw pasted results, grid recaps, private notes and hidden answers do not become public because of this change. Existing account namespaces, deletion locks, revision checks, transaction conflict resolution and friend revocation rules remain unchanged.

## 10. Controlled-deployment readiness

**Ready as a locally verified controlled-deployment candidate.** No automatic push/deploy was performed; production remains v76. For an authorized release, commit/review this work, rerun the documented checks, and package the generated website **with `assets/importers.mjs` and its existing scoring-module dependency**. The generated HTML bumps `app.js` to `v=45` and CSS to `v=41`; the new importer is loaded as `v=1`. Do not publish only the generated app script without its matching module.

Use the existing Sites workflow/audience and release procedures. There is no rules-first migration for this importer-only change because rules are unchanged; retain the v76 security configuration. Before broad rollout, verify a deployed preview with two authorized accounts (including local save → confirmed cloud sync → second-device read), native mobile clipboard denial fallback and one representative real publisher share per newly supported game. Existing v76 production friendship checks noted in the prior release documentation are not closed by this local importer task. Rollback requires the previous matching website/assets; no production-data rollback or rule loosening is necessary.
