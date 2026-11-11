# Solvry

Solvry is a Swift-generated universal leaderboard for daily games: paste a shared result, review it, and compare per-game and combined scores with friends.

## Current release and launch status (2026-11-11)

This repository contains the application source, Firebase rules/configuration, tests, and operations tooling for live **Solvry v67**. The published source checkpoint is `45bf30f4133344b7c86215ec618b755332d62b46` in the separate Sites source history; it is provenance, not a commit in this GitHub repository. GitHub stores the project source; publication remains through OpenAI Sites.

The site is still **invite-only** at https://solvry.walebkong.chatgpt.site/. No custom domain has been connected. Firebase Google sign-in and Toronto Firestore are active on Spark with billing disabled. Apple sign-in is not configured. Uploading this repository does not publish the website, widen access, deploy Firebase rules, or change billing.

See [the release verification summary](QA/RELEASE_READINESS.md) for the completed two-account beta, test results, rollback/restore drills, and remaining public-launch checks. Raw participant reports, screenshots, account exports, credentials, and encrypted backups are intentionally kept out of this public repository. Generated `dist/` files and installed dependencies are rebuilt locally.

## Launch operations (2026-11-10)

See [the operations runbook](Operations/RUNBOOK.md) for owner quota-warning emails, the usage dashboard, private operational error summaries, encrypted daily local backups and the tested application rollback procedure. Firebase stays on Spark; managed backups/PITR and billing-budget alerts are not enabled. Diagnostics exclude result content and are included in account export/deletion. The remaining audited parser defects QA-02–05 now have regression coverage.

## Reconnect recovery (2026-11-10)

An iPhone Safari beta save uploaded after reconnecting but left an offline-read error visible. Online events and manual retries now join one account-scoped recovery task, which waits for any prior upload, fetches fresh cloud state, and retries temporary read failures up to four attempts (2, 4 and 8 second delays). Permission failures remain visible. Switching accounts discards old recovery results. Success status follows a completed cloud check/save. The subsequent real iPhone retry uploaded successfully, reached Changes synced, and was read back on the computer.

## Friend request refresh (2026-11-10)

The beta exposed a local-save bug: rebuilding own-score records from the recovery journal also restored stale social caches, discarding freshly received requests and friend scores. Local saves now retain the current tab's fetched request lists and peer score cache while preserving the independently merged own records. Regression tests exercise the real persistence path, cache-write failure, peer-score removal and concurrent own-score edits.

Requests now load directly from the server at sign-in and when opening the Requests tab. Refresh friends reloads both scoped request lists before scores, alongside existing live listeners. The Requests panel shows the account handle, pending counts, loading state and retryable read errors. A failed refresh retains cached lists; reads completing after an account switch are discarded. The existing request appeared on the iPhone after the fix, was accepted, and the connected privacy and later removal checks passed.

## Invited beta permission checker (2026-11-10)

The direct `/assets/beta-check.html` page uses the browser’s existing Firebase sign-in to run read-only production permission probes. Enter the other beta account’s Solvry handle, the tagged Wordle score date, and the current relationship/answer-sharing stage. It checks own-profile/score reads, peer private-record denial, scoped request queries, and the peer score projection appropriate to that stage. Sanitized downloadable reports contain test names, pass/fail, errors, field names and identifier suffixes, with no answer/note/raw-result values or sign-in tokens. The checker makes no database changes and does not replace real phone, offline or account-switching tests.

## Account and score management (2026-11-10)

Account now includes JSON exports and a reauthenticated, resumable deletion flow. Saved game results offer Delete score and Change date; account date moves are atomic and reject occupied destinations. A persistent sync indicator distinguishes device saves, pending/offline work, errors, conflicts and cloud acknowledgments. The [privacy notice](PRIVACY_NOTICE.md) describes actual storage, sharing and retention, including recovery journals and minimal deletion markers. See [the implementation notes](ACCOUNT_DATA_SAFETY.md#account-and-score-controls-2026-11-10) for cleanup behavior and test coverage.

## Account and data safety (2026-11-09)

Account storage is isolated by verified Firebase UID; signing in does not import guest history. Private records and minimal friend-readable score projections replace the mixed account document. Revisioned transactions retain competing edits for explicit review. See [ACCOUNT_DATA_SAFETY.md](ACCOUNT_DATA_SAFETY.md) for the schema, recovery behavior, tests and required Firebase activation steps. Firebase was activated on 2026-11-10 in project `solvry-walebkong`, using the Toronto Standard Firestore database and Google sign-in. The tested rules are deployed and the admin activation marker is set. Apple sign-in is not configured.

The dated entries below describe earlier releases and may reference superseded storage behavior.

## Personal and shared custom games (2026-11-06)

Use **Games → Add a custom game**, or **Add score → Enter manually → Other game**. Set a name, optional HTTP(S) website, and scoring style (higher/lower score, time, guesses, mistakes, completion). The game starts personal and device-local. Personal definitions, scores, and pins are omitted from the friend-readable cloud document. All custom games are excluded from combined daily rankings; per-game rankings still follow their scoring rule.

On a custom game's page, **Share game → Share & copy link** explicitly enables sharing with connected friends. The URL contains only a versioned game definition and a random stable ID, never scores or profile data. A recipient reviews and confirms before adding the same game. Duplicate links do not duplicate or overwrite games. A conflicting definition is rejected. **Keep personal** stops future score sharing after the next successful cloud sync, but cannot revoke copies of the game definition already received.

Shared definitions/scores use the existing connected-friend backend when configured. Friends must join the same game link; loading friend scores never silently adds a custom game. Without configured sign-in, links can still transfer game setup, but scores remain device-local. The current Site access policy still applies to recipients; this feature does not change the site's audience. Unknown/unsafe URLs, oversized links and unsupported versions are rejected. Clipboard denial exposes a selectable link fallback.

Validation: custom-game link, data-minimization and ranking regression tests plus separate creator/recipient browser sessions. Existing local input/button styling was preserved.

## Original game illustrations (2026-11-05)

The Games catalog uses locally drawn SVG pictograms, visible game names, and muted subject-based colors rather than publisher logo files. Each supported game has a distinct subject cue; Immaculate Grid editions use sport-specific illustrations. Basketball editions share the ball illustration and keep their full names visible. Other views reuse the compact pictograms for consistency.

The catalog labels these as “Supported games” and includes a short independence notice. These design choices are not a claim of trademark clearance or publisher permission. No scoring, import, pinning, or saved-data logic changed.

## Solvry ribbon identity (2026-11-04)

The supplied brand board guides the three-ribbon S, lowercase serif wordmark, and tagline: **Your games. Your scores. One place.** The SVGs are a vector interpretation of the raster reference; the wordmark is outlined from local Georgia Bold so it renders consistently without a font download.

- Warm cream `#F5EEDB`: page background
- Petrol blue `#276776`: logo, links, primary actions, and focus rings
- Terracotta `#D46A50`: logo dot/ribbon and active navigation underline
- Muted gold `#EACB82`: upper logo ribbon
- Charcoal `#373B35`: text

`Assets/Brand/` contains the full logo, reversed logo, monochrome logo, standalone mark, monochrome mark, and app/favicon icon. The Swift build copies them to `dist/assets/Brand/`. Reversed logos use cream lettering and belong on petrol backgrounds; the standalone icon has its own petrol background. Gold and terracotta are decorative accents, not small-text colors. Existing line icons and score workflows remain unchanged.

## Restrained visual system (2026-11-04)

Warm neutral paper, dark text, and one evergreen accent replace the pastel cards, decorative gradients, and translucent navigation. Games use ruled rows with a locally rendered, consistent SVG line-icon family; stats and rankings use type and alignment instead of badges. Forms stay left-aligned at readable widths. Empty states describe the next action and preserve the distinction between device-only and online features. No fabricated scores or friends are introduced.

This supersedes the earlier stretched-card presentation while retaining wide desktop gutters, compact laptop sizing, responsive game counts (6 / 10 / 12), and readable mobile flows. Import parsing, ranking, persistence, pins, and account integration are unchanged. Verified Swift build, JavaScript syntax, 69 regression tests, and all six visible views at 320, 390, 768, and 1280px. Browser checks covered paste/manual saves, reloaded scores, search/pins, game-specific rankings, local friend creation, and account dismissal.

## Screen-filling overview (2026-11-04)

The desktop overview uses the browser width with 3% side margins and grows to the available viewport height. Cards and text scale within bounds, and screens at least 1400×850 show nine games, growing to twelve at 1700px wide. Pinned favorites remain the home lineup when present. Laptop and mobile layouts retain their compact sizing; forms remain at readable widths.

## Compact overview (2026-11-04)

The overview uses a compact header, inline progress stats, and a three-column desktop game lineup. Saved scores preview the first three entries; an expandable list retains access to every additional score. Empty states and recent activity take less space. The default overview fits tested 1280×720, 1366×768, and 1024×768 desktop viewports; narrow/mobile screens retain natural scrolling for readability. Expanding more scores or using browser zoom can require scrolling.

## Simplified navigation (2026-11-03)

- **Today** opens with a compact game lineup, saved scores for the selected date, current streak, total saved results, and a daily overall leaderboard preview.
- **Games** is a searchable catalog with readable names, saved-result checkmarks, pins, and a pinned-only filter. Pinning games personalizes the home lineup (six on laptops, up to twelve on roomy desktops).
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

Run from the repository root with Swift 6 (macOS 14 or later):

```sh
swift run solvry-site
```

The build writes the deployable site to `dist/`. To preview it locally:

```sh
python3 -m http.server 8080 --directory dist
```

Open http://localhost:8080/. Guest/local features work without a cloud session. Firebase sign-in requires an authorized origin; local preview does not modify production configuration.

Install the pinned Node dependencies and run the checks after building:

```sh
npm ci
node --check dist/app.js
npm test
npm run test:rules
```

The Firestore rules suite requires a Java 21+ runtime for the emulator. It uses the disposable `demo-solvry-safety` project rather than production. Operational scripts in `Scripts/` can access the configured production Firebase project when run by an authenticated operator; follow [the runbook](Operations/RUNBOOK.md) before using them. Firebase browser configuration and project/resource IDs are public identifiers, not administrator credentials. No service-account key or saved CLI session is shipped.

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
- Active Firebase Google sign-in; Apple sign-in remains unconfigured
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

Required Firebase products are Authentication and Firestore. Deploy the checked-in `firestore.rules` before creating the admin-only activation marker or enabling the browser configuration. Current collections are `privateUsers`, `profiles`, `sharedScores` and `friendRequests`; legacy `users` documents are denied to clients. Follow the full [activation and verification procedure](ACCOUNT_DATA_SAFETY.md#activate-a-new-firebase-backend).

## Current verification baseline

The v67 release validation passed **139 app tests**, **20 Firestore emulator tests**, JavaScript/module syntax checks, and live/source rule comparison. User-assisted computer Chrome and iPhone Safari checks covered sign-in, account isolation, accepted friendships, answer reveal/hide, removal permission revocation, and offline recovery. Backup restoration into isolated emulators and a live v67 → v65 → v67 application rollback were tested.

On November 11, production account export, occupied-date protection, atomic score date correction, score deletion/reload persistence, and complete disposable account deletion passed through the normal desktop Chrome UI with independent Firebase read-back. Google reauthentication completed, cloud data and the Firebase identity were removed, and only the minimal deletion marker remained. Production diagnostic delivery and its removal during account deletion were also observed. Private test identities, exports, and screenshots are not published here.

An encrypted snapshot is now stored in the owner's private Google Drive, with its key separately saved in Apple Passwords and confirmed on an iPhone. The downloaded snapshot passed checksum/decryption verification and an isolated restore of 22 documents and 2 Google identity records. Future daily snapshots still need offsite upload.

These checks do not establish readiness for unrestricted public traffic. Live competing edits, new-tester onboarding, Android/mobile Chrome coverage, anonymous public/custom-domain access, ongoing offsite backup uploads, and broader interrupted/stale-session deletion scenarios remain follow-up work. See [the release verification summary](QA/RELEASE_READINESS.md).

The dated sections below retain historical implementation and test notes; the hidden Solvry Holes engine is not part of the public launch scope.

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
