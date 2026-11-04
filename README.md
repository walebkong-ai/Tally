# Solvry

Solvry is a Swift-generated universal leaderboard for daily games: paste a shared result, review it, and compare per-game and combined scores with friends.

## Compact overview (2026-11-04)

The overview uses a compact header, inline progress stats, and a three-column desktop game lineup. Saved scores preview the first three entries; an expandable list retains access to every additional score. Empty states and recent activity take less space. The default overview fits tested 1280×720, 1366×768, and 1024×768 desktop viewports; narrow/mobile screens retain natural scrolling for readability. Expanding more scores or using browser zoom can require scrolling.

## Simplified navigation (2026-11-03)

- **Today** opens with a compact game lineup, saved scores for the selected date, current streak, total saved results, and a daily overall leaderboard preview.
- **Games** is a searchable catalog with readable names, saved-result checkmarks, pins, and a pinned-only filter. Pinning games personalizes the home lineup (up to six).
- **Leaderboard** contains overall daily/weekly and per-game rankings. **Friends** contains friend management and requests.
- **Add score** is always available in the header; paste and manual entry share a dedicated screen with links back to the overview after saving.
- Individual game details contain the official play link, saved result, scoring explanation, and collapsed answers/notes. Existing `#import`, `#friends`, and `#answers` links remain supported.
- Scores and pinned games retain the existing storage format. Loaded history survives storage write failures, failed pin saves roll back, and streak/history dates use local calendar days.
- Online Google/Apple sign-in and friend sync still require Firebase setup. The account dialog describes device-only use without showing implementation instructions.

Validation: Swift build, JavaScript syntax, parser/import/friends regression tests, and browser checks at 320, 390, 768, and 1366px. Checked all six views for overflow; exercised paste/manual save, overview updates, catalog search/pins, game-specific ranking navigation, local friend creation, and account dismissal. This pass does not resolve every parser/cloud issue in the earlier QA report.

## Universal leaderboard catalog (2026-11-03)

Official imports now include the original six games plus Connections: Sports Edition, Daily Tens, Centumth, Globle, Flagcognito, Size It Up, Color (Dialed), BuzzFeed Daily Trivia, and separate Immaculate Grid boards for baseball, football, men's basketball, women's basketball, and hockey. Sporcle is excluded per the product decision. Search filters the catalog; pins still work.

Only copied result text is imported. Challenge links without a numeric result are rejected with a manual-entry fallback. No scraper, account access, or automatic third-party score retrieval is implied. Unknown games can still be tracked with the existing Other game manual flow.

| Game | Parsed result and ordering |
| --- | --- |
| Connections: Sports Edition | Its own emoji grid; lowest mistakes, completed before partial |
| Daily Tens | Five rows of two trophies/crosses; most correct out of 10 |
| Centumth | Labeled Total out of 490; highest score from the five official guesses |
| Globle | Guess count after the emoji grid's equals sign; lowest wins, ignores streak/average |
| Flagcognito | Shared total out of 3,000 across three rounds; highest wins |
| Size It Up | Magnitudle's original daily Score out of 500; highest wins; other modes/practice rejected |
| Color (Dialed) | Numeric memory result out of 50 plus Color URL; highest wins; dated Color Daily results count in combined points, other challenges do not |
| BuzzFeed Daily Trivia | Correct answers out of five; highest wins |
| Immaculate Grid | Correct answers out of nine first, then lower rarity score; sport must be identifiable; rarity is not a percentage |

Format references inspected: [Daily Tens](https://dailytens.com/), [Centumth](https://www.centumth.com/how-to-play), [Globle](https://globle-game.com/), [Flagcognito](https://guessdash.com/flagcognito), [Size It Up](https://magnitudle.com/size-it-up), [Color](https://dialed.gg/color), [BuzzFeed](https://www.buzzfeed.com/daily-trivia), and [Immaculate Grid](https://www.sports-reference.com/immaculate-grid/). Read-only public share implementations and representative shared results informed the fixtures. These are format checks, not completed gameplay on each third-party site or a guarantee against future format changes.

## Build

```sh
swift run solvry-site
```

The build writes the deployable site to `dist/`.

## What is in this version

- Daily leaderboard for 19 paste-supported entries, including Wordle, Connections, Strands, Mini Crossword, Spelling Bee, and Krillion (full catalog above)
- Solvry Holes and Hoops are hidden from the website. Their engines, definitions, and saved rounds are retained; hidden games do not contribute to visible rankings or stats. `SHOW_SOLVRY_GAMES` controls the catalog gate.
- Deterministic Daily Holes course generation with nine holes, wind, hazards, club choice, two-tap shot execution, lie effects, water penalties, abstract putting, scorecard results, and locked local progress
- Simplified Daily Holes two-tap swing flow: lock the moving aim line, then lock the contextual colour power bar
- Polished Daily Holes game feel with smoother ball flight, landing/rollout callouts, hole-complete celebration, and cleaner round recap
- Logo-style game cards with pinned favorites
- Per-game scoring rules and score hints
- Individual game scoreboards plus a combined Solvry leaderboard
- Selected-day score count, current streak, and total saved results with a recent progress row
- Friendlier UI states for saved results, score examples, imports, and navigation
- Compact colorful overview and editorial headings with dedicated task-focused views
- Firebase-ready login/sign-up flow with Google and Apple account options
- Friend requests, friend leaderboards, and cloud-ready saved profiles/scores
- Spoiler-safe answer sharing
- Official game links
- Clipboard and paste import for supported official share results, with game-specific parsing errors when a pasted result is incomplete
- Paste-first Add score flow with automatic game detection, score/date preview, explicit save or replacement, duplicate protection, and sample results for every supported import
- Visible Paste result / Enter manually tabs for the supported official games, with game-specific score fields and Manual labels on saved results and individual leaderboards
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

- The initial manual entry pass covered existing official games. As of 2026-10-28, Other game also accepts a game name and scoring style; in-app game scores still cannot be overridden manually.
- Manual scores count on the same leaderboards as pasted scores and are labeled Manual.
- Answer, note, and answer-sharing controls are optional. Existing scores show a replacement warning.
- Desktop and 390x844 mobile checks covered all six games, saving and reload persistence, rank selection, missed Wordle, manual-to-paste switching, draft retention across tabs, replacement, optional fields, invalid/future dates, simulated storage failure/retry, and keyboard tabs.
- The import suite now has 22 passing tests, including manual score normalization and validation.

### Custom games (2026-10-28)

- Add score > Enter manually > Other game opens the game name and scoring-style form. Custom games appear under Your games and in the score picker after reload.
- Supported scoring: higher/lower numeric score (including decimals and negative scores), fastest time, fewest guesses/mistakes, or completion only. Custom scores retain the Manual label and existing leaderboard behavior.
- Custom definitions are included in the Firebase adapter's account payload and accepted-friend score loading. Live Firebase sync remains unverified without configured credentials/rules.
- Verified creation and score persistence for all six styles, duplicate-name prevention, cancel/close, pin persistence, score updates, simulated storage failures/retry, official import regression, and desktop/mobile layouts. The parser/normalization suite has 25 passing tests.

### Friends-first rankings (2026-11-02)

- Friends & scores has Overall and Per game tabs, a date picker, seven-day combined totals ending on the selected date, your highlighted rank, and an explanation of points. The per-game picker is independent of the game being played.
- Equal scores receive equal places and points (for example, 1, 1, 3). Overall ties use total points; names only stabilize display order. Completed puzzles rank ahead of partial results, while points/depth/rank games use their scoring value. Missed, invalid, and unplayed results receive no rank or points. Manual scores count equally and retain their label.
- Friends can be searched by name or handle. Local friends are explicitly device-only; adding one sends no invitation and does not invent their scores. The undefined-UID bug that replaced an existing local friend is fixed. Duplicate local handles are blocked, failed saves roll back, and removal keeps score history while excluding the person from rankings.
- Sample people are hidden by default, including legacy sample records. Show sample friends is a non-destructive preview toggle replacing Reset demo. Hidden/removed people are also excluded from completion counts and answer feeds.
- The Firebase adapter now exposes received/sent requests, accept/decline/cancel, connection removal, score refresh, and handle copying. Transactions check the latest request status and participant direction before changes; sending cannot overwrite pending or accepted requests. Remote score refresh removes stale deleted entries. Cloud score payloads contain only the account owner's entries, not cached friend/sample scores.
- Firebase is still **not configured**. Request and cloud UI checks used a simulated backend; no real Google/Apple login, deployed Firestore rules, or multi-device synchronization was verified. Before enabling production sync, finish the backend setup and test consent-based access rules, safe account lookup/unique handles, and account switching/data isolation. Client-side request checks are not a replacement for server-side authorization.

Verification: `swift run solvry-site`, `node --check dist/app.js`, `git diff --check`, and `node --test Tests/share-import.test.cjs Tests/friends-leaderboard.test.cjs` pass (38 tests). Browser QA at 1366×900 and 390×844 covered adding two distinct local friends, duplicate prevention, search, sample toggling, reload persistence, tied score import, date/game/period filters, keyboard tabs, removal confirmation/cancellation, and simulated storage failure/retry. Simulated cloud UI checks covered sending/accepting/declining/cancelling requests, duplicate/self-request prevention, refresh, unfriend, network failure/retry, and copying a handle. These checks do not re-certify golf gameplay.

## Universal import verification (2026-11-03)

Swift build, JavaScript syntax, 58 parser/leaderboard tests, and diff whitespace checks pass. Browser QA used an isolated local profile on desktop (1366×900) and mobile (390×844): every one of the 19 sample formats previewed and saved, persisted across reload, and updated the leaderboard. Checked manual correct-count/rarity entry, game search, rejected link-only Color text without storage writes, and no horizontal overflow. Preserved a fixture golf round and its entry while confirming neither its catalog card nor its daily ranking points appeared. Solvry game engines remain in the Swift source. No real user data or third-party gameplay was modified by QA.

## Import navigation correction (2026-11-03)

Switching games now clears already-saved paste text and its confirmation. Unsaved drafts retain their own text and Played on date per selected game for the current session; returning to a game restores its draft. Delayed clipboard reads cannot populate a different game after navigation. A new visit starts on the user's local calendar date, while historical scores remain intact.

The actual Color Daily share format supplied in the bug report is recognized separately from challenge shares. Its printed month/day (and year, when supplied) must match Played on. Valid daily shares contribute to combined points, including previously saved shares on their correct date; challenge or wrong-date entries do not affect daily placements. Existing dated entries are never silently moved. Yearless shares do not invent a year.

Validation: Swift build, JS syntax, diff checks, and 65 automated tests passed. Desktop/mobile browser QA reproduced saved Color → Size It Up navigation, unsaved draft switching via sidebar/quick tiles, stale selected-date reload, date mismatch rejection, correct daily ranking, and a delayed clipboard response after switching. Historical fixture entries stayed unchanged.
