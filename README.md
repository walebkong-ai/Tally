# Solvry

Solvry is a Swift-generated website for tracking daily word and puzzle games with friends.

## Build

```sh
swift run solvry-site
```

The build writes the deployable site to `dist/`.

## What is in this version

- Daily game tracker for paste-supported official games: Wordle, Connections, Strands, Mini Crossword, Spelling Bee, and Krillion
- Separate Solvry games section with a ranked Daily Holes MVP and playable Solvry Hoops
- Deterministic Daily Holes course generation with nine holes, wind, hazards, club choice, two-tap shot execution, lie effects, water penalties, abstract putting, scorecard results, and locked local progress
- Simplified Daily Holes two-tap swing flow: lock the moving aim line, then lock the contextual colour power bar
- Polished Daily Holes game feel with smoother ball flight, landing/rollout callouts, hole-complete celebration, and cleaner round recap
- Logo-style game cards with pinned favorites
- Per-game scoring rules and score hints
- Individual game scoreboards plus a combined Solvry leaderboard
- Streak, completed-today, and total-solves stats with a recent progress row
- Friendlier UI states for saved results, score examples, imports, and navigation
- Colorful Concept C-style dashboard strip with Concept A-style editorial headings
- Firebase-ready login/sign-up flow with Google and Apple account options
- Friend requests, friend leaderboards, and cloud-ready saved profiles/scores
- Spoiler-safe answer sharing
- Official game links
- Clipboard and paste import for supported official share results, with game-specific parsing errors when a pasted result is incomplete
- Paste-first Add score flow with automatic game detection, score/date preview, explicit save or replacement, duplicate protection, and sample results for all six supported games
- Visible Paste result / Enter manually tabs for the six existing official games, with game-specific score fields and Manual labels on saved results and individual leaderboards
- Add-friend and add-game flows
- Browser-local fallback when cloud config is not connected

## Account and friend sync

Solvry now includes a real-account adapter for Firebase Auth and Firestore. Without config, the site stays in local mode and labels friends as local-only. To enable production accounts, provide a Firebase web config as `window.SOLVRY_FIREBASE_CONFIG` before `app.js` loads, or save the same JSON in local storage under `solvry-firebase-config` while testing.

Required Firebase products:

- Authentication with Google and Apple providers enabled
- Firestore collections for `users` and `friendRequests`
- Security rules that let signed-in users read/write their own profile and scores, read accepted friends' public score data, and create/respond to their own friend requests

## Current verification baseline

Use this as the stable checkpoint for future Solvry work:

- Solvry Holes desktop browser flow visually verified
- One 2-shot hole verified
- One 3+ shot par 5 progression verified
- `swift run solvry-site` passed
- `node --check dist/app.js` passed
- `git diff --check` passed
- Targeted parser/import checks passed

## Score import checks (2026-10-26)

Run `swift run solvry-site`, then `node --test Tests/share-import.test.cjs` for the shipped share parsers. The 20 checks cover all six games, failed and incomplete results, ambiguous mixed-game pastes, invalid times, and emoji normalization.

Browser QA covered desktop (1366x900) and mobile (390x844): previews before saving, all six imports, reload persistence, duplicate detection, explicit score replacement preserving answers/notes/privacy, date validation, clipboard success/denial, storage-failure retry, manual entry, examples, and navigation from Solvry Holes. Clipboard and storage failures were simulated. These checks use representative fixtures, not a guarantee of compatibility with every future publisher format.

Imports use the explicitly selected Played on date; puzzle numbers are not converted into calendar dates. Saving updates the existing local/cloud adapter and does not enable account sync without Firebase configuration.

### Manual entry decisions and checks

- Manual entry is limited to the existing official games; no custom game creation or overrides for in-app game scores were added.
- Manual scores count on the same leaderboards as pasted scores and are labeled Manual.
- Answer, note, and answer-sharing controls are optional. Existing scores show a replacement warning.
- Desktop and 390x844 mobile checks covered all six games, saving and reload persistence, rank selection, missed Wordle, manual-to-paste switching, draft retention across tabs, replacement, optional fields, invalid/future dates, simulated storage failure/retry, and keyboard tabs.
- The import suite now has 22 passing tests, including manual score normalization and validation.
