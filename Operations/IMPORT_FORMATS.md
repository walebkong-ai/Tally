# Import format audit — Prompt 3

Inspected base: `44427521a62913bb26e2d7af616e59df88982e48` (v76 deployment documentation), not the earlier audit commit. The initial worktree was clean. All 43 active catalog definitions, existing parser tests, strict scoring profiles, import navigation, local journaling, sync projection and account-reset paths were inspected. The initial capability count was **14 paste / 29 manual**; this change makes it **19 paste / 24 manual**. Retired Immaculate editions remain unavailable for new entries; legacy parsing/history is retained.

## Existing capability retained

The existing clipboard button/direct paste, preview, selected date, manual form, rank eligibility checks, explicit replacement action, private answer/note/reveal preservation, account storage namespaces, durable local writes, revisioned cloud synchronization and midnight safeguards are reused. Existing parsers are extracted rather than rewritten. Existing performance and placement scoring formulas are unchanged.

Opportunities addressed: parser code was tied to the generated DOM script; duplicates depended on exact raw text; a batch was rejected rather than reviewed; printed dates were not generally suggested; a save failure had only one global status. Parsing now lives in a pure ESM module. No new runtime dependency was added.

## Newly verified publisher formats

These are source-derived representative fixtures, **not results from played accounts**. `Tests/fixtures/shares/representative.json` records synthetic examples of the observed grammar. `publisher-evidence.json` records official asset URLs and SHA-256 digests. Public publisher scripts were read, not executed. No private player data or credentials were used.

| Game / primary evidence | Accepted interpretation | Date and boundaries | Exclusions / uncertainty |
|---|---|---|---|
| [Contexto](https://contexto.me/en/) — publisher `aY` share builder and `HA`/`Ts` date formatting in [bundle](https://contexto.me/assets/index-p6O9qHBk.js) | English daily header, solved or gave-up status, total guesses, three ordered color/count rows. Zero guesses only for gave-up records. | Literal **MM/DD/YYYY** formatted by the English publisher; valid calendar date; at most 1,000,000 guesses. | Hinted solves are rejected with an unranked manual Played fallback. Unlimited, translated and older unverified grammars remain manual. Historical printed daily dates are allowed. |
| [Costcodle Classic](https://costcodle.com/) — `buildShareOutput`, `getGameNumber` and `dateForGameNumber` in [main.js](https://costcodle.com/scripts/main.js) | Classic puzzle number, 1–6 guesses or X/6; if rows are present they must match the score, arrows and final checkmark. The publisher also emits header-only archive summaries. | Publisher calendar: `2023-09-21 + (puzzleNumber - 2)` calendar days. UTC arithmetic produces the literal puzzle date without a browser-zone shift. | Checkout is rejected. No guessed Wordle-style offset. Conflicting played-on dates are blocked. |
| [Squirdle Daily](https://squirdle.fireblend.com/daily.html) — `copyCurrentDay` and daily initialization in [game.js](https://squirdle.fireblend.com/scripts/game.js) | Normal Daily **/9**, puzzle identifier, guesses or X; five-cell mosaic with optional Pokémon names, exactly one final solved row for wins. | 1–9 guesses or nine-row failure; puzzle number retained. User confirms date. | Stats /12, six-column mosaics, Free Play, restricted-generation variants and incomplete mosaics are rejected. No authoritative calendar mapping was established. |
| [Poople](https://poople.io/) — `p0`, path-distance lookup `jt`, and result display in [bundle](https://poople.io/assets/index-CbbZj1rp.js) | Numerator is **moves**, denominator is **best solution**. There are moves + 1 four-square rows because the starting word is included; last row is all brown. | Positive move count, best solution ≤ actual moves; puzzle identifier retained. User confirms date. | A denominator is never treated as an attempt cap. No date is inferred from the publisher’s time-zone-sensitive number calculation. |
| [Chainle](https://chainle.io/) — `ah`, `ih`, five-round state validation and integer point calculation in [bundle](https://chainle.io/assets/index-B6r5Nyi6.js) | Daily #number, total points and five round colors; optional percentile is informational. | Total 0–5,000 and consistent with publisher bands: green 900–1,000; yellow 600–899; orange 300–599; red 0–299. Date remains explicit user choice. | Plain/Unlimited headers and incomplete or inconsistent recaps are rejected. Percentile never becomes the score. |

Source selection prioritized reliably distinguishable daily editions and compatibility with the existing scoring definitions. No usage analytics were available to establish a popularity ranking. Contexto was a straightforward guess-based candidate; the other four had explicit machine-readable scores and boundaries. For a next parser pass, obtain actual publisher exports for Minute Cryptic, Travle, Categories and Flagle before implementing them; demand should be checked with beta users rather than assumed.

## Entire active catalog

The table below distinguishes existing support, newly verified support, and research limits. A failed fetch or an unverified grammar does **not** establish that a publisher lacks sharing. Direct requests returning 403 were not bypassed. Accessible publisher HTML/scripts without a verified compatible final-result grammar are deliberately left manual.

| Game | Capability after change | Evidence / remaining work |
|---|---|---|
| Wordle | Existing paste | Existing parser and regression fixtures retained. |
| Connections | Existing paste | Existing parser and regression fixtures retained. |
| Strands | Existing paste | Existing parser and regression fixtures retained. |
| Mini Crossword | Existing paste | Existing parser and regression fixtures retained. |
| Spelling Bee | Existing paste | Existing parser and regression fixtures retained. |
| Krillion | Existing paste | Existing parser and regression fixtures retained. |
| Contexto | New paste | Publisher share-builder evidence above. |
| Fine Print Daily | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| Minute Cryptic | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| Categories (CleverGoat) | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| RNGdle | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| DSMdle Classic | Manual | Publisher page/source retrieved; compatible final-result grammar not verified in this pass. |
| Quordle (quordlewordle.io) | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| Poople | New paste | Publisher share-builder evidence above. |
| Flagle | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| Terradle | Manual | Publisher page/source retrieved; compatible final-result grammar not verified in this pass. |
| Spotle | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| NYT Daily Crossword | Manual | Publisher page/source retrieved; compatible final-result grammar not verified in this pass. |
| Brandle | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| PricePoint | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| Metazooa | Manual | Publisher page/source retrieved; compatible final-result grammar not verified in this pass. |
| Travle | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| Unwordle | Manual | Publisher page/source retrieved; compatible final-result grammar not verified in this pass. |
| Feetle | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| LoLdle Classic | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| Murdle | Manual | Publisher page/source retrieved; compatible final-result grammar not verified in this pass. |
| Noillirk | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| MapTap | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| Fibble | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| Chainle | New paste | Publisher share-builder evidence above. |
| Costcodle Classic | New paste | Publisher share-builder evidence above. |
| Minecraftle | Manual | Final-turn win/loss remains ambiguous in the current share; do not infer completion. |
| Enclose Horse | Manual | Publisher request returned HTTP 403; obtain representative exports. |
| Genshindle Daily Normal | Manual | Share wording found; Daily Normal vs other modes not verified well enough for an importer. |
| Squirdle Daily | New paste | Publisher share-builder evidence above. |
| Connections: Sports Edition | Existing paste | Existing parser and regression fixtures retained. |
| Daily Tens | Existing paste | Existing parser and regression fixtures retained. |
| Centumth | Existing paste | Existing parser and regression fixtures retained. |
| Globle | Existing paste | Existing parser and regression fixtures retained. |
| Flagcognito | Existing paste | Existing parser and regression fixtures retained. |
| Size It Up | Existing paste | Existing parser and regression fixtures retained. |
| Color (Dialed) | Existing paste | Existing parser and regression fixtures retained. |
| BuzzFeed Daily Trivia | Existing paste | Existing parser and regression fixtures retained. |

For Minecraftle, the [current publisher share builder](https://minecraftle.zachmanson.com/_next/static/chunks/2ao21xf4k5tuz.js) (SHA-256 `bf683808b5590887d371566f726a93040b84fed1dcfcedc631d0f49077269683`) emits date, count out of ten and crafting tables. A final-turn count alone does not reliably establish a win. Solvry must not turn that into a solved score without stronger evidence. This is a parser limitation, not a claim about the game’s UI.

## Dates, duplicates and batches

- A printed full daily date is suggested automatically when the user has not chosen a date. Centumth, Globle, Flagcognito, Size It Up and Color Daily date recognition is limited to their date header/line, not arbitrary chat prose. A Color challenge does not become Daily because an unrelated date appears in the paste.
- Month/day-only Color Daily results require an explicit year. Wordle and other puzzle numbers do not imply a date unless there is an authoritative mapping; only Costcodle adds a verified number/calendar mapping here.
- Invalid calendar dates, future dates and disagreement with a reliable printed date block saving. ISO dates are literal calendar keys; no `toISOString()` conversion of a selected local day is used. Existing rollover watchers remain intact. Active and inactive batch drafts retain their chosen dates across game navigation and rollover.
- Semantic duplicate comparison uses game (via the per-game record), puzzle identity when present, date, normalized score, completion status, source and Color edition. Whitespace, CRLF, puzzle-number comma formatting and equivalent clock strings do not produce extra saves. A manual entry can be intentionally replaced by an official share, but requires confirmation.
- A known puzzle already stored on another day prompts the saved date; it is never silently copied to a second date. One result per game/date remains enforced. Manual records without a reliable puzzle identity are not guessed.
- Batch input supports up to **10 results / 12,000 characters**. Known headings separate results; `---` is the explicit separator when headings are missing or ambiguous. Unsupported and malformed blocks remain visible. Conflicting same-game/day cards and the same puzzle on two dates are blocked until resolved. Equivalent cards save once.
- Every replacement requires a per-card checkbox bound to the current date, parsed result and existing-entry snapshot. A changed existing record invalidates consent. The old/new score, status, source and known puzzle identity are shown; private answer/note/reveal are preserved.
- Save writes ready cards independently through the existing local journal and sync queue. Successful cards are marked Saved on device; error cards and their text/dates remain for retry. Cloud completion is reported only by the existing sync indicator. No cloud success is inferred from a local save.

## Limits and future maintenance

Publisher formats may change. This is format validation of self-reported shares, not publisher authentication or anti-cheat verification. Strands completion remains unverified/unranked unless entered manually as completed; Color challenges remain outside combined daily rankings; RNGdle’s existing exclusion is preserved.

Automatic batch boundaries are conservative. For an unrecognized header or a share consisting only of a score/link, use `---`; the importer does not discard or guess ambiguous material. Review drafts are held in memory and survive navigation within the tab; **unsaved drafts do not survive reload/closing the tab**, matching the prior nonpersistent draft behavior. Saved scores do survive reload. A batch is not a single atomic database transaction; device or sync errors can leave some cards saved and some pending. New cards continue through the existing conflict resolution mechanism.

The five catalog entries deliberately retain `manualOnly: true` internally because this legacy flag also selects strict catalog score validation. `pasteSupported: true` overrides only import capability, labels, examples and navigation. A future cleanup may rename this overloaded metadata, but changing scoring semantics is outside this task. `mergeState` refreshes this metadata from the built-in catalog so older cached catalogs gain the new parsers.

## Production readiness corrections (November 17)

The follow-up review rejects competing/negative/malformed Mini times, competing Spelling Bee ranks, and fractional/negative/competing Krillion totals rather than importing a convenient numeric substring. It also retains puzzle identifiers in legacy Connections header variants and rejects recaps exceeding the unchanged 100-row private-record limit with a manual fallback. These are release correctness fixes, not new supported formats; all 19 representative formats remain covered. See [the readiness review](../QA/PROMPT3_PRODUCTION_REVIEW.md) for tests and remaining native-iOS verification limits.
