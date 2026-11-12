# Solvry release verification and launch readiness

Updated November 11, 2026. This is the public summary of local release and beta evidence; it omits participant identities, account identifiers, scores, private answers/notes, raw reports, screenshots, and backup material.

## Release and scope

- Published application: **v74**, through OpenAI Sites.
- Sites source checkpoint: `f486fe5eafbf775f77cf43b01bad80dd7997e32c` (a separate source history from this repository).
- Website: https://solvry.walebkong.chatgpt.site/.
- Access: custom/invite-only; no custom domain attached at this checkpoint.
- Backend: Firebase Google Authentication and Toronto Firestore, Spark with billing disabled.
- Assessment: core invited-beta scenarios passed; additional checks remain before a small public beta and broader promotion.

## Category dropdown focus/spacing fix (v74)

CSS-only: a custom white chevron has dedicated right padding and keeps its image on hover; keyboard focus uses an inset gold indicator instead of the external oval. The control remains a native select. Local browser checks confirmed appearance, 42px text padding, 16px arrow inset, visible keyboard focus with a negative outline offset, normal unfocused styling, category filtering, and no horizontal overflow on desktop/mobile. Swift build, JavaScript syntax, all 175 existing app tests and diff checks pass. No tests were added for this styling-only correction; scoring and backend data are unchanged.

## Blue category control verification (v73)

CSS-only refinement: the category dropdown uses the same blue fill, white text, 12px corners, 44px minimum height and dark lower shadow as the button system, plus a darker hover color. Native category selection remains accessible. Local desktop/phone checks confirmed category filtering and no horizontal overflow at 1366 and 375 pixels. Swift build, JavaScript syntax, all 175 app tests and diff checks pass. No new tests were added for this styling-only change; game logic, Firebase rules and data are unchanged.

## Dual scoring verification (v72)

Both overall scoring views are available for a day or seven days: Placement preserves the existing scheme and remains the default; Performance uses a published 0–100 formula per eligible raw result. All 29 new games have specific fields, validation, live performance previews and score explanations, with performance profiles for all 43 active official games. RNGdle/custom games are excluded from both combined totals, and Color requires a matching dated Daily share. Original records are never rewritten to select a mode. These are Solvry conventions and disclosed benchmarks, not publisher ratings or normalized puzzle difficulty.

All **175 application tests** pass, including 19 dual-scoring cases covering all profiles, formulas/bounds, malformed records, misses/unfinished puzzles, ties, opponent-independent performance, per-result rounding, seven-day totals, valid zero-point ranking, exclusions, moves compatibility, cached metadata and the complete public guide. Generated JavaScript/module syntax and whitespace checks pass. Rules/auth were unchanged; the last rules test remains the previously documented run.

Local guest browser checks inspected all 29 new game field configurations and explanations, switched scoring modes, and saved one test score locally: its preview and resulting performance/placement totals matched. Special previews covered signed par, moves, bounded points, four strikes, time, completion and the Color exception. The 43-row public guide loaded, desktop/mobile layouts had no horizontal overflow, and no browser console errors appeared. No production fixtures or account operations were used. This does not constitute a new physical-device beta, Firebase rules test or public launch verification.

Built app.js SHA-256: `6ae75870b321b0330750dc72e53efd1c0bf16ee38145e9421810c4ffa31871ae`. Scoring module SHA-256: `daff5bc2a505cc431cc8b98db2d1cb6edd22b8131a818511e7c600b71be32297`.

## Single category dropdown verification (v71)

A single native category dropdown replaces the desktop category chips and remains compact on phones. It sits alongside search and Pinned only on desktop and below them on narrow screens. All removed-button DOM/event/render dependencies are deleted so startup does not reference a missing element. Includes the proportional Games action-button adjustment already on GitHub. For you remains the default and pinned/streak priority, six categories, aliases and retirement rules are unchanged.

All **156 application tests** pass, generated JavaScript syntax and diff checks pass, and local browser checks verified startup/reload, the default 43-game view, category selection, alias search, category + Pinned only, priority order, one dropdown with zero category chips, equal header action sizes, and no horizontal overflow at 320, 375 and 1366 pixels. No new automated tests were added for this UI refinement. Firebase rules, auth, scores and audience were not changed. The built app.js SHA-256 is `d0c1558a535887e0206dea59494c2be066d318d4a593743bc6c69cd7295dfc71`.

## Games organization verification (v70)

The default For you catalog prioritizes pinned games, then active per-game streaks, then remaining games in six categories without duplicate cards. Category filters combine with aliases and Pinned only. Phones use a compact dropdown; desktop category buttons retain keyboard focus. Today’s shortcuts use the same pinned/streak priority. Streaks are computed from own recorded results using local calendar dates, including month/year/DST boundaries; future records, friends’ records and historical Viewing date do not create streaks. A miss today breaks a streak.

All five Immaculate editions are retired from browsing, new score selectors, paste samples/saves, visible stats and rankings. Existing history remains intact internally and in exports. Cached flags cannot reactivate these definitions; retired active-game selections fall back to Wordle. There are 43 active official games and 44 manual options including Other.

All **156 app tests** pass after rebuilding, including eight new organization/streak/retirement cases; JavaScript syntax and diff checks pass. Local guest browser checks verified pinned-first ordering, active streaks, no duplicate cards, category + alias + pinned filtering, Today shortcuts, the compact phone category dropdown, stable desktop focus, retired manual/sample exclusion and blocked retired pastes. Responsive checks at 375 and 1366 pixels found no horizontal overflow; Add score and Account remained equal in size. Test pins and score fixtures were confined to localhost. No production scores, auth settings, rules, billing or audience were changed. This is not a new physical-device beta or rules test run.

The built app.js SHA-256 is `4579d523e5febc2a9155cb6a5c28512b63bdcefa8af38855b76d0425657693c6`. Invite-only access remains in place.

## Catalog expansion verification (v69)

Added 29 explicitly scoped daily editions, bringing the official catalog to 48 without duplicating existing IDs. New games use manual scoring, with publisher bounds where verified, signed par scores, completion-only records where appropriate, and an isolated RNGdle luck board. Search aliases normalize clarified names. The [eligibility review](../Operations/GAME_CATALOG_REVIEW.md) lists every addition, publisher link and exclusion. No publisher API integration or new paste-parser support is claimed.

All **148 application tests** passed after rebuilding, including nine catalog/scoring/upgrade cases. Generated JavaScript and the storage module passed syntax checks. New-ID projection tests retain private answers/notes outside shared records. A reproduced browser upgrade defect was corrected: saving must preserve current official definitions while keeping concurrent custom-definition edits and existing result history. The complete existing account/privacy suite also passed. Firestore rules were unchanged; this release does not claim a new rules deployment or physical-device account beta.

Local guest browser tests covered negative Minute Cryptic par, decimal RNGdle EP and its absence from overall standings, alias lookup, Fine Print’s fourth strike becoming a miss, and catalog persistence after save/reload. Live browser read-back confirmed 48 game cards and 49 manual dropdown options including Other, with Contexto selection retained after saving/reload. No production score fixtures or authentication changes were made. Invite-only access remains in place. The built app.js SHA-256 is `53c2990aae45bbb5455ee0dc879f564262774c08123044d7efd87b5df273403e`; sync-safety.mjs is `f67449c51d546470eba3acc2cc7c118dafb521a8ae3c7e46c86a5f41430a7af5`.

## Compact layout verification (v68)

UI-only source update: equal-sized Add score/Account header buttons, compact workspace spacing, two-column manual fields where space permits, optional entry tips and removal of unnecessary viewport-height minimums. The Swift generator builds successfully, all 139 app tests pass, and generated JavaScript syntax is valid. The v67 security-rule suite remains the last rules run; no backend or rules changed.

Live guest manual-entry checks measured matching 128×44px header buttons on a 1366×768 laptop and 88×44px buttons on a 375×667 phone viewport. Save is visible at both sizes (bottom at 706px and 646px respectively), with no horizontal overflow. A 390px phone uses matching 96×44px buttons; the 320px preview also has no horizontal overflow. Game details, Friends and the empty leaderboard were checked on the laptop; long game lists, expanded optional content and smaller screens can scroll naturally. These are browser viewport checks, not a new physical-device beta or a test with the software keyboard open. The built app.js SHA-256 is `6d1d19f7004f08ef090f0b86782e6406d6fbb1382cc278303b2cbbf512512dd3`; styles.css is `5b859996f5ed1ed97ab8bf08ecc9a40bd89e58ff626cc3af383cd55c52c1b9d5`. Published access remains custom/invite-only.

## Application and permissions

Recorded v67 validation passed 139 application tests and 20 Firestore emulator tests, generated JavaScript/module syntax checks, native rule validation, and a comparison of deployed rules with tested source. Automated coverage includes account storage isolation, revision conflicts, score date correction/deletion, account deletion locks, private/shared projection separation, reconnect recovery, and bounded/redacted operational diagnostics.

Before the November 11 GitHub upload, the source was rebuilt in this repository and the 139 app tests and 20 isolated Firestore permission tests passed again. The then-generated v67 `dist/app.js` SHA-256 was `3d0d00af520da4ba7054d40bd42d4d0475c1fa78918432cedfd7f49e6fcbe89b`, matching the verified v67 served artifact. Application source, rules, Firebase configuration, and dependency lockfile match the release checkout. The upload scan found no private key, saved authentication token, service-account credential, or private beta fixture identifiers/content in the candidate files; the embedded Firebase browser API key is intentionally public client configuration.

The two-account, user-assisted beta used computer Chrome and confirmed iPhone Safari. Completed scenarios included:

- Real Google sign-in and distinct private account histories.
- Switching between the two accounts and guest mode without importing the other account's private data.
- Sending and accepting a friend request after a persistence defect was reproduced and fixed.
- Private records denied to the peer; shared scores readable only in the intended relationship state.
- Intentional answer reveal followed by removal of the answer from the shared projection when sharing was turned off.
- Removal revoking new score reads in both directions.
- An offline device save, reconnect/retry after a reproduced recovery-status defect was fixed, and same-account read-back on the computer.

These results combine user observations, captured sanitized permission reports/screenshots, and independent administrative read-back. They are not a fully automated cross-device production test. Previously downloaded or cached data cannot be recalled by removing a friendship.

## Production account-management verification (2026-11-11)

All four requested flows passed in desktop Chrome against the live backend using a fresh disposable Solvry account. The owner supplied the spare Google sign-in and approved final account deletion. Test actions used the normal application UI; administrative access was read-only verification, not an alternative cleanup path.

- Downloaded account exports contained the intended private profile, scores, answers/notes, and diagnostics without sign-in token fields. Guest history was not imported.
- Date correction rejected an occupied destination, then atomically moved a score to a free date. Independent read-back confirmed one commit for old/new private records and shared projections, preserved private fields, and no hidden-answer/note/raw-paste/grid leakage into the shared score.
- Score deletion removed the result contents from private and shared records, preserved the other test score, and remained deleted in a fresh export after reload.
- Account deletion completed Google reauthentication, removed the nonempty account through the application, showed the success notice, and returned to guest mode with Continue with Google available.
- Independent Firebase read-back confirmed no authentication identity, private records, known shared result documents, profile, diagnostics, or sent/received requests for the deleted test account. Only the intended minimal lifecycle marker remains: schemaVersion, state=deleted, startedAt, and completedAt. The Google/Gmail account was not deleted. Existing participant accounts were not used for mutations.

The test identity, raw exports, and screenshots remain in the private local QA archive. This account had no friend requests, so populated social cleanup, interrupted/resumed deletion, large live cleanup batches, cross-device deletion propagation, and direct stale-token production probes remain outside this run; existing automated coverage is separate. No application, provider, rules, billing, or audience change was required.

## Parser audit

The remaining audited Wordle, Connections, Strands, and partial-completion defects were corrected with regression coverage. Malformed/contradictory shares are rejected, unknown Strands completion is saved as Played with a warning until manually confirmed, and partial puzzle attempts do not increase completion totals. Existing user history was not silently rewritten. Representative parser fixtures do not guarantee compatibility with future publisher format changes.

## Operations

- Four active read/write quota-warning policies at 80%/95% of daily free allowances. Owner email delivery was tested with a temporary canary, then the canary was removed. Operational metric windows differ from exact quota accounting, and metrics/email may lag. Other quotas are not covered.
- An operational usage dashboard and account-scoped health reporting are deployed. Health summaries exclude result content, free-form messages, stack traces, emails, and URLs. The November 11 production account exports captured the signed-in client's health summary; account deletion then removed its health document, independently verified in Firebase.
- AES-256-GCM local backup creation and a daily 03:00 local macOS schedule with 14-day retention were tested. A restore into fresh loopback Firestore/Auth emulators recovered all 20 documents and both Google identity records with matching hashes/metadata and zero production writes.
- A final v67 → v65 → v67 application rollback drill completed in 41 seconds, with authenticated served-artifact hash checks. The compatible database/rules remained in place; application rollback is not a production data restore.

Daily backup creation depends on the operator's Mac, logged-in user, network, and Firebase CLI session. A November 11 encrypted snapshot is now stored in the owner's restricted Google Drive folder with a non-secret checksum manifest and recovery instructions. The key is separately saved in Apple Passwords, with its arrival on the owner's iPhone confirmed. The downloaded cloud copy matched its SHA-256 and byte length, decrypted successfully and restored 22 documents and 2 Google identity records into fresh loopback emulators, with matching document hashes/identity metadata and zero production writes. Future daily snapshots are not automatically uploaded offsite, and backup-failure email is not configured. Managed cloud backups, PITR, and billing budgets remain off under the selected Spark setup. See [Operations/RUNBOOK.md](../Operations/RUNBOOK.md).

## Remaining launch checks

1. Exercise simultaneous conflicting edits across two devices and verify both resolution choices. Revisit the earlier date-entry and stale-score observations, whose causes were not reproduced.
2. Run fresh onboarding with an independent tester. Android/mobile Chrome, duplicate/declined/cancelled/repeated friend requests, and request delivery without reload still need live coverage.
3. Maintain fresh offsite copies: the first encrypted snapshot and separately synced recovery key are verified, but future daily snapshots still require upload.
4. After domain/DNS/HTTPS and sign-in configuration, verify the intended public pages and private-data restrictions from a fresh signed-out browser when public access is enabled.
5. Observe actual beta usage before wider promotion; no load/capacity test for a traffic surge has been completed. Cold offline startup, offline reload, storage eviction, and long offline intervals remain untested.
6. Broaden account-deletion coverage beyond the completed normal flow: populated friend requests, interruption/resume, multiple cleanup batches, and old authenticated sessions on other devices. The emulator suite remains the evidence for those protections so far.

## Repository boundaries

This repository includes reproducible source, brand assets, test fixtures, public Firebase client configuration, rules, lockfiles, and operator tooling. Participant reports and screenshots remain in the private local QA archive. Runtime data, administrator credentials, account exports, encrypted backups/keys, dependency directories, and generated site output are not published here. Source updates do not automatically deploy the website or Firebase configuration.
