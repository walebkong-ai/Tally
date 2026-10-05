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
- Add-friend and add-game flows
- Browser-local fallback when cloud config is not connected

## Account and friend sync

Solvry now includes a real-account adapter for Firebase Auth and Firestore. Without config, the site stays in local mode and labels friends as local-only. To enable production accounts, provide a Firebase web config as `window.SOLVRY_FIREBASE_CONFIG` before `app.js` loads, or save the same JSON in local storage under `solvry-firebase-config` while testing.

Required Firebase products:

- Authentication with Google and Apple providers enabled
- Firestore collections for `users` and `friendRequests`
- Security rules that let signed-in users read/write their own profile and scores, read accepted friends' public score data, and create/respond to their own friend requests
