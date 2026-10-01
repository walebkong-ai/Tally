# Solvry

Solvry is a Swift-generated website for tracking daily word and puzzle games with friends.

## Build

```sh
swift run solvry-site
```

The build writes the deployable site to `dist/`.

## What is in this version

- Daily game tracker for paste-supported games: Wordle and Krillion
- Only games with clipboard/paste result import are displayed
- Logo-style game cards with pinned favorites
- Per-game scoring rules and score hints
- Individual game scoreboards plus a combined Solvry leaderboard
- Streak, completed-today, and total-solves stats with a recent progress row
- Friendlier UI states for saved results, score examples, imports, and navigation
- Colorful Concept C-style dashboard strip with Concept A-style editorial headings
- Prototype login/sign-up flow with Apple and Google account options
- Friend leaderboard
- Spoiler-safe answer sharing
- Official game links
- Clipboard and paste import for official Wordle and Krillion share results
- Add-friend and add-game flows
- Browser-local saved data for the first prototype
