import Foundation

@main
struct SolvrySite {
    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let dist = root.appending(path: "dist", directoryHint: .isDirectory)

        if FileManager.default.fileExists(atPath: dist.path) {
            try FileManager.default.removeItem(at: dist)
        }

        try FileManager.default.createDirectory(at: dist, withIntermediateDirectories: true)
        try write(html, to: dist.appending(path: "index.html"))
        try write(styles, to: dist.appending(path: "styles.css"))
        try write(appScript, to: dist.appending(path: "app.js"))
        try FileManager.default.copyItem(at: root.appending(path: "Assets"), to: dist.appending(path: "assets"))

        print("Solvry built at \(dist.path)")
    }

    private static func write(_ content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}

let html = #"""
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Solvry</title>
    <meta
      name="description"
      content="One leaderboard for your daily games. Paste results, track your progress, and compare scores with friends."
    />
    <link rel="icon" type="image/svg+xml" href="assets/Brand/solvry-icon.svg?v=24" />
    <meta name="theme-color" content="#276776" />
    <link rel="stylesheet" href="styles.css?v=24" />
  </head>
  <body>
    <div class="app" id="app">
      <header class="topbar">
        <a class="brand" href="#today" aria-label="Solvry home">
          <span class="brand-lockup">
            <img class="brand-logo" src="assets/Brand/solvry-logo.svg" width="164" height="46" alt="solvry." />
            <small>Your games. Your scores. One place.</small>
          </span>
        </a>
        <nav class="topnav" aria-label="Primary">
          <a href="#today">Today</a>
          <a href="#games">Games</a>
          <a href="#leaderboard">Leaderboard</a>
          <a href="#friends">Friends</a>
        </nav>
        <div class="top-actions">
          <a class="primary-button nav-add-score" href="#import">＋ Add score</a>
          <div class="account-controls" id="accountControls">
            <button class="ghost-button compact-button" type="button" data-account-action="login">Account</button>
          </div>
        </div>
      </header>

      <main class="workspace" id="mainContent">
        <p id="appNotice" class="app-notice" role="status" hidden></p>
        <section class="app-view home-view" id="today" data-view="today" aria-label="Today">
          <div class="view-head">
            <div><h1>Your daily results</h1></div>
            <label class="date-control">Viewing date<input id="playDate" type="date" /></label>
          </div>
          <div class="metrics home-metrics" aria-label="Your progress">
            <div><strong id="playedMetric">0</strong><span>results this day</span></div>
            <div><strong id="streakMetric">0</strong><span>day streak</span></div>
            <div><strong id="totalSolvesMetric">0</strong><span>total results</span></div>
            <span id="solvedMetric" hidden>0</span>
          </div>
          <div class="home-columns">
            <div class="home-main">
              <section class="panel home-games"><div class="section-head compact"><div><h2>Your games</h2><p class="field-help" id="quickGamesHint">Pin your favorites to keep them here.</p></div><a class="text-link" href="#games">Browse all →</a></div><div class="dashboard-strip" id="quickGames" aria-label="Your games"></div></section>
              <section class="panel home-scores"><div class="section-head compact"><h2>Your scores</h2><a class="text-link" href="#import">Add score →</a></div><div id="homeScores" class="home-score-list"></div></section>
            </div>
            <div class="home-side">
              <section class="panel home-ranking"><div class="section-head compact"><h2>Overall leaderboard</h2></div><p class="field-help" id="homeRankingDate"></p><div id="homeLeaderboard" class="leaderboard"></div><a class="text-link block-link" href="#leaderboard">See full leaderboard →</a></section>
              <section class="panel activity-card"><h2>Recent activity</h2><div class="progress-days" id="progressDays" aria-label="Recent play history"></div></section>
            </div>
          </div>
        </section>

        <section class="app-view catalog-view" id="games" data-view="games" aria-label="Games" hidden>
          <div class="view-head"><div><h1>Games</h1><p class="view-copy">Play on the official site. Bring your result back here.</p></div><a class="ghost-button" href="#import">Add a score</a></div>
          <div class="catalog-controls"><label class="catalog-search">Find a game<input id="gameSearch" type="search" placeholder="Search games…" /></label><button id="pinnedFilter" class="ghost-button" type="button" aria-pressed="false">Pinned only</button></div>
          <div class="game-list" id="gameList"></div>
        </section>

        <section class="app-view game-view" id="game" data-view="game" aria-label="Game details" hidden>
          <a class="text-link back-link" href="#games">← All games</a>
          <div class="view-head"><div><p class="eyebrow" id="gameDateLabel">Your daily game</p><h1 id="activeGameTitle">Wordle</h1></div><div class="view-actions"><a class="ghost-button" id="officialLink" href="https://www.nytimes.com/games/wordle/index.html" target="_blank" rel="noopener">Play official ↗</a><a class="primary-button" href="#import">Add score</a></div></div>
          <div class="panel game-detail-card">
            <div class="current-result" id="currentResult"></div>
            <div class="game-meta-row"><span class="pill" id="friendCompletion">0 friends done</span><span class="pill" id="privacyState">Answers hidden</span><button type="button" class="text-link" id="viewGameLeaderboard">View leaderboard →</button></div>
            <details class="scoring-details"><summary>How scoring works</summary><p class="score-hint" id="scoreHint"></p></details>
            <div class="solvry-game" id="solvryGame" hidden></div><div class="letter-board" id="letterBoard" hidden></div>
          </div>
          <details class="game-answers" id="gameAnswers"><summary>Answers &amp; notes</summary>
        <section class="panel answer-panel" id="answers">
          <div class="section-head compact">
            <div>
              <p class="eyebrow">Spoiler-safe</p>
              <h2>Answers and reactions</h2>
            </div>
            <button class="ghost-button" id="copyButton" type="button">Copy recap</button>
          </div>
          <div class="answer-feed" id="answerFeed"></div>
        </section>
          </details>
        </section>

        <section class="app-view score-view panel" id="scoreView" data-view="import" aria-label="Add score" hidden>
          <div class="import-surface" id="import">
            <div>
              <p class="eyebrow">From your daily games</p>
              <h1>Add a score</h1><p class="view-copy">Paste a shared result or enter a score. Review it before saving.</p>
            </div>
            <div class="score-tabs" role="tablist" aria-label="Add score method">
              <button id="pasteTab" type="button" role="tab" aria-selected="true" aria-controls="pastePanel">Paste result</button>
              <button id="manualTab" type="button" role="tab" aria-selected="false" aria-controls="manualEntry" tabindex="-1">Enter manually</button>
            </div>
            <div id="pastePanel" class="paste-panel" role="tabpanel" aria-labelledby="pasteTab">
            <div class="import-input-head">
              <label for="shareTextInput">Your copied result</label>
              <button class="ghost-button compact-button" id="importClipboardButton" type="button">Paste from clipboard</button>
            </div>
            <textarea id="shareTextInput" class="share-input" rows="4" aria-describedby="importStatus" placeholder="Paste your game's shared result here" spellcheck="false"></textarea>
            <label class="import-date">
              Played on
              <input id="importDate" type="date" required />
            </label>
            <div class="import-status" id="importStatus" role="status" aria-live="polite"></div>
            <div class="share-preview" id="sharePreview" hidden></div>
            <div class="import-actions">
              <button class="primary-button" id="importPasteButton" type="button" disabled>Save score</button>
              <button class="ghost-button" id="importClearButton" type="button" hidden>Add another score</button>
            </div>
            <details class="import-help">
              <summary>Supported games &amp; sample results</summary>
              <label>Game<select id="importExampleGame">
                <option value="wordle">Wordle</option>
                <option value="connections">Connections</option>
                <option value="strands">Strands</option>
                <option value="mini-crossword">Mini Crossword</option>
                <option value="spelling-bee">Spelling Bee</option>
                <option value="krillion">Krillion</option>
              </select></label>
              <pre id="importExampleText" class="share-grid"></pre>
              <a id="importExampleLink" target="_blank" rel="noopener">Open game</a>
            </details>
            </div>
          </div>

            <div class="manual-entry" id="manualEntry" role="tabpanel" aria-labelledby="manualTab" hidden>
            <form class="entry-form" id="entryForm">
              <div class="manual-grid">
                <label>Game<select id="manualGameInput"></select></label>
                <label>Played on<input id="manualDateInput" type="date" required /></label>
              </div>
              <p class="import-warning" id="manualExisting" hidden></p>
              <div class="field-grid">
                <label>
                  Result
                  <select id="resultInput">
                    <option value="solved">Solved</option>
                    <option value="missed">Missed</option>
                    <option value="played">Played</option>
                  </select>
                </label>
                <div class="manual-score-field">
                  <label id="manualScoreLabel" for="scoreInput">Guesses</label>
                  <input id="scoreInput" type="text" autocomplete="off" aria-describedby="scoreHelp saveStatus" />
                  <select id="manualRankInput" hidden aria-label="Spelling Bee rank">
                    <option>Beginner</option><option>Good Start</option><option>Moving Up</option><option>Good</option><option>Solid</option><option>Nice</option><option>Great</option><option>Amazing</option><option>Genius</option><option>Queen Bee</option>
                  </select>
                  <small class="field-help" id="scoreHelp">Example: 4/6</small>
                </div>
              </div>
              <label id="rarityField" hidden>Rarity score<input id="rarityInput" type="number" min="0" max="900" step="any" disabled /><small>Lower is better. Use the score, not a percentage.</small></label>
              <details class="manual-extras">
                <summary>Answer &amp; note (optional)</summary>
                <label>
                  Answer
                  <input id="answerInput" type="text" placeholder="Optional" autocomplete="off" />
                  <small class="field-help">Only shared when reveal is on.</small>
                </label>
              <label class="wide-label">
                Note
                <input id="noteInput" type="text" placeholder="Close call, lucky guess, weird clue..." autocomplete="off" />
              </label>
                <label class="switch-row">
                  <input id="revealInput" type="checkbox" />
                  <span class="switch" aria-hidden="true"></span>
                  <span>Show my answer to friends</span>
                </label>
              </details>
              <div class="form-actions">
                <button class="primary-button" id="manualSaveButton" type="submit">Save score</button>
              </div>
              <div class="save-status" id="saveStatus" role="status"></div>
            </form>
            </div>
          <div id="scoreNextSteps" class="score-next-steps" hidden><a href="#today" class="text-link">Back to overview →</a><a href="#leaderboard" class="text-link">View leaderboard →</a></div>
        </section>

        <section class="app-view leaderboard-view panel" id="leaderboard" data-view="leaderboard" aria-label="Leaderboard" hidden>
          <div class="view-head"><div><h1>Leaderboard</h1><p class="view-copy">Compare your daily results with friends.</p></div><a class="text-link" href="#friends">Manage friends →</a></div>
          <div class="score-tabs" role="tablist" aria-label="Leaderboard view">
            <button id="overallTab" role="tab" aria-selected="true" aria-controls="overallBoard" type="button">Overall</button>
            <button id="gameBoardTab" role="tab" aria-selected="false" aria-controls="gameBoard" tabindex="-1" type="button">Per game</button>
          </div>
          <div class="leaderboard-controls">
            <label>Date<input id="leaderboardDate" type="date" /></label>
            <label id="leaderboardRangeLabel">Period<select id="leaderboardRange"><option value="1">Selected day</option><option value="7">Last 7 days</option></select></label>
            <label id="leaderboardGameLabel" hidden>Game<select id="leaderboardGameInput"></select></label>
            <p class="scoreboard-note" id="leaderboardDates"></p>
          </div>
          <p id="leaderboardSummary" class="leaderboard-summary" role="status"></p>
          <div class="scoreboard-stack">
            <section class="scoreboard-block" id="overallBoard" role="tabpanel" aria-labelledby="overallTab">
              <div class="scoreboard-head">
                <h3 id="overallScoreboardTitle">Solvry overall</h3>
                <span>Combined points</span>
              </div>
              <details class="ranking-rules"><summary>Points &amp; ties</summary><p>Daily places earn 10, 7, 5, 3, 2, then 1 point. Tied scores share the same place and points. Missed or invalid results earn no points. Overall totals reward playing more games.</p></details>
              <div class="leaderboard" id="overallLeaderboard"></div>
            </section>
            <section class="scoreboard-block" id="gameBoard" role="tabpanel" aria-labelledby="gameBoardTab" hidden>
              <div class="scoreboard-head">
                <h3 id="gameScoreboardTitle">Wordle scoreboard</h3>
                <span id="gameScoreboardMeta">Fewest guesses</span>
              </div>
              <p class="scoreboard-note" id="gameScoreboardNote">Lower guess counts rank higher.</p>
              <div class="leaderboard" id="gameLeaderboard"></div>
            </section>
          </div>
        </section>

        <section class="app-view friends-view panel" id="friends" data-view="friends" aria-label="Friends" hidden>
          <div class="view-head"><div><h1>Friends</h1><p class="view-copy">Manage the people you compare results with.</p></div><button class="ghost-button compact-button" id="refreshFriendsButton" type="button">Refresh scores</button></div>
          <section class="friends-section" aria-labelledby="friendsTitle">
          <div class="scoreboard-head"><h3 id="friendsTitle">Friends</h3><span id="friendsCount"></span></div>
          <div class="friend-sync" id="friendSync"></div>
          <div class="friend-toolbar"><button id="copyHandleButton" class="ghost-button compact-button" type="button" hidden>Copy my handle</button><label class="demo-toggle"><input id="showDemoFriends" type="checkbox" />Show sample friends</label></div>
          <div class="score-tabs" role="tablist" aria-label="Friends view">
            <button id="friendsTab" role="tab" aria-selected="true" aria-controls="friendsPanel" type="button">Friends</button>
            <button id="requestsTab" role="tab" aria-selected="false" aria-controls="requestsPanel" tabindex="-1" type="button">Requests</button>
          </div>
          <div id="friendsPanel" role="tabpanel" aria-labelledby="friendsTab">
            <label class="friend-search">Find a friend<input id="friendSearch" type="search" placeholder="Name or handle" autocomplete="off" /></label>
            <div id="friendRoster" class="friend-roster"></div>
          </div>
          <div id="requestsPanel" role="tabpanel" aria-labelledby="requestsTab" hidden><div id="friendRequests" class="friend-roster"></div></div>
          <details class="add-friend-details"><summary id="addFriendSummary">Add a local friend</summary>
          <form class="friend-form" id="friendForm">
            <label>
              Friend name
              <input id="friendNameInput" type="text" placeholder="Avery" autocomplete="off" maxlength="60" required />
            </label>
            <label>
              Handle
              <input id="friendHandleInput" type="text" placeholder="@averyplays" autocomplete="off" maxlength="60" />
            </label>
            <button class="primary-button" id="friendSubmitButton" type="submit">Add local friend</button>
          </form>
          </details>
          <p id="friendStatus" class="friend-status" role="status"></p>
          </section>        </section>
      </main>

      <dialog class="modal" id="gameDialog">
        <form method="dialog" class="modal-content" id="gameForm">
          <div class="section-head compact">
            <div>
              <p class="eyebrow">Track anything</p>
              <h2>Add a daily game</h2>
            </div>
            <button class="icon-button" id="closeGameDialogButton" type="button" aria-label="Close">x</button>
          </div>
          <label>
            Game name
            <input id="gameNameInput" type="text" placeholder="Game name" maxlength="60" required />
          </label>
          <label>
            Scoring style
            <select id="gameTypeInput">
              <option value="points">Score: higher is better</option>
              <option value="strokes">Score: lower is better</option>
              <option value="time">Time: fastest wins</option>
              <option value="guesses">Guesses: fewest wins</option>
              <option value="mistakes">Mistakes: fewest wins</option>
              <option value="complete">Completion only</option>
            </select>
          </label>
          <p id="gameFormStatus" class="import-warning" role="status"></p>
          <button class="primary-button" value="default" type="submit">Add game &amp; enter score</button>
        </form>
      </dialog>

      <dialog class="modal" id="accountDialog">
        <form method="dialog" class="modal-content account-modal" id="accountForm">
          <div class="section-head compact">
            <div>
              <p class="eyebrow">Account</p>
              <h2 id="accountTitle">Create your Solvry account</h2>
            </div>
            <button class="icon-button" id="closeAccountDialogButton" type="button" aria-label="Close">x</button>
          </div>
          <p class="account-copy">Save your profile and get ready to sync scores with friends.</p>
          <button class="provider-button" type="button" data-provider="Apple">
            <span class="provider-mark">A</span>
            <span>Continue with Apple</span>
          </button>
          <button class="provider-button" type="button" data-provider="Google">
            <span class="provider-mark google">G</span>
            <span>Continue with Google</span>
          </button>
          <p class="account-note" id="accountStatus">Online sign-in isn’t available yet. You can keep tracking scores on this device.</p>
        </form>
      </dialog>
    </div>
    <script src="app.js?v=24" type="module"></script>
  </body>
</html>
"""#

let styles = #"""
:root {
  color-scheme: light;
  --ink: #141719;
  --muted: #66706d;
  --paper: #f7f4ea;
  --panel: #fffefa;
  --line: #d8d4c7;
  --green: #10a77a;
  --yellow: #efbd3a;
  --coral: #f26d5b;
  --violet: #5f5bd7;
  --aqua: #bdeee2;
  --sky: #72b7ff;
  --pink: #ff87b0;
  --lime: #a7df4e;
  --mint: #8be8c8;
  --shadow: 0 22px 60px rgba(20, 23, 25, 0.12);
  --display: Georgia, "Times New Roman", ui-serif, serif;
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

* {
  box-sizing: border-box;
}

[hidden] {
  display: none !important;
}

html {
  scroll-behavior: smooth;
  overflow-x: hidden;
}

body {
  margin: 0;
  min-width: 320px;
  overflow-x: hidden;
  background:
    linear-gradient(135deg, rgba(114, 183, 255, 0.18) 0 18%, transparent 18% 100%),
    linear-gradient(225deg, rgba(255, 135, 176, 0.16) 0 20%, transparent 20% 100%),
    linear-gradient(180deg, rgba(167, 223, 78, 0.14), rgba(247, 244, 234, 0) 42%),
    var(--paper);
  color: var(--ink);
}

button,
input,
textarea,
select {
  font: inherit;
}

button {
  cursor: pointer;
}

a {
  color: inherit;
  text-decoration: none;
}

.app {
  min-height: 100vh;
}

.topbar {
  position: sticky;
  top: 0;
  z-index: 5;
  display: grid;
  grid-template-columns: minmax(180px, 1fr) auto minmax(250px, 0.6fr);
  gap: 18px;
  align-items: center;
  padding: 16px clamp(16px, 4vw, 42px);
  border-bottom: 1px solid rgba(20, 23, 25, 0.1);
  background: rgba(247, 244, 234, 0.9);
  backdrop-filter: blur(18px);
}

.brand {
  display: inline-flex;
  gap: 12px;
  align-items: center;
  min-width: 0;
}

.brand-mark {
  display: grid;
  width: 44px;
  height: 44px;
  place-items: center;
  border-radius: 8px;
  border: 2px solid var(--ink);
  background:
    linear-gradient(135deg, var(--yellow) 0 48%, var(--green) 48% 100%);
  color: var(--paper);
  font-size: 0.78rem;
  font-weight: 900;
  letter-spacing: 0;
  text-shadow: 0 1px 0 rgba(20, 23, 25, 0.32);
}

.brand strong,
.brand small {
  display: block;
}

.brand strong {
  font-family: var(--display);
  font-size: 1rem;
  letter-spacing: 0;
}

.brand small {
  color: var(--muted);
  font-size: 0.78rem;
}

.topnav {
  display: inline-flex;
  gap: 6px;
  padding: 5px;
  border: 1px solid var(--line);
  border-radius: 999px;
  background: rgba(255, 254, 250, 0.72);
}

.topnav a {
  padding: 9px 14px;
  border-radius: 999px;
  color: var(--muted);
  font-size: 0.92rem;
  font-weight: 700;
}

.topnav a:hover {
  background: var(--ink);
  color: var(--paper);
}

.topnav a.active {
  background: var(--yellow);
  color: var(--ink);
  box-shadow: inset 0 0 0 1px rgba(20, 23, 25, 0.12);
}

.top-actions {
  justify-self: end;
  display: flex;
  gap: 10px;
  align-items: end;
}

.date-control {
  display: grid;
  gap: 4px;
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 800;
  text-transform: uppercase;
}

.account-controls {
  display: inline-flex;
  gap: 8px;
  align-items: center;
  min-height: 42px;
}

.account-name {
  display: grid;
  max-width: 150px;
  color: var(--ink);
  font-size: 0.82rem;
  font-weight: 900;
  line-height: 1.15;
}

.account-name small {
  overflow: hidden;
  color: var(--muted);
  font-size: 0.72rem;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.date-control input,
input,
textarea,
select {
  width: 100%;
  min-width: 0;
  min-height: 42px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--panel);
  color: var(--ink);
  padding: 10px 12px;
}

textarea {
  resize: vertical;
  line-height: 1.45;
}

.workspace {
  display: grid;
  grid-template-columns: minmax(220px, 260px) minmax(0, 1.45fr) minmax(300px, 0.9fr);
  grid-template-areas:
    "rail tracker social"
    "rail tracker answers";
  gap: 18px;
  align-items: start;
  max-width: 1540px;
  margin: 0 auto;
  padding: clamp(16px, 4vw, 42px);
}

.game-rail {
  grid-area: rail;
  align-self: start;
  position: sticky;
  top: 94px;
}

.rail-title,
.section-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
}

.rail-title {
  margin-bottom: 12px;
  font-size: 0.86rem;
  font-weight: 900;
  text-transform: uppercase;
  color: var(--muted);
}

.game-list {
  display: grid;
  gap: 10px;
}

.game-section-label {
  display: grid;
  gap: 2px;
  margin: 4px 0 0;
  color: var(--muted);
  font-size: 0.74rem;
  font-weight: 900;
  text-transform: uppercase;
}

.game-section-label span {
  color: rgba(102, 112, 109, 0.78);
  font-size: 0.68rem;
}

.game-card,
.panel {
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 254, 250, 0.86);
  box-shadow: 0 8px 24px rgba(20, 23, 25, 0.06);
}

.game-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 36px;
  gap: 8px;
  align-items: center;
  width: 100%;
  padding: 10px;
  border-color: transparent;
  transition: transform 150ms ease, box-shadow 150ms ease, border-color 150ms ease;
}

.game-card:hover,
.game-card.active {
  border-color: var(--ink);
  background: var(--panel);
  transform: translateY(-1px);
}

.game-card.pinned {
  border-color: rgba(95, 91, 215, 0.45);
  background:
    linear-gradient(90deg, rgba(255, 226, 138, 0.24), rgba(189, 238, 226, 0.3)),
    rgba(255, 254, 250, 0.86);
}

.game-card.solvry {
  background:
    linear-gradient(90deg, rgba(201, 199, 255, 0.22), rgba(255, 135, 176, 0.14)),
    rgba(255, 254, 250, 0.82);
}

.game-select {
  display: grid;
  grid-template-columns: 46px minmax(0, 1fr) auto;
  gap: 10px;
  align-items: center;
  min-width: 0;
  border: 0;
  background: transparent;
  padding: 0;
  text-align: left;
}

.game-logo {
  display: grid;
  width: 46px;
  height: 46px;
  place-items: center;
  border-radius: 8px;
  background: var(--aqua);
  color: var(--ink);
  overflow: hidden;
}

.game-logo svg {
  width: 34px;
  height: 34px;
  display: block;
}

.game-logo.connections,
.game-logo.pinpoint,
.game-logo.krillion {
  background: linear-gradient(135deg, #ffe28a, #ffb86b);
}

.game-logo.strands,
.game-logo.queens {
  background: linear-gradient(135deg, #ffb1a7, #ff87b0);
}

.game-logo.mini-crossword,
.game-logo.crossclimb {
  background: linear-gradient(135deg, #c9c7ff, #9fd0ff);
}

.game-logo.sudoku,
.game-logo.zip {
  background: linear-gradient(135deg, #bdeee2, #a7df4e);
}

.game-logo.holes,
.game-logo.hoops {
  background: linear-gradient(135deg, #72b7ff, #a7df4e);
}

.game-meta {
  min-width: 0;
}

.game-meta strong,
.game-meta span {
  display: block;
}

.game-meta strong {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.game-meta span {
  color: var(--muted);
  font-size: 0.8rem;
}

.game-score {
  font-size: 0.78rem;
  font-weight: 900;
  color: var(--green);
}

.pin-button {
  display: grid;
  width: 36px;
  height: 36px;
  place-items: center;
  border: 1px solid transparent;
  border-radius: 8px;
  background: transparent;
  color: var(--muted);
}

.pin-button:hover,
.pin-button.active {
  border-color: var(--line);
  background: rgba(239, 189, 58, 0.22);
  color: var(--ink);
}

.pin-button svg {
  width: 18px;
  height: 18px;
}

.panel {
  min-width: 0;
  padding: clamp(18px, 3vw, 26px);
}

.tracker-panel {
  grid-area: tracker;
  overflow: hidden;
}

.social-panel {
  grid-area: social;
}

.answer-panel {
  grid-area: answers;
}

.compact {
  margin-bottom: 16px;
}

.eyebrow {
  margin: 0 0 4px;
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 900;
  text-transform: uppercase;
}

h1,
h2,
h3 {
  font-family: var(--display);
  margin: 0;
  letter-spacing: 0;
}

h1 {
  font-size: clamp(2.3rem, 6vw, 5rem);
  line-height: 0.96;
}

h2 {
  font-size: clamp(1.35rem, 3vw, 1.8rem);
}

.dashboard-strip {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
  margin-top: 20px;
}

.quick-game {
  display: grid;
  gap: 8px;
  min-width: 0;
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background:
    linear-gradient(135deg, rgba(189, 238, 226, 0.72), rgba(255, 254, 250, 0.88));
  text-align: left;
  transition: transform 150ms ease, box-shadow 150ms ease, border-color 150ms ease;
}

.quick-game:nth-child(2) {
  background:
    linear-gradient(135deg, rgba(255, 226, 138, 0.8), rgba(255, 254, 250, 0.9));
}

.quick-game:nth-child(3) {
  background:
    linear-gradient(135deg, rgba(255, 177, 167, 0.74), rgba(255, 254, 250, 0.9));
}

.quick-game:nth-child(4) {
  background:
    linear-gradient(135deg, rgba(201, 199, 255, 0.78), rgba(255, 254, 250, 0.9));
}

.quick-game:hover {
  border-color: rgba(20, 23, 25, 0.4);
  box-shadow: 0 10px 22px rgba(20, 23, 25, 0.08);
  transform: translateY(-1px);
}

.quick-game.active {
  border-color: var(--ink);
  box-shadow: 0 0 0 3px rgba(239, 189, 58, 0.4), 0 12px 24px rgba(20, 23, 25, 0.1);
}

.quick-game .game-logo {
  width: 44px;
  height: 44px;
}

.quick-game strong,
.quick-game span {
  display: block;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.quick-game span {
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 850;
}

.score-hint {
  max-width: 560px;
  margin: 8px 0 0;
  color: var(--muted);
  font-size: 0.96rem;
  font-weight: 800;
  line-height: 1.35;
}

.status-stack {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: flex-end;
}

.pill {
  display: inline-flex;
  align-items: center;
  min-height: 34px;
  padding: 7px 10px;
  border: 1px solid var(--line);
  border-radius: 999px;
  background: var(--panel);
  color: var(--muted);
  font-size: 0.82rem;
  font-weight: 900;
}

.pill.accent {
  border-color: rgba(242, 109, 91, 0.35);
  color: #9f3427;
  background: rgba(242, 109, 91, 0.12);
}

.official-link {
  display: inline-flex;
  align-items: center;
  min-height: 34px;
  padding: 7px 12px;
  border: 1px solid var(--ink);
  border-radius: 999px;
  background: var(--ink);
  color: var(--paper);
  font-size: 0.82rem;
  font-weight: 900;
}

.official-link.disabled {
  pointer-events: none;
  border-color: var(--line);
  background: var(--panel);
  color: var(--muted);
}

.play-surface {
  min-width: 0;
  margin-top: 22px;
  padding: clamp(16px, 3vw, 24px);
  border: 1px solid var(--ink);
  border-radius: 8px;
  background:
    linear-gradient(90deg, rgba(255, 255, 255, 0.72), rgba(255, 255, 255, 0.28)),
    repeating-linear-gradient(45deg, rgba(20, 23, 25, 0.04) 0 1px, transparent 1px 16px);
}

.import-surface {
  display: grid;
  gap: 12px;
  margin-top: 18px;
  padding: clamp(16px, 3vw, 22px);
  border-top: 3px solid var(--green);
  border-bottom: 1px solid var(--line);
  background: #fff;
  margin-bottom: 18px;
  scroll-margin-top: 110px;
}

.import-input-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.paste-panel { display: grid; gap: 12px; min-width: 0; }
.score-tabs { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); padding: 4px; gap: 4px; background: #edf3f4; border-radius: 8px; }
.score-tabs button { min-height: 44px; padding: 10px 6px; border: 1px solid transparent; border-radius: 5px; background: transparent; color: var(--muted); font-size: 14px; font-weight: 800; }
.score-tabs button[aria-selected="true"] { background: #fff; border-color: #a7c9bd; color: #07694e; }
.score-tabs button:focus-visible { outline: 2px solid var(--green); outline-offset: 2px; }
.manual-grid, .manual-entry .field-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px; }
.manual-score-field { display: grid; align-content: start; gap: 6px; min-width: 0; }
#gameDialog .section-head { display: grid; grid-template-columns: minmax(0, 1fr) auto; align-items: start; gap: 12px; }
.manual-entry .entry-form { margin: 0; }
.manual-entry .form-actions { justify-content: stretch; }
.manual-entry .form-actions button { width: 100%; }
.manual-extras summary { padding: 8px 0; cursor: pointer; font-size: 14px; font-weight: 700; }
.manual-extras[open] > label { margin-top: 12px; }
.manual-entry .save-status { min-height: 0; line-height: 1.5; }
.manual-entry .save-status.error { color: #9f3427; }
.manual-entry .save-status.success { color: #087255; }
@media (max-width: 480px) {
  .manual-grid, .manual-entry .field-grid { grid-template-columns: minmax(0, 1fr); }
}
.import-input-head label { margin: 0; }
.import-date { display: grid; grid-template-columns: auto minmax(0, 190px); align-items: center; justify-content: start; gap: 12px; }
.import-surface button:disabled { opacity: 0.55; cursor: not-allowed; }
.import-surface textarea { min-width: 0; width: 100%; font-weight: 500; font-size: 16px; resize: vertical; }
.import-status:empty { display: none; }
.import-help, .manual-entry { min-width: 0; }
.import-help summary, .manual-entry summary { cursor: pointer; padding: 12px 0; font-weight: 700; }
.import-help[open] { display: grid; gap: 12px; }
.import-help pre { margin: 12px 0; padding: 12px; background: #f1f6f8; overflow-wrap: anywhere; white-space: pre-wrap; font-size: 14px; }
.manual-entry[open] .entry-form { margin-top: 16px; }
.import-result-head { display: flex; gap: 12px; align-items: center; }
.import-result-head .game-logo { width: 44px; height: 44px; flex: 0 0 44px; }
.import-result-head > div { display: grid; gap: 4px; min-width: 0; }
.import-result-head small { color: var(--muted); }
.import-warning { margin: 0; color: #8a4c12; font-size: 14px; line-height: 1.5; }
.share-preview { overflow-wrap: anywhere; }
.share-preview details summary { cursor: pointer; font-size: 14px; }
.share-preview .share-grid { margin-top: 10px; overflow-wrap: anywhere; }
@media (max-width: 480px) {
  .import-date { grid-template-columns: minmax(0, 1fr); justify-content: stretch; gap: 6px; }
}

.import-surface h2 {
  font-size: clamp(1.2rem, 2.4vw, 1.5rem);
}

.import-copy {
  margin: 0;
  color: var(--muted);
  font-weight: 700;
  line-height: 1.45;
}

.support-row {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.support-row span {
  display: inline-flex;
  min-height: 30px;
  align-items: center;
  padding: 6px 9px;
  border: 1px solid var(--line);
  border-radius: 999px;
  background: var(--panel);
  color: var(--muted);
  font-size: 0.76rem;
  font-weight: 900;
}

.import-actions {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: 10px;
}

.share-input {
  min-height: 132px;
}

.import-status {
  min-height: 42px;
  display: flex;
  align-items: center;
  padding: 10px 12px;
  border-radius: 8px;
  background: rgba(20, 23, 25, 0.06);
  color: var(--muted);
  font-weight: 800;
}

.import-status.success {
  background: rgba(16, 167, 122, 0.12);
  color: #087255;
}

.import-status.error {
  background: rgba(242, 109, 91, 0.12);
  color: #9f3427;
}

.share-preview {
  display: grid;
  gap: 8px;
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--panel);
}

.share-preview[hidden] {
  display: none;
}

.share-grid {
  white-space: pre-line;
  font-size: 1.2rem;
  line-height: 1.25;
}

.letter-board {
  display: grid;
  grid-template-columns: repeat(5, minmax(38px, 1fr));
  gap: 8px;
  max-width: 360px;
  margin-bottom: 22px;
}

.letter-tile {
  aspect-ratio: 1;
  display: grid;
  place-items: center;
  border: 2px solid rgba(20, 23, 25, 0.18);
  border-radius: 8px;
  background: var(--panel);
  font-weight: 950;
  font-size: clamp(1.1rem, 4vw, 1.8rem);
}

.letter-tile.hit {
  background: var(--green);
  color: white;
  border-color: var(--green);
}

.letter-tile.warn {
  background: var(--yellow);
  border-color: var(--yellow);
}

.letter-tile.miss {
  background: #515957;
  border-color: #515957;
  color: white;
}

.current-result {
  display: grid;
  grid-template-columns: 44px minmax(0, 1fr) auto;
  gap: 12px;
  align-items: center;
  margin-bottom: 18px;
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 254, 250, 0.74);
}

.current-result strong,
.current-result span {
  display: block;
}

.current-result span {
  color: var(--muted);
  font-size: 0.82rem;
  font-weight: 800;
}

.current-result .game-logo {
  width: 44px;
  height: 44px;
}

.current-result .game-logo svg {
  width: 32px;
  height: 32px;
}

.solvry-game {
  display: grid;
  gap: 14px;
  min-width: 0;
  margin-bottom: 20px;
}

.solvry-game[hidden] {
  display: none;
}

.solvry-board {
  display: grid;
  grid-template-columns: minmax(0, 1.1fr) minmax(220px, 0.9fr);
  gap: 14px;
}

.play-card {
  display: grid;
  gap: 12px;
  min-width: 0;
  padding: 14px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 254, 250, 0.82);
}

.play-card.primary {
  border-color: var(--ink);
  background:
    linear-gradient(135deg, rgba(189, 238, 226, 0.58), rgba(255, 226, 138, 0.24)),
    rgba(255, 254, 250, 0.9);
}

.play-card h3 {
  margin: 0;
  font-size: 1rem;
}

.play-card p {
  margin: 0;
  color: var(--muted);
  font-weight: 800;
  line-height: 1.4;
}

.play-topline {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.course-view,
.court-view {
  position: relative;
  min-height: 230px;
  overflow: hidden;
  border: 2px solid var(--ink);
  border-radius: 8px;
}

.course-view {
  background:
    radial-gradient(circle at 78% 22%, #fffefa 0 10px, transparent 11px),
    radial-gradient(circle at 18% 65%, rgba(114, 183, 255, 0.86) 0 24px, transparent 25px),
    linear-gradient(120deg, #a7df4e 0 28%, #55b66f 29% 70%, #6ac26d 71% 100%);
}

.court-view {
  background:
    radial-gradient(circle at 50% 21%, #f26d5b 0 10px, transparent 11px),
    linear-gradient(#141719 0 0) 50% 22% / 70px 5px no-repeat,
    radial-gradient(circle at 50% 23%, transparent 0 28px, rgba(20, 23, 25, 0.85) 29px 31px, transparent 32px),
    linear-gradient(180deg, #ffe28a 0 46%, #f2b55f 47% 100%);
}

.course-path,
.shot-arc {
  position: absolute;
  left: 17%;
  right: 17%;
  top: 24%;
  height: 48%;
  border-top: 5px dashed rgba(20, 23, 25, 0.42);
  border-radius: 50%;
  transform: rotate(var(--play-angle));
}

.shot-arc {
  left: 23%;
  right: 23%;
  top: 30%;
  border-color: rgba(255, 254, 250, 0.78);
}

.play-target {
  position: absolute;
  left: var(--target-x);
  top: var(--target-y);
  display: grid;
  width: 42px;
  height: 42px;
  place-items: center;
  border: 2px solid var(--ink);
  border-radius: 50%;
  background: var(--panel);
  color: var(--ink);
  font-weight: 950;
  transform: translate(-50%, -50%);
}

.play-avatar {
  position: absolute;
  left: var(--avatar-x);
  bottom: var(--avatar-y);
  display: grid;
  width: 38px;
  height: 38px;
  place-items: center;
  border: 2px solid var(--ink);
  border-radius: 50%;
  background: var(--coral);
  color: var(--paper);
  font-weight: 950;
  transform: translateX(-50%);
}

.play-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
}

.play-tile {
  display: grid;
  gap: 2px;
  min-height: 64px;
  place-items: center;
  padding: 8px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 254, 250, 0.78);
  color: var(--muted);
  text-align: center;
  font-size: 0.74rem;
  font-weight: 850;
}

.play-tile.current {
  border-color: var(--ink);
  background: var(--yellow);
  color: var(--ink);
}

.play-tile.done {
  border-color: rgba(16, 167, 122, 0.44);
  background: rgba(16, 167, 122, 0.14);
  color: #087255;
}

.play-tile strong {
  display: block;
  color: inherit;
  font-size: 1rem;
}

.meter-stack {
  display: grid;
  gap: 10px;
}

.play-meter {
  display: grid;
  gap: 5px;
}

.meter-label {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  color: var(--muted);
  font-size: 0.76rem;
  font-weight: 900;
  text-transform: uppercase;
}

.meter-track {
  position: relative;
  height: 18px;
  overflow: hidden;
  border: 1px solid var(--ink);
  border-radius: 999px;
  background: linear-gradient(90deg, var(--coral), var(--yellow), var(--green), var(--yellow), var(--coral));
}

.meter-thumb {
  position: absolute;
  top: -3px;
  left: calc(var(--meter-value) * 1%);
  width: 6px;
  height: 24px;
  border-radius: 999px;
  background: var(--ink);
  transform: translateX(-50%);
}

.play-actions {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.play-actions.three {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.play-button {
  min-height: 48px;
  border: 1px solid rgba(39, 60, 50, 0.16);
  border-radius: 999px;
  background: rgba(255, 254, 250, 0.74);
  color: #273c32;
  font-weight: 850;
  transition: transform 0.16s ease, border-color 0.16s ease, background 0.16s ease, box-shadow 0.16s ease;
}

.play-button:hover {
  border-color: rgba(8, 114, 85, 0.38);
  background: rgba(235, 246, 232, 0.92);
  box-shadow: 0 10px 24px rgba(39, 60, 50, 0.08);
  transform: translateY(-1px);
}

.play-button.active {
  border-color: rgba(8, 114, 85, 0.5);
  background:
    linear-gradient(180deg, rgba(218, 245, 233, 0.96), rgba(246, 251, 244, 0.94));
  color: #087255;
  box-shadow: 0 10px 24px rgba(8, 114, 85, 0.12);
}

.play-button.main {
  grid-column: 1 / -1;
  min-height: 56px;
  border-color: rgba(6, 70, 50, 0.95);
  background:
    linear-gradient(180deg, #16392c, #0e261f);
  color: var(--paper);
  box-shadow: 0 18px 32px rgba(9, 45, 33, 0.22);
}

.play-button.main:hover {
  background:
    linear-gradient(180deg, #1f513e, #0d3328);
  border-color: rgba(16, 167, 122, 0.56);
  color: #fffefa;
}

.play-button:disabled {
  cursor: not-allowed;
  opacity: 0.48;
}

.daily-golf {
  display: flex;
  flex-direction: column;
  gap: 0;
  width: min(100%, 590px);
  max-width: 590px;
  height: min(600px, calc(100dvh - 104px));
  min-height: 480px;
  margin: 0 auto;
  overflow: hidden;
  border: 1.5px solid rgba(20, 23, 25, 0.9);
  border-radius: 18px;
  background:
    radial-gradient(circle at 14% 0%, rgba(189, 238, 226, 0.36), transparent 34%),
    linear-gradient(180deg, rgba(255, 254, 250, 0.98), rgba(246, 242, 230, 0.94)),
    var(--panel);
  box-shadow: 0 18px 54px rgba(28, 50, 39, 0.12), 0 1px 0 rgba(255, 254, 250, 0.72) inset;
}

.golf-game-header {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 10px;
  align-items: center;
  flex: 0 0 auto;
  min-height: 42px;
  padding: 7px 13px;
  background:
    linear-gradient(180deg, rgba(255, 254, 250, 0.92), rgba(250, 248, 240, 0.78));
}

.golf-game-header strong {
  display: block;
  font-family: var(--display);
  font-size: clamp(1.12rem, 2.3vw, 1.46rem);
  line-height: 1;
  color: #121817;
  letter-spacing: 0;
}

.golf-game-header span {
  color: var(--muted);
  font-size: clamp(0.68rem, 0.95vw, 0.8rem);
  font-weight: 900;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.golf-game-header .pill {
  justify-self: end;
  min-width: 32px;
  min-height: 30px;
  place-content: center;
  border-radius: 999px;
  background: rgba(255, 254, 250, 0.78);
  box-shadow: inset 0 0 0 1px rgba(39, 60, 50, 0.08);
}

.golf-score-strip {
  display: grid;
  grid-template-columns: repeat(9, minmax(0, 1fr));
  flex: 0 0 auto;
  overflow: hidden;
  border-block: 1px solid rgba(39, 60, 50, 0.1);
  border-radius: 0;
  background: rgba(251, 249, 241, 0.72);
}

.golf-score-hole {
  display: grid;
  gap: 1px;
  min-width: 0;
  padding: 4px 3px 3px;
  border-right: 1px solid rgba(39, 60, 50, 0.08);
  color: var(--muted);
  text-align: center;
  font-size: 0.7rem;
  font-weight: 850;
  transition: background 0.16s ease, color 0.16s ease;
}

.golf-score-hole:last-child {
  border-right: 0;
}

.golf-score-hole.current {
  background:
    linear-gradient(180deg, rgba(217, 244, 229, 0.96), rgba(238, 249, 240, 0.8));
  color: #087255;
  box-shadow: inset 0 3px 0 rgba(8, 114, 85, 0.58);
}

.golf-score-hole.done {
  background: rgba(232, 223, 197, 0.26);
  color: var(--ink);
}

.golf-score-hole strong {
  font-size: clamp(0.84rem, 1.55vw, 0.96rem);
  line-height: 1;
}

.golf-score-hole span {
  font-size: 0.64rem;
}

.golf-score-hole small {
  font-size: 0.6rem;
  opacity: 0.78;
}

.golf-hero-card,
.hole-card,
.results-card {
  display: grid;
  gap: 18px;
  padding: clamp(20px, 4vw, 30px);
  border: 1px solid rgba(39, 60, 50, 0.14);
  border-radius: 18px;
  background:
    linear-gradient(135deg, rgba(189, 238, 226, 0.4), rgba(255, 254, 250, 0.94)),
    var(--panel);
  box-shadow: 0 18px 42px rgba(39, 60, 50, 0.08);
}

.golf-hero-grid,
.hole-card-grid,
.results-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
}

.golf-stat {
  padding: 12px 14px;
  border: 1px solid rgba(39, 60, 50, 0.12);
  border-radius: 14px;
  background: rgba(255, 254, 250, 0.68);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.54);
}

.golf-stat span,
.golf-stat strong {
  display: block;
}

.golf-stat span {
  color: var(--muted);
  font-size: 0.68rem;
  font-weight: 850;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.golf-stat strong {
  margin-top: 5px;
  font-size: clamp(1.05rem, 2vw, 1.35rem);
  line-height: 1.08;
  color: #101817;
}

.daily-golf-board {
  display: grid;
  flex: 1 1 auto;
  grid-template-columns: 1fr;
  grid-template-rows: minmax(0, 1fr) auto;
  gap: 0;
  min-height: 0;
}

.play-card.primary.golf-map-card,
.golf-map-card {
  position: relative;
  display: grid;
  gap: 0;
  min-width: 0;
  min-height: 0;
  overflow: hidden;
  padding: 0;
  border: 0;
  border-radius: 0;
  background:
    linear-gradient(180deg, rgba(218, 234, 213, 0.66), rgba(245, 244, 235, 0.8));
}

.golf-hud {
  position: absolute;
  z-index: 3;
  top: 10px;
  left: 12px;
  right: 12px;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 8px 18px;
  padding: 0;
  background: transparent;
  pointer-events: none;
}

.golf-hud .golf-stat {
  min-width: 0;
  min-height: 0;
  padding: 0;
  border: 0;
  border-radius: 0;
  background: transparent;
  box-shadow: none;
  text-shadow: 0 1px 10px rgba(255, 254, 250, 0.88);
}

.golf-hud .golf-stat:nth-child(2),
.golf-hud .golf-stat:nth-child(4) {
  text-align: right;
}

.golf-hud .golf-stat span {
  font-size: 0.62rem;
  letter-spacing: 0.14em;
}

.golf-hud .golf-stat strong {
  margin-top: 2px;
  font-size: clamp(0.88rem, 1.55vw, 1.08rem);
}

.golf-course-map {
  display: block;
  width: 100%;
  height: 100%;
  min-height: 0;
  border: 0;
  border-radius: 0;
  background: #dfe9d5;
  box-shadow:
    inset 0 0 86px rgba(39, 60, 50, 0.13),
    0 14px 28px rgba(39, 60, 50, 0.08);
  touch-action: pan-y;
}

.golf-course-map .course-water-wave {
  animation: waterShimmer 5.8s ease-in-out infinite alternate;
}

.golf-course-map .course-target-ring {
  transform-box: fill-box;
  transform-origin: center;
  animation: targetBreathe 1.8s ease-in-out infinite;
}

.golf-course-map .golf-aim-layer {
  filter: drop-shadow(0 1px 1px rgba(20, 23, 25, 0.18));
}

.golf-course-map .golf-ball-marker {
  filter: drop-shadow(0 1px 1px rgba(20, 23, 25, 0.28));
}

.golf-flight-preview .flight-trail-shadow {
  stroke-dasharray: 2.2 2.4;
  animation: flightTrace 1.26s ease-out forwards;
}

.golf-flight-preview .flight-trail-main {
  stroke-dasharray: 1.6 1.7;
  animation: flightTrace 1.26s ease-out forwards;
}

.golf-flight-preview .rollout-line {
  stroke-dasharray: 1.2 1.2;
  animation: rolloutTrace 1.26s ease-out forwards;
}

.golf-flight-preview .flight-ball {
  filter: drop-shadow(0 0.9px 1px rgba(20, 23, 25, 0.42));
}

.golf-flight-preview .flight-shadow {
  filter: blur(0.12px);
}

.landing-ring {
  animation: landingPop 1.05s ease-out forwards;
  transform-box: fill-box;
  transform-origin: center;
}

.rollout-dot {
  animation: rolloutSettle 1.1s ease-out forwards;
}

.shot-callout text {
  paint-order: stroke;
  stroke: rgba(255, 254, 250, 0.86);
  stroke-width: 1.45px;
  stroke-linejoin: round;
}

.golf-course-map .pin-flag {
  filter: drop-shadow(0 0.7px 0.6px rgba(20, 23, 25, 0.24));
}

@keyframes waterShimmer {
  from { opacity: 0.18; transform: translateX(-0.5px); }
  to { opacity: 0.36; transform: translateX(0.7px); }
}

@keyframes targetBreathe {
  0%, 100% { opacity: 0.58; }
  50% { opacity: 0.86; }
}

@keyframes flightTrace {
  from { stroke-dashoffset: 18; opacity: 0.2; }
  42% { opacity: 0.96; }
  to { stroke-dashoffset: 0; opacity: 0.72; }
}

@keyframes rolloutTrace {
  from { stroke-dashoffset: 9; opacity: 0; }
  54% { opacity: 0; }
  to { stroke-dashoffset: 0; opacity: 0.78; }
}

@keyframes landingPop {
  0%, 48% { opacity: 0; transform: scale(0.45); }
  64% { opacity: 0.94; transform: scale(1.14); }
  100% { opacity: 0.54; transform: scale(1); }
}

@keyframes rolloutSettle {
  0%, 72% { opacity: 0; transform: scale(0.52); }
  100% { opacity: 1; transform: scale(1); }
}

.golf-course-map text {
  font-family: Inter, ui-sans-serif, system-ui, sans-serif;
  letter-spacing: 0;
}

.play-card.golf-controls,
.golf-controls {
  display: grid;
  gap: 5px;
  align-content: start;
  flex: 0 0 auto;
  padding: 6px 11px 8px;
  border-radius: 0;
  border: 0;
  background:
    linear-gradient(180deg, rgba(255, 254, 250, 0.94), rgba(248, 246, 237, 0.94));
}

.golf-controls > * {
  min-width: 0;
}

.golf-shot-id {
  display: none;
}

.golf-shot-id h3 {
  margin: 0;
  font-family: var(--display);
  font-size: clamp(1.35rem, 3vw, 2rem);
  line-height: 1.08;
  color: #151c1a;
}

.golf-shot-id .pill {
  justify-self: start;
}

.golf-facts {
  display: none;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.golf-facts .golf-stat {
  min-height: 104px;
}

.golf-facts .hazard-stat {
  background:
    linear-gradient(180deg, rgba(249, 239, 213, 0.78), rgba(255, 254, 250, 0.82));
}

.golf-club-section {
  display: grid;
  gap: 0;
}

.club-grid {
  display: grid;
  grid-template-columns: repeat(7, minmax(50px, 1fr));
  gap: 4px;
  width: 100%;
  max-width: 100%;
  min-width: 0;
  overflow-x: auto;
  padding: 0 1px 2px;
  scrollbar-width: thin;
}

.club-button {
  display: grid;
  gap: 2px;
  min-height: 38px;
  padding: 4px;
  border: 1px solid rgba(39, 60, 50, 0.12);
  border-radius: 10px;
  background:
    linear-gradient(180deg, rgba(255, 254, 250, 0.9), rgba(248, 246, 236, 0.72));
  color: var(--muted);
  font-weight: 850;
  text-align: center;
  box-shadow: 0 8px 20px rgba(39, 60, 50, 0.04);
  transition: transform 0.16s ease, border-color 0.16s ease, background 0.16s ease, color 0.16s ease, box-shadow 0.16s ease;
}

.club-button:hover {
  border-color: rgba(8, 114, 85, 0.28);
  background: rgba(245, 250, 241, 0.94);
  transform: translateY(-1px);
}

.club-button strong,
.club-button span {
  display: block;
}

.club-button span {
  font-size: 0.64rem;
  font-weight: 800;
}

.club-button.active {
  border-color: #087255;
  background:
    linear-gradient(180deg, rgba(216, 246, 232, 0.98), rgba(240, 251, 243, 0.94));
  color: #087255;
  box-shadow: 0 9px 18px rgba(8, 114, 85, 0.13), inset 0 1px 0 rgba(255, 254, 250, 0.7);
}

.swing-meter {
  position: relative;
  height: 28px;
  overflow: hidden;
  border: 1px solid var(--ink);
  border-radius: 999px;
  background:
    linear-gradient(90deg, rgba(242, 109, 91, 0.18) 0 18%, rgba(239, 189, 58, 0.26) 18% 38%, rgba(16, 167, 122, 0.34) 38% 62%, rgba(239, 189, 58, 0.26) 62% 82%, rgba(242, 109, 91, 0.18) 82% 100%),
    var(--panel);
}

.swing-meter::before {
  content: "";
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(90deg, transparent 0 9%, rgba(20, 23, 25, 0.12) 9% 9.4%);
}

.swing-needle {
  position: absolute;
  z-index: 1;
  top: -4px;
  left: 50%;
  width: 8px;
  height: 36px;
  border-radius: 999px;
  background: var(--ink);
  animation: swingSweep 1.55s linear infinite alternate;
}

@keyframes swingSweep {
  from { left: 5%; }
  to { left: 95%; }
}

.shot-stage {
  display: grid;
  gap: 6px;
  padding-top: 0;
  border: 0;
  border-radius: 0;
  background: transparent;
}

.swing-stage {
  min-height: 38px;
  place-items: center;
  cursor: pointer;
}

.swing-stage strong {
  display: grid;
  width: 100%;
  min-height: 38px;
  place-items: center;
  border: 2px solid rgba(8, 114, 85, 0.78);
  border-radius: 9px;
  background: linear-gradient(180deg, #27834f, #167247);
  color: #fffefa;
  font-size: clamp(0.96rem, 2vw, 1.12rem);
  letter-spacing: 0;
  text-transform: none;
  box-shadow: 0 14px 26px rgba(8, 114, 85, 0.18);
}

.swing-stage .power-meter + strong {
  margin-top: 2px;
}

.shot-stage.locked {
  min-height: 38px;
  place-items: center;
  text-align: center;
}

.shot-stage.locked strong {
  display: inline-grid;
  place-items: center;
  min-width: 118px;
  min-height: 36px;
  padding: 7px 12px;
  border: 1px solid rgba(8, 114, 85, 0.28);
  border-radius: 999px;
  background: rgba(232, 248, 238, 0.88);
  animation: golfLockPulse 0.48s ease-out;
}

.hole-complete-stage strong {
  min-width: 148px;
  background: rgba(255, 250, 224, 0.94);
  color: #103c2b;
}

.hole-complete-stage {
  position: relative;
  overflow: hidden;
  min-height: 96px;
  border-radius: 14px;
  background:
    radial-gradient(circle at 24% 18%, rgba(255, 226, 138, 0.48), transparent 28%),
    radial-gradient(circle at 74% 30%, rgba(16, 167, 122, 0.22), transparent 25%),
    rgba(255, 254, 250, 0.7);
}

.hole-complete-stage::before,
.hole-complete-stage::after {
  content: "";
  position: absolute;
  inset: 14px 18px auto auto;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #efbd3a;
  box-shadow:
    -34px 10px 0 #10a77a,
    -62px -2px 0 #f26d5b,
    -92px 15px 0 #7fc3d8,
    -122px -6px 0 #efbd3a;
  animation: holeSparkle 1.15s ease-out both;
}

.hole-complete-stage::after {
  inset: auto auto 16px 26px;
  animation-delay: 0.08s;
}

.hole-complete-stage .score-badge {
  display: inline-grid;
  place-items: center;
  min-width: 58px;
  min-height: 58px;
  margin: 2px auto 6px;
  border: 2px solid rgba(16, 167, 122, 0.4);
  border-radius: 50%;
  background:
    radial-gradient(circle at 34% 28%, #fffefa, #e9f6d4 64%, #c5e49f);
  color: #0e4d37;
  font-family: var(--display);
  font-size: 1.5rem;
  line-height: 1;
  box-shadow: 0 12px 24px rgba(8, 114, 85, 0.12);
  animation: golfLockPulse 0.72s ease-out;
}

@keyframes holeSparkle {
  0% { opacity: 0; transform: translateY(12px) scale(0.7); }
  40% { opacity: 1; }
  100% { opacity: 0; transform: translateY(-12px) scale(1.05); }
}

.shot-stage:not(.swing-stage) > strong {
  display: block;
  font-size: 0.82rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #121817;
}

.shot-stage span,
.shot-stage p {
  margin: 0;
  color: var(--muted);
  font-weight: 750;
  line-height: 1.45;
}

.strategy-actions {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
}

.strategy-actions .play-button {
  min-height: 44px;
}

.power-meter {
  position: relative;
  width: 100%;
  min-width: 0;
  height: 28px;
  overflow: hidden;
  border: 1.5px solid rgba(20, 23, 25, 0.72);
  border-radius: 999px;
  background:
    linear-gradient(90deg,
      #ec715d 0%,
      #f2a24d calc(var(--green-warm-start) * 1%),
      #e8c446 calc(var(--green-start) * 1%),
      #18a871 calc(var(--green-start) * 1%),
      #0c9163 calc(var(--green-end) * 1%),
      #e8c446 calc(var(--green-end) * 1%),
      #f2a24d calc(var(--green-warm-end) * 1%),
      #ec715d 100%);
  box-shadow: inset 0 1px 2px rgba(255, 254, 250, 0.5), 0 6px 16px rgba(39, 60, 50, 0.08);
}

.power-meter::before {
  content: "";
  position: absolute;
  z-index: 1;
  top: 5px;
  bottom: 5px;
  left: calc(var(--green-start) * 1%);
  width: calc(var(--green-width) * 1%);
  border: 3px solid rgba(255, 254, 250, 0.98);
  border-radius: 999px;
  background: repeating-linear-gradient(135deg, rgba(255, 254, 250, 0.32) 0 6px, rgba(255, 254, 250, 0.72) 6px 12px);
  box-shadow: 0 0 0 1px rgba(20, 23, 25, 0.5), 0 0 18px rgba(16, 167, 122, 0.5);
}

.power-meter::after {
  content: "BEST";
  position: absolute;
  z-index: 2;
  top: 50%;
  left: calc(var(--green-center) * 1%);
  transform: translate(-50%, -50%);
  color: rgba(20, 23, 25, 0.7);
  font-size: 0.62rem;
  font-weight: 950;
  letter-spacing: 0.08em;
}

.power-marker {
  position: absolute;
  z-index: 3;
  top: -5px;
  left: calc(var(--power-marker) * 1%);
  width: 7px;
  height: 38px;
  border-radius: 999px;
  background: #fffefa;
  box-shadow: 0 0 0 2px rgba(20, 23, 25, 0.9), 0 0 18px rgba(255, 254, 250, 0.95);
  transform: translateX(-50%);
}

.power-meter.moving .power-marker {
  animation: powerSweep 1.45s linear infinite alternate;
}

@keyframes powerSweep {
  from { left: 4%; }
  to { left: 96%; }
}

@keyframes golfLockPulse {
  0% { transform: scale(0.94); box-shadow: 0 0 0 0 rgba(16, 167, 122, 0.38); }
  70% { transform: scale(1.035); box-shadow: 0 0 0 14px rgba(16, 167, 122, 0); }
  100% { transform: scale(1); box-shadow: 0 0 0 0 rgba(16, 167, 122, 0); }
}

.tap-panel {
  border-color: rgba(6, 70, 50, 0.95);
  background:
    linear-gradient(180deg, #1c5a3c, #103c2b);
  color: var(--paper);
  box-shadow: 0 14px 25px rgba(6, 70, 50, 0.18);
}

.tap-panel:hover {
  border-color: rgba(16, 167, 122, 0.58);
  background:
    linear-gradient(180deg, #235845, #103629);
}

.shot-summary {
  position: absolute;
  z-index: 2;
  left: 12px;
  right: 12px;
  bottom: 10px;
  display: grid;
  grid-template-columns: 1fr;
  gap: 2px;
  min-height: 0;
  max-height: 50px;
  margin: 0;
  padding: 6px 9px;
  border: 0;
  border-radius: 10px;
  background: rgba(255, 254, 250, 0.66);
  backdrop-filter: blur(12px);
  color: var(--ink);
  font-weight: 850;
  line-height: 1.35;
  box-shadow: 0 14px 30px rgba(39, 60, 50, 0.1);
}

.daily-golf[data-shot-phase="scouting"] .shot-summary,
.daily-golf[data-shot-phase="aiming"] .shot-summary,
.daily-golf[data-shot-phase="aim-locked"] .shot-summary,
.daily-golf[data-shot-phase="power"] .shot-summary,
.daily-golf[data-shot-phase="power-locked"] .shot-summary,
.daily-golf[data-shot-phase="ball-flight"] .shot-summary {
  display: none;
}

.shot-summary small {
  color: var(--muted);
  font-size: 0.66rem;
  font-weight: 900;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.shot-summary span {
  min-width: 0;
}

.shot-summary strong,
.shot-summary em {
  display: block;
  font-style: normal;
}

.shot-summary strong {
  font-size: 0.62rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.shot-summary em {
  margin-top: 0;
  color: #273c32;
  font-size: 0.84rem;
  font-weight: 900;
}

.scorecard-table {
  width: 100%;
  border-collapse: collapse;
  overflow: hidden;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 254, 250, 0.8);
}

.scorecard-table th,
.scorecard-table td {
  padding: 8px;
  border-bottom: 1px solid var(--line);
  text-align: center;
  font-size: 0.82rem;
}

.scorecard-table th {
  color: var(--muted);
  font-size: 0.72rem;
  text-transform: uppercase;
}

.scorecard-table tr:last-child td {
  border-bottom: 0;
}

.results-card {
  gap: 14px;
}

.round-recap-hero {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 14px;
  align-items: end;
  padding: 16px;
  border: 1px solid rgba(39, 60, 50, 0.14);
  border-radius: 16px;
  background:
    radial-gradient(circle at 14% 12%, rgba(255, 226, 138, 0.44), transparent 32%),
    linear-gradient(135deg, rgba(226, 247, 222, 0.84), rgba(255, 254, 250, 0.82));
}

.round-recap-hero strong {
  display: block;
  font-family: var(--display);
  font-size: clamp(2.35rem, 7vw, 4.4rem);
  line-height: 0.9;
  color: #101817;
}

.round-recap-hero span {
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 900;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.round-recap-hero em {
  display: block;
  margin-top: 5px;
  color: #273c32;
  font-style: normal;
  font-weight: 850;
}

.round-recap-badge {
  display: grid;
  min-width: 92px;
  min-height: 92px;
  place-items: center;
  border: 2px solid rgba(16, 167, 122, 0.34);
  border-radius: 50%;
  background: #fffefa;
  color: #087255;
  text-align: center;
  font-weight: 950;
  box-shadow: 0 16px 30px rgba(8, 114, 85, 0.12);
}

.round-recap-badge small {
  display: block;
  color: var(--muted);
  font-size: 0.64rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.recap-highlights {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
}

.recap-chip {
  min-width: 0;
  padding: 9px 10px;
  border: 1px solid rgba(39, 60, 50, 0.12);
  border-radius: 12px;
  background: rgba(255, 254, 250, 0.72);
}

.recap-chip span,
.recap-chip strong {
  display: block;
}

.recap-chip span {
  color: var(--muted);
  font-size: 0.64rem;
  font-weight: 900;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.recap-chip strong {
  margin-top: 3px;
  color: #101817;
  font-size: 0.92rem;
  line-height: 1.1;
}

.play-result {
  min-height: 44px;
  display: grid;
  align-items: center;
  padding: 10px 12px;
  border-radius: 8px;
  background: rgba(20, 23, 25, 0.07);
  color: var(--ink);
  font-weight: 900;
  line-height: 1.35;
}

.entry-form,
.friend-form,
.modal-content {
  display: grid;
  gap: 14px;
}

.field-grid {
  display: grid;
  grid-template-columns: minmax(0, 0.75fr) minmax(0, 1fr) minmax(0, 1fr);
  gap: 12px;
}

label {
  display: grid;
  min-width: 0;
  gap: 6px;
  color: var(--muted);
  font-size: 0.82rem;
  font-weight: 900;
}

.field-help {
  color: var(--muted);
  font-size: 0.74rem;
  font-weight: 800;
  line-height: 1.3;
}

.wide-label {
  margin-top: 12px;
}

.form-actions {
  display: flex;
  gap: 14px;
  align-items: center;
  justify-content: space-between;
  margin-top: 14px;
}

.save-status {
  min-height: 24px;
  color: #087255;
  font-size: 0.82rem;
  font-weight: 900;
}

.save-status:empty {
  display: none;
}

.switch-row {
  display: flex;
  grid-template-columns: none;
  flex-wrap: wrap;
  align-items: center;
  color: var(--ink);
  text-transform: none;
}

.switch-row input {
  position: absolute;
  width: 1px;
  min-width: 1px;
  height: 1px;
  opacity: 0;
}

.switch {
  position: relative;
  width: 48px;
  height: 28px;
  border-radius: 999px;
  background: #c9c4b5;
}

.switch::after {
  position: absolute;
  top: 4px;
  left: 4px;
  width: 20px;
  height: 20px;
  content: "";
  border-radius: 50%;
  background: var(--panel);
  transition: transform 160ms ease;
}

.switch-row input:checked + .switch {
  background: var(--green);
}

.switch-row input:checked + .switch::after {
  transform: translateX(20px);
}

.primary-button,
.ghost-button,
.icon-button {
  min-height: 42px;
  border: 1px solid var(--ink);
  border-radius: 8px;
  font-weight: 900;
}

.primary-button {
  padding: 10px 16px;
  background: var(--ink);
  color: var(--paper);
}

.primary-button:hover {
  background: var(--green);
  border-color: var(--green);
}

.ghost-button,
.icon-button {
  background: var(--panel);
  color: var(--ink);
}

.ghost-button {
  padding: 10px 14px;
}

.compact-button {
  min-height: 38px;
  padding: 8px 12px;
  white-space: nowrap;
}

.icon-button {
  display: grid;
  width: 42px;
  place-items: center;
}

.metrics {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  margin-top: 18px;
}

.metrics div,
.rank-row,
.answer-card {
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 254, 250, 0.68);
}

.metrics div {
  position: relative;
  overflow: hidden;
  padding: 16px;
}

.metrics div::before {
  content: "";
  position: absolute;
  inset: 0 0 auto;
  height: 5px;
  background: var(--green);
}

.metrics div:nth-child(2)::before {
  background: var(--yellow);
}

.metrics div:nth-child(3)::before {
  background: var(--coral);
}

.metrics div:nth-child(4)::before {
  background: var(--violet);
}

.metrics strong,
.metrics span {
  display: block;
}

.metrics strong {
  font-family: var(--display);
  font-size: 1.95rem;
  line-height: 1;
}

.metrics span {
  margin-top: 6px;
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 800;
  text-transform: uppercase;
}

.progress-days {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 8px;
  margin-top: 12px;
}

.progress-day {
  display: grid;
  gap: 4px;
  min-width: 0;
  padding: 10px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 254, 250, 0.62);
  color: var(--muted);
  text-align: center;
}

.progress-day strong,
.progress-day span {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.progress-day strong {
  color: var(--ink);
  font-size: 0.82rem;
  text-transform: uppercase;
}

.progress-day span {
  font-size: 0.74rem;
  font-weight: 850;
}

.progress-day.done {
  border-color: rgba(16, 167, 122, 0.4);
  background:
    linear-gradient(135deg, rgba(16, 167, 122, 0.16), rgba(255, 226, 138, 0.22)),
    rgba(255, 254, 250, 0.78);
  color: #087255;
}

.progress-day.today {
  border-color: var(--ink);
  box-shadow: inset 0 0 0 2px rgba(239, 189, 58, 0.5);
}

.leaderboard,
.answer-feed {
  display: grid;
  gap: 10px;
}

.scoreboard-stack {
  display: grid;
  gap: 14px;
}

.social-panel { scroll-margin-top: 24px; }
.catalog-search { margin: 0 0 14px; font-size: 12px; }
.catalog-search input { min-width: 0; width: 100%; }
.leaderboard-controls { display: grid; gap: 10px; margin: 14px 0; }
.leaderboard-summary { padding: 12px; background: #e4f5ed; color: #07694e; border-radius: 6px; font-size: 14px; font-weight: 750; line-height: 1.5; }
.ranking-rules { color: var(--muted); font-size: 13px; line-height: 1.5; }
.ranking-rules summary, .add-friend-details summary { cursor: pointer; font-weight: 750; padding: 10px 0; }
.rank-row.is-you { border: 1px solid #65b89b; background: #effaf5; }
.rank-row > span { min-width: 0; overflow-wrap: anywhere; }
.rank-row .points { max-width: 105px; font-size: 15px; }
.rank-row .points small { font-size: 11px; }
.friends-section { border-top: 1px solid var(--line); margin-top: 24px; padding-top: 20px; }
.friend-toolbar { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; margin: 12px 0; }
.demo-toggle { display: flex; flex-direction: row; align-items: center; gap: 8px; font-size: 12px; }
.demo-toggle input { width: 18px; height: 18px; }
.friend-search { margin: 14px 0 8px; }
.friend-roster { display: grid; gap: 0; }
.friend-person { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 8px; align-items: center; padding: 14px 0; border-bottom: 1px solid var(--line); }
.friend-person strong, .friend-person small { display: block; overflow-wrap: anywhere; }
.friend-person small { margin-top: 4px; color: var(--muted); font-size: 12px; line-height: 1.5; }
.friend-person .request-actions { grid-column: 1 / -1; flex-wrap: wrap; }
.friend-status { min-height: 20px; font-size: 13px; line-height: 1.5; color: #07694e; }
.friend-status.error { color: #9f3427; }
.social-empty { padding: 16px 0; color: var(--muted); font-size: 14px; line-height: 1.5; }
.social-panel button:disabled { opacity: 0.5; cursor: not-allowed; }

.scoreboard-block {
  display: grid;
  gap: 10px;
}

.scoreboard-head {
  display: flex;
  align-items: end;
  justify-content: space-between;
  gap: 12px;
}

.scoreboard-head h3 {
  margin: 0;
  font-size: 1rem;
}

.scoreboard-head span {
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 900;
  text-align: right;
}

.scoreboard-note {
  margin: -4px 0 0;
  color: var(--muted);
  font-size: 0.82rem;
  font-weight: 800;
  line-height: 1.35;
}

.rank-row {
  display: grid;
  grid-template-columns: 36px 1fr auto;
  gap: 10px;
  align-items: center;
  padding: 12px;
}

.rank {
  display: grid;
  width: 34px;
  height: 34px;
  place-items: center;
  border-radius: 8px;
  background: var(--ink);
  color: var(--paper);
  font-weight: 900;
}

.rank-row strong,
.rank-row small,
.answer-card strong,
.answer-card small {
  display: block;
}

.rank-row small,
.answer-card small {
  color: var(--muted);
}

.points {
  color: var(--green);
  font-weight: 950;
  text-align: right;
}

.points small {
  color: var(--muted);
  font-size: 0.72rem;
  font-weight: 800;
}

.friend-form {
  grid-template-columns: 1fr;
  align-items: end;
  margin-top: 16px;
}

.friend-form .primary-button {
  width: 100%;
}

.friend-sync {
  display: grid;
  gap: 10px;
  margin-top: 12px;
}

.sync-card {
  display: grid;
  gap: 8px;
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 254, 250, 0.72);
}

.sync-card header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.sync-card strong,
.sync-card small {
  display: block;
}

.sync-card small,
.sync-pill {
  color: var(--muted);
  font-size: 0.76rem;
  font-weight: 850;
}

.request-actions {
  display: flex;
  gap: 8px;
}

.request-actions .ghost-button,
.request-actions .primary-button {
  min-height: 34px;
  padding: 7px 10px;
}

.answer-card {
  padding: 14px;
}

.answer-card header {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 10px;
}

.answer-value {
  min-height: 42px;
  display: flex;
  align-items: center;
  padding: 10px 12px;
  border-radius: 8px;
  background: var(--ink);
  color: var(--paper);
  font-weight: 900;
}

.answer-value.locked {
  background: repeating-linear-gradient(135deg, #464d4b 0 8px, #343a38 8px 16px);
}

.modal {
  width: min(420px, calc(100% - 32px));
  border: 0;
  border-radius: 8px;
  padding: 0;
  box-shadow: var(--shadow);
}

.modal::backdrop {
  background: rgba(20, 23, 25, 0.44);
}

.modal-content {
  padding: 22px;
  background: var(--paper);
}

.account-modal {
  gap: 12px;
}

.account-copy,
.account-note {
  margin: 0;
  color: var(--muted);
  font-weight: 800;
  line-height: 1.4;
}

.account-note {
  font-size: 0.78rem;
}

.account-note.error,
.sync-pill.error {
  color: #a63a2f;
}

.provider-button {
  display: grid;
  grid-template-columns: 34px 1fr;
  gap: 10px;
  align-items: center;
  min-height: 48px;
  padding: 8px 12px;
  border: 1px solid var(--ink);
  border-radius: 8px;
  background: var(--panel);
  color: var(--ink);
  font-weight: 900;
  text-align: left;
}

.provider-button:hover {
  background: var(--ink);
  color: var(--paper);
}

.provider-mark {
  display: grid;
  width: 32px;
  height: 32px;
  place-items: center;
  border-radius: 8px;
  background: var(--ink);
  color: var(--paper);
  font-size: 0.9rem;
  font-weight: 950;
}

.provider-mark.google {
  background: conic-gradient(from 45deg, #4285f4, #34a853, #fbbc05, #ea4335, #4285f4);
}

body.solvry-holes-focus .workspace {
  grid-template-columns: minmax(200px, 240px) minmax(0, 620px) minmax(260px, 1fr);
  max-width: 1320px;
  padding-block: 8px;
}

body.solvry-holes-focus .tracker-panel {
  align-self: start;
  padding: 6px 10px 10px;
}

body.solvry-holes-focus .section-head,
body.solvry-holes-focus .dashboard-strip,
body.solvry-holes-focus .current-result,
body.solvry-holes-focus .metrics,
body.solvry-holes-focus .progress-days {
  display: none;
}

body.solvry-holes-focus .play-surface {
  justify-items: center;
  align-items: start;
}

body.solvry-holes-focus .solvry-game {
  display: block;
  width: 100%;
  margin-top: 0;
  margin-bottom: 0;
}

body.solvry-holes-focus .daily-golf {
  width: min(100%, 590px);
  max-width: 590px;
  height: min(598px, calc(100dvh - 102px));
}

body.solvry-holes-focus .daily-golf[data-shot-phase="scouting"] .meter-label {
  display: none;
}

@media (max-width: 1080px) {
  .workspace {
    grid-template-columns: 210px 1fr;
    grid-template-areas:
      "rail tracker"
      "rail social"
      "rail answers";
  }

  body.solvry-holes-focus .workspace {
    grid-template-columns: 210px minmax(0, 1fr);
    grid-template-areas:
      "rail tracker"
      "rail social"
      "rail answers";
  }
}

@media (max-width: 900px) {
  .workspace {
    grid-template-columns: 1fr;
    grid-template-areas:
      "rail"
      "tracker"
      "social"
      "answers";
  }

  body.solvry-holes-focus .workspace {
    grid-template-columns: 1fr;
    grid-template-areas:
      "tracker"
      "social"
      "answers";
  }

  .game-rail,
  body.solvry-holes-focus .game-rail {
    position: static;
  }

  body.solvry-holes-focus .game-rail {
    display: none;
  }

  .game-list {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 780px) {
  body.solvry-holes-focus .workspace {
    max-width: none;
    padding: 0;
  }

  body.solvry-holes-focus .topbar {
    position: static;
    grid-template-columns: 1fr;
    gap: 8px;
    padding: 8px 16px 10px;
  }

  body.solvry-holes-focus .brand {
    display: none;
  }

  body.solvry-holes-focus .date-control,
  body.solvry-holes-focus .account-controls {
    display: none;
  }

  body.solvry-holes-focus .topnav {
    justify-self: stretch;
    justify-content: center;
    overflow-x: auto;
  }

  body.solvry-holes-focus .daily-golf {
    width: 100%;
    max-width: 100%;
    height: min(650px, calc(100dvh - 86px));
    border-radius: 0;
  }

  .topbar {
    position: static;
    grid-template-columns: 1fr;
  }

  .topnav,
  .top-actions,
  .date-control {
    justify-self: stretch;
  }

  .topnav {
    overflow-x: auto;
  }

  .top-actions {
    align-items: stretch;
    flex-direction: column;
  }

  .account-controls {
    display: grid;
    grid-template-columns: 1fr 1fr;
  }

  .section-head,
  .form-actions {
    align-items: flex-start;
    flex-direction: column;
  }

  .field-grid,
  .import-actions,
  .metrics,
  .current-result,
  .solvry-board,
  .daily-golf-board,
  .golf-facts,
  .golf-hero-grid,
  .hole-card-grid,
  .results-grid,
  .recap-highlights,
  .round-recap-hero,
  .strategy-actions,
  .play-actions.three {
    grid-template-columns: 1fr;
  }

  .play-card.primary.golf-map-card,
  .golf-map-card {
    gap: 0;
  }

  .golf-hud {
    position: absolute;
    top: 14px;
    left: 14px;
    right: 14px;
    grid-template-columns: minmax(0, 1fr) auto;
  }

  .golf-hud .golf-stat {
    min-width: 0;
    padding: 0;
  }

  .golf-hud .golf-stat strong {
    font-size: 1rem;
  }

  .club-grid {
    grid-template-columns: repeat(7, minmax(48px, 1fr));
    gap: 3px;
    overflow-x: hidden;
  }

  .club-button {
    min-height: 36px;
    padding: 3px;
    border-radius: 9px;
  }

  .golf-course-map {
    height: 100%;
  }

  .shot-summary {
    position: absolute;
    left: 14px;
    right: 14px;
    bottom: 14px;
  }

  .dashboard-strip {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .current-result {
    align-items: flex-start;
  }

  .primary-button,
  .ghost-button {
    width: 100%;
  }
}

@media (max-width: 480px) {
  .game-list {
    grid-template-columns: 1fr;
  }

  .dashboard-strip {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .letter-board {
    grid-template-columns: repeat(5, minmax(0, 1fr));
  }

  .daily-golf {
    border-radius: 14px;
  }

  .golf-game-header {
    grid-template-columns: minmax(0, 1fr) auto;
    align-items: start;
  }

  .golf-course-map {
    height: 100%;
  }

  .club-grid {
    grid-template-columns: repeat(7, minmax(0, 1fr));
    gap: 2px;
    padding-inline: 0;
  }

  .club-button {
    min-width: 0;
    min-height: 36px;
    padding: 3px 2px;
  }

  .club-button span {
    font-size: 0.58rem;
  }

  .golf-score-hole {
    padding-inline: 2px;
  }
}
/* Solvry brand: cream, petrol, charcoal; terracotta and gold are restrained accents. */
:root { --paper: #F5EEDB; --ink: #373B35; --muted: #626357; --line: #d4cbb7; --green: #276776; --petrol: #276776; --terracotta: #D46A50; --gold: #EACB82; --shadow: none; }
html { scroll-behavior: auto; }
body { background: var(--paper); color: var(--ink); }
.topbar { grid-template-columns: 1fr auto 1fr; padding: 12px 3vw; gap: 24px; background: var(--paper); border-bottom: 1px solid var(--line); backdrop-filter: none; box-shadow: none; }
.brand { gap: 0; }
.brand-lockup { display: flex; flex-direction: column; align-items: flex-start; gap: 0; }
.brand-logo { display: block; width: 164px; height: auto; }
.brand strong { font-size: 25px; letter-spacing: -.04em; }
.brand small { font-size: 10px; line-height: 1.3; font-weight: 400; color: var(--petrol); white-space: nowrap; }
.brand-mark { width: 34px; height: 34px; border: 0; border-radius: 3px; background: var(--green); color: white; font-size: 11px; box-shadow: none; }
.topnav { gap: 22px; padding: 0; border: 0; border-radius: 0; background: none; }
.topnav a { border-radius: 0; padding: 13px 0 11px; border-bottom: 2px solid transparent; font-size: 14px; font-weight: 500; color: var(--muted); }
.topnav a.active { background: none; color: var(--ink); border-color: var(--terracotta); box-shadow: none; font-weight: 700; }
.top-actions { flex-direction: row; align-items: center; gap: 12px; }
.account-controls { display: flex; align-items: center; }
.account-name { max-width: 110px; overflow-wrap: anywhere; }
.account-name small { display: none; }
.primary-button, .ghost-button, .official-link { display: inline-flex; align-items: center; justify-content: center; min-height: 42px; padding: 10px 16px; border-radius: 4px; font-size: 14px; line-height: 1.3; font-weight: 600; text-align: center; box-shadow: none; }
.primary-button, .official-link { color: #fff; background: var(--green); border: 1px solid var(--green); }
.primary-button:hover, .official-link:hover { background: #1d505c; }
.ghost-button { color: var(--ink); background: transparent; border: 1px solid #b7ae98; }
.ghost-button:hover { background: #ece5d4; }
.nav-add-score { white-space: nowrap; }
.nav-add-score[aria-current="page"] { outline: 2px solid var(--green); outline-offset: 3px; }
.workspace, .workspace:has(.home-view:not([hidden])) { display: block; max-width: none; width: 100%; padding: 24px 3vw 32px; }
.app-view { min-width: 0; margin: 0; }
.app-view h1 { font-size: clamp(30px, 2.6vw, 44px); line-height: 1.1; letter-spacing: -.035em; overflow-wrap: anywhere; }
.app-view h2 { font-family: inherit; font-size: 18px; font-weight: 650; letter-spacing: -.02em; line-height: 1.3; }
.app-view h3 { font-family: inherit; font-size: 16px; }
.view-head { display: flex; justify-content: space-between; align-items: center; gap: 24px; margin-bottom: 22px; }
.view-head > div { min-width: 0; }
.view-copy { margin: 8px 0 0; color: var(--muted); font-size: 14px; line-height: 1.6; font-weight: 400; }
.eyebrow { margin-bottom: 8px; font-size: 11px; font-weight: 600; letter-spacing: .06em; }
.panel { padding: 0; background: none; border: 0; border-radius: 0; box-shadow: none; }
.section-head.compact { flex-direction: row; align-items: center; margin-bottom: 12px; gap: 12px; }
.field-help { margin: 4px 0 0; color: var(--muted); font-size: 12px; line-height: 1.5; font-weight: 400; }
.text-link { display: inline-block; padding: 5px 0; color: var(--green); background: none; border: 0; font: inherit; font-size: 13px; font-weight: 600; text-decoration: none; white-space: nowrap; }
.text-link:hover { text-decoration: underline; }
.block-link { display: block; margin-top: 16px; }
.back-link { margin-bottom: 20px; }
.date-control { display: flex; align-items: center; gap: 10px; font-size: 12px; font-weight: 500; text-transform: none; }
.date-control input { width: 155px; min-height: 40px; padding: 8px; font-size: 14px; }
.home-view .view-head { margin-bottom: 20px; }
.home-metrics { display: flex; gap: 0; margin: 0 0 26px; padding: 16px 0; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }
.home-metrics > div, .home-metrics > div:nth-child(n) { display: flex; align-items: baseline; gap: 10px; flex: 1; padding: 0 24px; border: 0; border-right: 1px solid var(--line); border-radius: 0; background: none; }
.home-metrics > div:first-child { padding-left: 0; }
.home-metrics > div:last-of-type { border-right: 0; }
.home-metrics > div::before { display: none; }
.home-metrics strong { font-family: var(--display); font-size: 32px; line-height: 1; font-variant-numeric: tabular-nums; }
.home-metrics span { margin: 0; font-size: 12px; font-weight: 400; text-transform: none; color: var(--muted); }
.home-columns { display: grid; grid-template-columns: minmax(0,1.6fr) minmax(0,1fr); gap: 36px; align-items: start; }
.home-main, .home-side { display: grid; gap: 28px; min-width: 0; }
.home-side { padding-left: 28px; border-left: 1px solid var(--line); }
.home-view .panel { padding: 0; }
.home-scores, .activity-card { border-top: 1px solid var(--line); padding-top: 20px !important; }
.home-view .dashboard-strip { display: grid; grid-template-columns: repeat(2,minmax(0,1fr)); grid-auto-rows: auto; gap: 0 24px; margin: 0; }
.home-view .quick-game, .home-view .quick-game:nth-child(n) { display: grid; grid-template-columns: 30px minmax(0,1fr) 16px; align-items: center; gap: 12px; min-height: 64px; padding: 10px 0; border: 0; border-bottom: 1px solid var(--line); border-radius: 0; background: none; box-shadow: none; transform: none; transition: none; text-align: left; }
.home-view .quick-game::after { content: '›'; font-size: 22px; color: #747366; }
.home-view .quick-game:hover { background: #ece5d4; }
.home-view .quick-game.active { box-shadow: none; }
.home-view .quick-game > span { min-width: 0; }
.home-view .quick-game strong { font-size: 14px; line-height: 1.3; color: var(--ink); white-space: normal; font-weight: 600; }
.home-view .quick-game span span { display: block; margin-top: 3px; font-size: 12px; font-weight: 400; color: var(--muted); }
.game-logo, .game-logo[class], .quick-game .game-logo, .current-result .game-logo { display: inline-flex; width: 30px; height: 30px; padding: 3px; align-items: center; justify-content: center; border: 0; border-radius: 0; background: transparent; color: var(--petrol); box-shadow: none; }
.game-logo svg, .current-result .game-logo svg { width: 24px; height: 24px; }
.home-score-list { display: grid; gap: 0; }
.home-score-row { display: grid; grid-template-columns: 30px minmax(0,1fr) auto; align-items: center; gap: 12px; min-height: 48px; padding: 8px 0; width: 100%; text-align: left; background: none; border: 0; border-bottom: 1px solid var(--line); border-radius: 0; }
.home-score-row:hover { background: #ece5d4; }
.home-score-row strong, .home-score-row small { display: block; }
.home-score-row strong { font-size: 14px; font-weight: 600; }
.home-score-row small { font-size: 11px; color: var(--muted); margin-top: 3px; font-weight: 400; }
.home-score-value { font-size: 15px; font-weight: 650; text-align: right; max-width: 145px; overflow-wrap: anywhere; color: var(--ink); font-variant-numeric: tabular-nums; }
.home-score-value span { margin-left: 10px; color: var(--muted); }
.home-empty { display: flex; align-items: center; justify-content: space-between; gap: 16px; padding: 18px 0; text-align: left; }
.home-empty h3 { font-size: 15px; font-weight: 600; }
.home-empty p, .ranking-empty p { font-size: 14px; line-height: 1.6; color: var(--muted); font-weight: 400; margin: 6px 0; }
.home-empty .primary-button { flex-shrink: 0; }
.ranking-empty { padding: 20px 0; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }
.ranking-empty strong { font-size: 15px; font-weight: 600; }
.home-ranking .leaderboard { margin-top: 16px; }
.rank-row, .rank-row.is-you { grid-template-columns: 28px minmax(0,1fr) auto; border: 0; border-bottom: 1px solid var(--line); padding: 15px 0; gap: 12px; border-radius: 0; background: none; }
.rank-row.is-you { box-shadow: inset 3px 0 var(--green); padding-left: 12px; }
.rank-row .rank { width: 28px; height: 28px; border-radius: 0; background: none; color: var(--ink); font-family: var(--display); font-size: 22px; }
.rank-row strong { font-size: 14px; font-weight: 600; }
.rank-row small { font-size: 12px; line-height: 1.5; font-weight: 400; }
.rank-row .points { font-size: 16px; color: var(--ink); }
.rank-row .points small { font-size: 11px; color: var(--muted); }
.progress-days { display: grid; grid-template-columns: repeat(5,minmax(0,1fr)); gap: 0; margin-top: 16px; }
.progress-day, .progress-day.done, .progress-day.today { padding: 12px 4px; background: none; border: 0; border-right: 1px solid var(--line); border-radius: 0; box-shadow: none; outline: none; }
.progress-day:last-child { border-right: 0; }
.progress-day.today { border-bottom: 2px solid var(--green); }
.progress-day.done { color: var(--green); }
.progress-day strong { font-size: 11px; font-weight: 600; }
.progress-day span { font-size: 11px; font-weight: 400; margin-top: 6px; }
.more-home-scores { margin-top: 8px; }
.more-home-scores summary { padding: 8px 0; color: var(--green); font-size: 13px; font-weight: 600; cursor: pointer; }
.catalog-controls { display: flex; align-items: end; gap: 12px; margin-bottom: 24px; }
.catalog-search { max-width: 420px; flex: 1; margin: 0; font-size: 13px; text-transform: none; }
#pinnedFilter[aria-pressed="true"] { color: var(--green); border-color: var(--green); background: #e7ece4; }
.catalog-view .game-list { display: grid; grid-template-columns: repeat(3,minmax(0,1fr)); gap: 0 28px; }
.game-section-label { grid-column: 1/-1; display: flex; align-items: baseline; gap: 12px; margin: 18px 0 4px; padding: 0 0 12px; border-bottom: 1px solid var(--line); }
.game-section-label strong { font-size: 12px; }
.game-section-label span { font-size: 12px; font-weight: 400; text-transform: none; }
.game-card, .game-card.active, .game-card.pinned { grid-template-columns: minmax(0,1fr) 30px; min-height: 82px; padding: 12px 0; gap: 6px; background: none; border: 0; border-bottom: 1px solid var(--line); border-radius: 0; box-shadow: none; }
.game-card:hover { background: #ece5d4; box-shadow: none; }
.game-select { grid-template-columns: 30px minmax(0,1fr) 14px; gap: 10px; min-width: 0; padding: 0; }
.game-meta strong { white-space: normal; overflow: visible; text-overflow: clip; font-size: 14px; font-weight: 600; line-height: 1.3; }
.game-meta > span { font-size: 12px; font-weight: 400; margin-top: 4px; }
.game-score { font-size: 13px; color: var(--green); }
.pin-button, .pin-button.active { width: 30px; height: 44px; padding: 6px; background: none; border: 0; color: var(--muted); }
.pin-button.active { color: var(--green); }
.game-view { max-width: 900px; }
.view-actions { display: flex; gap: 10px; align-items: center; flex-shrink: 0; }
.game-detail-card { padding: 20px 0; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }
.game-detail-card .current-result { padding: 0; border: 0; background: none; border-radius: 0; grid-template-columns: 30px minmax(0,1fr) auto; }
.current-result strong { font-size: 16px; }
.current-result span span { font-size: 13px; font-weight: 400; }
.game-meta-row { display: flex; flex-wrap: wrap; gap: 16px; align-items: center; margin-top: 20px; }
.pill, .pill.hidden, .pill.revealed { padding: 4px 0; border: 0; border-radius: 0; background: none; color: var(--muted); font-size: 12px; }
.scoring-details { margin-top: 20px; border-top: 1px solid var(--line); padding-top: 16px; }
.scoring-details summary, .game-answers > summary { font-size: 14px; font-weight: 600; cursor: pointer; }
.score-hint { margin-top: 10px; font-size: 14px; line-height: 1.6; font-weight: 400; }
.game-answers { margin-top: 22px; }
.game-answers > summary { padding: 14px 0; }
.answer-card { border-radius: 0; box-shadow: none; background: none; }
.answer-mask, .answer-value.locked { background: #e9e1cf; color: var(--ink); }
.score-view { max-width: 760px; }
.import-surface { margin: 0; padding: 0; border: 0; background: none; }
.score-tabs { padding: 0; margin: 22px 0; gap: 0; background: none; border: 0; border-bottom: 1px solid var(--line); border-radius: 0; }
.score-tabs button { min-height: 44px; padding: 10px 18px; border: 0; border-bottom: 2px solid transparent; border-radius: 0; background: none; font-size: 14px; font-weight: 500; box-shadow: none; color: var(--muted); }
.score-tabs button[aria-selected="true"] { color: var(--green); border-color: var(--green); background: none; box-shadow: none; font-weight: 650; }
label { font-size: 13px; line-height: 1.5; font-weight: 600; color: var(--ink); }
input, select, textarea { background: #fffefa; border: 1px solid #b7ae98; border-radius: 4px; padding: 10px 12px; font-size: 15px; font-weight: 400; color: var(--ink); }
.import-input-head { margin-top: 0; }
.share-input { min-height: 140px; font-size: 15px; font-weight: 400; }
.import-date { margin-top: 16px; }
.import-status, .save-status, .friend-status { font-size: 14px; line-height: 1.5; font-weight: 400; border-radius: 0; }
.import-help { padding-top: 18px; margin-top: 20px; border-top: 1px solid var(--line); font-size: 13px; }
.import-actions { margin-top: 16px; }
.share-preview { margin-top: 16px; padding: 16px 0; background: none; border: 0; border-block: 1px solid var(--line); border-radius: 0; }
.import-help pre { background: #ece5d4; }
.import-status.success { background: #e7ece4; color: var(--green); }
.import-status.error { background: #ece5d4; color: var(--ink); border-left: 3px solid var(--ink); }
.manual-entry .save-status.error, .friend-status.error, .account-note.error { color: var(--ink); }
.manual-entry .save-status.success { color: var(--green); }
.import-warning { font-size: 13px; font-weight: 400; line-height: 1.5; color: var(--ink); }
.score-next-steps { display: flex; justify-content: space-between; gap: 16px; padding-top: 20px; }
.leaderboard-view { max-width: 1000px; }
.leaderboard-controls { grid-template-columns: 1fr 1fr; }
.leaderboard-controls #leaderboardDates { display: none; }
.leaderboard-summary { padding: 12px 0; background: none; border: 0; border-radius: 0; color: var(--muted); font-size: 14px; font-weight: 400; }
.scoreboard-head h3 { font-size: 17px; }
.scoreboard-head span { font-size: 12px; font-weight: 400; }
.friends-view { max-width: 900px; }
.friends-section { border: 0; padding: 0; margin: 0; }
.friends-section > .scoreboard-head h3 { display: none; }
.friends-section > .scoreboard-head { justify-content: flex-end; }
.sync-card { padding: 16px 0; border: 0; border-block: 1px solid var(--line); background: none; border-radius: 0; }
.sync-card strong { font-size: 15px; }
.sync-card small { font-size: 13px; line-height: 1.6; font-weight: 400; }
.friend-toolbar { margin: 16px 0; }
.friend-person { padding: 14px 0; }
.friend-person strong { font-size: 15px; font-weight: 600; }
.social-empty { grid-column: 1/-1; padding: 24px 0; color: var(--muted); font-size: 14px; font-weight: 400; line-height: 1.6; }
.add-friend-details { margin-top: 20px; }
.app-notice { padding: 12px 16px; margin: 0 0 20px; border-left: 3px solid var(--ink); background: #ece5d4; font-size: 14px; }
.modal { max-width: min(520px,calc(100vw - 28px)); border: 1px solid var(--line); border-radius: 6px; background: var(--paper); box-shadow: 0 12px 40px #20252220; }
.modal-content { padding: 24px; }
.modal-content h2 { font-size: 28px; }
.icon-button { width: 40px; height: 40px; min-width: 40px; padding: 0; border-radius: 4px; }
.account-copy { font-size: 15px; font-weight: 400; line-height: 1.6; }
.account-note { font-size: 13px; font-weight: 400; line-height: 1.5; }
.provider-button { min-height: 56px; font-size: 16px; border-radius: 4px; }
.provider-icon, .provider-icon.google { background: var(--ink); color: white; border-radius: 4px; }
:focus-visible { outline: 2px solid var(--green); outline-offset: 4px; }
h1:focus { outline: none; }
@media (min-width: 1400px) and (min-height: 850px) {
  .workspace { padding-top: 32px; }
  .home-columns { gap: 48px; }
  .home-side { padding-left: 36px; }
  .home-view .quick-game { min-height: 70px; }
  .home-view h2 { font-size: 20px; }
}
@media (max-width: 1100px) {
  .topbar { gap: 14px; }
  .brand small { display: none; }
  .topnav { gap: 16px; }
  .home-columns { gap: 24px; grid-template-columns: minmax(0,1.4fr) minmax(0,1fr); }
  .home-side { padding-left: 20px; }
  .catalog-view .game-list { grid-template-columns: repeat(2,minmax(0,1fr)); }
  .home-empty { flex-wrap: wrap; }
}
@media (max-width: 760px) {
  .topbar { position: sticky; grid-template-columns: 1fr auto; gap: 8px; padding: 8px 16px 0; }
  .brand strong { font-size: 23px; }
  .brand-logo { width: 120px; }
  .brand-mark { display: none; }
  .topnav { display: grid; grid-template-columns: repeat(4,minmax(0,1fr)); grid-column: 1/-1; grid-row: 2; gap: 0; justify-self: stretch; overflow: visible; }
  .topnav a { text-align: center; font-size: 12px; padding: 12px 0; }
  .top-actions { gap: 8px; flex-direction: row; }
  .top-actions .primary-button, .top-actions .ghost-button { min-height: 38px; padding: 8px 10px; font-size: 12px; }
  .workspace, .workspace:has(.home-view:not([hidden])) { padding: 22px 16px 32px; }
  .view-head { flex-wrap: wrap; gap: 14px; }
  .home-metrics { padding-block: 14px; margin-bottom: 24px; }
  .home-metrics > div, .home-metrics > div:nth-child(n) { display: block; padding: 0 12px; }
  .home-metrics > div:first-child { padding-left: 0; }
  .home-metrics strong { font-size: 28px; }
  .home-metrics span { display: block; margin-top: 5px; font-size: 11px; }
  .home-columns { grid-template-columns: 1fr; gap: 26px; }
  .home-side { padding-left: 0; border-left: 0; border-top: 1px solid var(--line); padding-top: 20px; }
  .home-main, .home-side { gap: 24px; }
  .home-view .dashboard-strip { gap: 0 16px; }
  .home-view .quick-game { grid-template-columns: 24px minmax(0,1fr); gap: 8px; min-height: 70px; }
  .home-view .quick-game::after { display: none; }
  .home-view .quick-game strong { font-size: 13px; }
  .home-view .quick-game .game-logo { width: 24px; height: 24px; padding: 0; }
  .home-empty { flex-wrap: wrap; }
  .catalog-view .game-list { grid-template-columns: 1fr; }
  .catalog-controls { gap: 8px; }
  #pinnedFilter { padding: 10px; font-size: 12px; }
  .game-section-label span { display: none; }
  .view-actions { width: 100%; }
  .view-actions > a { flex: 1; }
  .game-detail-card .current-result { grid-template-columns: 30px minmax(0,1fr); }
  .game-detail-card .current-result > .pill { grid-column: 2; }
  .field-grid, .leaderboard-controls { grid-template-columns: 1fr; }
  .score-tabs { margin: 18px 0; }
  .score-tabs button { font-size: 13px; padding-inline: 10px; }
  .share-input, input, select, textarea { font-size: 16px; }
  .import-actions { grid-template-columns: 1fr; }
  .rank-row .points { max-width: 105px; overflow-wrap: anywhere; font-size: 14px; }
  .modal-content { padding: 20px; }
  .modal-content .section-head { flex-direction: row; align-items: start; }
}
@media (prefers-reduced-motion: reduce) { *, *::before, *::after { scroll-behavior: auto !important; transition: none !important; } }

"""#

let appScript = #"""
const STORAGE_KEY = "solvry-state-v1";
const LEGACY_STORAGE_KEY = "tallyo-state-v1";
const today = localDateKey();

function localDateKey(date = new Date()) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}
const SOLVRY_FIREBASE_CONFIG = window.SOLVRY_FIREBASE_CONFIG || null;
const FIREBASE_MODULES = {
  app: "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js",
  auth: "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js",
  firestore: "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js"
};
const LEGACY_GAME_ID_MAP = {
  sudoku: "solvry-sudoku",
  queens: "solvry-queens",
  zip: "solvry-zip",
  crossclimb: "solvry-crossclimb",
  pinpoint: "solvry-pinpoint"
};

const SCORING_STYLES = {
  guesses: {
    label: "Fewest guesses",
    helper: "Lower guess counts win. Use a score like 4/6; X/6 means missed.",
    example: "4/6"
  },
  time: {
    label: "Fastest time",
    helper: "Fastest completion time wins. Use mm:ss or hh:mm:ss.",
    example: "01:48"
  },
  mistakes: {
    label: "Fewest mistakes",
    helper: "Lower mistake counts win. Use a number or a label like 0 mistakes.",
    example: "0 mistakes"
  },
  strokes: {
    label: "Lowest strokes",
    helper: "Lowest stroke total wins. Use a number like 38 strokes.",
    example: "38 strokes"
  },
  rank: {
    label: "Best rank",
    helper: "Best rank wins. Use the rank shown by the official game.",
    example: "Genius"
  },
  complete: {
    label: "Completion",
    helper: "Track whether the game was completed today.",
    example: "Complete"
  },
  points: {
    label: "Most points",
    helper: "Higher point totals win.",
    example: "110"
  },
  depth: {
    label: "Highest depth",
    helper: "Higher depth or rarity score wins. Krillion shares this as a total like 110.",
    example: "110"
  }
};

const GOLF_GENERATION_VERSION = 3;
const GOLF_GAME_VERSION = 9;
const GOLF_IDEAL_POWER = 60;
const GOLF_CLUBS = [
  { id: "driver", label: "DR", name: "Driver", carry: 278, max: 278, dispersion: 9.5, rollout: 30 },
  { id: "wood", label: "3W", name: "Wood", carry: 243, max: 243, dispersion: 8.2, rollout: 24 },
  { id: "long-iron", label: "4i", name: "Long Iron", carry: 199, max: 199, dispersion: 6.8, rollout: 17 },
  { id: "mid-iron", label: "6i", name: "Mid Iron", carry: 179, max: 179, dispersion: 5.6, rollout: 12 },
  { id: "short-iron", label: "8i", name: "Short Iron", carry: 156, max: 156, dispersion: 4.4, rollout: 8 },
  { id: "wedge", label: "PW", name: "Wedge", carry: 131, max: 131, dispersion: 3.2, rollout: 4 },
  { id: "lob-wedge", label: "LW", name: "Lob Wedge", carry: 66, max: 66, dispersion: 2.4, rollout: 2 }
];
const GOLF_SURFACES = {
  tee: { label: "Tee", rollout: 1, power: 1, accuracy: 1 },
  fairway: { label: "Fairway", rollout: 1, power: 1, accuracy: 1 },
  rough: { label: "Rough", rollout: 0.45, power: 0.92, accuracy: 1.25 },
  deepRough: { label: "Deep rough", rollout: 0.18, power: 0.8, accuracy: 1.55 },
  bunker: { label: "Bunker", rollout: 0.08, power: 0.74, accuracy: 1.75 },
  green: { label: "Green", rollout: 0.85, power: 0.92, accuracy: 0.9 },
  cartPath: { label: "Cart path", rollout: 2.4, power: 1.05, accuracy: 1.35 },
  water: { label: "Water", rollout: 0, power: 0, accuracy: 2 }
};

// Keep the game engines and saved rounds available for a future return.
const SHOW_SOLVRY_GAMES = false;
const ADDITIONAL_IMPORT_GAMES = [
  { id: "connections-sports", name: "Connections: Sports Edition", type: "mistakes", maxScore: 4, scoring: { label: "Fewest mistakes", helper: "The Athletic's Sports Edition has its own scoreboard. Lower mistakes win; four is a miss.", example: "1 mistake" }, logo: "connections", officialUrl: "https://www.nytimes.com/athletic/connections-sports-edition" },
  { id: "daily-tens", name: "Daily Tens", type: "points", maxScore: 10, scoring: { label: "Most correct", helper: "One point per trophy in the shared top-10 grid. More correct answers win; percentile is not used.", example: "8/10" }, logo: "daily-tens", officialUrl: "https://dailytens.com/" },
  { id: "centumth", name: "Centumth", type: "points", maxScore: 490, scoring: { label: "Most points", helper: "Sum of the ranks from your five official guesses. Higher is better, up to 490. Arcade guesses do not count.", example: "350/490" }, logo: "centumth", officialUrl: "https://www.centumth.com/" },
  { id: "globle", name: "Globle", type: "guesses", scoring: { label: "Fewest guesses", helper: "Today's guess count after the equals sign. Lower wins; your streak and average are not the daily score.", example: "5 guesses" }, logo: "globle", officialUrl: "https://globle-game.com/" },
  { id: "flagcognito", name: "Flagcognito", type: "points", maxScore: 3000, scoring: { label: "Most points", helper: "The shared total across three rounds, up to 3,000 points. Higher wins.", example: "2400/3000" }, logo: "flagcognito", officialUrl: "https://guessdash.com/flagcognito" },
  { id: "size-it-up", name: "Size It Up", type: "points", maxScore: 500, scoring: { label: "Most points", helper: "Magnitudle's original daily game: five rounds, up to 500 points. Higher wins. Other editions and practice runs need a separate game.", example: "425/500" }, logo: "size-it-up", officialUrl: "https://magnitudle.com/size-it-up" },
  { id: "color", name: "Color (Dialed)", type: "points", maxScore: 50, decimalScore: true, dailyRanked: false, scoring: { label: "Best color memory", helper: "Share the score out of 50 and the Dialed Color link. Dated Color Daily results count in the combined leaderboard. Other challenge results stay on this game’s board.", example: "39.12/50" }, logo: "color", officialUrl: "https://dialed.gg/color" },
  { id: "buzzfeed-trivia", name: "BuzzFeed Daily Trivia", type: "points", maxScore: 5, scoring: { label: "Most correct", helper: "Correct answers out of five. More correct answers win.", example: "4/5" }, logo: "buzzfeed-trivia", officialUrl: "https://www.buzzfeed.com/daily-trivia" },
  ...[
    ["baseball", "Baseball", ""], ["football", "Football", "football/"],
    ["basketball-men", "Men’s Basketball", "basketball/mens/"], ["basketball-women", "Women’s Basketball", "basketball/womens/"], ["hockey", "Hockey", "hockey/"]
  ].map(([sport, name, path]) => ({ id: `immaculate-${sport}`, name: `Immaculate Grid: ${name}`, type: "grid", scoring: { label: "Correct + rarity", helper: "More correct answers out of nine rank first. Lower rarity score breaks ties. Rarity is a score, not a percentage; sports stay separate.", example: "9/9 · rarity 75" }, logo: "immaculate", officialUrl: `https://www.sports-reference.com/immaculate-grid/${path}` }))
].map((game) => ({ ...game, source: "official" }));

const starterState = {
  activeGameId: "wordle",
  selectedDate: today,
  profile: { name: "You", handle: "@solvry" },
  account: { signedIn: false, provider: "", email: "", uid: "", backend: "local" },
  friendRequests: { incoming: [], outgoing: [] },
  pinnedGameIds: [],
  solvryPlays: {},
  games: [
    { id: "wordle", name: "Wordle", source: "official", type: "guesses", scoring: { label: "Fewest guesses", helper: "Guess count out of 6. Lower is better; X/6 is a miss.", example: "4/6" }, logo: "wordle", officialUrl: "https://www.nytimes.com/games/wordle/index.html" },
    { id: "connections", name: "Connections", source: "official", type: "mistakes", scoring: { label: "Fewest mistakes", helper: "Imported Connections grids rank by mistakes. Lower is better.", example: "0 mistakes" }, logo: "connections", officialUrl: "https://www.nytimes.com/games/connections" },
    { id: "strands", name: "Strands", source: "official", type: "complete", scoring: { label: "Completion", helper: "Imported Strands shares track completion and hints.", example: "Complete" }, logo: "strands", officialUrl: "https://www.nytimes.com/games/strands" },
    { id: "mini-crossword", name: "Mini Crossword", source: "official", type: "time", scoring: { label: "Fastest time", helper: "Imported Mini shares rank by completion time.", example: "00:54" }, logo: "mini-crossword", officialUrl: "https://www.nytimes.com/crosswords/game/mini" },
    { id: "spelling-bee", name: "Spelling Bee", source: "official", type: "rank", scoring: { label: "Best rank", helper: "Imported Spelling Bee shares rank by official level.", example: "Genius" }, logo: "spelling-bee", officialUrl: "https://www.nytimes.com/puzzles/spelling-bee" },
    { id: "krillion", name: "Krillion", source: "official", type: "depth", scoring: { label: "Highest depth", helper: "Rarer valid answers score more. Higher total depth points win.", example: "110" }, logo: "krillion", officialUrl: "https://krillion.io/" },
    ...ADDITIONAL_IMPORT_GAMES,
    { id: "solvry-holes", name: "Solvry Holes", source: "solvry", type: "strokes", scoring: { label: "Lowest strokes", helper: "Play nine tiny daily holes. Fewer total strokes win.", example: "38 strokes" }, logo: "holes", officialUrl: "" },
    { id: "solvry-hoops", name: "Solvry Hoops", source: "solvry", type: "points", scoring: { label: "Most points", helper: "Play nine daily basketball shots. Higher point total wins.", example: "24 points" }, logo: "hoops", officialUrl: "" }
  ],
  friends: [
    { id: "mira", name: "Mira", handle: "@mirasolves", status: "demo" },
    { id: "jay", name: "Jay", handle: "@jayplaysdaily", status: "demo" },
    { id: "nolan", name: "Nolan", handle: "@gridnolan", status: "demo" }
  ],
  entries: {
    [today]: {
      wordle: {
        mira: { result: "solved", score: "3/6", answer: "BLOOM", note: "Fast opener", reveal: true },
        jay: { result: "solved", score: "5/6", answer: "BLOOM", note: "Barely saved it", reveal: true },
        nolan: { result: "missed", score: "X/6", answer: "BLOOM", note: "Tomorrow is revenge", reveal: true }
      },
      connections: {
        mira: { result: "solved", score: "1 mistake", answer: "", note: "Imported grid", reveal: false }
      },
      "solvry-holes": {
        mira: { result: "played", score: "39 strokes", answer: "", note: "Clean back nine", reveal: false }
      },
      "solvry-hoops": {
        jay: { result: "played", score: "21 points", answer: "", note: "Hot corner round", reveal: false }
      }
    }
  }
};

let state = loadState();
let saveStatusTimers = new WeakMap();

const elements = {
  navLinks: [...document.querySelectorAll(".topnav a")],
  playDate: document.querySelector("#playDate"),
  gameList: document.querySelector("#gameList"),
  quickGames: document.querySelector("#quickGames"),
  activeGameTitle: document.querySelector("#activeGameTitle"),
  scoreHint: document.querySelector("#scoreHint"),
  friendCompletion: document.querySelector("#friendCompletion"),
  privacyState: document.querySelector("#privacyState"),
  currentResult: document.querySelector("#currentResult"),
  solvryGame: document.querySelector("#solvryGame"),
  letterBoard: document.querySelector("#letterBoard"),
  entryForm: document.querySelector("#entryForm"),
  resultInput: document.querySelector("#resultInput"),
  scoreInput: document.querySelector("#scoreInput"),
  scoreHelp: document.querySelector("#scoreHelp"),
  answerInput: document.querySelector("#answerInput"),
  noteInput: document.querySelector("#noteInput"),
  revealInput: document.querySelector("#revealInput"),
  saveStatus: document.querySelector("#saveStatus"),
  playedMetric: document.querySelector("#playedMetric"),
  solvedMetric: document.querySelector("#solvedMetric"),
  streakMetric: document.querySelector("#streakMetric"),
  totalSolvesMetric: document.querySelector("#totalSolvesMetric"),
  progressDays: document.querySelector("#progressDays"),
  overallLeaderboard: document.querySelector("#overallLeaderboard"),
  gameLeaderboard: document.querySelector("#gameLeaderboard"),
  gameScoreboardTitle: document.querySelector("#gameScoreboardTitle"),
  gameScoreboardMeta: document.querySelector("#gameScoreboardMeta"),
  gameScoreboardNote: document.querySelector("#gameScoreboardNote"),
  friendForm: document.querySelector("#friendForm"),
  friendSync: document.querySelector("#friendSync"),
  friendNameInput: document.querySelector("#friendNameInput"),
  friendHandleInput: document.querySelector("#friendHandleInput"),
  answerFeed: document.querySelector("#answerFeed"),
  copyButton: document.querySelector("#copyButton"),
  importSurface: document.querySelector("#import"),
  officialLink: document.querySelector("#officialLink"),
  importClipboardButton: document.querySelector("#importClipboardButton"),
  importPasteButton: document.querySelector("#importPasteButton"),
  importClearButton: document.querySelector("#importClearButton"),
  importDate: document.querySelector("#importDate"),
  importExampleGame: document.querySelector("#importExampleGame"),
  importExampleText: document.querySelector("#importExampleText"),
  importExampleLink: document.querySelector("#importExampleLink"),
  manualEntry: document.querySelector("#manualEntry"),
  pastePanel: document.querySelector("#pastePanel"),
  pasteTab: document.querySelector("#pasteTab"),
  manualTab: document.querySelector("#manualTab"),
  manualGameInput: document.querySelector("#manualGameInput"),
  manualDateInput: document.querySelector("#manualDateInput"),
  manualRankInput: document.querySelector("#manualRankInput"),
  manualScoreLabel: document.querySelector("#manualScoreLabel"),
  manualExisting: document.querySelector("#manualExisting"),
  manualSaveButton: document.querySelector("#manualSaveButton"),
  shareTextInput: document.querySelector("#shareTextInput"),
  importStatus: document.querySelector("#importStatus"),
  sharePreview: document.querySelector("#sharePreview"),
  overallTab: document.querySelector("#overallTab"),
  gameBoardTab: document.querySelector("#gameBoardTab"),
  overallBoard: document.querySelector("#overallBoard"),
  gameBoard: document.querySelector("#gameBoard"),
  leaderboardRange: document.querySelector("#leaderboardRange"),
  leaderboardDate: document.querySelector("#leaderboardDate"),
  leaderboardRangeLabel: document.querySelector("#leaderboardRangeLabel"),
  leaderboardGameInput: document.querySelector("#leaderboardGameInput"),
  leaderboardGameLabel: document.querySelector("#leaderboardGameLabel"),
  leaderboardDates: document.querySelector("#leaderboardDates"),
  leaderboardSummary: document.querySelector("#leaderboardSummary"),
  friendsCount: document.querySelector("#friendsCount"),
  friendsTab: document.querySelector("#friendsTab"),
  requestsTab: document.querySelector("#requestsTab"),
  friendsPanel: document.querySelector("#friendsPanel"),
  requestsPanel: document.querySelector("#requestsPanel"),
  friendSearch: document.querySelector("#friendSearch"),
  friendRoster: document.querySelector("#friendRoster"),
  friendRequests: document.querySelector("#friendRequests"),
  friendStatus: document.querySelector("#friendStatus"),
  friendSubmitButton: document.querySelector("#friendSubmitButton"),
  addFriendSummary: document.querySelector("#addFriendSummary"),
  showDemoFriends: document.querySelector("#showDemoFriends"),
  copyHandleButton: document.querySelector("#copyHandleButton"),
  refreshFriendsButton: document.querySelector("#refreshFriendsButton"),
  addGameButton: document.querySelector("#addGameButton"),
  closeGameDialogButton: document.querySelector("#closeGameDialogButton"),
  gameDialog: document.querySelector("#gameDialog"),
  gameForm: document.querySelector("#gameForm"),
  gameNameInput: document.querySelector("#gameNameInput"),
  gameTypeInput: document.querySelector("#gameTypeInput"),
  gameFormStatus: document.querySelector("#gameFormStatus"),
  accountControls: document.querySelector("#accountControls"),
  accountDialog: document.querySelector("#accountDialog"),
  accountForm: document.querySelector("#accountForm"),
  accountTitle: document.querySelector("#accountTitle"),
  accountStatus: document.querySelector("#accountStatus"),
  closeAccountDialogButton: document.querySelector("#closeAccountDialogButton")
};

let cloudBackend = {
  configured: false,
  ready: false,
  status: "offline",
  error: "",
  auth: null,
  db: null,
  modules: null,
  unsubscribers: [],
  saveTimer: 0,
  applyingRemote: false
};

elements.playDate.value = state.selectedDate;
elements.importDate.value = state.selectedDate;
elements.importDate.max = today;
elements.manualDateInput.value = state.selectedDate;
elements.manualDateInput.max = today;
elements.importSurface.append(elements.manualEntry);
elements.playDate.max = today;
renderImportExample();
let scoreMethod = "paste";
let manualFormKey = "";
let manualFormDirty = false;
let lastRenderedGameId = null;
const importDrafts = new Map();
let importDraftRevision = 0;
let leaderboardView = "overall";
let leaderboardDays = 1;
let leaderboardGameId = state.activeGameId;
let friendBusy = false;
let pinnedOnly = false;
const roomyOverview = window.matchMedia("(min-width: 1400px) and (min-height: 850px)");
roomyOverview.addEventListener("change", () => renderQuickGames());
const wideOverview = window.matchMedia("(min-width: 1700px) and (min-height: 850px)");
wideOverview.addEventListener("change", () => renderQuickGames());
document.querySelector("#gameSearch").addEventListener("input", renderGameList);
document.querySelector("#pinnedFilter").addEventListener("click", (event) => {
  pinnedOnly = !pinnedOnly;
  event.currentTarget.setAttribute("aria-pressed", String(pinnedOnly));
  renderGameList();
});
document.querySelector("#viewGameLeaderboard").addEventListener("click", () => {
  leaderboardGameId = state.activeGameId;
  leaderboardView = "game";
  renderScoreboards(getActiveGame());
  navigateTo("leaderboard");
});
document.querySelector("#homeScores").addEventListener("click", (event) => {
  const button = event.target.closest("[data-home-game]");
  if (button) openGame(button.dataset.homeGame);
});
elements.importExampleGame.innerHTML += ADDITIONAL_IMPORT_GAMES.map((game) => `<option value="${game.id}">${escapeHtml(game.name)}</option>`).join("");

function wireSocialTabs(tabs, select) {
  tabs.forEach((tab, index) => {
    tab.addEventListener("click", () => select(index));
    tab.addEventListener("keydown", (event) => {
      if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
      event.preventDefault();
      const next = event.key === "Home" ? 0 : event.key === "End" ? 1 : 1 - index;
      tabs[next].click();
      tabs[next].focus();
    });
  });
}
wireSocialTabs([elements.overallTab, elements.gameBoardTab], (index) => {
  leaderboardView = index ? "game" : "overall";
  renderScoreboards(getActiveGame());
});
wireSocialTabs([elements.friendsTab, elements.requestsTab], (index) => {
  [elements.friendsTab, elements.requestsTab].forEach((tab, i) => {
    tab.setAttribute("aria-selected", String(i === index));
    tab.tabIndex = i === index ? 0 : -1;
  });
  elements.friendsPanel.hidden = index === 1;
  elements.requestsPanel.hidden = index === 0;
});
elements.leaderboardRange.addEventListener("change", () => {
  leaderboardDays = Number(elements.leaderboardRange.value) === 7 ? 7 : 1;
  renderScoreboards(getActiveGame());
});
elements.leaderboardDate.addEventListener("change", () => {
  if (!elements.leaderboardDate.value || !elements.leaderboardDate.validity.valid) return;
  state.selectedDate = elements.leaderboardDate.value;
  elements.playDate.value = state.selectedDate;
  elements.importDate.value = state.selectedDate;
  elements.manualDateInput.value = state.selectedDate;
  try { saveState(); } catch { setFriendStatus("This date selection couldn't be saved on this device.", true); }
  render(false);
});
elements.leaderboardGameInput.addEventListener("change", () => {
  leaderboardGameId = elements.leaderboardGameInput.value;
  renderScoreboards(getActiveGame());
});
elements.friendSearch.addEventListener("input", renderFriendSync);
elements.showDemoFriends.addEventListener("change", () => {
  const previous = state.showDemoFriends;
  state.showDemoFriends = elements.showDemoFriends.checked;
  try { saveState(); } catch {
    state.showDemoFriends = previous;
    setFriendStatus("Couldn't save this preference. Try again.", true);
  }
  refreshSocialViews();
});
elements.copyHandleButton.addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(state.profile.handle);
    setFriendStatus("Handle copied. Share it with a friend so they can find you.");
  } catch { setFriendStatus(`Copy your handle: ${state.profile.handle}`, true); }
});
elements.refreshFriendsButton.addEventListener("click", () => runFriendAction(async () => {
  await refreshAcceptedFriends();
  saveState();
  setFriendStatus("Friend scores refreshed.");
}));
elements.friendRoster.addEventListener("click", (event) => {
  const button = event.target.closest("[data-remove-friend]");
  if (!button) return;
  const friend = state.friends.find((person) => person.id === button.dataset.removeFriend);
  if (!friend || !window.confirm(`Remove ${friend.name} from your friends and rankings? Saved score history will remain on this device.`)) return;
  runFriendAction(async () => {
    if (friend.uid) {
      const request = [...state.friendRequests.incoming, ...state.friendRequests.outgoing].find((item) => item.status === "accepted" && [item.fromUid, item.toUid].includes(friend.uid));
      if (!request) throw new Error("This connection hasn't loaded yet. Try again shortly.");
      await updateFriendRequest("remove", request.id);
    }
    const previous = state.friends;
    state.friends = state.friends.filter((person) => person.id !== friend.id);
    try { saveState(); } catch { state.friends = previous; throw new Error("Couldn't save this change. Try again."); }
    setFriendStatus(`${friend.name} removed from your friends.`);
  });
});

window.addEventListener("hashchange", () => {
  renderNav();
  window.scrollTo({ top: 0, behavior: "instant" });
  const heading = document.querySelector(".app-view:not([hidden]) h1");
  heading?.setAttribute("tabindex", "-1");
  heading?.focus({ preventScroll: true });
});

elements.playDate.addEventListener("change", (event) => {
  if (!event.target.value || !event.target.validity.valid) { event.target.value = state.selectedDate; return; }
  state.selectedDate = event.target.value;
  elements.importDate.value = state.selectedDate;
  elements.manualDateInput.value = state.selectedDate;
  try { saveState(); } catch { showAppNotice("This date couldn't be saved on your device."); }
  render();
});

elements.entryForm.addEventListener("submit", (event) => {
  event.preventDefault();
  saveManualScore();
});

elements.entryForm.addEventListener("input", () => {
  manualFormDirty = true;
  elements.scoreInput.setCustomValidity("");
  elements.saveStatus.textContent = "";
});
elements.resultInput.addEventListener("change", updateManualScoreField);
elements.manualGameInput.addEventListener("change", () => {
  if (elements.manualGameInput.value === "__other__") {
    elements.manualGameInput.value = state.activeGameId;
    elements.gameForm.reset();
    elements.gameFormStatus.textContent = "";
    elements.gameDialog.showModal();
    elements.gameNameInput.focus();
    return;
  }
  state.activeGameId = elements.manualGameInput.value;
  manualFormDirty = false;
  render();
});
elements.manualDateInput.addEventListener("change", () => { manualFormDirty = false; renderForm(); });
[elements.pasteTab, elements.manualTab].forEach((tab, index, tabs) => {
  tab.addEventListener("click", () => setScoreMethod(index ? "manual" : "paste"));
  tab.addEventListener("keydown", (event) => {
    if (!["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) return;
    event.preventDefault();
    const next = event.key === "Home" ? 0 : event.key === "End" ? 1 : 1 - index;
    tabs[next].click();
    tabs[next].focus();
  });
});

elements.friendForm.addEventListener("submit", (event) => {
  event.preventDefault();
  handleFriendSubmit();
});

elements.addGameButton?.addEventListener("click", () => {
  elements.gameForm.reset();
  elements.gameDialog.showModal();
});

elements.closeGameDialogButton.addEventListener("click", () => {
  elements.gameDialog.close();
});

elements.gameForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const name = elements.gameNameInput.value.trim().replace(/\s+/g, " ");
  if (!name) { elements.gameFormStatus.textContent = "Enter a game name."; return; }
  const existing = state.games.find((game) => game.name.toLowerCase() === name.toLowerCase());
  if (existing) {
    elements.gameFormStatus.textContent = `${existing.name} is already listed. Choose it from the game list.`;
    return;
  }
  const type = elements.gameTypeInput.value;
  const id = uniqueId(`custom-${slugify(name) || "game"}-${type}`, state.games.map((game) => game.id));
  const game = { id, name, source: "custom", type, scoring: customScoringForType(type), logo: "custom", officialUrl: "" };
  const previousGameId = state.activeGameId;
  state.games.push(game);
  state.activeGameId = id;
  try { saveState(); } catch {
    state.games = state.games.filter((item) => item !== game);
    state.activeGameId = previousGameId;
    elements.gameFormStatus.textContent = "Couldn't save this game on your device. Try again.";
    return;
  }
  manualFormDirty = false;
  elements.gameDialog.close();
  render();
  setScoreMethod("manual");
  navigateTo("import");
  (type === "complete" ? elements.resultInput : elements.scoreInput).focus();
});

elements.accountControls.addEventListener("click", (event) => {
  const actionButton = event.target.closest("[data-account-action]");
  if (!actionButton) return;
  const action = actionButton.dataset.accountAction;
  if (action === "signout") {
    signOutAccount();
    return;
  }
  openAccountDialog(action);
});

elements.closeAccountDialogButton.addEventListener("click", () => {
  elements.accountDialog.close();
});

elements.accountForm.addEventListener("click", (event) => {
  const providerButton = event.target.closest("[data-provider]");
  if (!providerButton) return;
  signInWithProvider(providerButton.dataset.provider);
});

elements.accountForm.addEventListener("submit", (event) => {
  event.preventDefault();
});

elements.friendRequests.addEventListener("click", (event) => {
  const actionButton = event.target.closest("[data-friend-action]");
  if (!actionButton) return;
  handleFriendRequestAction(actionButton.dataset.friendAction, actionButton.dataset.requestId);
});

elements.copyButton.addEventListener("click", async () => {
  const activeGame = getActiveGame();
  const mine = getGameEntries(state.selectedDate, state.activeGameId).you;
  const recap = mine
    ? `Solvry: ${activeGame.name} ${state.selectedDate} - ${mine.result}, ${mine.score}${mine.answer && mine.reveal ? `, answer ${mine.answer}` : ""}`
    : `Solvry: ${activeGame.name} ${state.selectedDate} - no result yet`;

  try {
    await navigator.clipboard.writeText(recap);
    flashButton(elements.copyButton, "Copied", "Copy recap");
  } catch {
    flashButton(elements.copyButton, "Copy failed", "Copy recap");
  }
});

elements.importClipboardButton.addEventListener("click", async () => {
  const previousText = elements.shareTextInput.value;
  const previousRevision = importDraftRevision;
  const previousGameId = state.activeGameId;
  elements.importClipboardButton.disabled = true;
  try {
    const text = await navigator.clipboard.readText();
    if (elements.shareTextInput.value !== previousText || previousRevision !== importDraftRevision || previousGameId !== state.activeGameId) return;
    elements.shareTextInput.value = text;
    previewImport(true);
  } catch {
    setImportStatus("Clipboard unavailable. Paste directly into the result box instead.", "error");
    elements.shareTextInput.focus();
  } finally {
    elements.importClipboardButton.disabled = false;
  }
});

elements.shareTextInput.addEventListener("input", () => previewImport());
elements.importDate.addEventListener("change", () => previewImport());
elements.importExampleGame.addEventListener("change", renderImportExample);
elements.importClearButton.addEventListener("click", () => {
  importDraftRevision += 1;
  importDrafts.delete(state.activeGameId);
  elements.shareTextInput.value = "";
  previewImport();
  elements.shareTextInput.focus();
});
elements.importPasteButton.addEventListener("click", () => {
  importShareText(elements.shareTextInput.value);
});

let solvryPointerStart = null;
let ignoreNextSolvryTap = false;

elements.solvryGame.addEventListener("pointerdown", (event) => {
  solvryPointerStart = { x: event.clientX, y: event.clientY };
});

elements.solvryGame.addEventListener("pointerup", (event) => {
  if (!solvryPointerStart) return;
  const moved = Math.hypot(event.clientX - solvryPointerStart.x, event.clientY - solvryPointerStart.y);
  solvryPointerStart = null;
  if (moved > 10) {
    ignoreNextSolvryTap = true;
    window.setTimeout(() => {
      ignoreNextSolvryTap = false;
    }, 120);
  }
});

elements.solvryGame.addEventListener("click", (event) => {
  const actionButton = event.target.closest("[data-play-action]");
  if (actionButton) {
    handleSolvryPlayAction(actionButton.dataset.playAction);
    return;
  }

  if (ignoreNextSolvryTap) return;

  const game = getActiveGame();
  if (!isPlayableSolvryGame(game)) return;
  const play = getSolvryPlay(game);
  if (play.kind === "holes" && play.shotPhase === "aiming") handleSolvryPlayAction("lock-aim");
  if (play.kind === "holes" && play.shotPhase === "power") handleSolvryPlayAction("lock-power");
});

function render(focusGolf = true) {
  const activeGame = getActiveGame();
  state.activeGameId = activeGame.id;
  if (lastRenderedGameId && lastRenderedGameId !== activeGame.id) switchImportDraft(lastRenderedGameId, activeGame.id);
  if (activeGame.source === "custom" && lastRenderedGameId !== activeGame.id) setScoreMethod("manual");
  lastRenderedGameId = activeGame.id;
  const gameEntries = getGameEntries(state.selectedDate, state.activeGameId);
  const myEntry = gameEntries.you;
  const friendEntries = visibleFriends().filter((friend) => gameEntries[friend.id]);

  document.body.classList.toggle("solvry-holes-focus", activeGame.id === "solvry-holes");
  elements.activeGameTitle.textContent = activeGame.name;
  document.querySelector("#gameDateLabel").textContent = state.selectedDate;
  elements.scoreHint.textContent = scoreStyleHelp(activeGame);
  elements.friendCompletion.textContent = `${friendEntries.length} friend${friendEntries.length === 1 ? "" : "s"} done`;
  elements.privacyState.textContent = myEntry?.reveal ? "Answer shown" : "Answers hidden";
  elements.importSurface.hidden = gameSource(activeGame) === "solvry";

  renderNav();
  renderAccount();
  renderQuickGames();
  renderGameList();
  renderOfficialLink(activeGame);
  renderCurrentResult(activeGame, myEntry);
  renderSolvryGame(activeGame);
  if (SHOW_SOLVRY_GAMES) renderBoard(activeGame.name);
  elements.letterBoard.hidden = !SHOW_SOLVRY_GAMES;
  renderForm(myEntry);
  renderMetrics();
  renderScoreboards(activeGame);
  renderFriendSync();
  renderAnswers();
  renderHome();
  previewImport();
  if (focusGolf) focusHolesViewport(activeGame);
}

function focusHolesViewport(activeGame) {
  if (activeGame.id !== "solvry-holes" || elements.solvryGame.hidden) return;
  const alignGolfCard = () => {
    const golfCard = elements.solvryGame.querySelector(".daily-golf") || elements.solvryGame;
    const topbar = document.querySelector(".topbar");
    const topbarPosition = topbar ? getComputedStyle(topbar).position : "";
    const topbarHeight = topbar && ["fixed", "sticky"].includes(topbarPosition) ? topbar.getBoundingClientRect().height : 0;
    const targetTop = golfCard.getBoundingClientRect().top + window.scrollY - topbarHeight - 6;
    if (Math.abs(window.scrollY - targetTop) <= 6) return;
    const previousScrollBehavior = document.documentElement.style.scrollBehavior;
    document.documentElement.style.scrollBehavior = "auto";
    window.scrollTo({ top: Math.max(0, targetTop), behavior: "auto" });
    document.documentElement.style.scrollBehavior = previousScrollBehavior;
  };
  window.requestAnimationFrame(() => {
    alignGolfCard();
    window.setTimeout(alignGolfCard, 60);
  });
}

function renderAccount() {
  if (state.account?.signedIn) {
    elements.accountControls.innerHTML = `
      <span class="account-name">
        ${escapeHtml(state.profile.name)}
        <small>${escapeHtml(state.account.provider)} · ${state.account.backend === "cloud" ? "synced" : "local"}</small>
      </span>
      <button class="ghost-button compact-button" type="button" data-account-action="signout">Sign out</button>
    `;
    return;
  }

  elements.accountControls.innerHTML = `
    <button class="ghost-button compact-button" type="button" data-account-action="login">Account</button>
  `;
}

function currentView() {
  const route = location.hash.slice(1) || "today";
  if (route === "answers") return "game";
  return ["today", "games", "game", "leaderboard", "friends", "import"].includes(route) ? route : "today";
}

function renderNav() {
  const view = currentView();
  document.querySelectorAll(".app-view").forEach((panel) => { panel.hidden = panel.dataset.view !== view; });
  elements.navLinks.forEach((link) => {
    const selected = link.hash === `#${view === "game" ? "games" : view}`;
    link.classList.toggle("active", selected);
    if (selected) link.setAttribute("aria-current", "page");
    else link.removeAttribute("aria-current");
  });
  const addScore = document.querySelector(".nav-add-score");
  if (view === "import") addScore.setAttribute("aria-current", "page");
  else addScore.removeAttribute("aria-current");
  if (location.hash === "#answers") document.querySelector("#gameAnswers").open = true;
}

function navigateTo(view) {
  if (location.hash === `#${view}`) renderNav();
  else location.hash = view;
}

function openGame(gameId) {
  state.activeGameId = gameId;
  try { saveState(); } catch { showAppNotice("Your game selection couldn't be saved. Your scores are still here."); }
  render();
  navigateTo("game");
}

function showAppNotice(message) {
  const notice = document.querySelector("#appNotice");
  notice.textContent = message;
  notice.hidden = !message;
}

function renderHome() {
  const games = visibleGames().filter((game) => state.entries[state.selectedDate]?.[game.id]?.you);
  const scoreRows = games.map((game) => {
    const entry = state.entries[state.selectedDate][game.id].you;
    return `<button type="button" class="home-score-row" data-home-game="${escapeHtml(game.id)}">${gameLogo(game)}<span><strong>${escapeHtml(game.name)}</strong><small>${entry.source === "manual" ? "Manual" : "Imported"} · ${escapeHtml(entry.result)}</small></span><span class="home-score-value">${escapeHtml(entry.score)} <span aria-hidden="true">→</span></span></button>`;
  });
  document.querySelector("#homeScores").innerHTML = scoreRows.length
    ? scoreRows.slice(0, 3).join("") + (scoreRows.length > 3 ? `<details class="more-home-scores"><summary>Show ${scoreRows.length - 3} more ${scoreRows.length === 4 ? "score" : "scores"}</summary>${scoreRows.slice(3).join("")}</details>` : "")
    : '<div class="home-empty"><div><h3>No scores yet.</h3><p>Copy a game’s result and paste it here.</p></div><a class="primary-button" href="#import">Add your first score</a></div>';
  const rows = buildOverallLeaderboard();
  const ranked = rows.filter((row) => row.rank);
  document.querySelector("#homeLeaderboard").innerHTML = ranked.length ? renderRankRows(ranked.slice(0, 3), "No scores yet") : '<div class="ranking-empty"><strong>No ranked results yet.</strong><p>Save a result to see your place. Compare scores with friends when they’re available.</p><a class="text-link" href="#import">Add a result →</a></div>';
  document.querySelector("#homeRankingDate").textContent = `${state.selectedDate} · Daily combined points`;
}

function openAccountDialog(mode) {
  elements.accountTitle.textContent = mode === "login" ? "Log in to Solvry" : "Create your Solvry account";
  updateAccountStatus();
  elements.accountDialog.showModal();
}

function getFirebaseConfig() {
  if (SOLVRY_FIREBASE_CONFIG?.apiKey && SOLVRY_FIREBASE_CONFIG?.projectId && SOLVRY_FIREBASE_CONFIG?.appId) {
    return SOLVRY_FIREBASE_CONFIG;
  }
  try {
    const localConfig = JSON.parse(localStorage.getItem("solvry-firebase-config") || "null");
    return localConfig?.apiKey && localConfig?.projectId && localConfig?.appId ? localConfig : null;
  } catch {
    return null;
  }
}

async function initCloudBackend() {
  const config = getFirebaseConfig();
  cloudBackend.configured = !!config;
  if (!config) {
    cloudBackend.status = "local-only";
    updateAccountStatus();
    renderFriendSync();
    return;
  }

  try {
    const [appModule, authModule, firestoreModule] = await Promise.all([
      import(FIREBASE_MODULES.app),
      import(FIREBASE_MODULES.auth),
      import(FIREBASE_MODULES.firestore)
    ]);
    const app = appModule.initializeApp(config);
    cloudBackend.modules = { auth: authModule, firestore: firestoreModule };
    cloudBackend.auth = authModule.getAuth(app);
    cloudBackend.db = firestoreModule.getFirestore(app);
    cloudBackend.ready = true;
    cloudBackend.status = "ready";
    authModule.onAuthStateChanged(cloudBackend.auth, (user) => {
      handleCloudAuthUser(user).catch((error) => {
        cloudBackend.error = error.message || "Could not sync account.";
        updateAccountStatus();
      });
    });
    updateAccountStatus();
  } catch (error) {
    cloudBackend.status = "error";
    cloudBackend.error = error.message || "Could not load Firebase.";
    updateAccountStatus();
  }
}

function updateAccountStatus(message = "") {
  if (!elements.accountStatus) return;
  const text = message
    || (cloudBackend.ready
      ? "Google and Apple sign-in are connected. Scores, friends, and requests sync to Solvry Cloud."
      : cloudBackend.configured
        ? cloudBackend.error || "Connecting Solvry Cloud."
        : "Online sign-in isn’t available yet. Your scores are saved on this device.");
  elements.accountStatus.textContent = text;
  elements.accountStatus.classList.toggle("error", !!cloudBackend.error || (!cloudBackend.ready && !cloudBackend.configured));
}

async function signInWithProvider(providerName) {
  if (!cloudBackend.ready) {
    updateAccountStatus("Online sign-in isn’t available yet. You can keep tracking scores on this device.");
    return;
  }

  const { GoogleAuthProvider, OAuthProvider, signInWithPopup } = cloudBackend.modules.auth;
  const provider = providerName === "Google" ? new GoogleAuthProvider() : new OAuthProvider("apple.com");
  try {
    updateAccountStatus(`Opening ${providerName} sign-in.`);
    await signInWithPopup(cloudBackend.auth, provider);
  } catch (error) {
    cloudBackend.error = error.message || `${providerName} sign-in failed.`;
    updateAccountStatus();
  }
}

async function signOutAccount() {
  if (cloudBackend.ready && cloudBackend.auth?.currentUser) {
    try {
      await cloudBackend.modules.auth.signOut(cloudBackend.auth);
    } catch (error) {
      cloudBackend.error = error.message || "Could not sign out of Solvry Cloud.";
      setFriendStatus("Couldn't sign out. Please try again.", true);
      return;
    }
  }
  clearCloudSubscriptions();
  state.account = { signedIn: false, provider: "", email: "", uid: "", backend: "local" };
  state.friendRequests = { incoming: [], outgoing: [] };
  saveState();
  render();
}

async function handleCloudAuthUser(user) {
  if (!user) return;
  clearCloudSubscriptions();
  const provider = getAuthProviderLabel(user);
  const profile = {
    name: user.displayName || state.profile.name || "You",
    handle: state.profile.handle && state.profile.handle !== "@solvry" ? state.profile.handle : `@${slugify((user.displayName || user.email || "solvry").split("@")[0])}`
  };
  state.profile = { ...state.profile, ...profile, id: "you" };
  state.account = {
    signedIn: true,
    provider,
    email: user.email || "",
    uid: user.uid,
    backend: "cloud"
  };
  try {
    await loadCloudState(user.uid);
    await persistCloudState();
    subscribeFriendRequests(user.uid);
    await refreshAcceptedFriends();
    elements.accountDialog.close();
    saveState();
    render();
  } catch (error) {
    cloudBackend.error = error.message || "Could not finish account sync.";
    updateAccountStatus();
    renderFriendSync();
  }
}

function getAuthProviderLabel(user) {
  const providerId = user.providerData?.[0]?.providerId || "";
  if (providerId.includes("google")) return "Google";
  if (providerId.includes("apple")) return "Apple";
  return "Solvry";
}

async function loadCloudState(uid) {
  const { doc, getDoc } = cloudBackend.modules.firestore;
  cloudBackend.applyingRemote = true;
  try {
    const snap = await getDoc(doc(cloudBackend.db, "users", uid));
    if (!snap.exists()) return;
    const remote = snap.data();
    state.profile = { ...state.profile, ...(remote.profile || {}) };
    state.friends = Array.isArray(remote.friends) ? remote.friends : state.friends;
    state.pinnedGameIds = Array.isArray(remote.pinnedGameIds) ? remote.pinnedGameIds : state.pinnedGameIds;
    state.entries = mergeEntries(state.entries, remote.entries || {});
    state.games = mergeCustomGames(state.games, remote.customGames);
  } finally {
    cloudBackend.applyingRemote = false;
  }
}

function serializeCloudState() {
  const ownEntries = Object.fromEntries(Object.entries(state.entries).map(([date, games]) => [date,
    Object.fromEntries(Object.entries(games).filter(([, entries]) => entries.you).map(([game, entries]) => [game, { you: entries.you }]))
  ]));
  return {
    profile: {
      name: state.profile.name,
      handle: state.profile.handle,
      handleLower: normalizeHandle(state.profile.handle)
    },
    friends: state.friends.filter((friend) => !isDemoFriend(friend)),
    entries: ownEntries,
    customGames: state.games.filter((game) => game.source === "custom"),
    pinnedGameIds: state.pinnedGameIds,
    updatedAt: new Date().toISOString()
  };
}

function queueCloudSave() {
  if (!cloudFriendsAvailable() || cloudBackend.applyingRemote) return;
  window.clearTimeout(cloudBackend.saveTimer);
  cloudBackend.saveTimer = window.setTimeout(() => {
    persistCloudState().catch((error) => {
      cloudBackend.error = error.message || "Could not save to Solvry Cloud.";
      renderFriendSync();
    });
  }, 420);
}

async function persistCloudState() {
  if (!cloudFriendsAvailable()) return;
  const { doc, setDoc } = cloudBackend.modules.firestore;
  await setDoc(doc(cloudBackend.db, "users", state.account.uid), serializeCloudState(), { mergeFields: ["profile", "friends", "entries", "customGames", "pinnedGameIds", "updatedAt"] });
  cloudBackend.error = "";
}

function clearCloudSubscriptions() {
  window.clearTimeout(cloudBackend.saveTimer);
  cloudBackend.unsubscribers.forEach((unsubscribe) => unsubscribe?.());
  cloudBackend.unsubscribers = [];
}

function subscribeFriendRequests(uid) {
  const { collection, onSnapshot, query, where } = cloudBackend.modules.firestore;
  const requests = collection(cloudBackend.db, "friendRequests");
  const incoming = onSnapshot(query(requests, where("toUid", "==", uid)), (snapshot) => {
    state.friendRequests.incoming = snapshot.docs.map(requestSnapshotToState);
    applyAcceptedRequests();
    refreshSocialViews();
  }, friendSubscriptionError);
  const outgoing = onSnapshot(query(requests, where("fromUid", "==", uid)), (snapshot) => {
    state.friendRequests.outgoing = snapshot.docs.map(requestSnapshotToState);
    applyAcceptedRequests();
    refreshSocialViews();
  }, friendSubscriptionError);
  cloudBackend.unsubscribers.push(incoming, outgoing);
}

function friendSubscriptionError() {
  setFriendStatus("Couldn't refresh friend requests. Check your connection and try signing in again.", true);
}

function requestSnapshotToState(snapshot) {
  return { id: snapshot.id, ...snapshot.data() };
}

function applyAcceptedRequests() {
  const requests = [...(state.friendRequests.incoming || []), ...(state.friendRequests.outgoing || [])];
  requests.filter((request) => ["rejected", "cancelled", "removed"].includes(request.status)).forEach((request) => {
    const uid = request.fromUid === state.account.uid ? request.toUid : request.fromUid;
    state.friends = state.friends.filter((friend) => friend.uid !== uid);
  });
  [...(state.friendRequests.incoming || []), ...(state.friendRequests.outgoing || [])]
    .filter((request) => request.status === "accepted")
    .forEach((request) => {
      const friend = request.fromUid === state.account.uid
        ? { uid: request.toUid, ...(request.toProfile || {}) }
        : { uid: request.fromUid, ...(request.fromProfile || {}) };
      addOrUpdateFriend({
        id: friend.uid,
        uid: friend.uid,
        name: friend.name || friend.handle || "Friend",
        handle: friend.handle || "@friend",
        ownerUid: state.account.uid,
        status: "accepted"
      });
    });
  saveState();
}

async function handleFriendSubmit() {
  const name = elements.friendNameInput.value.trim();
  const handle = elements.friendHandleInput.value.trim();
  return runFriendAction(async () => {
    if (cloudFriendsAvailable()) {
      await sendCloudFriendRequest(name, handle);
      setFriendStatus("Friend request sent. They'll appear in your rankings once they accept.");
    } else {
      if (!name) throw new Error("Enter your friend's name.");
      const normalized = normalizeHandle(handle || slugify(name) || uniqueId("friend", state.friends.map((friend) => normalizeHandle(friend.handle))));
      if (normalized === normalizeHandle(state.profile.handle)) throw new Error("That's your own handle. Enter a friend's handle.");
      if (state.friends.some((friend) => !isDemoFriend(friend) && normalizeHandle(friend.handle) === normalized)) throw new Error("That friend is already in your list.");
      const previous = structuredClone(state.friends);
      addOrUpdateFriend({
        id: uniqueId(`local-${slugify(name)}`, state.friends.map((friend) => friend.id)),
        name, handle: `@${normalized}`, status: "local"
      });
      try { saveState(); } catch { state.friends = previous; throw new Error("Couldn't save your friend on this device. Try again."); }
      setFriendStatus(`${name} added on this device. No invitation was sent; their scores won't sync yet.`);
    }
    elements.friendForm.reset();
  });
}

async function sendCloudFriendRequest(name, handle) {
  const normalizedHandle = normalizeHandle(handle);
  if (!normalizedHandle) throw new Error("Enter a friend's Solvry handle to send a request.");
  if (normalizedHandle === normalizeHandle(state.profile.handle)) throw new Error("You can't send yourself a friend request.");
  const { collection, doc, getDocs, query, runTransaction, where } = cloudBackend.modules.firestore;
  const users = await getDocs(query(collection(cloudBackend.db, "users"), where("profile.handleLower", "==", normalizedHandle)));
  const matches = users.docs.filter((item) => item.id !== state.account.uid);
  if (!matches.length) throw new Error(`No Solvry account found for @${normalizedHandle}. Check the handle with your friend.`);
  if (matches.length !== 1) throw new Error("More than one account uses that handle. Your friend needs a unique handle first.");
  const target = matches[0];

  const requestId = [state.account.uid, target.id].sort().join("__");
  const targetProfile = target.data().profile || {};
  const ref = doc(cloudBackend.db, "friendRequests", requestId);
  await runTransaction(cloudBackend.db, async (transaction) => {
    const existing = await transaction.get(ref);
    const status = existing.exists() ? existing.data().status : "";
    if (status === "accepted") throw new Error("You're already connected with this friend.");
    if (status === "pending") throw new Error("A request is already pending. Check your Requests tab.");
    transaction.set(ref, {
    fromUid: state.account.uid,
    toUid: target.id,
    fromProfile: { name: state.profile.name, handle: state.profile.handle },
    toProfile: { name: targetProfile.name || name || "Friend", handle: targetProfile.handle || `@${normalizedHandle}` },
    status: "pending",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
    });
  });
  cloudBackend.error = "";
}

async function handleFriendRequestAction(action, requestId) {
  return runFriendAction(async () => {
    await updateFriendRequest(action, requestId);
    if (action === "accept") await refreshAcceptedFriends();
    setFriendStatus({ accept: "Friend accepted. Their available scores are now in your rankings.", reject: "Request declined.", cancel: "Request cancelled." }[action] || "Connection updated.");
  });
}

function friendRequestStatus(action, request, uid) {
  const incoming = request.toUid === uid;
  const outgoing = request.fromUid === uid;
  if (request.status === "pending") {
    if (incoming && action === "accept") return "accepted";
    if (incoming && action === "reject") return "rejected";
    if (outgoing && action === "cancel") return "cancelled";
  }
  if (request.status === "accepted" && (incoming || outgoing) && action === "remove") return "removed";
  throw new Error("That request has changed or isn't yours to update. Refresh and try again.");
}

async function updateFriendRequest(action, requestId) {
  if (!cloudFriendsAvailable() || !requestId) throw new Error("Sign in to manage friend requests.");
  const { doc, runTransaction } = cloudBackend.modules.firestore;
  const ref = doc(cloudBackend.db, "friendRequests", requestId);
  const updated = await runTransaction(cloudBackend.db, async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists()) throw new Error("That request is no longer available.");
    const request = snapshot.data();
    const status = friendRequestStatus(action, request, state.account.uid);
    transaction.update(ref, { status, updatedAt: new Date().toISOString() });
    return { ...request, id: requestId, status };
  });
  const key = updated.toUid === state.account.uid ? "incoming" : "outgoing";
  state.friendRequests[key] = [...state.friendRequests[key].filter((request) => request.id !== requestId), updated];
  applyAcceptedRequests();
}

async function refreshAcceptedFriends() {
  if (!cloudBackend.ready || !state.account?.uid) return;
  const accepted = visibleFriends().filter((friend) => friend.uid && friend.status === "accepted");
  await Promise.all(accepted.map((friend) => loadFriendEntries(friend)));
}

async function loadFriendEntries(friend) {
  const { doc, getDoc } = cloudBackend.modules.firestore;
  const snap = await getDoc(doc(cloudBackend.db, "users", friend.uid));
  if (!snap.exists()) { mergeFriendEntries(friend.id, {}); return; }
  state.games = mergeCustomGames(state.games, snap.data().customGames);
  mergeFriendEntries(friend.id, snap.data().entries || {});
}

function mergeFriendEntries(friendId, entries) {
  Object.values(state.entries).forEach((day) => Object.values(day).forEach((game) => { delete game[friendId]; }));
  Object.entries(entries).forEach(([dateKey, dayEntries]) => {
    Object.entries(dayEntries || {}).forEach(([gameId, gameEntries]) => {
      const entry = gameEntries?.you;
      if (!entry) return;
      state.entries[dateKey] ||= {};
      state.entries[dateKey][gameId] ||= {};
      state.entries[dateKey][gameId][friendId] = entry;
    });
  });
}

function mergeEntries(localEntries, remoteEntries) {
  const merged = structuredClone(remoteEntries || {});
  Object.entries(localEntries || {}).forEach(([dateKey, dayEntries]) => {
    merged[dateKey] ||= {};
    Object.entries(dayEntries || {}).forEach(([gameId, entries]) => {
      merged[dateKey][gameId] = { ...(merged[dateKey][gameId] || {}), ...entries };
    });
  });
  return merged;
}

function addOrUpdateFriend(friend) {
  const existingIndex = state.friends.findIndex((item) => (friend.id && item.id === friend.id) || (friend.uid && item.uid === friend.uid) || (!isDemoFriend(item) && !friend.uid && !item.uid && normalizeHandle(friend.handle) && normalizeHandle(item.handle) === normalizeHandle(friend.handle)));
  if (existingIndex >= 0) {
    state.friends[existingIndex] = { ...state.friends[existingIndex], ...friend };
  } else {
    state.friends.push(friend);
  }
}

function normalizeHandle(value) {
  return String(value || "").trim().toLowerCase().replace(/^@/, "");
}

function cloudFriendsAvailable() {
  return !!(cloudBackend.ready && state.account?.uid && cloudBackend.auth?.currentUser?.uid === state.account.uid);
}

function isDemoFriend(friend) {
  const samples = { mira: "mirasolves", jay: "jayplaysdaily", nolan: "gridnolan" };
  return friend.status === "demo" || (!friend.uid && samples[friend.id] && samples[friend.id] === normalizeHandle(friend.handle));
}

function visibleFriends() {
  return state.friends.filter((friend) => {
    if (isDemoFriend(friend)) return !!state.showDemoFriends;
    if (friend.uid) {
      const verifiedOwner = friend.ownerUid === state.account.uid || (!friend.ownerUid && [...(state.friendRequests.incoming || []), ...(state.friendRequests.outgoing || [])].some((request) => request.status === "accepted" && [request.fromUid, request.toUid].includes(state.account.uid) && [request.fromUid, request.toUid].includes(friend.uid)));
      return cloudFriendsAvailable() && friend.status === "accepted" && verifiedOwner;
    }
    return !["pending", "removed", "rejected"].includes(friend.status);
  });
}

function setFriendStatus(message, error = false) {
  elements.friendStatus.textContent = message;
  elements.friendStatus.className = `friend-status${error ? " error" : ""}`;
}

async function runFriendAction(action) {
  if (friendBusy) return;
  friendBusy = true;
  setFriendStatus("Working…");
  renderFriendSync();
  try { await action(); } catch (error) {
    setFriendStatus(error.code ? "Couldn't connect to your friends. Check your connection and try again." : error.message || "Couldn't complete that action. Try again.", true);
  } finally {
    friendBusy = false;
    refreshSocialViews();
  }
}

function refreshSocialViews() {
  renderFriendSync();
  renderScoreboards(getActiveGame());
  renderAnswers();
  renderQuickGames();
  renderGameList();
  renderHome();
  const count = visibleFriends().filter((friend) => state.entries[state.selectedDate]?.[state.activeGameId]?.[friend.id]).length;
  elements.friendCompletion.textContent = `${count} friend${count === 1 ? "" : "s"} done`;
}

function renderFriendSync() {
  const connected = cloudFriendsAvailable();
  const friends = visibleFriends();
  const incoming = connected ? (state.friendRequests.incoming || []).filter((request) => request.status === "pending") : [];
  const outgoing = connected ? (state.friendRequests.outgoing || []).filter((request) => request.status === "pending") : [];
  elements.friendSync.innerHTML = `<article class="sync-card">
    <header><strong>${connected ? "Connected friends" : "Saved on this device"}</strong><span class="sync-pill">${connected ? "Online" : "Local only"}</span></header>
    <small>${connected ? "Send requests using a friend's handle. Refresh to load their latest scores." : cloudBackend.ready ? "Sign in to send requests and compare scores across devices. Local friends don't receive invitations." : "Online friendships aren't enabled yet. Local friends stay on this device; their scores won't sync. Try sample friends to preview the rankings."}</small>
    ${cloudBackend.error ? '<small>Sync is unavailable right now. Your saved scores are still on this device.</small>' : ""}
  </article>`;
  elements.friendsCount.textContent = `${friends.filter((friend) => !isDemoFriend(friend)).length} friend${friends.filter((friend) => !isDemoFriend(friend)).length === 1 ? "" : "s"}`;
  elements.showDemoFriends.checked = !!state.showDemoFriends;
  elements.copyHandleButton.hidden = !connected;
  elements.refreshFriendsButton.disabled = !connected || friendBusy;
  elements.refreshFriendsButton.title = connected ? "Refresh friend scores" : "Available when online friends are connected";
  elements.friendNameInput.closest("label").hidden = connected;
  elements.friendNameInput.required = !connected;
  elements.friendHandleInput.required = connected;
  elements.friendSubmitButton.disabled = friendBusy;
  elements.friendSubmitButton.textContent = connected ? "Send request" : "Add local friend";
  elements.addFriendSummary.textContent = connected ? "Find a friend by handle" : "Add a local friend";
  elements.requestsTab.textContent = `Requests${incoming.length ? ` (${incoming.length})` : ""}`;
  const search = elements.friendSearch.value.trim().toLowerCase();
  const matches = friends.filter((friend) => `${friend.name} ${friend.handle}`.toLowerCase().includes(search));
  elements.friendRoster.innerHTML = matches.length ? matches.map((friend) => `
    <article class="friend-person"><span><strong>${escapeHtml(friend.name)}</strong><small>${escapeHtml(friend.handle)} · ${isDemoFriend(friend) ? "Sample" : friend.uid ? "Connected" : "Device only"}</small></span>
    ${isDemoFriend(friend) ? '<span class="pill">Sample</span>' : `<button type="button" class="ghost-button" data-remove-friend="${escapeHtml(friend.id)}" aria-label="Remove ${escapeHtml(friend.name)}" ${friendBusy ? "disabled" : ""}>Remove</button>`}</article>
  `).join("") : `<p class="social-empty">${search ? "No matching friends. Try a name or handle." : connected ? "No friends added yet. Send a request using a friend's handle below." : "No friends added yet. Add a local friend below, or enable sample friends to preview rankings."}</p>`;
  elements.friendRequests.innerHTML = !connected ? '<p class="social-empty">Real requests need online sign-in. Local friends are saved only on this device.</p>' : [...incoming, ...outgoing].map((request) => {
    const received = request.toUid === state.account.uid;
    const profile = received ? request.fromProfile : request.toProfile;
    const action = (value, label) => `<button type="button" class="ghost-button" data-friend-action="${value}" data-request-id="${escapeHtml(request.id)}" ${friendBusy ? "disabled" : ""}>${label}</button>`;
    return `<article class="sync-card"><header><strong>${escapeHtml(profile?.name || "Friend")}</strong><span class="sync-pill">${received ? "Received" : "Sent"}</span></header><small>${escapeHtml(profile?.handle || "")}</small><div class="request-actions">${received ? action("accept", "Accept") + action("reject", "Decline") : action("cancel", "Cancel request")}</div></article>`;
  }).join("") || '<p class="social-empty">No pending requests. Find a friend by handle below.</p>';
}

function renderCurrentResult(game, entry) {
  const summary = entry
    ? `${entry.result} · ${entry.score || defaultScoreLabel(entry.result)}`
    : "No result saved yet";
  const detail = entry
    ? entry.note || (entry.reveal ? "Answer reveal is on." : "Answer reveal is off.")
    : `Example score: ${scoreStyleExample(game)}`;
  elements.currentResult.innerHTML = `
    ${gameLogo(game)}
    <span>
      <strong>${escapeHtml(summary)}</strong>
      <span>${escapeHtml(detail)}</span>
    </span>
    <span class="pill">${entry?.source === "manual" ? "Manual" : entry ? "Saved" : "Open"}</span>
  `;
}

function renderSolvryGame(game) {
  if (!isPlayableSolvryGame(game)) {
    elements.solvryGame.hidden = true;
    elements.solvryGame.innerHTML = "";
    return;
  }

  elements.solvryGame.hidden = false;
  const play = getSolvryPlay(game);
  elements.solvryGame.innerHTML = play.kind === "holes" ? renderHolesBoard(play) : renderHoopsBoard(play);
}

function renderHolesBoard(play) {
  if (play.completed) return renderGolfResults(play);
  if (!play.started) return renderGolfStart(play);

  const hole = getCurrentGolfHole(play);
  if (play.showHoleCard) return renderGolfHoleCard(play, hole);

  const phase = play.shotPhase || "scouting";
  const remaining = Math.round(yardsBetween(play.ball, hole.pin, hole));
  const selectedClub = getGolfClub(play.selectedClubId);
  const displayAimAngle = phase === "aiming" ? getActiveAimAngle(play) : play.lockedAimAngle ?? play.aimAngle;
  const shotContext = getGolfShotContext(play, hole, selectedClub, displayAimAngle);
  const cameraAngle = play.cameraAnchorAngle ?? play.aimCenterAngle ?? play.aimAngle;
  const cameraContext = getGolfShotContext(play, hole, selectedClub, cameraAngle);
  const target = shotContext.aimEndpoint;
  const scoreLabel = formatRelativeScore(getGolfRelativeScore(play));
  const showClubControls = !["power-locked", "ball-flight", "shot-result", "hole-complete"].includes(phase);

  return `
    <div class="daily-golf" data-shot-phase="${escapeHtml(phase)}">
      ${renderGolfGameHeader(play)}
      ${renderGolfScoreStrip(play)}
      <div class="daily-golf-board">
        <section class="play-card primary golf-map-card">
          <div class="golf-hud">
            <div class="golf-stat"><span>Hole ${hole.number} · Par ${hole.par}</span><strong>${remaining} yds</strong></div>
            <div class="golf-stat"><span>Wind</span><strong>${hole.wind.speed} mph ${windArrow(hole.wind.direction)}</strong></div>
          </div>
          ${renderGolfCourseSvg(play, hole, target, displayAimAngle, phase, cameraContext)}
          <div class="shot-summary">
            <span><strong>${surfaceLabel(play.currentSurface)} · shot ${play.holeStrokes + 1}</strong><em>${remaining} yds to pin</em></span>
            <small>${escapeHtml(play.lastShot ? play.lastShot.summary : play.message)}</small>
          </div>
        </section>
        <section class="play-card golf-controls">
          ${showClubControls ? `<div class="golf-club-section">
            <label class="meter-label"><span>Club</span><span>${escapeHtml(selectedClub.name)}</span></label>
            <div class="club-grid">
              ${GOLF_CLUBS.map((club) => `
                <button class="club-button${club.id === selectedClub.id ? " active" : ""}" type="button" data-play-action="club:${club.id}" ${!["scouting", "aiming"].includes(phase) ? "disabled" : ""}>
                  <strong>${club.label}</strong>
                  <span>${club.max}</span>
                </button>
              `).join("")}
            </div>
          </div>` : ""}
          ${renderGolfShotControls(play, hole, selectedClub, phase)}
        </section>
      </div>
    </div>
  `;
}

function renderGolfShotControls(play, hole, selectedClub, phase) {
  if (phase === "aiming") {
    return `
      <div class="shot-stage swing-stage">
        <strong>Tap to lock aim</strong>
      </div>
    `;
  }

  if (phase === "aim-locked") {
    return `
      <div class="shot-stage locked">
        <strong>Aim locked</strong>
        <p>Set power next.</p>
      </div>
    `;
  }

  if (phase === "power") {
    const window = getPowerWindow(play, hole, selectedClub);
    return `
      <div class="shot-stage swing-stage">
        ${renderGolfPowerMeter(window, true)}
        <strong>Tap to lock power</strong>
      </div>
    `;
  }

  if (phase === "power-locked" || phase === "ball-flight" || phase === "shot-result") {
    return `
      <div class="shot-stage locked">
        <strong>${phase === "power-locked" ? "Power locked" : phase === "shot-result" ? "Settling" : "Swinging"}</strong>
        <p>${phase === "power-locked" ? "Watch the shot." : phase === "shot-result" ? "Camera moving to the next lie." : "Controls hidden during flight."}</p>
      </div>
    `;
  }

  if (phase === "hole-complete") {
    const feedback = play.holeCompleteFeedback;
    const scoreBadge = feedback ? formatRelativeScore(feedback.relative) : "✓";
    return `
      <div class="shot-stage locked hole-complete-stage">
        <span class="score-badge">${escapeHtml(scoreBadge)}</span>
        <strong>${escapeHtml(feedback?.label || "Hole complete")}</strong>
        <p>${feedback?.strokes || play.holeStrokes} strokes${feedback?.putts ? ` · ${feedback.putts} putt${feedback.putts === 1 ? "" : "s"}` : feedback?.putts === 0 ? " · holed out" : ""}</p>
      </div>
    `;
  }

  return `
    <div class="shot-stage">
      <div class="play-actions">
        <button class="play-button main tap-panel" type="button" data-play-action="take-shot">Take shot</button>
      </div>
    </div>
  `;
}

function renderGolfPowerMeter(window, moving) {
  const greenEnd = window.start + window.width;
  const warmStart = clamp(window.start - 14, 0, 100);
  const warmEnd = clamp(greenEnd + 14, 0, 100);
  return `
    <div class="power-meter${moving ? " moving" : ""}" style="--green-start:${window.start};--green-width:${window.width};--green-end:${greenEnd};--green-center:${window.center};--green-warm-start:${warmStart};--green-warm-end:${warmEnd};--power-marker:${window.marker}">
      <span class="power-marker" aria-hidden="true"></span>
    </div>
  `;
}

function renderGolfStart(play) {
  const course = play.course;
  return `
    <div class="daily-golf">
      ${renderGolfGameHeader(play)}
      ${renderGolfScoreStrip(play)}
      <section class="golf-hero-card">
        <div class="play-topline">
          <div>
            <p class="eyebrow">Ranked daily round</p>
            <h3>${escapeHtml(course.name)}</h3>
          </div>
          <span class="pill">Seed ${escapeHtml(course.dailyNumber)}</span>
        </div>
        <div class="golf-hero-grid">
          <div class="golf-stat"><span>Format</span><strong>9 holes</strong></div>
          <div class="golf-stat"><span>Course par</span><strong>${course.par}</strong></div>
          <div class="golf-stat"><span>Theme</span><strong>${escapeHtml(course.environment)}</strong></div>
        </div>
        <p class="import-copy">One official ranked round for ${escapeHtml(state.selectedDate)}. The course, wind, hazards, and pins are deterministic, so every player gets the same challenge.</p>
        <button class="primary-button" type="button" data-play-action="start-round">Start ranked round</button>
      </section>
    </div>
  `;
}

function renderGolfHoleCard(play, hole) {
  return `
    <div class="daily-golf">
      ${renderGolfGameHeader(play)}
      ${renderGolfScoreStrip(play)}
      <section class="hole-card">
        <div class="play-topline">
          <div>
            <p class="eyebrow">Hole ${hole.number} · Par ${hole.par}</p>
            <h3>${escapeHtml(hole.name)}</h3>
          </div>
          <span class="pill">${hole.distance} yds</span>
        </div>
        <div class="hole-card-grid">
          <div class="golf-stat"><span>Wind</span><strong>${hole.wind.speed} mph ${windArrow(hole.wind.direction)}</strong></div>
          <div class="golf-stat"><span>Primary hazard</span><strong>${escapeHtml(hole.primaryHazard)}</strong></div>
          <div class="golf-stat"><span>Green</span><strong>${escapeHtml(hole.greenDifficulty)}</strong></div>
        </div>
        <p class="import-copy">${escapeHtml(hole.summary)}</p>
        <button class="primary-button" type="button" data-play-action="start-hole">Tap to play</button>
      </section>
    </div>
  `;
}

function renderGolfResults(play) {
  const relative = getGolfRelativeScore(play);
  const recap = getGolfRoundRecap(play);
  const birdies = play.holeResults.filter((result) => result.relative === -1).length;
  const eagles = play.holeResults.filter((result) => result.relative <= -2).length;
  const pars = play.holeResults.filter((result) => result.relative === 0).length;
  const bogeys = play.holeResults.filter((result) => result.relative > 0).length;
  const penalties = play.holeResults.reduce((total, result) => total + (result?.penaltyStrokes || 0), 0);
  return `
    <div class="daily-golf">
      ${renderGolfGameHeader(play)}
      ${renderGolfScoreStrip(play)}
      <section class="results-card">
        <div class="round-recap-hero">
          <div>
            <span>Daily Golf ${escapeHtml(play.course.dailyNumber)}</span>
            <strong>${formatRelativeScore(relative)}</strong>
            <em>${play.totalStrokes} strokes on ${escapeHtml(play.course.name)}</em>
          </div>
          <span class="round-recap-badge">${play.totalStrokes}<small>strokes</small></span>
        </div>
        <div class="recap-highlights">
          <div class="recap-chip"><span>Best hole</span><strong>${escapeHtml(recap.bestHole)}</strong></div>
          <div class="recap-chip"><span>Toughest</span><strong>${escapeHtml(recap.toughestHole)}</strong></div>
          <div class="recap-chip"><span>Putting</span><strong>${escapeHtml(recap.putting)}</strong></div>
        </div>
        <div class="results-grid">
          <div class="golf-stat"><span>Total strokes</span><strong>${play.totalStrokes}</strong></div>
          <div class="golf-stat"><span>Course par</span><strong>${play.course.par}</strong></div>
          <div class="golf-stat"><span>Birdies</span><strong>${birdies}</strong></div>
          <div class="golf-stat"><span>Eagles</span><strong>${eagles}</strong></div>
          <div class="golf-stat"><span>Pars</span><strong>${pars}</strong></div>
          <div class="golf-stat"><span>Bogeys</span><strong>${bogeys}</strong></div>
          <div class="golf-stat"><span>Penalties</span><strong>${penalties}</strong></div>
        </div>
        ${renderGolfScorecardTable(play)}
        <div class="play-actions">
          <button class="play-button" type="button" data-play-action="share-round">Share</button>
          <button class="play-button" type="button" data-play-action="practice">Practice</button>
        </div>
      </section>
    </div>
  `;
}

function renderGolfGameHeader(play) {
  return `
    <header class="golf-game-header">
      <div>
        <strong>Solvry Holes</strong>
        <span>${escapeHtml(play.course.name)} · Ranked</span>
      </div>
      <span class="pill">${formatRelativeScore(getGolfRelativeScore(play))}</span>
    </header>
  `;
}

function renderGolfScoreStrip(play) {
  return `
    <div class="golf-score-strip">
      ${play.course.holes.map((hole, index) => {
        const result = play.holeResults[index];
        return `
          <span class="golf-score-hole${index === play.holeIndex ? " current" : ""}${result ? " done" : ""}">
            <strong>${hole.number}</strong>
            <span>${result ? formatRelativeScore(result.relative) : "·"}</span>
            <small>${hole.par}</small>
          </span>
        `;
      }).join("")}
    </div>
  `;
}

function renderGolfScorecardTable(play) {
  return `
    <table class="scorecard-table">
      <thead><tr><th>Hole</th><th>Par</th><th>Strokes</th><th>Putts</th><th>Score</th></tr></thead>
      <tbody>
        ${play.course.holes.map((hole, index) => {
          const result = play.holeResults[index];
          return `<tr><td>${hole.number}</td><td>${hole.par}</td><td>${result?.strokes || "-"}</td><td>${result?.putts ?? "-"}</td><td>${result ? formatRelativeScore(result.relative) : "-"}</td></tr>`;
        }).join("")}
      </tbody>
    </table>
  `;
}

function renderGolfCourseSvg(play, hole, target, displayAimAngle, phase, cameraContext) {
  const ball = play.ball;
  const camera = getGolfCameraFrame(play, hole, cameraContext, phase);
  const viewBox = formatGolfCameraViewBox(camera);
  const previousViewBox = play.previousCameraFrame ? formatGolfCameraViewBox(play.previousCameraFrame) : "";
  const animateCamera = previousViewBox && previousViewBox !== viewBox
    ? `<animate attributeName="viewBox" from="${previousViewBox}" to="${viewBox}" dur="420ms" fill="freeze" calcMode="spline" keyTimes="0;1" keySplines="0.2 0.76 0.24 1"></animate>`
    : "";
  const puttZones = getGolfPuttZones(hole);
  const landingRadius = getGolfLandingRadius(play, hole);
  const ballMarker = renderGolfBallMarker(ball);
  const flightPath = renderGolfFlightPath(play.flightPreview, phase);
  const restingBallMarker = phase === "ball-flight" && play.flightPreview ? "" : ballMarker;
  const centerAngle = play.aimCenterAngle ?? play.aimAngle;
  const sweepRange = getAimSweepRange(play, hole);
  const sweepDuration = getAimSweepDuration(play, hole);
  const visibleLineLength = Math.min(
    getVisibleAimLineLength(ball, centerAngle - sweepRange),
    getVisibleAimLineLength(ball, centerAngle),
    getVisibleAimLineLength(ball, centerAngle + sweepRange)
  );
  const lineLength = Math.min(visibleLineLength, Math.max(8, distance(ball, target)));
  const lineEnd = { x: ball.x, y: ball.y - lineLength };
  const aimLine = phase === "aiming"
    ? `<g class="golf-aim-layer" transform="rotate(${centerAngle} ${ball.x} ${ball.y})"><animateTransform attributeName="transform" type="rotate" values="${centerAngle} ${ball.x} ${ball.y};${centerAngle + sweepRange} ${ball.x} ${ball.y};${centerAngle} ${ball.x} ${ball.y};${centerAngle - sweepRange} ${ball.x} ${ball.y};${centerAngle} ${ball.x} ${ball.y}" keyTimes="0;0.25;0.5;0.75;1" dur="${sweepDuration}ms" repeatCount="indefinite"></animateTransform><line x1="${ball.x}" y1="${ball.y}" x2="${lineEnd.x}" y2="${lineEnd.y}" stroke="#fffefa" stroke-width="2.1" stroke-linecap="round" opacity="0.9"></line><line x1="${ball.x}" y1="${ball.y}" x2="${lineEnd.x}" y2="${lineEnd.y}" stroke="#9c2f23" stroke-width="1.08" stroke-linecap="round"></line><circle cx="${lineEnd.x}" cy="${lineEnd.y}" r="2.75" fill="#ffe28a" stroke="#fffefa" stroke-width="0.9"></circle><circle cx="${lineEnd.x}" cy="${lineEnd.y}" r="2.75" fill="none" stroke="#141719" stroke-width="0.45"></circle></g>`
    : `<g class="golf-aim-layer"><line x1="${ball.x}" y1="${ball.y}" x2="${target.x}" y2="${target.y}" stroke="#fffefa" stroke-width="2.1" stroke-linecap="round" opacity="0.9"></line><line x1="${ball.x}" y1="${ball.y}" x2="${target.x}" y2="${target.y}" stroke="#9c2f23" stroke-width="1.08" stroke-linecap="round"></line><circle cx="${target.x}" cy="${target.y}" r="2.75" fill="#ffe28a" stroke="#fffefa" stroke-width="0.9"></circle><circle cx="${target.x}" cy="${target.y}" r="2.75" fill="none" stroke="#141719" stroke-width="0.45"></circle></g>`;
  const lockPulse = phase === "aim-locked"
    ? `<circle cx="${target.x}" cy="${target.y}" r="2.2" fill="#fffefa" stroke="#b12a1c" stroke-width="0.75" opacity="0.8"><animate attributeName="r" values="2.2;5.4;2.6" dur="0.5s" fill="freeze"></animate><animate attributeName="opacity" values="0.8;0.18;0" dur="0.5s" fill="freeze"></animate></circle>`
    : "";
  const fairwayFringe = fairwayPathWithWidth(hole, 7);
  const fairwayCore = fairwayPath(hole);
  return `
    <svg class="golf-course-map" viewBox="${viewBox}" preserveAspectRatio="xMidYMid meet" data-camera-mode="${camera.mode}" role="img" aria-label="${escapeHtml(hole.name)} course map">
      ${animateCamera}
      <defs>
        <filter id="course-shadow-${hole.number}" x="-20%" y="-20%" width="140%" height="140%">
          <feDropShadow dx="0" dy="0.8" stdDeviation="0.65" flood-color="#273c32" flood-opacity="0.18"></feDropShadow>
        </filter>
        <pattern id="rough-texture-${hole.number}" width="7" height="7" patternUnits="userSpaceOnUse" patternTransform="rotate(18)">
          <rect width="7" height="7" fill="transparent"></rect>
          <path d="M1 6 l1.2 -2.2 M4.6 5.5 l0.9 -2" stroke="#4f7551" stroke-width="0.22" opacity="0.24" stroke-linecap="round"></path>
        </pattern>
        <pattern id="fairway-stripes-${hole.number}" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(18)">
          <rect width="10" height="10" fill="#a8d98a"></rect>
          <rect width="5" height="10" fill="#c2e8a0" opacity="0.78"></rect>
          <path d="M0 9 H10" stroke="#e8f7d6" stroke-width="0.18" opacity="0.36"></path>
        </pattern>
        <radialGradient id="green-glow-${hole.number}" cx="50%" cy="50%" r="55%">
          <stop offset="0%" stop-color="#f0f9df" stop-opacity="0.98"></stop>
          <stop offset="58%" stop-color="#beeaa7" stop-opacity="0.86"></stop>
          <stop offset="100%" stop-color="#78ac68" stop-opacity="0.38"></stop>
        </radialGradient>
        <linearGradient id="water-fill-${hole.number}" x1="0%" x2="100%" y1="0%" y2="100%">
          <stop offset="0%" stop-color="#bce6e6" stop-opacity="0.76"></stop>
          <stop offset="100%" stop-color="#5caec3" stop-opacity="0.84"></stop>
        </linearGradient>
        <radialGradient id="sand-fill-${hole.number}" cx="42%" cy="35%" r="76%">
          <stop offset="0%" stop-color="#f5e5ae"></stop>
          <stop offset="100%" stop-color="#d8bc75"></stop>
        </radialGradient>
        <radialGradient id="tee-fill-${hole.number}" cx="50%" cy="42%" r="64%">
          <stop offset="0%" stop-color="#fffefa"></stop>
          <stop offset="100%" stop-color="#d9dfd2"></stop>
        </radialGradient>
      </defs>
      <rect width="100" height="100" fill="${escapeHtml(hole.palette.rough)}"></rect>
      <rect width="100" height="100" fill="url(#rough-texture-${hole.number})" opacity="0.58"></rect>
      <rect width="100" height="100" fill="#fffefa" opacity="0.06"></rect>
      ${hole.treeZones.map((zone, index) => renderGolfTreeZone(zone, index)).join("")}
      ${hole.water.map((water, index) => renderGolfWater(water, index, hole.number)).join("")}
      <path d="${escapeHtml(fairwayFringe)}" fill="#8fbd7a" opacity="0.35"></path>
      <path d="${escapeHtml(fairwayCore)}" fill="url(#fairway-stripes-${hole.number})" opacity="0.94" filter="url(#course-shadow-${hole.number})"></path>
      <path d="${escapeHtml(fairwayCore)}" fill="none" stroke="#e9f6d4" stroke-width="0.55" opacity="0.28"></path>
      ${hole.cartPaths.map((path) => `<path d="${escapeHtml(path.d)}" fill="none" stroke="#d8cdb5" stroke-width="${path.width + 1.15}" stroke-linecap="round" opacity="0.3"></path><path d="${escapeHtml(path.d)}" fill="none" stroke="#eee4cf" stroke-width="${path.width}" stroke-linecap="round" opacity="0.68"></path>`).join("")}
      ${hole.bunkers.map((bunker, index) => renderGolfBunker(bunker, index, hole.number)).join("")}
      <g class="course-target-ring">
        <circle cx="${target.x}" cy="${target.y}" r="${landingRadius}" fill="#7fc3d8" opacity="0.13" stroke="#5fa6bd" stroke-width="0.32" stroke-dasharray="1.8 1.5"></circle>
        <circle cx="${target.x}" cy="${target.y}" r="${Math.max(4, landingRadius * 0.28)}" fill="#fffefa" opacity="0.26" stroke="#273c32" stroke-width="0.3" stroke-dasharray="1.2 1.2"></circle>
      </g>
      <circle cx="${hole.green.x}" cy="${hole.green.y}" r="${hole.green.r + 5.2}" fill="#8ec674" opacity="0.3"></circle>
      <circle cx="${hole.green.x}" cy="${hole.green.y}" r="${hole.green.r + 2.4}" fill="#d6f0bd" opacity="0.42"></circle>
      <circle cx="${hole.green.x}" cy="${hole.green.y}" r="${hole.green.r}" fill="url(#green-glow-${hole.number})" stroke="#6f9e64" stroke-width="0.38" filter="url(#course-shadow-${hole.number})"></circle>
      <path d="M ${hole.green.x - hole.green.r * 0.7} ${hole.green.y + 1.3} C ${hole.green.x - 2.5} ${hole.green.y - 2.3} ${hole.green.x + 2.4} ${hole.green.y + 3.7} ${hole.green.x + hole.green.r * 0.72} ${hole.green.y - 0.6}" fill="none" stroke="#fffefa" stroke-width="0.38" opacity="0.48"></path>
      <circle cx="${hole.pin.x}" cy="${hole.pin.y}" r="${puttZones.outer}" fill="none" stroke="#fffefa" stroke-width="0.42" stroke-dasharray="1.6 1.4" opacity="0.34"></circle>
      <circle cx="${hole.pin.x}" cy="${hole.pin.y}" r="${puttZones.two}" fill="none" stroke="#fffefa" stroke-width="0.55" opacity="0.5"></circle>
      <circle cx="${hole.pin.x}" cy="${hole.pin.y}" r="${puttZones.one}" fill="none" stroke="#224238" stroke-width="0.42" opacity="0.64"></circle>
      ${aimLine}
      ${lockPulse}
      <line x1="${ball.x}" y1="${ball.y}" x2="${target.x}" y2="${target.y}" stroke="#273c32" stroke-width="0.28" stroke-dasharray="2 2" opacity="0.26"></line>
      ${play.lastShot ? `<line x1="${play.lastShot.start.x}" y1="${play.lastShot.start.y}" x2="${play.lastShot.final.x}" y2="${play.lastShot.final.y}" stroke="#fffefa" stroke-width="1.05" opacity="0.78"></line>` : ""}
      ${flightPath}
      <circle cx="${target.x}" cy="${target.y}" r="2.4" fill="rgba(255, 254, 250, 0.24)" stroke="#273c32" stroke-width="0.46" stroke-dasharray="1.5 1.5"></circle>
      <g class="pin-flag">
        <ellipse cx="${hole.pin.x}" cy="${hole.pin.y + 0.35}" rx="1.75" ry="1.05" fill="#11211d" opacity="0.24"></ellipse>
        <circle cx="${hole.pin.x}" cy="${hole.pin.y}" r="1.14" fill="#1d332b"></circle>
        <circle cx="${hole.pin.x}" cy="${hole.pin.y}" r="0.62" fill="#cbead5"></circle>
        <path d="M ${hole.pin.x + 0.05} ${hole.pin.y + 0.2} v -6.6" fill="none" stroke="#263c32" stroke-width="0.46" stroke-linecap="round"></path>
        <path d="M ${hole.pin.x + 0.2} ${hole.pin.y - 6.3} C ${hole.pin.x + 2.1} ${hole.pin.y - 5.8} ${hole.pin.x + 3.2} ${hole.pin.y - 5} ${hole.pin.x + 4.8} ${hole.pin.y - 4.25} C ${hole.pin.x + 3.1} ${hole.pin.y - 3.55} ${hole.pin.x + 2.1} ${hole.pin.y - 2.9} ${hole.pin.x + 0.2} ${hole.pin.y - 2.4} Z" fill="#ee6e5b" stroke="#263c32" stroke-width="0.25"></path>
      </g>
      <ellipse cx="${hole.tee.x}" cy="${hole.tee.y}" rx="2.85" ry="1.9" fill="url(#tee-fill-${hole.number})" stroke="#273c32" stroke-width="0.32" opacity="0.86"></ellipse>
      ${restingBallMarker}
    </svg>
  `;
}

function renderGolfFlightPath(outcome, phase) {
  if (phase !== "ball-flight" || !outcome) return "";
  const start = outcome.start;
  const landing = outcome.landing;
  const final = outcome.final;
  const flightDistance = distance(start, landing);
  const apexY = Math.max(4, Math.min(start.y, landing.y) - clamp(flightDistance * 0.18, 8, 18));
  const controlOne = { x: start.x + (landing.x - start.x) * 0.26 - outcome.crossWind.x * 0.12, y: apexY };
  const controlTwo = { x: start.x + (landing.x - start.x) * 0.72 + outcome.crossWind.x * 0.48, y: apexY + 2.4 };
  const arc = `M ${start.x} ${start.y} C ${controlOne.x} ${controlOne.y} ${controlTwo.x} ${controlTwo.y} ${landing.x} ${landing.y}`;
  const hasRollout = distance(landing, final) > 1.2;
  const labelsClose = distance(landing, final) < 7;
  const rollout = hasRollout ? `M ${landing.x} ${landing.y} L ${final.x} ${final.y}` : "";
  const motionPath = `${arc}${hasRollout ? ` L ${final.x} ${final.y}` : ""}`;
  const carryLabel = `${Math.round(outcome.carryYards)}y carry`;
  const rolloutLabel = outcome.penalty
    ? "+1 drop"
    : hasRollout ? `${Math.round(outcome.rolloutYards)}y roll` : surfaceLabel(outcome.finalSurface);
  const combinedLabel = `${carryLabel} · ${rolloutLabel}`;
  return `
    <g class="golf-flight-preview" aria-hidden="true">
      <path class="flight-trail-shadow" d="${arc}" fill="none" stroke="#fffefa" stroke-width="1.25" opacity="0.72" stroke-linecap="round"></path>
      <path class="flight-trail-main" d="${arc}" fill="none" stroke="#9c2f23" stroke-width="0.62" opacity="0.82" stroke-linecap="round"></path>
      ${hasRollout ? `<path class="rollout-line" d="${rollout}" fill="none" stroke="#273c32" stroke-width="0.42" opacity="0.78" stroke-linecap="round"></path>` : ""}
      <circle class="landing-ring" cx="${landing.x}" cy="${landing.y}" r="3.8" fill="none" stroke="${outcome.penalty ? "#2f7fa3" : "#fffefa"}" stroke-width="0.7"></circle>
      ${hasRollout ? `<circle class="rollout-dot" cx="${final.x}" cy="${final.y}" r="1.55" fill="#fffefa" stroke="#141719" stroke-width="0.42"></circle>` : ""}
      <g class="shot-callout">
        ${labelsClose
          ? `<text x="${clamp(landing.x + 2.4, 8, 76)}" y="${clamp(landing.y - 3.5, 8, 92)}" fill="#17231f" font-size="2.72" font-weight="900">${escapeHtml(combinedLabel)}</text>`
          : `<text x="${clamp(landing.x + 2.8, 8, 84)}" y="${clamp(landing.y - 3.2, 8, 92)}" fill="#17231f" font-size="2.9" font-weight="900">${escapeHtml(carryLabel)}</text><text x="${clamp(final.x + 2.2, 8, 86)}" y="${clamp(final.y + 4.5, 8, 94)}" fill="#17231f" font-size="2.9" font-weight="900">${escapeHtml(rolloutLabel)}</text>`}
      </g>
      <circle class="flight-ball" r="1.55" fill="#fffefa" stroke="#141719" stroke-width="0.48">
        <animateMotion path="${motionPath}" dur="1.16s" fill="freeze" calcMode="spline" keyTimes="0;0.72;1" keySplines="0.18 0.78 0.2 1;0.16 0.7 0.28 1"></animateMotion>
        <animate attributeName="r" values="1.3;2.15;1.55" dur="1.16s" fill="freeze"></animate>
      </circle>
      <ellipse class="flight-shadow" rx="2.9" ry="0.85" fill="#273c32" opacity="0.22">
        <animateMotion path="M ${start.x} ${start.y + 2.5} L ${landing.x} ${landing.y + 1.65}${hasRollout ? ` L ${final.x} ${final.y + 1.15}` : ""}" dur="1.16s" fill="freeze"></animateMotion>
        <animate attributeName="opacity" values="0.12;0.28;0.2" dur="1.16s" fill="freeze"></animate>
      </ellipse>
    </g>
  `;
}

function renderGolfBallMarker(ball) {
  return `
    <g class="golf-ball-marker" aria-label="Golf ball">
      <circle cx="${ball.x}" cy="${ball.y}" r="4.1" fill="#fffefa" opacity="0.32"></circle>
      <circle cx="${ball.x}" cy="${ball.y}" r="2.55" fill="none" stroke="#141719" stroke-width="0.62" opacity="0.88"></circle>
      <circle cx="${ball.x}" cy="${ball.y}" r="1.9" fill="#fffefa" stroke="#141719" stroke-width="0.78"></circle>
      <circle cx="${ball.x - 0.55}" cy="${ball.y - 0.45}" r="0.18" fill="#cfd6d0"></circle>
      <circle cx="${ball.x + 0.45}" cy="${ball.y - 0.2}" r="0.16" fill="#cfd6d0"></circle>
      <circle cx="${ball.x - 0.05}" cy="${ball.y + 0.42}" r="0.15" fill="#cfd6d0"></circle>
    </g>
  `;
}

function renderGolfWater(water, index, holeNumber) {
  const shape = organicOvalPath(water, 0.18, index + 1);
  const waveY = water.y - water.ry * 0.2;
  return `
    <g class="course-water">
      <path d="${shape}" fill="url(#water-fill-${holeNumber})" opacity="0.86"></path>
      <path d="${shape}" fill="none" stroke="#e4f4ef" stroke-width="0.72" opacity="0.34"></path>
      <path class="course-water-wave" d="M ${water.x - water.rx * 0.62} ${waveY} C ${water.x - water.rx * 0.2} ${waveY - 1.4} ${water.x + water.rx * 0.18} ${waveY + 1.2} ${water.x + water.rx * 0.62} ${waveY - 0.3}" fill="none" stroke="#effff8" stroke-width="0.42" stroke-linecap="round"></path>
      <path class="course-water-wave" d="M ${water.x - water.rx * 0.42} ${water.y + water.ry * 0.32} C ${water.x - water.rx * 0.1} ${water.y + water.ry * 0.9} ${water.x + water.rx * 0.22} ${water.y + water.ry * 0.1} ${water.x + water.rx * 0.48} ${water.y + water.ry * 0.46}" fill="none" stroke="#effff8" stroke-width="0.32" stroke-linecap="round"></path>
    </g>
  `;
}

function renderGolfBunker(bunker, index, holeNumber) {
  const shape = organicOvalPath(bunker, 0.2, index + 6);
  return `
    <g class="course-bunker">
      <path d="${shape}" fill="url(#sand-fill-${holeNumber})" stroke="#bda462" stroke-width="0.34" opacity="0.95"></path>
      <path d="${shape}" fill="none" stroke="#fff4c9" stroke-width="0.45" opacity="0.42"></path>
      <path d="M ${bunker.x - bunker.rx * 0.45} ${bunker.y + 0.2} C ${bunker.x - 1.5} ${bunker.y - bunker.ry * 0.42} ${bunker.x + 1.5} ${bunker.y + bunker.ry * 0.44} ${bunker.x + bunker.rx * 0.48} ${bunker.y - 0.1}" fill="none" stroke="#b89e5d" stroke-width="0.25" opacity="0.4"></path>
    </g>
  `;
}

function renderGolfTreeZone(zone, index) {
  const base = `<ellipse cx="${zone.x}" cy="${zone.y}" rx="${zone.rx}" ry="${zone.ry}" fill="#315b3f" opacity="0.2"></ellipse>`;
  const trees = Array.from({ length: 10 }, (_, item) => {
    const angle = item * 2.38 + index * 0.9;
    const radius = 0.25 + ((item * 37 + index * 11) % 58) / 100;
    const x = zone.x + Math.cos(angle) * zone.rx * radius;
    const y = zone.y + Math.sin(angle) * zone.ry * radius;
    const size = 1.25 + ((item * 17 + index * 5) % 8) * 0.22;
    const fill = item % 3 === 0 ? "#6f9766" : item % 3 === 1 ? "#517b57" : "#8bac72";
    return `<g opacity="0.76"><ellipse cx="${x + 0.45}" cy="${y + 0.75}" rx="${size * 0.9}" ry="${size * 0.52}" fill="#273c32" opacity="0.1"></ellipse><circle cx="${x}" cy="${y}" r="${size}" fill="${fill}"></circle><circle cx="${x - size * 0.28}" cy="${y - size * 0.32}" r="${size * 0.34}" fill="#d5e8cf" opacity="0.58"></circle></g>`;
  }).join("");
  return `<g class="course-tree-zone">${base}${trees}</g>`;
}

function organicOvalPath(shape, wobble, phase) {
  const rx = shape.rx;
  const ry = shape.ry;
  const x = shape.x;
  const y = shape.y;
  const a = 0.552;
  const w1 = 1 + Math.sin(phase * 1.7) * wobble;
  const w2 = 1 + Math.cos(phase * 1.3) * wobble;
  const w3 = 1 - Math.sin(phase * 1.1) * wobble * 0.8;
  const w4 = 1 - Math.cos(phase * 1.9) * wobble * 0.7;
  return `M ${x} ${y - ry * w1} C ${x + rx * a * w2} ${y - ry * w1} ${x + rx * w2} ${y - ry * a * w2} ${x + rx * w2} ${y} C ${x + rx * w2} ${y + ry * a * w3} ${x + rx * a * w3} ${y + ry * w3} ${x} ${y + ry * w3} C ${x - rx * a * w4} ${y + ry * w3} ${x - rx * w4} ${y + ry * a * w4} ${x - rx * w4} ${y} C ${x - rx * w4} ${y - ry * a * w1} ${x - rx * a * w1} ${y - ry * w1} ${x} ${y - ry * w1} Z`;
}

function renderHoopsBoard(play) {
  const shot = play.shots[play.shotIndex];
  const complete = play.shots.every((item) => item.done);
  const nextDisabled = shot.done ? "" : "disabled";
  const finishDisabled = complete ? "" : "disabled";

  return `
    <div class="solvry-board">
      <section class="play-card primary">
        <div class="play-topline">
          <h3>Shot ${play.shotIndex + 1} of ${play.shots.length}</h3>
          <span class="pill">${play.totalPoints} point${play.totalPoints === 1 ? "" : "s"}</span>
        </div>
        <div class="court-view" style="--play-angle:${shot.angle}deg;--target-x:${shot.targetX}%;--target-y:${shot.targetY}%;--avatar-x:${play.aim}%;--avatar-y:${Math.max(18, 76 - play.power / 2)}px">
          <span class="shot-arc" aria-hidden="true"></span>
          <span class="play-target" aria-label="Rim">${shot.value}</span>
          <span class="play-avatar" aria-label="Shooter">●</span>
        </div>
        <p>${escapeHtml(shot.label)} · worth ${shot.value} point${shot.value === 1 ? "" : "s"}</p>
        <div class="meter-stack">
          ${renderPlayMeter("Aim", play.aim)}
          ${renderPlayMeter("Power", play.power)}
          ${renderPlayMeter("Release", play.release)}
        </div>
        <div class="play-result">${escapeHtml(play.message)}</div>
        <div class="play-actions three">
          <button class="play-button" type="button" data-play-action="aim-left">Aim left</button>
          <button class="play-button" type="button" data-play-action="aim-right">Aim right</button>
          <button class="play-button" type="button" data-play-action="power-up">Power up</button>
          <button class="play-button" type="button" data-play-action="power-down">Power down</button>
          <button class="play-button" type="button" data-play-action="release-early">Earlier</button>
          <button class="play-button" type="button" data-play-action="release-late">Later</button>
          <button class="play-button main" type="button" data-play-action="shoot" ${shot.done ? "disabled" : ""}>Shoot</button>
          <button class="play-button" type="button" data-play-action="next" ${nextDisabled}>Next shot</button>
          <button class="play-button" type="button" data-play-action="finish" ${finishDisabled}>Save score</button>
          <button class="play-button" type="button" data-play-action="reset">Reset</button>
        </div>
      </section>
      <section class="play-card">
        <h3>Shot chart</h3>
        <div class="play-grid">
          ${play.shots.map((item, index) => `
            <span class="play-tile${index === play.shotIndex ? " current" : ""}${item.done ? " done" : ""}">
              <strong>${index + 1}</strong>
              ${item.done ? `${item.points} pt${item.points === 1 ? "" : "s"}` : item.label}
            </span>
          `).join("")}
        </div>
        <p>Set aim, power, and release for each shot. Deeper shots are worth more, but the sweet spot is tighter.</p>
      </section>
    </div>
  `;
}

function renderPlayMeter(label, value) {
  const displayValue = Math.round(value);
  return `
    <div class="play-meter">
      <span class="meter-label"><span>${escapeHtml(label)}</span><span>${displayValue}</span></span>
      <span class="meter-track"><span class="meter-thumb" style="--meter-value:${displayValue}"></span></span>
    </div>
  `;
}

function handleSolvryPlayAction(action) {
  const game = getActiveGame();
  if (!isPlayableSolvryGame(game)) return;

  if (action === "reset") {
    delete state.solvryPlays[getSolvryPlayKey(game.id)];
    saveState();
    render();
    return;
  }

  const play = getSolvryPlay(game);
  if (play.kind === "holes") {
    handleHolesAction(play, action, game);
  } else {
    handleHoopsAction(play, action, game);
  }
  saveState();
  render();
}

function handleHolesAction(play, action, game) {
  if (action === "start-round" && !play.started) {
    play.started = true;
    play.roundStarted = true;
    play.startedAt = new Date().toISOString();
    startCurrentGolfHole(play);
    play.message = "Ranked round started. Bad shots count, so choose the target first.";
    syncGolfRoundState(play);
    return;
  }

  if (action === "start-hole") {
    startCurrentGolfHole(play);
    return;
  }

  if (action.startsWith("club:")) {
    const phase = play.shotPhase || "scouting";
    if (!["scouting", "aiming"].includes(phase)) return;
    const club = getGolfClub(action.split(":")[1]);
    play.selectedClubId = club.id;
    play.powerWindow = null;
    play.flightPreview = null;
    if (phase === "aiming") {
      setGolfAimCenterToPin(play);
      play.cameraAnchorAngle = play.aimCenterAngle;
      play.aimStartedAt = Date.now();
    }
    play.message = `${club.name} selected.`;
    return;
  }

  if (action === "target-safe" && (play.shotPhase || "scouting") === "scouting") aimGolfAtSafeTarget(play);
  if (action === "target-pin" && (play.shotPhase || "scouting") === "scouting") aimGolfAtPin(play);
  if (action === "take-shot" && (play.shotPhase || "scouting") === "scouting") startGolfShot(play);
  if (action === "lock-aim" && play.shotPhase === "aiming") lockGolfAim(play, game);
  if (action === "lock-power" && play.shotPhase === "power") lockGolfPower(play, game);
  if (action === "share-round" && play.completed) shareGolfRound(play);
  if (action === "practice" && play.completed) {
    play.practiceUnlocked = true;
    play.message = "Practice unlocked. Tomorrow's ranked course will still be fresh.";
  }
}

function startGolfShot(play) {
  const hole = getCurrentGolfHole(play);
  beginGolfAiming(play, hole);
}

function beginGolfAiming(play, hole = getCurrentGolfHole(play)) {
  setGolfAimCenterToPin(play, hole);
  play.shotPhase = "aiming";
  play.aimStartedAt = Date.now();
  play.cameraAnchorAngle = play.aimCenterAngle;
  play.previousCameraFrame = null;
  play.lockedAimAngle = null;
  play.lockedPower = null;
  play.powerWindow = null;
  play.flightPreview = null;
  play.lastTapAt = Date.now();
  play.message = "Step 1 of 2: tap to lock aim.";
}

function setGolfAimCenterToPin(play, hole = getCurrentGolfHole(play)) {
  const pinAimAngle = angleToPoint(play.ball, hole.pin);
  play.aimAngle = pinAimAngle;
  play.aimCenterAngle = pinAimAngle;
}

function lockGolfAim(play, game) {
  play.lockedAimAngle = getActiveAimAngle(play);
  play.aimAngle = play.lockedAimAngle;
  play.shotPhase = "aim-locked";
  play.lastTapAt = Date.now();
  play.message = "Aim locked.";
  window.setTimeout(() => {
    if (play.completed || play.shotPhase !== "aim-locked") return;
    play.shotPhase = "power";
    play.powerStartedAt = Date.now();
    play.powerWindow = getPowerWindow(play, getCurrentGolfHole(play), getGolfClub(play.selectedClubId));
    play.message = "Step 2 of 2: tap when the marker reaches the ideal zone.";
    saveState();
    render();
  }, 360);
}

function lockGolfPower(play, game) {
  if (Date.now() - (play.lastTapAt || 0) < 260) return;
  play.lockedPower = getActivePowerPosition(play);
  play.flightPreview = computeGolfShotOutcome(play, play.lockedPower);
  play.shotPhase = "power-locked";
  play.lastTapAt = Date.now();
  play.message = "Power locked.";
  const lockedPower = play.lockedPower;
  window.setTimeout(() => {
    if (play.completed || play.shotPhase !== "power-locked") return;
    play.shotPhase = "ball-flight";
    play.message = "Swinging.";
    saveState();
    render();
    window.setTimeout(() => {
      if (play.completed || play.shotPhase !== "ball-flight") return;
      playGolfSwing(play, game, lockedPower, play.flightPreview);
      saveState();
      render();
    }, 1220);
  }, 560);
}

function computeGolfShotOutcome(play, powerPosition) {
  const hole = getCurrentGolfHole(play);
  const club = getGolfClub(play.selectedClubId);
  const lockedAngle = play.lockedAimAngle ?? play.aimAngle;
  const context = getGolfShotContext(play, hole, club, lockedAngle, powerPosition);
  const window = play.powerWindow || getPowerWindow(play, hole, club);
  const quality = getPowerQuality(powerPosition, window);
  const start = context.start;
  const lie = context.lie;
  const yardsPerUnit = hole.yardsPerUnit;
  const powerMultiplier = getGolfPowerFactor(powerPosition) * lie.power;
  const baselineCarryYards = club.carry * getGolfPowerFactor(powerPosition) * lie.power;
  const direction = context.direction;
  const wind = context.wind;
  const windAlong = context.windAlong;
  const crossWind = context.crossWind;
  const windCarryYards = context.windCarryYards;
  const carryYards = context.predictedCarryYards;
  const carryUnits = carryYards / yardsPerUnit;
  const landing = clampPoint({
    x: start.x + direction.x * carryUnits + crossWind.x,
    y: start.y + direction.y * carryUnits + crossWind.y
  });
  const landingSurface = getGolfSurfaceAtPoint(hole, landing);
  const waterPenalty = landingSurface === "water";
  const surface = GOLF_SURFACES[landingSurface] || GOLF_SURFACES.rough;
  const rolloutUnits = waterPenalty ? 0 : club.rollout * surface.rollout * quality.rollout / yardsPerUnit;
  const rolloutYards = rolloutUnits * yardsPerUnit;
  let final = clampPoint({
    x: landing.x + direction.x * rolloutUnits,
    y: landing.y + direction.y * rolloutUnits
  });
  let finalSurface = getGolfSurfaceAtPoint(hole, final);
  const endedInWater = waterPenalty || finalSurface === "water";

  if (endedInWater) {
    final = getDropPoint(hole, start);
    finalSurface = getGolfSurfaceAtPoint(hole, final);
  }

  return {
    hole,
    club,
    window,
    quality,
    start,
    lie,
    powerPosition,
    powerMultiplier,
    lockedAngle,
    direction,
    wind,
    windAlong,
    crossWind,
    windCarryYards,
    baselineCarryYards,
    carryYards,
    carryUnits,
    landing,
    landingSurface,
    rolloutUnits,
    rolloutYards,
    final,
    finalSurface,
    penalty: endedInWater ? 1 : 0
  };
}

function playGolfSwing(play, game, powerPosition, preparedOutcome = null) {
  const currentHole = getCurrentGolfHole(play);
  const previousCameraFrame = getGolfCameraFrame(
    play,
    currentHole,
    getGolfShotContext(play, currentHole, getGolfClub(play.selectedClubId), play.cameraAnchorAngle ?? play.aimCenterAngle ?? play.aimAngle),
    "ball-flight"
  );
  const outcome = preparedOutcome || computeGolfShotOutcome(play, powerPosition);
  const { hole, club, quality, start, carryYards, landing, final, finalSurface, rolloutYards } = outcome;
  const shotNumber = play.holeStrokes + 1;
  let penalty = 0;

  play.holeStrokes += 1;
  play.totalStrokes += 1;

  if (outcome.penalty) {
    penalty = 1;
    play.holeStrokes += 1;
    play.totalStrokes += 1;
  }

  play.ball = final;
  play.currentSurface = finalSurface;
  play.flightPreview = null;
  play.lastShot = {
    hole: hole.number,
    shotNumber,
    club: club.id,
    aimAngle: outcome.lockedAngle,
    powerPosition,
    quality: quality.label,
    carryDistance: Math.round(carryYards),
    windCarryDistance: Math.round(outcome.windCarryYards),
    start,
    landing,
    final,
    landingSurface: outcome.landingSurface,
    rolloutDistance: Math.round(rolloutYards),
    surface: finalSurface,
    penalty,
    summary: summarizeGolfShot(outcome, penalty)
  };
  play.shotLog.push(play.lastShot);

  if (isGolfBallOnGreen(hole, final)) {
    completeGolfHole(play, game, hole);
    return;
  }

  if (play.holeStrokes >= getGolfMaxStrokes(hole)) {
    pickUpGolfHole(play, game, hole);
    return;
  }

  const remaining = Math.round(yardsBetween(final, hole.pin, hole));
  play.selectedClubId = recommendGolfClub(remaining);
  play.targetMode = "pin";
  setGolfAimCenterToPin(play, hole);
  play.cameraAnchorAngle = play.aimCenterAngle;
  play.previousCameraFrame = previousCameraFrame;
  play.shotPhase = "shot-result";
  play.lockedAimAngle = null;
  play.lockedPower = null;
  play.powerWindow = null;
  const resultMessage = penalty
    ? `WATER +1. ${remaining} yds left from ${surfaceLabel(finalSurface).toLowerCase()}.`
    : `${quality.label.toUpperCase()} · landed ${surfaceLabel(outcome.landingSurface).toLowerCase()} · ${Math.round(rolloutYards)} yd rollout · ${remaining} yds left.`;
  play.message = resultMessage;
  window.setTimeout(() => {
    if (play.completed || play.shotPhase !== "shot-result") return;
    beginGolfAiming(play, hole);
    play.message = resultMessage;
    saveState();
    render();
  }, 360);
}

function summarizeGolfShot(outcome, penalty) {
  const carry = Math.round(outcome.carryYards);
  const rollout = Math.round(outcome.rolloutYards || 0);
  const landing = surfaceLabel(outcome.landingSurface).toLowerCase();
  const finish = surfaceLabel(outcome.finalSurface).toLowerCase();
  if (penalty) return `${outcome.club.name} · ${outcome.quality.label} strike · ${carry} yd carry · water penalty`;
  return `${outcome.club.name} · ${outcome.quality.label} strike · ${carry} yd carry · ${rollout} yd rollout · ${finish}${landing !== finish ? ` from ${landing}` : ""}`;
}

function handleHoopsAction(play, action, game) {
  const shot = play.shots[play.shotIndex];
  if (action === "aim-left") play.aim = clamp(play.aim - 5, 8, 92);
  if (action === "aim-right") play.aim = clamp(play.aim + 5, 8, 92);
  if (action === "power-down") play.power = clamp(play.power - 5, 20, 95);
  if (action === "power-up") play.power = clamp(play.power + 5, 20, 95);
  if (action === "release-early") play.release = clamp(play.release - 5, 8, 92);
  if (action === "release-late") play.release = clamp(play.release + 5, 8, 92);
  if (action === "shoot" && !shot.done) playHoopsShot(play, shot);
  if (action === "next" && shot.done && play.shotIndex < play.shots.length - 1) {
    play.shotIndex += 1;
    const nextShot = play.shots[play.shotIndex];
    play.aim = clamp(nextShot.targetAim - 11, 10, 90);
    play.power = clamp(nextShot.targetPower + 9, 24, 92);
    play.release = clamp(nextShot.targetRelease - 7, 12, 88);
    play.message = `${nextShot.label}: square up the shot before you release.`;
  }
  if (action === "finish" && play.shots.every((item) => item.done)) {
    saveSolvryResult(game, `${play.totalPoints} points`, `Finished Solvry Hoops with ${play.totalPoints} points.`);
    play.message = "Score saved to your leaderboard.";
  }
}

function playHoopsShot(play, shot) {
  const error = Math.abs(play.aim - shot.targetAim) + Math.abs(play.power - shot.targetPower) + Math.abs(play.release - shot.targetRelease);
  let points = 0;
  if (error <= 20) points = shot.value;
  else if (error <= 34) points = Math.max(1, shot.value - 1);
  else if (error <= 46) points = 1;

  shot.done = true;
  shot.points = points;
  play.totalPoints += points;
  if (points === shot.value) {
    play.message = `Clean make from ${shot.label.toLowerCase()} for ${points}.`;
  } else if (points > 0) {
    play.message = `It rattled in for ${points}.`;
  } else {
    play.message = "Off target. No points on that shot.";
  }
}

function getSolvryPlay(game) {
  state.solvryPlays ||= {};
  const key = getSolvryPlayKey(game.id);
  const existing = state.solvryPlays[key];
  const needsNewGolfRound = game.id === "solvry-holes" && existing?.version !== GOLF_GAME_VERSION;
  if (!existing || needsNewGolfRound) {
    state.solvryPlays[key] = game.id === "solvry-holes" ? createHolesPlay(game.id) : createHoopsPlay(game.id);
  }
  return state.solvryPlays[key];
}

function getSolvryPlayKey(gameId) {
  return `${state.selectedDate}:${gameId}`;
}

function createHolesPlay(gameId) {
  const course = generateDailyGolfCourse(state.selectedDate, GOLF_GENERATION_VERSION);
  const firstHole = course.holes[0];
  const firstAimAngle = angleToPoint(firstHole.tee, firstHole.pin);
  const firstDistance = yardsBetween(firstHole.tee, firstHole.pin, firstHole);
  return {
    version: GOLF_GAME_VERSION,
    gameId,
    kind: "holes",
    isRanked: true,
    started: false,
    completed: false,
    startedAt: "",
    completedAt: "",
    date: state.selectedDate,
    seed: course.seed,
    generationVersion: GOLF_GENERATION_VERSION,
    course,
    holeIndex: 0,
    currentHoleIndex: 0,
    showHoleCard: false,
    ball: { ...firstHole.tee },
    aimAngle: firstAimAngle,
    aimCenterAngle: firstAimAngle,
    lockedAimAngle: null,
    lockedPower: null,
    powerWindow: null,
    flightPreview: null,
    shotPhase: "scouting",
    lastTapAt: 0,
    selectedClubId: recommendGolfClub(firstDistance),
    currentSurface: "tee",
    totalStrokes: 0,
    holeStrokes: 0,
    roundScore: 0,
    roundStarted: false,
    roundCompleted: false,
    holeResults: [],
    shotLog: [],
    lastShot: null,
    holeCompleteFeedback: null,
    practiceUnlocked: false,
    message: "Today's ranked course is ready."
  };
}

function generateDailyGolfCourse(dateKey, version) {
  const seed = `solvry-holes:${version}:${dateKey}`;
  const random = mulberry32(hashSeed(seed));
  const environments = [
    { name: "Ravendown Golf Club", environment: "Pine forest", rough: "#dfe9d5" },
    { name: "Blueglass Links", environment: "Coastal dunes", rough: "#e8e2bf" },
    { name: "Cinder Mesa", environment: "Desert parkland", rough: "#ead7ac" }
  ];
  const env = environments[Math.floor(random() * environments.length)];
  const parPlan = [3, 4, 4, 5, 3, 4, 4, 3, 5];
  const holes = parPlan.map((par, index) => generateGolfHole(index + 1, par, random, env));
  return {
    id: seed,
    seed,
    generationVersion: version,
    date: dateKey,
    dailyNumber: `#${dateKey.replaceAll("-", "").slice(2)}`,
    name: env.name,
    environment: env.environment,
    par: holes.reduce((total, hole) => total + hole.par, 0),
    holes
  };
}

function generateGolfHole(number, par, random, env) {
  const distanceRanges = { 3: [105, 178], 4: [285, 430], 5: [455, 560] };
  const [minimum, maximum] = distanceRanges[par];
  const distance = Math.round(minimum + random() * (maximum - minimum));
  const greenX = 40 + random() * 20;
  const teeX = clamp(greenX + (random() - 0.5) * 22, 34, 66);
  const doglegX = clamp((teeX + greenX) / 2 + (random() - 0.5) * 28, 26, 74);
  const width = par === 3 ? 16 : 12 + random() * 8;
  const greenRadius = par === 3 ? 7.2 : 6.2 + random() * 1.6;
  const greenDifficulty = random() > 0.62 ? "Tight" : random() > 0.34 ? "Rolling" : "Friendly";
  const puttBase = greenDifficulty === "Friendly" ? 2.6 : greenDifficulty === "Rolling" ? 2.1 : 1.7;
  const water = [];
  if (number >= 4 || random() > 0.7) {
    water.push({ x: clamp(doglegX + (random() - 0.5) * 26, 12, 88), y: 36 + random() * 30, rx: 8 + random() * 6, ry: 4 + random() * 8 });
  }
  if (number === 9) water.push({ x: greenX + 8, y: 18, rx: 13, ry: 10 });
  const bunkers = [
    { x: greenX - 8 - random() * 5, y: 15 + random() * 6, rx: 4.5, ry: 2.6 },
    { x: greenX + 8 + random() * 5, y: 18 + random() * 7, rx: 4.2, ry: 2.4 }
  ];
  if (par > 3) bunkers.push({ x: doglegX + 5, y: 48 + random() * 10, rx: 5.8, ry: 2.8 });
  const treeZones = [
    { x: clamp(doglegX - 22, 8, 92), y: 52, rx: 9, ry: 25 },
    { x: clamp(doglegX + 24, 8, 92), y: 55, rx: 8, ry: 23 }
  ];
  const cartPaths = random() > 0.45 ? [{ d: `M ${clamp(teeX + 18, 8, 92)} 96 C ${clamp(doglegX + 25, 8, 92)} 70 ${clamp(greenX + 22, 8, 92)} 35 ${clamp(greenX + 18, 8, 92)} 8`, width: 2.4 }] : [];
  const windDirection = Math.round(random() * 360);
  const windSpeed = Math.round(3 + random() * (number > 6 ? 12 : 8));
  const primaryHazard = number === 9 ? "Signature water carry" : water.length ? "Water crossing" : bunkers.length ? "Greenside bunkers" : "Tree line";
  const teePosition = { x: teeX, y: 92 };
  const pinPosition = { x: greenX + (random() - 0.5) * 4, y: 10 + random() * 5 };

  return {
    id: `h${number}`,
    number,
    name: number === 9 ? "The Last Carry" : `${env.environment} ${number}`,
    par,
    distance,
    yardsPerUnit: distance / 82,
    tee: teePosition,
    pin: pinPosition,
    teePosition,
    pinPosition,
    green: { x: greenX, y: 13.5, r: greenRadius },
    fairway: { teeX, doglegX, greenX, width },
    water,
    bunkers,
    treeZones,
    cartPaths,
    wind: { speed: windSpeed, direction: windDirection },
    primaryHazard,
    greenDifficulty,
    puttZones: { one: puttBase, two: puttBase * 2.5, outer: greenRadius },
    palette: { rough: env.rough },
    summary: `${primaryHazard}. ${windSpeed} mph wind ${windArrow(windDirection)}. Choose a safe landing zone or attack the pin.`
  };
}

function startCurrentGolfHole(play) {
  play.holeIndex = clamp(play.holeIndex || 0, 0, play.course.holes.length - 1);
  play.currentHoleIndex = play.holeIndex;
  const hole = getCurrentGolfHole(play);
  play.showHoleCard = false;
  play.ball = { ...hole.tee };
  play.holeCompleteFeedback = null;
  play.pendingAdvanceToken = null;
  play.selectedClubId = recommendGolfClub(yardsBetween(play.ball, hole.pin, hole));
  play.targetMode = "pin";
  play.currentSurface = "tee";
  play.holeStrokes = 0;
  play.lastShot = null;
  beginGolfAiming(play, hole);
  syncGolfRoundState(play);
  play.message = `Hole ${hole.number}: ${hole.distance} yards. Pick a club and time the swing.`;
}

function completeGolfHole(play, game, hole) {
  if (play.completed || play.roundCompleted || play.holeResults[play.holeIndex]?.completed) return;
  const proximity = yardsBetween(play.ball, hole.pin, hole);
  const holeShots = play.shotLog.filter((shot) => shot.hole === hole.number);
  const penaltyStrokes = holeShots.reduce((total, shot) => total + (shot.penalty || 0), 0);
  const normalShots = Math.max(0, play.holeStrokes - penaltyStrokes);
  const isHoleInOne = play.holeStrokes === 1 && proximity <= getGolfHoleInOneThresholdYards(hole);
  const putting = isHoleInOne ? { putts: 0, zone: "cup" } : getGolfPuttingResult(hole, play.ball);
  const putts = putting.putts;
  play.holeStrokes += putts;
  play.totalStrokes += putts;
  const relative = play.holeStrokes - hole.par;
  const label = isHoleInOne ? "Hole in one" : getGolfScoreName(relative);
  const result = {
    holeId: hole.id,
    holeIndex: play.holeIndex,
    index: play.holeIndex,
    par: hole.par,
    normalShots,
    penaltyStrokes,
    penalties: penaltyStrokes,
    putts,
    strokes: play.holeStrokes,
    totalStrokes: play.holeStrokes,
    relative,
    relativeScore: relative,
    scoreName: label,
    completed: true,
    puttingZone: putting.zone,
    shots: holeShots
  };
  const puttCopy = putts ? `${putts} putt${putts === 1 ? "" : "s"}` : "holed from the shot";
  finishGolfHole(play, game, hole, result, `${label.toUpperCase()} · ${play.holeStrokes} stroke${play.holeStrokes === 1 ? "" : "s"} · ${puttCopy}.`);
}

function pickUpGolfHole(play, game, hole) {
  if (play.completed || play.roundCompleted || play.holeResults[play.holeIndex]?.completed) return;
  const maxStrokes = getGolfMaxStrokes(hole);
  if (play.holeStrokes > maxStrokes) {
    play.totalStrokes -= play.holeStrokes - maxStrokes;
    play.holeStrokes = maxStrokes;
  }
  const relative = play.holeStrokes - hole.par;
  const result = {
    holeId: hole.id,
    holeIndex: play.holeIndex,
    index: play.holeIndex,
    par: hole.par,
    normalShots: Math.max(0, play.holeStrokes - play.shotLog.filter((shot) => shot.hole === hole.number).reduce((total, shot) => total + (shot.penalty || 0), 0)),
    penaltyStrokes: play.shotLog.filter((shot) => shot.hole === hole.number).reduce((total, shot) => total + (shot.penalty || 0), 0),
    penalties: play.shotLog.filter((shot) => shot.hole === hole.number).reduce((total, shot) => total + (shot.penalty || 0), 0),
    strokes: play.holeStrokes,
    totalStrokes: play.holeStrokes,
    relative,
    relativeScore: relative,
    completed: true,
    putts: 0,
    pickup: true,
    shots: play.shotLog.filter((shot) => shot.hole === hole.number)
  };
  finishGolfHole(play, game, hole, result, `Hole ${hole.number} picked up at ${play.holeStrokes} strokes (${formatRelativeScore(relative)}). Next tee.`);
}

function getGolfMaxStrokes(hole) {
  return hole.par + 5;
}

function finishGolfHole(play, game, hole, result, message) {
  if (play.holeResults[play.holeIndex]?.completed) return;
  play.holeResults[play.holeIndex] = result;
  syncGolfRoundState(play);
  play.shotPhase = "hole-complete";
  play.showHoleCard = false;
  play.powerWindow = null;
  play.lockedAimAngle = null;
  play.lockedPower = null;
  play.flightPreview = null;
  const advanceToken = `${hole.id}:${Date.now()}`;
  play.pendingAdvanceToken = advanceToken;
  play.holeCompleteFeedback = {
    holeIndex: play.holeIndex,
    holeNumber: hole.number,
    label: (result.scoreName || getGolfScoreName(result.relative)).toUpperCase(),
    strokes: result.strokes,
    relative: result.relative,
    putts: result.putts,
    isFinalHole: play.holeIndex >= play.course.holes.length - 1,
    advanceToken
  };
  play.message = message;
  scheduleGolfHoleAdvance(play, game);
}

function scheduleGolfHoleAdvance(play, game) {
  const advanceToken = play.pendingAdvanceToken;
  window.setTimeout(() => {
    if (play.completed || play.shotPhase !== "hole-complete" || !play.holeCompleteFeedback || play.pendingAdvanceToken !== advanceToken) return;
    advanceGolfAfterHole(play, game);
    saveState();
    render();
  }, 1900);
}

function advanceGolfAfterHole(play, game) {
  const feedback = play.holeCompleteFeedback;
  if (!feedback) return;

  if (feedback.isFinalHole) {
    play.completed = true;
    play.roundCompleted = true;
    play.completedAt = new Date().toISOString();
    syncGolfRoundState(play);
    const score = `${play.totalStrokes} strokes`;
    const note = `${formatRelativeScore(getGolfRelativeScore(play))} to par on ${play.course.name}`;
    saveSolvryResult(game, score, note);
    play.holeCompleteFeedback = null;
    play.pendingAdvanceToken = null;
    return;
  }

  play.holeIndex = Math.min(feedback.holeIndex + 1, play.course.holes.length - 1);
  startCurrentGolfHole(play);
}

function aimGolfAtSafeTarget(play) {
  const hole = getCurrentGolfHole(play);
  const safe = { x: hole.fairway.doglegX, y: hole.par === 3 ? 28 : 52 };
  play.aimAngle = angleToPoint(play.ball, safe);
  play.aimCenterAngle = play.aimAngle;
  play.lockedAimAngle = null;
  play.powerWindow = null;
  play.selectedClubId = recommendGolfClub(yardsBetween(play.ball, safe, hole));
  play.targetMode = "safe";
  play.message = "Aiming at the widest fairway landing zone.";
}

function aimGolfAtPin(play) {
  const hole = getCurrentGolfHole(play);
  setGolfAimCenterToPin(play, hole);
  play.lockedAimAngle = null;
  play.powerWindow = null;
  play.selectedClubId = recommendGolfClub(yardsBetween(play.ball, hole.pin, hole));
  play.targetMode = "pin";
  play.message = "Aiming at the pin. Time it cleanly.";
}

function shareGolfRound(play) {
  const grid = play.holeResults.map((result) => formatRelativeScore(result.relative)).join(" ");
  const share = `Solvry Holes ${play.course.dailyNumber}\\n${formatRelativeScore(getGolfRelativeScore(play))}\\n${grid}\\n${play.totalStrokes} strokes · ${play.course.holes.length} holes`;
  navigator.clipboard?.writeText(share).then(() => {
    flashStatus(elements.saveStatus, "Spoiler-free round copied.");
  }).catch(() => {
    flashStatus(elements.saveStatus, share);
  });
}

function getCurrentGolfHole(play) {
  play.holeIndex = clamp(play.holeIndex || 0, 0, play.course.holes.length - 1);
  play.currentHoleIndex = play.holeIndex;
  return play.course.holes[play.holeIndex];
}

function getGolfClub(clubId) {
  return GOLF_CLUBS.find((club) => club.id === clubId) || GOLF_CLUBS[0];
}

function recommendGolfClub(yards) {
  const club = [...GOLF_CLUBS].reverse().find((item) => item.max >= yards);
  return (club || GOLF_CLUBS[0]).id;
}

function getGolfTargetPoint(play, hole, club) {
  return getGolfTargetPointForAngle(play, hole, club, play.aimAngle);
}

function getGolfTargetPointForAngle(play, hole, club, angle) {
  return getGolfShotContext(play, hole, club, angle).aimEndpoint;
}

function getGolfCameraFrame(play, hole, context, phase) {
  if (phase === "ball-flight" && play.flightPreview) {
    return getGolfCameraFrameForPoints([
      play.flightPreview.start,
      play.flightPreview.landing,
      play.flightPreview.final
    ], "ball-follow", 13);
  }

  const ball = context.start;
  const remainingUnits = Math.max(1, context.distanceToPin / hole.yardsPerUnit);
  const clubUnits = Math.max(8, context.nominalCarryYards / hole.yardsPerUnit);
  const nearGreen = context.distanceToPin <= 92;
  const shouldIncludePin = nearGreen || context.distanceToPin <= context.nominalCarryYards * 1.18;
  const forwardFocus = shouldIncludePin ? hole.pin : context.aimEndpoint;
  const forwardDistance = distance(ball, forwardFocus);
  const progress = clamp(1 - context.distanceToPin / Math.max(1, hole.distance), 0, 1);
  let size = Math.max(34, Math.min(remainingUnits, clubUnits) * (shouldIncludePin ? 1.35 : 1.58) + 18);

  if (play.holeStrokes === 0 && play.currentSurface === "tee") {
    size = Math.max(size, Math.min(92, distance(hole.tee, hole.pin) * 1.05));
  }

  size = clamp(size - progress * 16, nearGreen ? 26 : 32, 92);

  const direction = normalizeGolfVector({ x: forwardFocus.x - ball.x, y: forwardFocus.y - ball.y });
  const center = {
    x: ball.x + direction.x * Math.min(forwardDistance * 0.54, size * 0.28),
    y: ball.y + direction.y * Math.min(forwardDistance * 0.54, size * 0.28)
  };
  const points = [ball, context.aimEndpoint];
  const sweepRange = getAimSweepRange(play, hole);
  const club = getGolfClub(play.selectedClubId);
  points.push(
    getGolfShotContext(play, hole, club, context.angle - sweepRange).aimEndpoint,
    getGolfShotContext(play, hole, club, context.angle + sweepRange).aimEndpoint
  );
  if (shouldIncludePin) points.push(hole.pin, hole.green);
  const frame = clampGolfCameraFrame(center, size, size, points, nearGreen ? 6 : 8);
  const mode = nearGreen ? "green" : progress > 0.45 ? "approach" : play.holeStrokes ? "shot-setup" : "hole-overview";
  return { ...frame, mode };
}

function getGolfCameraFrameForPoints(points, mode, padding = 10) {
  const xs = points.map((point) => point.x);
  const ys = points.map((point) => point.y);
  const minX = Math.min(...xs);
  const maxX = Math.max(...xs);
  const minY = Math.min(...ys);
  const maxY = Math.max(...ys);
  const size = clamp(Math.max(maxX - minX, maxY - minY) + padding * 2, 34, 96);
  return { ...clampGolfCameraFrame({ x: (minX + maxX) / 2, y: (minY + maxY) / 2 }, size, size, points, padding), mode };
}

function clampGolfCameraFrame(center, width, height, points = [], padding = 6) {
  let frameWidth = clamp(width, 24, 100);
  let frameHeight = clamp(height, 24, 100);
  for (const point of points) {
    while ((point.x < center.x - frameWidth / 2 + padding || point.x > center.x + frameWidth / 2 - padding || point.y < center.y - frameHeight / 2 + padding || point.y > center.y + frameHeight / 2 - padding) && frameWidth < 100) {
      frameWidth = Math.min(100, frameWidth + 4);
      frameHeight = Math.min(100, frameHeight + 4);
    }
  }
  const x = clamp(center.x - frameWidth / 2, 0, 100 - frameWidth);
  const y = clamp(center.y - frameHeight / 2, 0, 100 - frameHeight);
  return { x, y, width: frameWidth, height: frameHeight };
}

function formatGolfCameraViewBox(frame) {
  return `${roundCameraValue(frame.x)} ${roundCameraValue(frame.y)} ${roundCameraValue(frame.width)} ${roundCameraValue(frame.height)}`;
}

function roundCameraValue(value) {
  return Math.round(value * 100) / 100;
}

function normalizeGolfVector(vector) {
  const length = Math.hypot(vector.x, vector.y) || 1;
  return { x: vector.x / length, y: vector.y / length };
}

function getVisibleAimLineLength(origin, angle) {
  const vector = golfVectorFromAngle(angle);
  const limits = [];
  if (vector.x > 0) limits.push((94 - origin.x) / vector.x);
  if (vector.x < 0) limits.push((origin.x - 6) / -vector.x);
  if (vector.y > 0) limits.push((94 - origin.y) / vector.y);
  if (vector.y < 0) limits.push((origin.y - 6) / -vector.y);
  const available = Math.min(...limits.filter((value) => Number.isFinite(value) && value > 0));
  return clamp((Number.isFinite(available) ? available : 88) - 1.5, 8, 88);
}

function getActiveAimAngle(play) {
  const hole = getCurrentGolfHole(play);
  const elapsed = Date.now() - (play.aimStartedAt || Date.now());
  const phase = Math.sin((elapsed / getAimSweepDuration(play, hole)) * Math.PI * 2);
  return (play.aimCenterAngle ?? play.aimAngle) + phase * getAimSweepRange(play, hole);
}

function getAimSweepRange(play, hole) {
  const club = getGolfClub(play.selectedClubId);
  const lie = GOLF_SURFACES[play.currentSurface] || GOLF_SURFACES.rough;
  return clamp(13 + club.dispersion * 0.55 + (lie.accuracy - 1) * 5 + hole.wind.speed * 0.18, 15, 25);
}

function getAimSweepDuration(play, hole) {
  const club = getGolfClub(play.selectedClubId);
  return clamp(1900 - club.dispersion * 45 - hole.wind.speed * 18, 1180, 1900);
}

function getGolfLandingRadius(play, hole) {
  const club = getGolfClub(play.selectedClubId);
  const lie = GOLF_SURFACES[play.currentSurface] || GOLF_SURFACES.rough;
  return clamp(11 + club.dispersion * 1.2 + (lie.accuracy - 1) * 9 + hole.wind.speed * 0.22, 12, 28);
}

function getActivePowerPosition(play) {
  const elapsed = Date.now() - (play.powerStartedAt || Date.now());
  const cycle = 1450;
  const progress = (elapsed % (cycle * 2)) / cycle;
  const folded = progress <= 1 ? progress : 2 - progress;
  return clamp(Math.round(folded * 100), 4, 96);
}

function getGolfPowerFactor(powerPosition) {
  return 0.48 + powerPosition / 100 * 0.88;
}

function getGolfWindCarryYards(club, hole, windAlong) {
  return clamp(windAlong * hole.yardsPerUnit * 0.42, -club.carry * 0.14, club.carry * 0.14);
}

function getGolfCarryYards(club, lie, powerPosition, windCarryYards = 0) {
  return Math.max(8, club.carry * getGolfPowerFactor(powerPosition) * lie.power + windCarryYards);
}

function getGolfRequiredPowerForCarry(club, lie, targetYards, windCarryYards = 0) {
  const baseCarry = Math.max(1, club.carry * lie.power);
  return clamp(((targetYards - windCarryYards) / baseCarry - 0.48) / 0.88 * 100, 8, 92);
}

function getGolfShotContext(play, hole = getCurrentGolfHole(play), club = getGolfClub(play.selectedClubId), angle = play.lockedAimAngle ?? play.aimAngle, powerPosition = GOLF_IDEAL_POWER) {
  const start = { ...play.ball };
  const pin = hole.pin;
  const lie = GOLF_SURFACES[play.currentSurface] || GOLF_SURFACES.rough;
  const baseAimAngle = angleToPoint(start, pin);
  const lockedAngle = Number.isFinite(angle) ? angle : baseAimAngle;
  const direction = golfVectorFromAngle(lockedAngle);
  const wind = golfWindVector(hole.wind, hole.yardsPerUnit);
  const windAlong = wind.x * direction.x + wind.y * direction.y;
  const crossWind = {
    x: wind.x - direction.x * windAlong,
    y: wind.y - direction.y * windAlong
  };
  const windCarryYards = getGolfWindCarryYards(club, hole, windAlong);
  const distanceToPin = yardsBetween(start, pin, hole);
  const nominalCarryYards = getGolfCarryYards(club, lie, GOLF_IDEAL_POWER, windCarryYards);
  const referenceCarryYards = clamp(Math.min(distanceToPin, nominalCarryYards), 8, nominalCarryYards);
  const requiredPower = getGolfRequiredPowerForCarry(club, lie, referenceCarryYards, windCarryYards);
  const carryUnits = referenceCarryYards / hole.yardsPerUnit;
  const aimEndpoint = clampPoint({
    x: start.x + direction.x * carryUnits,
    y: start.y + direction.y * carryUnits
  });
  const predictedCarryYards = getGolfCarryYards(club, lie, powerPosition, windCarryYards);
  return {
    hole,
    club,
    lie,
    start,
    pin,
    yardsPerUnit: hole.yardsPerUnit,
    distanceToPin,
    baseAimAngle,
    angle: lockedAngle,
    direction,
    wind,
    windAlong,
    crossWind,
    windCarryYards,
    nominalCarryYards,
    referenceCarryYards,
    requiredPower,
    aimEndpoint,
    powerPosition,
    predictedCarryYards
  };
}

function getPowerWindow(play, hole, club) {
  const context = getGolfShotContext(play, hole, club, play.lockedAimAngle ?? play.aimAngle);
  const target = context.aimEndpoint;
  const lie = GOLF_SURFACES[play.currentSurface] || GOLF_SURFACES.rough;
  const required = context.requiredPower;
  const landingSurface = getGolfSurfaceAtPoint(hole, target);
  const carryRisk = hole.water.some((water) => distanceToSegment(water, play.ball, target) < Math.max(water.rx, water.ry) * 0.9);
  let width = 23;
  width -= club.dispersion * 0.75;
  width -= (lie.accuracy - 1) * 8;
  width -= hole.wind.speed * 0.35;
  if (carryRisk) width -= 4;
  if (landingSurface === "green") width -= 2;
  if (club.id === "wedge" || club.id === "lob-wedge") width += 5;
  width = clamp(width, 8, 28);
  const start = clamp(required - width / 2, 4, 96 - width);
  return { center: Math.round(required), start: Math.round(start), width: Math.round(width), marker: 4 };
}

function getPowerQuality(powerPosition, window) {
  const error = Math.abs(powerPosition - window.center);
  if (error <= window.width * 0.22) return { label: "Pure", rollout: 1.08 };
  if (error <= window.width * 0.5) return { label: "Controlled", rollout: 1 };
  if (powerPosition < window.center) return { label: "Underhit", rollout: 0.72 };
  return { label: "Overhit", rollout: 1.18 };
}

function golfVectorFromAngle(angle) {
  const radians = (angle * Math.PI) / 180;
  return { x: Math.sin(radians), y: -Math.cos(radians) };
}

function angleToPoint(from, to) {
  const radians = Math.atan2(to.x - from.x, from.y - to.y);
  return (radians * 180) / Math.PI;
}

function yardsBetween(a, b, hole) {
  return Math.hypot(a.x - b.x, a.y - b.y) * hole.yardsPerUnit;
}

function getGolfPuttZones(hole) {
  const one = hole.puttZones?.one ?? Math.max(1.6, hole.green.r * 0.28);
  const two = hole.puttZones?.two ?? Math.max(one + 1.2, hole.green.r * 0.66);
  const outer = hole.puttZones?.outer ?? hole.green.r;
  return {
    one: Math.min(one, outer),
    two: Math.min(Math.max(two, one), outer),
    outer
  };
}

function getGolfPuttingResult(hole, point) {
  const zones = getGolfPuttZones(hole);
  const proximityUnits = distance(point, hole.pin);
  if (proximityUnits <= zones.one) return { putts: 1, zone: "inner" };
  if (proximityUnits <= zones.two) return { putts: 2, zone: "middle" };
  return { putts: 3, zone: "outer" };
}

function getGolfHoleInOneThresholdYards(hole) {
  return Math.max(0.75, hole.yardsPerUnit * 0.45);
}

function isGolfBallOnGreen(hole, point) {
  const zones = getGolfPuttZones(hole);
  return getGolfSurfaceAtPoint(hole, point) === "green" || distance(point, hole.pin) <= zones.outer;
}

function getSwingTimingValue() {
  const cycle = 1550;
  const progress = (performance.now() % (cycle * 2)) / cycle;
  const folded = progress <= 1 ? progress : 2 - progress;
  return Math.round(folded * 100);
}

function getSwingQuality(timing) {
  const error = Math.abs(timing - 50);
  if (error <= 7) return { label: "Pure", rollout: 1.12 };
  if (error <= 18) return { label: "Good", rollout: 1 };
  if (timing < 50) return { label: "Low", rollout: 0.76 };
  return { label: "Over", rollout: 1.18 };
}

function golfWindVector(wind, yardsPerUnit) {
  const radians = (wind.direction * Math.PI) / 180;
  const units = wind.speed / yardsPerUnit * 0.22;
  return { x: Math.sin(radians) * units, y: -Math.cos(radians) * units };
}

function getGolfSurfaceAtPoint(hole, point) {
  if (nearPoint(point, hole.tee, 4)) return "tee";
  if (hole.water.some((water) => pointInEllipse(point, water))) return "water";
  if (hole.bunkers.some((bunker) => pointInEllipse(point, bunker))) return "bunker";
  if (distance(point, hole.green) <= hole.green.r) return "green";
  if (hole.cartPaths.some((path) => distanceToPolyline(point, path.d) <= path.width * 0.55)) return "cartPath";
  if (isPointOnFairway(hole, point)) return "fairway";
  if (hole.treeZones.some((zone) => pointInEllipse(point, zone))) return "deepRough";
  return "rough";
}

function isPointOnFairway(hole, point) {
  const segments = [
    [hole.tee, { x: hole.fairway.doglegX, y: 52 }],
    [{ x: hole.fairway.doglegX, y: 52 }, { x: hole.fairway.greenX, y: 16 }]
  ];
  return segments.some(([a, b]) => distanceToSegment(point, a, b) <= hole.fairway.width / 2);
}

function fairwayPath(hole) {
  return fairwayPathWithWidth(hole, 0);
}

function fairwayPathWithWidth(hole, extraWidth) {
  const tee = hole.tee;
  const mid = { x: hole.fairway.doglegX, y: 52 };
  const green = { x: hole.fairway.greenX, y: 16 };
  const width = hole.fairway.width + extraWidth;
  return `M ${tee.x - width / 2} ${tee.y} C ${mid.x - width} 75 ${mid.x - width} 62 ${mid.x - width / 2} ${mid.y} C ${green.x - width / 2} 38 ${green.x - width / 2} 25 ${green.x - width / 2} ${green.y} L ${green.x + width / 2} ${green.y} C ${green.x + width / 2} 25 ${mid.x + width / 2} 38 ${mid.x + width / 2} ${mid.y} C ${mid.x + width} 66 ${tee.x + width / 2} 72 ${tee.x + width / 2} ${tee.y} Z`;
}

function getDropPoint(hole, start) {
  const target = { x: hole.fairway.doglegX, y: Math.min(78, Math.max(38, start.y - 18)) };
  return isPointOnFairway(hole, target) ? target : { x: hole.fairway.doglegX, y: 56 };
}

function getGolfRelativeScore(play) {
  return play.holeResults.reduce((total, result) => total + (result?.relative || 0), 0);
}

function getGolfRoundRecap(play) {
  const completed = play.holeResults.filter(Boolean);
  if (!completed.length) {
    return { bestHole: "Not started", toughestHole: "Not started", putting: "0 putts" };
  }

  const best = [...completed].sort((a, b) => a.relative - b.relative || a.strokes - b.strokes)[0];
  const toughest = [...completed].sort((a, b) => b.relative - a.relative || b.strokes - a.strokes)[0];
  const totalPutts = completed.reduce((total, result) => total + (result.putts || 0), 0);
  const onePutts = completed.filter((result) => result.putts === 1).length;
  const penalties = completed.reduce((total, result) => total + (result.penaltyStrokes || 0), 0);
  return {
    bestHole: `#${best.holeIndex + 1} ${getGolfScoreName(best.relative)}`,
    toughestHole: `#${toughest.holeIndex + 1} ${formatRelativeScore(toughest.relative)}`,
    putting: `${totalPutts} putts${onePutts ? ` · ${onePutts} one-putt${onePutts === 1 ? "" : "s"}` : ""}${penalties ? ` · ${penalties} penalty` : ""}`
  };
}

function syncGolfRoundState(play) {
  play.currentHoleIndex = clamp(play.holeIndex || 0, 0, play.course.holes.length - 1);
  play.roundStarted = !!play.started;
  play.roundCompleted = !!play.completed;
  play.roundScore = getGolfRelativeScore(play);
  play.dailySeed = play.seed;
}

function formatRelativeScore(value) {
  if (value === 0) return "E";
  return value > 0 ? `+${value}` : `${value}`;
}

function getGolfScoreName(relative) {
  if (relative <= -3) return "Albatross";
  if (relative === -2) return "Eagle";
  if (relative === -1) return "Birdie";
  if (relative === 0) return "Par";
  if (relative === 1) return "Bogey";
  if (relative === 2) return "Double bogey";
  return `+${relative}`;
}

function surfaceLabel(surface) {
  return GOLF_SURFACES[surface]?.label || "Rough";
}

function windArrow(direction) {
  const arrows = ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"];
  return arrows[Math.round((((direction % 360) + 360) % 360) / 45) % arrows.length];
}

function clampPoint(point) {
  return { x: clamp(point.x, 4, 96), y: clamp(point.y, 4, 96) };
}

function nearPoint(a, b, radius) {
  return distance(a, b) <= radius;
}

function distance(a, b) {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

function pointInEllipse(point, ellipse) {
  return ((point.x - ellipse.x) ** 2) / (ellipse.rx ** 2) + ((point.y - ellipse.y) ** 2) / (ellipse.ry ** 2) <= 1;
}

function distanceToSegment(point, a, b) {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const lengthSquared = dx * dx + dy * dy;
  if (!lengthSquared) return distance(point, a);
  const t = clamp(((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared, 0, 1);
  return distance(point, { x: a.x + t * dx, y: a.y + t * dy });
}

function distanceToPolyline(point, pathData) {
  const numbers = pathData.match(/-?\d+(\.\d+)?/g)?.map(Number) || [];
  const points = [];
  for (let index = 0; index < numbers.length - 1; index += 2) {
    points.push({ x: numbers[index], y: numbers[index + 1] });
  }
  if (points.length < 2) return Number.POSITIVE_INFINITY;
  return points.slice(1).reduce((minimum, current, index) => Math.min(minimum, distanceToSegment(point, points[index], current)), Number.POSITIVE_INFINITY);
}

function hashSeed(value) {
  let hash = 1779033703 ^ value.length;
  for (let index = 0; index < value.length; index += 1) {
    hash = Math.imul(hash ^ value.charCodeAt(index), 3432918353);
    hash = (hash << 13) | (hash >>> 19);
  }
  return () => {
    hash = Math.imul(hash ^ (hash >>> 16), 2246822507);
    hash = Math.imul(hash ^ (hash >>> 13), 3266489909);
    return (hash ^= hash >>> 16) >>> 0;
  };
}

function mulberry32(seedFactory) {
  let seed = seedFactory();
  return () => {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let next = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    next ^= next + Math.imul(next ^ (next >>> 7), 61 | next);
    return ((next ^ (next >>> 14)) >>> 0) / 4294967296;
  };
}

function createHoopsPlay(gameId) {
  const shots = [
    { label: "Wing jumper", value: 2, targetAim: 52, targetPower: 49, targetRelease: 48, targetX: 50, targetY: 24, angle: -8 },
    { label: "Left corner", value: 3, targetAim: 29, targetPower: 66, targetRelease: 56, targetX: 30, targetY: 38, angle: 18 },
    { label: "Right corner", value: 3, targetAim: 71, targetPower: 66, targetRelease: 44, targetX: 70, targetY: 38, angle: -18 },
    { label: "Free throw", value: 2, targetAim: 50, targetPower: 43, targetRelease: 50, targetX: 50, targetY: 46, angle: 0 },
    { label: "Top three", value: 3, targetAim: 48, targetPower: 72, targetRelease: 61, targetX: 50, targetY: 64, angle: 0 },
    { label: "Bank shot", value: 2, targetAim: 61, targetPower: 57, targetRelease: 39, targetX: 58, targetY: 30, angle: -12 },
    { label: "Elbow pull-up", value: 2, targetAim: 40, targetPower: 54, targetRelease: 53, targetX: 42, targetY: 42, angle: 11 },
    { label: "Deep wing", value: 3, targetAim: 78, targetPower: 84, targetRelease: 47, targetX: 78, targetY: 61, angle: -24 },
    { label: "Logo shot", value: 4, targetAim: 51, targetPower: 91, targetRelease: 64, targetX: 50, targetY: 76, angle: 2 }
  ].map((shot) => ({ ...shot, done: false, points: 0 }));

  return {
    gameId,
    kind: "hoops",
    shotIndex: 0,
    aim: 41,
    power: 58,
    release: 45,
    totalPoints: 0,
    shots,
    message: "Shot 1: set aim, power, and release, then shoot."
  };
}

function saveSolvryResult(game, score, note) {
  const gameEntries = getGameEntries(state.selectedDate, game.id);
  gameEntries.you = {
    result: "played",
    score,
    answer: "",
    note,
    reveal: false,
    source: "solvry-play"
  };
  flashStatus(elements.saveStatus, `${game.name} saved.`);
}

function isPlayableSolvryGame(game) {
  return SHOW_SOLVRY_GAMES && gameSource(game) === "solvry" && ["solvry-holes", "solvry-hoops"].includes(game.id);
}

function clamp(value, minimum, maximum) {
  return Math.min(maximum, Math.max(minimum, value));
}

function renderQuickGames() {
  const pinned = visibleGames().filter((game) => state.pinnedGameIds.includes(game.id));
  const games = (pinned.length ? pinned : visibleGames()).slice(0, wideOverview.matches ? 12 : roomyOverview.matches ? 10 : 6);
  document.querySelector("#quickGamesHint").textContent = pinned.length ? "Your pinned favorites." : "Pin favorites in Games.";
  elements.quickGames.innerHTML = games
    .map((game) => {
      const entries = getGameEntries(state.selectedDate, game.id);
      const mine = entries.you;
      const status = mine ? mine.score || defaultScoreLabel(mine.result) : "Add your result";
      return `
        <button class="quick-game${game.id === state.activeGameId ? " active" : ""}" type="button" data-game-id="${escapeHtml(game.id)}" aria-label="Open ${escapeHtml(game.name)}">
          ${gameLogo(game)}
          <span>
            <strong>${escapeHtml(game.name)}</strong>
            <span>${escapeHtml(status)}</span>
          </span>
        </button>
      `;
    })
    .join("");

  elements.quickGames.querySelectorAll("[data-game-id]").forEach((button) => {
    button.addEventListener("click", () => {
      openGame(button.dataset.gameId);
    });
  });
}

function renderGameList() {
  elements.gameList.innerHTML = "";
  const search = document.querySelector("#gameSearch").value.trim().toLowerCase();
  [
    { source: "official", title: "Official imports", detail: "Paste share results" },
    { source: "custom", title: "Your games", detail: "Manual scores" },
    { source: "solvry", title: "Solvry games", detail: "In-app versions" }
  ].forEach((section) => {
    const games = getSortedGames().filter((game) => gameSource(game) === section.source && game.name.toLowerCase().includes(search) && (!pinnedOnly || state.pinnedGameIds.includes(game.id)));
    if (!games.length) return;
    const heading = document.createElement("div");
    heading.className = "game-section-label";
    heading.innerHTML = `<strong>${escapeHtml(section.title)}</strong><span>${escapeHtml(section.detail)}</span>`;
    elements.gameList.append(heading);
    games.forEach((game) => {
      elements.gameList.append(renderGameCard(game));
    });
  });
  if (!elements.gameList.children.length) elements.gameList.innerHTML = `<p class="social-empty">${pinnedOnly ? "No pinned games match. Turn off Pinned only to browse the catalog." : "No matching games. Try another name, or add a custom game under Enter manually."}</p>`;
}

function renderGameCard(game) {
    const entries = getGameEntries(state.selectedDate, game.id);
    const playedCount = getPeople().filter((person) => entries[person.id]).length;
    const isPinned = state.pinnedGameIds.includes(game.id);
    const card = document.createElement("article");
    card.className = `game-card ${gameSource(game)}${game.id === state.activeGameId ? " active" : ""}${isPinned ? " pinned" : ""}`;
    card.innerHTML = `
      <button class="game-select" type="button" aria-label="Select ${escapeHtml(game.name)}">
        ${gameLogo(game)}
        <span class="game-meta">
          <strong>${escapeHtml(game.name)}</strong>
          <span>${scoreStyleLabel(game)}</span>
        </span>
        <span class="game-score" aria-label="${entries.you ? "Result saved" : "No result yet"}">${entries.you ? "✓" : ""}</span>
      </button>
      <button class="pin-button${isPinned ? " active" : ""}" type="button" aria-pressed="${isPinned}" title="${isPinned ? "Unpin" : "Pin"} ${escapeHtml(game.name)}" aria-label="${isPinned ? "Unpin" : "Pin"} ${escapeHtml(game.name)}">
        ${pinIcon(isPinned)}
      </button>
    `;
    card.querySelector(".game-select").addEventListener("click", () => {
      openGame(game.id);
    });
    card.querySelector(".pin-button").addEventListener("click", () => {
      togglePin(game.id);
    });
    return card;
}

function getSortedGames() {
  const pinned = new Set(state.pinnedGameIds);
  return visibleGames().sort((a, b) => {
    const sourceDelta = sourceOrder(gameSource(a)) - sourceOrder(gameSource(b));
    if (sourceDelta) return sourceDelta;
    const pinDelta = Number(pinned.has(b.id)) - Number(pinned.has(a.id));
    if (pinDelta) return pinDelta;
    return state.games.findIndex((game) => game.id === a.id) - state.games.findIndex((game) => game.id === b.id);
  });
}

function gameSource(game) {
  return game.source || "official";
}

function sourceOrder(source) {
  return source === "official" ? 0 : source === "custom" ? 1 : 2;
}

function togglePin(gameId) {
  const previousPins = [...state.pinnedGameIds];
  if (state.pinnedGameIds.includes(gameId)) {
    state.pinnedGameIds = state.pinnedGameIds.filter((id) => id !== gameId);
  } else {
    state.pinnedGameIds = [...state.pinnedGameIds, gameId];
  }
  try { saveState(); } catch {
    state.pinnedGameIds = previousPins;
    showAppNotice("Couldn't save your pins. Try again when device storage is available.");
  }
  render();
}

// One stroke-based icon family, rendered locally without an external dependency.
function gameLogo(game) {
  const paths = {
    wordle: '<rect x="3" y="3" width="18" height="18" rx="1"/><path d="M9 3v18M15 3v18M3 9h18M3 15h18"/>',
    connections: '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
    strands: '<circle cx="5" cy="6" r="2"/><circle cx="19" cy="18" r="2"/><path d="M7 6h8a4 4 0 0 1 0 8H9a4 4 0 0 0 0 8h8M17 18h-5"/>',
    'mini-crossword': '<rect x="3" y="3" width="18" height="18" rx="1"/><path d="M9 3v18M15 3v18M3 9h18M3 15h18"/><path d="M9 9h6v6H9z" fill="currentColor"/>',
    'spelling-bee': '<path d="m12 2 8 5v10l-8 5-8-5V7zM4 7l8 5 8-5M12 12v10"/>',
    krillion: '<path d="M12 3C9 7 5 11 5 15a7 7 0 0 0 14 0c0-4-4-8-7-12zM8 16h8"/>',
    'daily-tens': '<path d="M9 5h12M9 12h12M9 19h12M3 5h1M3 12h1M3 19h1"/>',
    centumth: '<path d="M5 21V13h4v8M10 21V8h4v13M15 21V3h4v18"/>',
    globle: '<circle cx="12" cy="12" r="9"/><ellipse cx="12" cy="12" rx="4" ry="9"/><path d="M3 12h18"/>',
    flagcognito: '<path d="M5 22V3c5-4 9 4 14 0v11c-5 4-9-4-14 0"/>',
    'size-it-up': '<path d="m3 17 14-14 4 4L7 21zM7 13l2 2M11 9l2 2M15 5l2 2"/>',
    color: '<path d="M12 3C9 7 5 11 5 15a7 7 0 0 0 14 0c0-4-4-8-7-12zM12 10v10"/>',
    'buzzfeed-trivia': '<circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 1 1 5 2c-1 1-2 1-2 3M12 17h.01"/>',
    immaculate: '<rect x="3" y="3" width="18" height="18" rx="1"/><path d="M9 3v18M15 3v18M3 9h18M3 15h18"/>'
  };
  const drawing = paths[game.logo || game.id] || '<rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 8h8M8 12h8M8 16h5"/>';
  return `<span class="game-logo" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">${drawing}</svg></span>`;
}

function pinIcon(isPinned) {
  return isPinned
    ? `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 3h10l-2 7 4 4v2h-6v5l-1 1-1-1v-5H5v-2l4-4z" fill="currentColor"/></svg>`
    : `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 3h8l-2 7 4 4v2h-5v5l-1 1-1-1v-5H6v-2l4-4z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/></svg>`;
}

function renderOfficialLink(game) {
  if (gameSource(game) === "solvry") {
    elements.officialLink.href = "#today";
    elements.officialLink.textContent = "Play in Solvry";
    elements.officialLink.classList.add("disabled");
    elements.officialLink.setAttribute("aria-disabled", "true");
    return;
  }

  if (game?.officialUrl) {
    elements.officialLink.href = game.officialUrl;
    elements.officialLink.textContent = `Play ${game.name}`;
    elements.officialLink.classList.remove("disabled");
    elements.officialLink.removeAttribute("aria-disabled");
  } else {
    elements.officialLink.href = "#";
    elements.officialLink.textContent = "No official link";
    elements.officialLink.classList.add("disabled");
    elements.officialLink.setAttribute("aria-disabled", "true");
  }
}

function renderBoard(seedText) {
  elements.letterBoard.hidden = true;
  elements.letterBoard.innerHTML = "";
}

function setScoreMethod(method) {
  scoreMethod = method;
  elements.pastePanel.hidden = method !== "paste";
  elements.manualEntry.hidden = method !== "manual";
  [elements.pasteTab, elements.manualTab].forEach((tab, index) => {
    const selected = (index === 1) === (method === "manual");
    tab.setAttribute("aria-selected", String(selected));
    tab.tabIndex = selected ? 0 : -1;
  });
  if (method === "manual") renderForm();
}

function renderForm() {
  const activeGame = getActiveGame();
  elements.manualEntry.hidden = scoreMethod !== "manual" || gameSource(activeGame) === "solvry";
  if (gameSource(activeGame) === "solvry") {
    elements.entryForm.hidden = true;
    return;
  }
  elements.entryForm.hidden = false;
  elements.manualGameInput.innerHTML = state.games.filter((game) => gameSource(game) !== "solvry")
    .map((game) => `<option value="${escapeHtml(game.id)}">${escapeHtml(game.name)}</option>`).join("")
    + '<option value="__other__">Other game…</option>';
  elements.manualGameInput.value = activeGame.id;
  const date = elements.manualDateInput.value;
  const entry = state.entries[date]?.[activeGame.id]?.you;
  elements.manualExisting.hidden = !entry;
  elements.manualExisting.textContent = entry ? `${entry.score} is already saved for ${date}. Saving will replace it with a Manual entry.` : "";
  elements.manualSaveButton.textContent = entry ? "Replace saved score" : "Save score";
  const key = `${activeGame.id}:${date}`;
  if (manualFormKey === key && manualFormDirty) return;
  manualFormKey = key;
  manualFormDirty = false;
  elements.saveStatus.textContent = "";
  elements.scoreInput.setCustomValidity("");
  elements.resultInput.value = entry?.result || (activeGame.id === "krillion" || activeGame.id === "spelling-bee" ? "played" : "solved");
  updateManualScoreField();
  elements.scoreInput.value = activeGame.type === "time" ? entry?.score || "" : String(entry?.score || "").match(/-?\d+(?:\.\d+)?/)?.[0] || (entry?.score === "No hints" ? "0" : "");
  if (activeGame.type === "rank") {
    const rank = entry?.score?.split(" · ")[0];
    elements.manualRankInput.value = rank === "Moving" ? "Moving Up" : rank || "Beginner";
  }
  document.querySelector("#rarityInput").value = entry?.score?.match(/rarity (\d+(?:\.\d+)?)/i)?.[1] || "";
  elements.answerInput.value = entry?.answer || "";
  elements.noteInput.value = entry?.note || "";
  elements.revealInput.checked = Boolean(entry?.reveal);
}

function updateManualScoreField() {
  const game = getActiveGame();
  const fields = {
    wordle: ["Guesses", "3", "1 to 6 guesses", 1, 6],
    connections: ["Mistakes", "0", "0 to 4 mistakes", 0, 4],
    strands: ["Hints used", "0", "0 for no hints", 0, 999],
    "mini-crossword": ["Time", "00:54", "Minutes:seconds, e.g. 00:54", 0, 0],
    "spelling-bee": ["Rank", "", "Best rank reached", 0, 0],
    krillion: ["Depth score", "110", "Final depth score", 0, 9999]
  };
  const customFields = {
    grid: ["Correct answers", "9", "Correct answers out of 9", 0, 9],
    points: ["Score", "100", "Higher is better", -1000000000, 1000000000],
    strokes: ["Score", "10", "Lower is better", -1000000000, 1000000000],
    time: ["Time", "01:30", "Minutes:seconds or hours:minutes:seconds", 0, 0],
    guesses: ["Guesses", "7", "Total guesses", 1, 1000000],
    mistakes: ["Mistakes", "0", "Total mistakes", 0, 1000000],
    complete: ["Completion", "", "", 0, 0]
  };
  const [label, example, help, min, max] = fields[game.id] || (game.maxScore ? ["Score", String(game.maxScore), `Score out of ${game.maxScore}`, 0, game.maxScore] : customFields[game.type]);
  const rarityInput = document.querySelector("#rarityInput");
  document.querySelector("#rarityField").hidden = game.type !== "grid";
  rarityInput.disabled = game.type !== "grid";
  rarityInput.required = game.type === "grid";
  elements.manualScoreLabel.textContent = label;
  elements.scoreHelp.textContent = help;
  const isRank = game.type === "rank";
  elements.manualScoreLabel.htmlFor = isRank ? "manualRankInput" : "scoreInput";
  elements.resultInput.closest("label").hidden = isRank || (ADDITIONAL_IMPORT_GAMES.some((item) => item.id === game.id) && game.id !== "connections-sports");
  const missedWordle = game.id === "wordle" && elements.resultInput.value === "missed";
  const completionOnly = game.source === "custom" && game.type === "complete";
  elements.manualScoreLabel.closest(".manual-score-field").hidden = completionOnly;
  elements.scoreInput.hidden = isRank || missedWordle || completionOnly;
  elements.scoreInput.disabled = isRank || missedWordle || completionOnly;
  elements.scoreInput.required = !isRank && !missedWordle && !completionOnly;
  elements.scoreInput.type = game.type === "time" ? "text" : "number";
  elements.scoreInput.inputMode = game.type === "time" ? "text" : "numeric";
  elements.scoreInput.min = String(min);
  elements.scoreInput.max = String(max);
  elements.scoreInput.step = game.decimalScore ? "any" : game.source === "custom" && ["points", "strokes"].includes(game.type) ? "any" : "1";
  elements.scoreInput.placeholder = example;
  elements.manualRankInput.hidden = !isRank;
  elements.manualRankInput.disabled = !isRank;
  if (missedWordle) elements.scoreHelp.textContent = "X/6";
}

function normalizeManualScore(gameId, result, raw, rank, rarity = "") {
  const value = String(raw).trim();
  if (gameId === "wordle" && result === "missed") return { score: "X/6", result };
  if (gameId === "mini-crossword") {
    if (!/^\d{1,3}:[0-5]\d$/.test(value)) return { error: "Enter a time like 00:54 or 12:03." };
    return { score: value.padStart(5, "0"), result };
  }
  if (gameId === "spelling-bee") {
    if (!["Beginner", "Good Start", "Moving Up", "Good", "Solid", "Nice", "Great", "Amazing", "Genius", "Queen Bee"].includes(rank)) return { error: "Choose your Spelling Bee rank." };
    return { score: rank, result: rank === "Queen Bee" ? "solved" : "played" };
  }
  const added = ADDITIONAL_IMPORT_GAMES.find((game) => game.id === gameId);
  if (added && gameId !== "connections-sports") {
    const number = Number(value);
    if (added.type === "grid") {
      if (!/^\d+$/.test(value) || number > 9 || !/^\d+(?:\.\d+)?$/.test(String(rarity)) || Number(rarity) > 900) return { error: "Enter 0–9 correct and a rarity score from 0–900 (not a percentage)." };
      return { score: `${number}/9 · rarity ${Number(rarity)}`, result: number === 9 ? "solved" : "played" };
    }
    const valid = added.decimalScore ? /^\d+(?:\.\d{1,2})?$/.test(value) : /^\d+$/.test(value);
    const max = added.maxScore || 1000000;
    const min = added.type === "guesses" ? 1 : 0;
    if (!valid || number < min || number > max) return { error: `Enter ${min} to ${max}${added.decimalScore ? " (up to two decimals)" : " as a whole number"}.` };
    return { score: added.type === "guesses" ? `${number} guess${number === 1 ? "" : "es"}` : `${number}/${max}`, result: added.type === "guesses" || (["daily-tens", "buzzfeed-trivia"].includes(gameId) && number === max) ? "solved" : "played" };
  }
  if (gameId === "connections-sports") gameId = "connections";
  const max = { wordle: 6, connections: 4, strands: 999, krillion: 9999 }[gameId];
  const min = gameId === "wordle" ? 1 : 0;
  const number = Number(value);
  if (max === undefined || !/^\d+$/.test(value) || !Number.isInteger(number) || number < min || number > max) {
    return { error: `Enter a whole number from ${min} to ${max ?? 9999}.` };
  }
  if (gameId === "wordle") return { score: `${number}/6`, result };
  if (gameId === "connections") return { score: `${number} mistake${number === 1 ? "" : "s"}`, result: number === 4 ? "missed" : result };
  if (gameId === "strands") return { score: number ? `${number} hint${number === 1 ? "" : "s"}` : "No hints", result };
  return { score: String(number), result };
}

function normalizeCustomScore(type, result, raw) {
  const value = String(raw).trim();
  if (type === "complete") return { score: result === "solved" ? "Complete" : result === "missed" ? "Missed" : "Played", result };
  if (type === "time") {
    if (!/^\d{1,3}:[0-5]\d(?::[0-5]\d)?$/.test(value)) return { error: "Enter a time like 01:30 or 1:02:30." };
    return { score: value.padStart(5, "0"), result };
  }
  if (["guesses", "mistakes"].includes(type)) {
    const number = Number(value);
    if (!/^\d+$/.test(value) || number < (type === "guesses" ? 1 : 0) || number > 1000000) return { error: "Enter a valid whole-number count." };
    return { score: `${number} ${type === "guesses" ? number === 1 ? "guess" : "guesses" : number === 1 ? "mistake" : "mistakes"}`, result };
  }
  if (["points", "strokes"].includes(type) && /^-?\d+(?:\.\d+)?$/.test(value) && Math.abs(Number(value)) <= 1000000000) return { score: String(Number(value)), result };
  return { error: "Enter a valid score between -1,000,000,000 and 1,000,000,000." };
}

function saveManualScore() {
  const game = getActiveGame();
  if (gameSource(game) === "solvry") return;
  const date = elements.manualDateInput.value;
  if (!date || !elements.manualDateInput.validity.valid) { elements.manualDateInput.reportValidity(); return; }
  const normalized = game.source === "custom"
    ? normalizeCustomScore(game.type, elements.resultInput.value, elements.scoreInput.value)
    : normalizeManualScore(game.id, elements.resultInput.value, elements.scoreInput.value, elements.manualRankInput.value, document.querySelector("#rarityInput").value);
  if (normalized.error) {
    elements.saveStatus.className = "save-status error";
    elements.saveStatus.textContent = normalized.error;
    elements.scoreInput.focus();
    return;
  }
  const entries = getGameEntries(date, game.id);
  const previous = entries.you;
  const previousDate = state.selectedDate;
  entries.you = { ...normalized, source: "manual", answer: elements.answerInput.value.trim(), note: elements.noteInput.value.trim(), reveal: elements.revealInput.checked };
  state.selectedDate = date;
  try { saveState(); } catch {
    if (previous) entries.you = previous;
    else delete entries.you;
    state.selectedDate = previousDate;
    elements.saveStatus.className = "save-status error";
    elements.saveStatus.textContent = "Couldn't save on this device. Your entries are still here; try again.";
    return;
  }
  elements.playDate.value = date;
  elements.importDate.value = date;
  manualFormDirty = false;
  render();
  elements.saveStatus.className = "save-status success";
  elements.saveStatus.textContent = `${game.name} saved for ${date}. Manual score added to the leaderboard.`;
  document.querySelector("#scoreNextSteps").hidden = false;
}

function renderMetrics() {
  const dayEntries = state.entries[state.selectedDate] || {};
  let played = 0;
  let completed = 0;

  visibleGames().forEach((game) => {
    const gameEntries = dayEntries[game.id] || {};
    const mine = gameEntries.you;
    if (!mine) return;
    played += 1;
    if (isCompletedResult(mine.result)) completed += 1;
  });

  elements.playedMetric.textContent = played;
  elements.solvedMetric.textContent = completed;
  elements.streakMetric.textContent = calculateStreak();
  elements.totalSolvesMetric.textContent = Object.values(state.entries).reduce((count, day) => count + visibleGames().filter((game) => day[game.id]?.you).length, 0);
  renderProgressDays();
}

function renderProgressDays() {
  const baseDate = new Date(`${state.selectedDate}T00:00:00`);
  const days = [];

  for (let offset = -4; offset <= 0; offset += 1) {
    const date = new Date(baseDate);
    date.setDate(baseDate.getDate() + offset);
    const key = localDateKey(date);
    const played = hasUserPlayedDate(key);
    const isToday = key === today;
    days.push(`
      <div class="progress-day${played ? " done" : ""}${isToday ? " today" : ""}">
        <strong>${escapeHtml(shortWeekday(date))}</strong>
        <span>${played ? "Recorded" : "—"}</span>
      </div>
    `);
  }

  elements.progressDays.innerHTML = days.join("");
}

function renderScoreboards(activeGame) {
  elements.leaderboardDate.value = state.selectedDate;
  elements.leaderboardDate.max = today;
  const game = visibleGames().find((item) => item.id === leaderboardGameId) || activeGame;
  leaderboardGameId = game.id;
  elements.leaderboardGameInput.innerHTML = visibleGames().map((item) => `<option value="${escapeHtml(item.id)}">${escapeHtml(item.name)}</option>`).join("");
  elements.leaderboardGameInput.value = game.id;
  elements.gameScoreboardTitle.textContent = `${game.name} scoreboard`;
  elements.gameScoreboardMeta.textContent = scoreStyleLabel(game);
  elements.gameScoreboardNote.textContent = scoreStyleHelp(game);
  const overall = leaderboardView === "overall";
  [elements.overallTab, elements.gameBoardTab].forEach((tab, index) => {
    const selected = overall === (index === 0);
    tab.setAttribute("aria-selected", String(selected));
    tab.tabIndex = selected ? 0 : -1;
  });
  elements.overallBoard.hidden = !overall;
  elements.gameBoard.hidden = overall;
  elements.leaderboardRangeLabel.hidden = !overall;
  elements.leaderboardGameLabel.hidden = overall;
  const dates = leaderboardDates(overall ? leaderboardDays : 1);
  elements.leaderboardDates.textContent = dates.length > 1 ? `${dates[dates.length - 1]} – ${dates[0]}` : dates[0];
  const overallRows = buildOverallLeaderboard(leaderboardDays);
  const gameRows = buildGameLeaderboard(game);
  elements.overallLeaderboard.innerHTML = renderRankRows(overallRows, "No scores yet");
  elements.gameLeaderboard.innerHTML = renderRankRows(gameRows, `No ${game.name} scores yet`);
  const mine = (overall ? overallRows : gameRows).find((person) => person.id === "you");
  const sample = state.showDemoFriends ? " · Includes sample friends" : "";
  elements.leaderboardSummary.textContent = (mine?.rank ? `You're #${mine.rank} · ${mine.value}` : "Save a score to join these rankings.") + sample;
}

function renderRankRows(rows, emptyText) {
  if (!rows.length) {
    return `<p class="social-empty">${escapeHtml(emptyText)}. Add a score to start ranking.</p>`;
  }

  return rows
    .map(
      (person) => `
      <article class="rank-row${person.id === "you" ? " is-you" : ""}">
        <span class="rank">${person.rank || "—"}</span>
        <span>
          <strong>${person.id === "you" ? "You" : escapeHtml(person.name)}${person.demo ? " · Sample" : ""}</strong>
          <small>${escapeHtml(person.detail)}</small>
        </span>
        <span class="points">${escapeHtml(person.value)}${person.subvalue ? `<small>${escapeHtml(person.subvalue)}</small>` : ""}</span>
      </article>
    `
    )
    .join("");
}

function leaderboardDates(days = 1) {
  const end = new Date(`${state.selectedDate}T12:00:00Z`);
  return Array.from({ length: days === 7 ? 7 : 1 }, (_, offset) => {
    const date = new Date(end);
    date.setUTCDate(date.getUTCDate() - offset);
    return date.toISOString().slice(0, 10);
  });
}

function buildOverallLeaderboard(days = 1) {
  const totals = new Map(
    getPeople().map((person) => [
      person.id,
      { ...person, solvryPoints: 0, completed: 0, wins: 0, manual: 0 }
    ])
  );

  leaderboardDates(days).forEach((date) => visibleGames().forEach((game) => {
    const rows = buildGameLeaderboard(game, date, true).filter((row) => row.rank);
    rows.forEach((row) => {
      const total = totals.get(row.id);
      if (!total) return;
      const placementPoints = placementScore(row.rank - 1);
      total.solvryPoints += placementPoints;
      total.completed += 1;
      if (row.entry.source === "manual") total.manual += 1;
      if (row.rank === 1) total.wins += 1;
    });
  }));
  const rows = [...totals.values()].sort((a, b) => b.solvryPoints - a.solvryPoints || a.name.localeCompare(b.name));
  return rows.map((person) => ({
      ...person,
      rank: person.completed ? rows.findIndex((row) => row.solvryPoints === person.solvryPoints) + 1 : null,
      detail: person.completed ? `${person.completed} game${person.completed === 1 ? "" : "s"} scored · ${person.wins} first${person.wins === 1 ? "" : "s"}${person.manual ? ` · ${person.manual} Manual` : ""}` : "No ranked scores yet",
      value: person.completed ? `${person.solvryPoints} pts` : "—",
      subvalue: person.completed ? "Solvry" : ""
    }));
}

function eligibleForDailyRanking(game, entry, date) {
  if (game.dailyRanked !== false) return true;
  if (game.id !== "color" || entry?.source !== "official-share") return false;
  const parsed = parseShareText(entry.shareText).parsed;
  return Boolean(parsed?.gameId === "color" && parsed.dailyMonthDay && parsed.score === entry.score && !importDateError(parsed, date));
}

function buildGameLeaderboard(game, date = state.selectedDate, dailyOnly = false) {
  const entries = state.entries[date]?.[game.id] || {};
  const rows = getPeople()
    .map((person) => {
      const candidate = entries[person.id];
      const entry = dailyOnly && !eligibleForDailyRanking(game, candidate, date) ? null : candidate;
      const score = scoreEntryForGame(entry, game);
      return {
        ...person,
        entry,
        hasEntry: Boolean(entry),
        score,
        detail: entry ? `${score.detail} · ${entry.result}${entry.source === "manual" ? " · Manual" : ""}` : "Not played",
        value: entry ? score.label : "-",
        subvalue: entry ? scoreStyleLabel(game) : ""
      };
    })
    .sort((a, b) => compareScoreRows(a, b, game));
  return rows.map((row) => ({ ...row, rank: scoreTier(row, game) ? rows.findIndex((other) => compareScoreValues(row, other, game) === 0) + 1 : null }));
}

function scoreTier(row, game) {
  if (!row.hasEntry || !Number.isFinite(row.score.value) || !["solved", "played"].includes(row.entry?.result)) return 0;
  if (["guesses", "mistakes", "time", "complete"].includes(game.type)) return row.entry.result === "solved" ? 2 : 1;
  return 1;
}

function compareScoreValues(a, b, game) {
  const tier = scoreTier(b, game) - scoreTier(a, game);
  if (tier) return tier;
  if (!scoreTier(a, game)) return 0;
  if (a.score.value !== b.score.value) {
    return gameScoreDirection(game) === "high" ? b.score.value - a.score.value : a.score.value - b.score.value;
  }
  if (game.type === "grid") return a.score.rarity - b.score.rarity;
  return 0;
}

function compareScoreRows(a, b, game) {
  return compareScoreValues(a, b, game) || Number(b.hasEntry) - Number(a.hasEntry) || a.name.localeCompare(b.name);
}

function scoreEntryForGame(entry, game) {
  if (!entry) {
    return { value: Number.POSITIVE_INFINITY, label: "-", detail: "Not played" };
  }

  const score = String(entry.score || "").trim();
  const type = game.type;
  if (type === "grid") {
    const match = score.match(/^(\d)\/9 · rarity (\d+(?:\.\d+)?)$/);
    const valid = match && Number(match[2]) <= 900;
    return { value: valid ? Number(match[1]) : Infinity, rarity: valid ? Number(match[2]) : Infinity, label: score, detail: "Most correct, then lowest rarity" };
  }
  if (type === "time") return parseTimeScore(score);
  if (type === "guesses") return parseGuessScore(score, entry.result);
  if (type === "mistakes") return parseNumberScore(score, "mistakes");
  if (type === "strokes") return parseNumberScore(score, "strokes");
  if (type === "rank") return parseRankScore(score);
  if (type === "points" || type === "depth") return parseNumberScore(score, type === "depth" ? "depth points" : "points", "high");
  if (type === "complete") {
    return {
      value: resultWeight(entry.result),
      label: score || defaultScoreLabel(entry.result),
      detail: entry.result === "solved" ? "Completed" : "Played"
    };
  }
  return parseNumberScore(score, "score");
}

function parseGuessScore(score, result) {
  const miss = /x\/6/i.test(score) || result === "missed";
  const match = score.match(/([1-6])\s*\/\s*6/i) || score.match(/\b([1-9]\d*)\s*(?:guess|guesses)\b/i);
  return {
    value: miss ? Number.POSITIVE_INFINITY : Number(match?.[1] || Number.POSITIVE_INFINITY),
    label: score || defaultScoreLabel(result),
    detail: miss ? "Missed" : "Fewest guesses"
  };
}

function parseTimeScore(score) {
  const parts = score.split(":").map((part) => Number(part));
  const valid = /^\d+:\d{2}(?::\d{2})?$/.test(score) && parts.every((part, index) => Number.isFinite(part) && part >= 0 && (index === 0 || part < 60));
  const seconds = valid ? parts.reduce((total, part) => total * 60 + part, 0) : Number.POSITIVE_INFINITY;
  return {
    value: seconds,
    label: score || "-",
    detail: valid ? "Fastest time" : "Time needed"
  };
}

function parseNumberScore(score, unit) {
  const match = score.match(/-?\d+(\.\d+)?/);
  const value = match ? Number(match[0]) : Number.POSITIVE_INFINITY;
  return {
    value,
    label: score || "-",
    detail: Number.isFinite(value) ? unit : "Score needed"
  };
}

function parseRankScore(score) {
  const rankMap = {
    beginner: 1,
    "good start": 2,
    moving: 3,
    good: 4,
    solid: 5,
    nice: 6,
    great: 7,
    amazing: 8,
    genius: 9,
    "queen bee": 10
  };
  const normalized = score.toLowerCase();
  const key = Object.keys(rankMap).find((rank) => normalized.includes(rank));
  return {
    value: key ? rankMap[key] : Number.NEGATIVE_INFINITY,
    label: score || "-",
    detail: key ? "Best rank" : "Rank needed"
  };
}

function renderAnswers() {
  const activeGame = getActiveGame();
  const entries = getGameEntries(state.selectedDate, state.activeGameId);
  const people = getPeople().map((person) => ({
    id: person.id || "you",
    name: person.name,
    handle: person.handle,
    entry: entries[person.id || "you"]
  }));

  elements.answerFeed.innerHTML = people
    .map((person) => {
      const entry = person.entry;
      if (!entry) {
        return `
          <article class="answer-card">
            <header>
              <span><strong>${escapeHtml(person.name)}</strong><small>${escapeHtml(activeGame.name)}</small></span>
              <span class="pill">Not played</span>
            </header>
            <div class="answer-value locked">Waiting for result</div>
          </article>
        `;
      }

      const canShow = person.id === "you" || entry.reveal;
      const answer = canShow && entry.answer ? escapeHtml(entry.answer) : "Spoiler locked";
      return `
        <article class="answer-card">
          <header>
            <span><strong>${escapeHtml(person.name)}</strong><small>${escapeHtml(entry.score)} · ${escapeHtml(entry.result)}</small></span>
            <span class="pill">${entry.reveal ? "Shown" : "Hidden"}</span>
          </header>
          <div class="answer-value${canShow && entry.answer ? "" : " locked"}">${answer}</div>
          ${entry.grid?.length ? `<div class="share-grid">${escapeHtml(entry.grid.join("\n"))}</div>` : ""}
          ${entry.note ? `<small>${escapeHtml(entry.note)}</small>` : ""}
        </article>
      `;
    })
    .join("");
}

function renderImportExample() {
  const examples = {
    wordle: "Wordle 1,234 3/6\n\n⬛🟨⬛⬛⬛\n🟩🟩🟨⬛⬛\n🟩🟩🟩🟩🟩",
    connections: "Connections\nPuzzle #123\n🟨🟨🟨🟨\n🟩🟩🟩🟩\n🟦🟦🟦🟦\n🟪🟪🟪🟪",
    strands: "Strands #123\n🔵🔵🟡🔵🔵🔵🔵",
    "mini-crossword": "I solved the Mini Crossword in 0:54!",
    "spelling-bee": "Spelling Bee\nGenius · 150 points",
    krillion: "Krillion #77\n110",
    "connections-sports": "Connections: Sports Edition\nPuzzle #123\n🟨🟨🟨🟨\n🟩🟩🟩🟩\n🟦🟦🟦🟦\n🟪🟪🟪🟪",
    "daily-tens": "DailyTens #123\n🏆 🏆\n🏆 ❌\n🏆 🏆\n❌ 🏆\n🏆 🏆\nhttps://dailytens.com/",
    centumth: "Centumth Nov 3, 2026 - Example topic\nTotal: 350/490\nhttps://www.centumth.com/",
    globle: "🌎 Nov 3, 2026 🌍\n🔥 4 | Avg. Guesses: 6.2\n🟨🟥🟩 = 3\nhttps://globle-game.com\n#globle",
    flagcognito: "Flagcognito · Nov 3, 2026\n2,400 / 3,000\nhttps://guessdash.com/flagcognito",
    "size-it-up": "Magnitudle — Size It Up\nNov 3, 2026\nScore: 425/500\nhttps://magnitudle.com/size-it-up",
    color: "My color memory is a 39.12/50.\nhttps://dialed.gg/color?c=example",
    "buzzfeed-trivia": "I got 4 out of 5 on today’s Daily Trivia. Can you beat my score? https://www.buzzfeed.com/daily-trivia"

  };
  const id = elements.importExampleGame.value;
  const gridSports = { "immaculate-baseball": "⚾", "immaculate-football": "🏈", "immaculate-basketball-men": "🏀 (Men’s)", "immaculate-basketball-women": "🏀 (Women’s)", "immaculate-hockey": "🏒" };
  elements.importExampleText.textContent = examples[id] || `${gridSports[id]} Immaculate Grid 123 9/9:\nRarity: 75\n🟩🟩🟩\n🟩🟩🟩\n🟩🟩🟩`;
  elements.importExampleLink.href = state.games.find((game) => game.id === id)?.officialUrl || "#";
}

// Drafts belong to the selected game; successful saves remain visible until navigation.
function switchImportDraft(previousGameId, nextGameId) {
  const text = elements.shareTextInput.value;
  const date = elements.importDate.value;
  const parsed = parseShareText(text).parsed;
  const saved = parsed && sameImportedScore(state.entries[date]?.[parsed.gameId]?.you, parsed);
  if (text.trim() && !saved) importDrafts.set(previousGameId, { text, date });
  else importDrafts.delete(previousGameId);
  const next = importDrafts.get(nextGameId);
  elements.shareTextInput.value = next?.text || "";
  elements.importDate.value = next?.date || state.selectedDate;
  importDraftRevision += 1;
}

function importDateError(parsed, date) {
  if (!parsed.dailyMonthDay) return "";
  if (date.slice(5) === parsed.dailyMonthDay && (!parsed.dailyYear || date.slice(0, 4) === parsed.dailyYear)) return "";
  return `This Color Daily result is dated ${parsed.dailyYear ? parsed.dailyYear + "-" : ""}${parsed.dailyMonthDay}, but Played on is ${date}. Change Played on to the result's date before saving.`;
}

function sameImportedScore(entry, parsed) {
  return entry?.source === "official-share" && entry.result === parsed.result && entry.score === parsed.score
    && entry.shareText === elements.shareTextInput.value.trim();
}

function previewImport(showEmptyError = false) {
  const text = elements.shareTextInput.value.trim();
  const { parsed, error } = parseShareText(text);
  elements.importPasteButton.disabled = true;
  elements.importPasteButton.textContent = "Save score";
  elements.sharePreview.hidden = true;
  elements.sharePreview.innerHTML = "";
  document.querySelector("#scoreNextSteps").hidden = true;
  elements.importClearButton.hidden = !text;
  elements.importClearButton.textContent = "Clear";
  elements.shareTextInput.removeAttribute("aria-invalid");
  if (!text && !showEmptyError) { setImportStatus(""); return null; }
  if (!parsed) {
    elements.shareTextInput.setAttribute("aria-invalid", "true");
    setImportStatus(error, "error");
    return null;
  }
  const game = state.games.find((item) => item.id === parsed.gameId);
  if (!game) { setImportStatus("This game isn't available in your game list.", "error"); return null; }
  const date = elements.importDate.value;
  if (!date || !elements.importDate.validity.valid) {
    setImportStatus("Choose the day you played, up to today.", "error");
    return null;
  }
  const dateError = importDateError(parsed, date);
  if (dateError) { setImportStatus(dateError, "error"); return null; }
  const existing = state.entries[date]?.[game.id]?.you;
  const duplicate = sameImportedScore(existing, parsed);
  renderSharePreview(parsed, game, date, existing, duplicate);
  if (duplicate) {
    document.querySelector("#scoreNextSteps").hidden = false;
    setImportStatus(`Already saved for ${date}. No duplicate added.`, "success");
    elements.importPasteButton.textContent = "Already saved";
    elements.importClearButton.textContent = "Add another score";
    return null;
  }
  elements.importPasteButton.disabled = false;
  elements.importPasteButton.textContent = existing ? "Replace saved score" : "Save score";
  setImportStatus("");
  return { parsed, game, date, existing };
}

function importShareText(text) {
  const draft = previewImport(true);
  if (!draft) return;
  const { parsed, game, date, existing } = draft;
  const entry = {
    ...existing,
    result: parsed.result,
    score: parsed.score,
    answer: existing?.answer || "",
    note: existing?.note || parsed.note,
    reveal: existing?.reveal || false,
    source: "official-share",
    shareText: text.trim(),
    grid: parsed.grid
  };
  const previousDate = state.selectedDate;
  const previousGame = state.activeGameId;
  state.activeGameId = game.id;
  state.selectedDate = date;
  const gameEntries = getGameEntries(date, game.id);
  gameEntries.you = entry;
  try {
    saveState();
  } catch {
    if (existing) gameEntries.you = existing;
    else delete gameEntries.you;
    state.selectedDate = previousDate;
    state.activeGameId = previousGame;
    setImportStatus("Couldn't save on this device. Your pasted result is still here; free some browser storage and try again.", "error");
    return;
  }
  elements.playDate.value = date;
  elements.manualDateInput.value = date;
  manualFormDirty = false;
  importDrafts.delete(previousGame);
  importDrafts.delete(game.id);
  lastRenderedGameId = game.id;
  importDraftRevision += 1;
  render();
  setImportStatus(`${game.name} saved for ${date}. Scoreboards updated.`, "success");
  elements.importClearButton.focus({ preventScroll: true });
}

function parseShareText(text) {
  const cleaned = String(text || "").trim();
  if (!cleaned) return { parsed: null, error: "Paste a share result first." };
  if (cleaned.length > 12000) return { parsed: null, error: "That text is too long. Paste just one game's shared result." };

  const lines = normalizeShareLines(cleaned);
  const attempts = [
    parseWordleShare(lines),
    parseConnectionsShare(lines),
    parseStrandsShare(lines),
    parseMiniCrosswordShare(lines),
    parseSpellingBeeShare(lines),
    parseKrillionShare(lines),
    parseAdditionalShare(lines)
  ];
  if (attempts.filter((attempt) => attempt.parsed || attempt.error).length > 1) {
    return { parsed: null, error: "There is more than one game here. Paste one result at a time so each score goes to the right scoreboard." };
  }
  const parsedAttempt = attempts.find((attempt) => attempt.parsed);
  if (parsedAttempt) return parsedAttempt;

  const knownError = attempts.find((attempt) => attempt.error);
  return knownError || {
    parsed: null,
    error: "I could not identify this result. Copy the full result including its game name or link. Check Supported games & sample results, or use Enter manually for another game."
  };
}

function parseAdditionalShare(lines) {
  const text = lines.join("\n");
  const games = [
    ["daily-tens", /\bDaily\s*Tens\b/i], ["centumth", /\bCentumth\b/i],
    ["globle", /(?:#globle\b|globle-game\.com|^Globle\b)/im],
    ["flagcognito", /\bFlagcognito\b/i], ["size-it-up", /\bSize It Up\b|magnitudle\.com\/size-it-up/i],
    ["color", /dialed\.gg\/color(?:[?\s/#]|$)/i],
    ["buzzfeed-trivia", /buzzfeed\.com\/daily-trivia|BuzzFeed.*Daily Trivia/i],
    ["immaculate", /\bImmaculate Grid\b/i]
  ].filter(([, pattern]) => pattern.test(text));
  const fail = (error) => ({ parsed: null, error });
  if (!games.length) return { parsed: null };
  if (games.length > 1) return fail("Paste one result at a time so each game reaches the right scoreboard.");
  const id = games[0][0];
  const finish = (gameId, score, result = "played", grid = []) => ({ parsed: { gameId, score, result, grid, note: "Imported shared result" } });
  const total = (pattern, max, decimal = false) => {
    const matches = [...text.matchAll(pattern)];
    if (matches.length !== 1) return null;
    const raw = matches[0][1].replace(/,/g, "");
    const denominator = matches[0][2].replace(/,/g, "");
    const number = Number(raw);
    return (decimal ? /^\d+(?:\.\d{1,2})?$/.test(raw) : /^\d+$/.test(raw)) && Number(denominator) === max && number >= 0 && number <= max ? number : null;
  };
  if (id === "daily-tens") {
    const grid = lines.map(compactEmojiLine).filter((line) => /[🏆❌]/u.test(line));
    if (grid.length !== 5 || grid.some((line) => !/^[🏆❌]{2}$/u.test(line))) return fail("Daily Tens needs all five rows of two trophies/crosses. Copy the full result from Share.");
    const correct = (grid.join("").match(/🏆/gu) || []).length;
    return finish(id, `${correct}/10`, correct === 10 ? "solved" : "played", grid);
  }
  if (id === "centumth") {
    const score = total(/^Total:\s*([\d,]+)\s*\/\s*(\d+)(?![\d.])/gim, 490);
    return score === null ? fail("Copy Centumth’s final Total: …/490 line. Individual guesses and Arcade scores aren't the daily total.") : finish(id, `${score}/490`);
  }
  if (id === "globle") {
    if (/capitals/i.test(text)) return fail("This is Globle Capitals. Use a separate Other game entry; Globle tracks the country game.");
    const results = lines.filter((line) => /=/.test(line));
    const match = results.length === 1 && results[0].match(/^[\s🟥🟧🟨🟩🟦🟪⬜⬛]+\s*=\s*([1-9]\d*)$/u);
    if (!match || Number(match[1]) > 1000000) return fail("Copy Globle’s completed emoji result with = followed by today's guess count. A streak or average isn't a daily score.");
    return finish(id, `${Number(match[1])} guess${Number(match[1]) === 1 ? "" : "es"}`, "solved", results);
  }
  if (id === "flagcognito") {
    const score = total(/^\s*([\d,]+)\s*\/\s*([\d,]+)\s*$/gm, 3000);
    return score === null ? fail("Copy Flagcognito’s final total out of 3,000, including the game name. Tap counts and distances aren't the score.") : finish(id, `${score}/3000`);
  }
  if (id === "size-it-up") {
    if (/\b(practice|unlimited|pop culture|weekly|geography)\b/i.test(text)) return fail("This scoreboard is for original daily Size It Up. Track other editions or practice with a separate Other game entry.");
    if (!/magnitudle/i.test(text)) return fail("Include the Magnitudle name or official Size It Up link so we can identify the edition.");
    const score = total(/^Score:\s*([\d,]+)\s*\/\s*(\d+)\s*$/gim, 500);
    return score === null ? fail("Copy Size It Up’s final Score: …/500 line, not an individual round.") : finish(id, `${score}/500`);
  }
  if (id === "color") {
    if (/dialed\.gg\/color\/(?:live|toon)|\blive game\b/i.test(text)) return fail("Use the Color memory result, not a live room or another Dialed game.");
    const score = total(/(?<![\w.\-])(\d+(?:\.\d+)?)\s*\/\s*(50)(?!\d|\.\d)/g, 50, true);
    if (score === null) return fail("This Color link doesn't include a readable score. Copy the result text with your score out of 50, or enter it manually.");
    const output = finish(id, `${score}/50`);
    if (/^Color Daily\b/im.test(text)) {
      const daily = text.match(/^Color Daily\s*[—–-]\s*([A-Za-z]+)\s+(\d{1,2})(?:,?\s+(\d{4}))?\s*$/im);
      const months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
      const month = daily ? months.indexOf(daily[1].slice(0, 3).toLowerCase()) + 1 : 0;
      const day = daily ? Number(daily[2]) : 0;
      const validDay = new Date(Date.UTC(Number(daily?.[3] || 2024), month - 1, day)).getUTCDate() === day;
      if (!daily || !month || !day || !validDay || !/https?:\/\/(?:www\.)?dialed\.gg\/color\?[^\s]*\bd=1(?:&|$|\s)/im.test(text)) return fail("Copy the complete Color Daily result including its date and daily link.");
      output.parsed.dailyMonthDay = `${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
      output.parsed.dailyYear = daily[3] || null;
      output.parsed.note = "Imported Color Daily result";
    }
    return output;
  }
  if (id === "buzzfeed-trivia") {
    const score = total(/\bI got\s+(\d+)\s+out of\s+(\d+)\b/gi, 5);
    return score === null ? fail("Copy BuzzFeed Daily Trivia’s full result: I got … out of 5, plus the Daily Trivia link.") : finish(id, `${score}/5`, score === 5 ? "solved" : "played");
  }
  const headers = lines.filter((line) => /Immaculate Grid/i.test(line));
  if (headers.length !== 1) return fail("Paste one Immaculate Grid result, with its sport and rarity score.");
  const sportMatches = [
    ["baseball", /⚾|\bbaseball\b/i], ["football", /🏈|\bfootball\b/i],
    ["basketball-women", /\bwomen[’']?s\b|\/basketball\/womens\//i],
    ["hockey", /🏒|\bhockey\b/i]
  ].filter(([, pattern]) => pattern.test(text));
  if (/🏀|\bbasketball\b|\bmen[’']?s\b/i.test(text) && !sportMatches.some(([sport]) => sport === "basketball-women")) sportMatches.push(["basketball-men"]);
  if (sportMatches.length !== 1) return fail("Include the sport emoji or name in your Immaculate Grid result so it goes to the correct sport's scoreboard.");
  const count = headers[0].match(/\b([0-9])\s*\/\s*9\b/);
  const rarities = lines.filter((line) => /^Rarity(?: score)?:/i.test(line));
  const rarity = rarities.length === 1 && rarities[0].match(/^Rarity(?: score)?:\s*(\d+(?:\.\d+)?)\s*$/i);
  if (!count || !rarity || Number(rarity[1]) > 900) return fail("Include correct answers out of 9 and Rarity: followed by its score (0–900). Rarity is not a percentage.");
  const grid = lines.map(compactEmojiLine).filter((line) => /[🟩⬜⬛]/u.test(line));
  if (grid.length && (grid.length !== 3 || grid.some((line) => !/^[🟩⬜⬛]{3}$/u.test(line)) || (grid.join("").match(/🟩/gu) || []).length !== Number(count[1]))) return fail("The Immaculate Grid squares don't match the score. Copy the complete 3×3 result again.");
  return finish(`immaculate-${sportMatches[0][0]}`, `${Number(count[1])}/9 · rarity ${Number(rarity[1])}`, count[1] === "9" ? "solved" : "played", grid);
}

function parseWordleShare(lines) {
  const wordleLine = lines.find((line) => /^Wordle\b/i.test(line));
  if (!wordleLine) return { parsed: null };

  const scoreMatch = wordleLine.match(/^Wordle\s+#?([\d,]+)?\s*([1-6X])\/6\*?/i)
    || lines.join(" ").match(/\bWordle\b.*?\b#?([\d,]+)?\s*([1-6X])\/6\*?/i);
  if (!scoreMatch) {
    return {
      parsed: null,
      error: "I found Wordle, but I could not find a score like 4/6 or X/6. Paste the result line plus the emoji grid."
    };
  }

  const gridPattern = /^[\u{1F7E9}\u{1F7E8}\u{2B1B}\u{2B1C}\u{1F7E6}]+$/u;
  const grid = lines
    .map(compactEmojiLine)
    .filter((line) => gridPattern.test(line));
  const rawScore = scoreMatch[2].toUpperCase();
  const score = `${rawScore}/6`;

  return {
    parsed: {
      gameId: "wordle",
      score,
      result: rawScore === "X" ? "missed" : "solved",
      note: `Imported official Wordle${scoreMatch[1] ? ` #${scoreMatch[1]}` : ""}${grid.length ? ` with ${grid.length} rows` : ""}`,
      grid
    }
  };
}

function parseConnectionsShare(lines) {
  const text = lines.join(" ");
  const header = lines.find((line) => /^Connections\b/i.test(line)) || (/\bConnections\b/i.test(text) ? text : "");
  if (!header) return { parsed: null };

  const sports = /Connections\s*:?\s*Sports Edition/i.test(header);
  const headers = lines.filter((line) => /^Connections\b/i.test(line));
  if (headers.length > 1) return { parsed: null, error: "Paste one Connections result at a time, including its edition." };
  const gridPattern = /^[\u{1F7E8}\u{1F7E9}\u{1F7E6}\u{1F7EA}]{4}$/u;
  const grid = lines
    .map((line) => sports ? line.replace(/🟡/gu, "🟨").replace(/🟢/gu, "🟩").replace(/🔵/gu, "🟦").replace(/🟣/gu, "🟪") : line)
    .map(compactEmojiLine)
    .filter((line) => gridPattern.test(line));
  if (!grid.length) {
    return {
      parsed: null,
      error: "I found Connections, but I could not find the four-color emoji grid. Paste the full shared result, including the colored square rows."
    };
  }

  const puzzleMatch = text.match(/(?:Puzzle\s*)?#\s*([\d,]+)/i) || text.match(/\bConnections\s+#?([\d,]+)/i);
  const correctRows = grid.filter((line) => /^([\u{1F7E8}]{4}|[\u{1F7E9}]{4}|[\u{1F7E6}]{4}|[\u{1F7EA}]{4})$/u.test(line));
  const solvedRows = new Set(correctRows).size;
  const mistakes = grid.length - correctRows.length;
  if (grid.length > 7 || mistakes > 4 || solvedRows !== correctRows.length) return { parsed: null, error: "This Connections grid has repeated groups or too many rows. Paste one complete result." };

  return {
    parsed: {
      gameId: sports ? "connections-sports" : "connections",
      score: `${mistakes} mistake${mistakes === 1 ? "" : "s"}`,
      result: solvedRows >= 4 ? "solved" : mistakes >= 4 ? "missed" : "played",
      note: `Imported official Connections${puzzleMatch ? ` #${puzzleMatch[1]}` : ""} with ${grid.length} rows`,
      grid
    }
  };
}

function parseStrandsShare(lines) {
  const text = lines.join(" ");
  const header = lines.find((line) => /^Strands\b/i.test(line)) || (/\bStrands\b/i.test(text) ? text : "");
  if (!header) return { parsed: null };

  const grid = lines
    .map(compactEmojiLine)
    .filter((line) => /^[\u{1F535}\u{1F7E1}\u{1F4A1}]+$/u.test(line));
  if (!grid.length) {
    return {
      parsed: null,
      error: "I found Strands, but I could not find the blue/yellow/hint emoji recap. Paste the full shared result."
    };
  }

  const puzzleMatch = text.match(/#\s*([\d,]+)/i) || text.match(/\bStrands\s+#?([\d,]+)/i);
  const hintCount = (grid.join("").match(/\u{1F4A1}/gu) || []).length;
  const foundSpangram = grid.some((line) => /\u{1F7E1}/u.test(line));
  const score = hintCount ? `${hintCount} hint${hintCount === 1 ? "" : "s"}` : "No hints";

  return {
    parsed: {
      gameId: "strands",
      score,
      result: foundSpangram ? "solved" : "played",
      note: `Imported official Strands${puzzleMatch ? ` #${puzzleMatch[1]}` : ""}${foundSpangram ? " with spangram" : ""}`,
      grid
    }
  };
}

function parseMiniCrosswordShare(lines) {
  const text = lines.join(" ");
  if (!/\b(Mini Crossword|The Mini|NYT Mini|New York Times Mini)\b/i.test(text)) return { parsed: null };

  const timeMatch = text.match(/\b(?:in|time:|time\s*)\s*(\d{1,2}:\d{2}(?::\d{2})?)\b/i)
    || text.match(/\b(\d{1,2}:\d{2}(?::\d{2})?)\b/);
  if (!timeMatch) {
    return {
      parsed: null,
      error: "I found Mini Crossword, but I could not find a completion time like 0:54 or 12:03."
    };
  }
  if (timeMatch[1].split(":").slice(1).some((part) => Number(part) > 59)) {
    return { parsed: null, error: "That time doesn't look right. Seconds and minutes within an hour must be between 00 and 59." };
  }

  return {
    parsed: {
      gameId: "mini-crossword",
      score: normalizeTimeScore(timeMatch[1]),
      result: "solved",
      note: "Imported official Mini Crossword time",
      grid: []
    }
  };
}

function parseSpellingBeeShare(lines) {
  const text = lines.join(" ");
  if (!/Spelling Bee/i.test(text)) return { parsed: null };

  const ranks = ["Queen Bee", "Genius", "Amazing", "Great", "Nice", "Solid", "Good Start", "Good", "Moving Up", "Moving", "Beginner"];
  const rank = ranks.find((item) => new RegExp(`\\b${item}\\b`, "i").test(text));
  if (!rank) {
    return {
      parsed: null,
      error: "I found Spelling Bee, but I could not find a rank like Genius, Amazing, or Queen Bee."
    };
  }

  const pointMatch = text.match(/\b(\d{1,4})\s*(?:points?|pts?)\b/i);
  const score = pointMatch ? `${rank} · ${pointMatch[1]} pts` : rank;

  return {
    parsed: {
      gameId: "spelling-bee",
      score,
      result: rank === "Queen Bee" ? "solved" : "played",
      note: `Imported official Spelling Bee rank: ${rank}`,
      grid: []
    }
  };
}

function parseKrillionShare(lines) {
  const text = lines.join(" ");
  const header = lines.find((line) => /^Krillion\b/i.test(line)) || (/\bKrillion\b/i.test(text) ? text : "");
  if (!header) return { parsed: null };

  const headerIndex = lines.indexOf(header);
  const searchableLines = headerIndex >= 0 ? lines.slice(headerIndex + 1) : lines;
  const directScore = searchableLines.find((line) => /^\d{1,4}$/.test(line));
  const labeledScore = text.match(/\b(?:score|depth|total)\s*:?\s*(\d{1,4})\b/i)
    || text.match(/\b(\d{1,4})\s*(?:depth\s*)?(?:points?|pts?)\b/i);
  const scoreLine = directScore || labeledScore?.[1];
  if (!scoreLine) {
    return {
      parsed: null,
      error: "I found Krillion, but I could not find the total depth score. Paste the line with the final number, like 110."
    };
  }

  const numberMatch = text.match(/\bKrillion\s+#?([\d,]+)/i);
  const grid = lines
    .slice(Math.max(lines.indexOf(String(scoreLine)) + 1, 0))
    .filter((line) => !/^https?:\/\//i.test(line) && line !== scoreLine && !/^Krillion\b/i.test(line));

  return {
    parsed: {
      gameId: "krillion",
      score: scoreLine,
      result: Number(scoreLine) > 0 ? "played" : "missed",
      note: `Imported official Krillion #${numberMatch?.[1] || "daily dive"} with ${scoreLine} depth points`,
      grid
    }
  };
}

function normalizeShareLines(text) {
  return text
    .replace(/\uFE0F/g, "")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
}

function compactEmojiLine(line) {
  return line.replace(/[\s\u200B-\u200D]/g, "");
}

function normalizeTimeScore(score) {
  const parts = score.split(":");
  return parts.length === 2 ? score.padStart(5, "0") : score;
}

function renderSharePreview(parsed, game, date, existing, duplicate) {
  elements.sharePreview.hidden = false;
  elements.sharePreview.innerHTML = `
    <div class="import-result-head">
      ${gameLogo(game)}
      <div><strong>${escapeHtml(game.name)} · ${escapeHtml(parsed.score)}</strong>
      <small>${escapeHtml(parsed.result)} · ${escapeHtml(date)}${duplicate ? " · Saved" : " · Not saved yet"}</small></div>
    </div>
    ${game.dailyRanked === false && !parsed.dailyMonthDay ? `<p class="import-warning">Challenge result: compare the same challenge with friends. Excluded from the combined daily ranking.</p>` : ""}
    ${parsed.dailyMonthDay ? `<p class="field-help">Daily result · Counts toward the combined leaderboard.</p>` : ""}
    ${existing && !duplicate ? `<p class="import-warning">You already saved ${escapeHtml(existing.score)} for this day. Saving will replace that score and keep your answer, note, and sharing choice.</p>` : ""}
    ${parsed.grid.length ? `<details><summary>View shared result</summary><div class="share-grid">${escapeHtml(parsed.grid.join("\n"))}</div></details>` : ""}
  `;
}

function setImportStatus(message, tone = "") {
  elements.importStatus.textContent = message;
  elements.importStatus.className = `import-status${tone ? ` ${tone}` : ""}`;
}

function visibleGames() {
  return state.games.filter((game) => SHOW_SOLVRY_GAMES || gameSource(game) !== "solvry");
}

function getActiveGame() {
  return visibleGames().find((game) => game.id === state.activeGameId) || visibleGames()[0];
}

function getGameEntries(date, gameId) {
  state.entries[date] ||= {};
  state.entries[date][gameId] ||= {};
  return state.entries[date][gameId];
}

function getPeople() {
  return [state.profile, ...visibleFriends()].map((person) => ({
    id: person.id || "you",
    name: person.name,
    handle: person.handle,
    demo: isDemoFriend(person)
  }));
}

function placementScore(index) {
  return [10, 7, 5, 3, 2, 1][index] || 1;
}

function gameScoreDirection(game) {
  if (["points", "depth", "rank", "complete", "grid"].includes(game.type)) return "high";
  return "low";
}

function resultWeight(result) {
  return { solved: 3, played: 2, missed: 0 }[result] ?? 1;
}

function calculateCompleted(personId) {
  const dayEntries = state.entries[state.selectedDate] || {};
  return visibleGames().filter((game) => dayEntries[game.id]?.[personId]).length;
}

function isCompletedResult(result) {
  return result === "solved" || result === "played";
}

function hasUserPlayedDate(dateKey) {
  const dayEntries = state.entries[dateKey] || {};
  return visibleGames().some((game) => dayEntries[game.id]?.you);
}

function calculateTotalSolves() {
  return Object.values(state.entries).reduce((total, dayEntries) => {
    return total + visibleGames().filter((game) => {
      return isCompletedResult(dayEntries[game.id]?.you?.result);
    }).length;
  }, 0);
}

function calculateStreak() {
  const dates = Object.keys(state.entries).sort().reverse();
  let streak = 0;
  let cursor = new Date(`${today}T00:00:00`);

  for (const date of dates) {
    const expected = localDateKey(cursor);
    if (date === expected && hasUserPlayedDate(date)) {
      streak += 1;
      cursor.setDate(cursor.getDate() - 1);
    }
  }

  return streak;
}

function shortWeekday(date) {
  return date.toLocaleDateString(undefined, { weekday: "short" });
}

function scoreStyleLabel(type) {
  const game = typeof type === "object" ? type : { type };
  return game.scoring?.label || SCORING_STYLES[game.type]?.label || "Score";
}

function scoreStyleHelp(game) {
  return game.scoring?.helper || SCORING_STYLES[game.type]?.helper || "Track the score shown by the official game.";
}

function scoreStyleExample(game) {
  return game.scoring?.example || SCORING_STYLES[game.type]?.example || "Score";
}

function scoringForType(type) {
  return { ...(SCORING_STYLES[type] || SCORING_STYLES.complete) };
}

function customScoringForType(type) {
  const styles = {
    points: { label: "Highest score", helper: "Higher scores win.", example: "100" },
    strokes: { label: "Lowest score", helper: "Lower scores win.", example: "10" },
    guesses: { label: "Fewest guesses", helper: "Fewer guesses win.", example: "7 guesses" }
  };
  return { ...scoringForType(type), ...styles[type] };
}

function mergeCustomGames(baseGames, savedGames = []) {
  const games = [...baseGames];
  const ids = new Set(games.map((game) => game.id));
  for (const game of Array.isArray(savedGames) ? savedGames : []) {
    if (!game || game.source !== "custom" || typeof game.id !== "string" || !/^custom-[a-z0-9-]+$/.test(game.id)
      || ids.has(game.id) || typeof game.name !== "string" || !game.name.trim() || game.name.length > 60
      || !["points", "strokes", "time", "guesses", "mistakes", "complete"].includes(game.type)) continue;
    games.push({ id: game.id, name: game.name.trim(), source: "custom", type: game.type, scoring: customScoringForType(game.type), logo: "custom", officialUrl: "" });
    ids.add(game.id);
  }
  return games;
}

function defaultScoreLabel(result) {
  return result === "missed" ? "Missed" : "Complete";
}

function loadState() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || localStorage.getItem(LEGACY_STORAGE_KEY));
    const nextState = saved ? mergeState(starterState, saved) : structuredClone(starterState);
    // Viewing an old date is a session choice, not the default for the next visit.
    nextState.selectedDate = today;
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(nextState)); } catch { /* Keep the loaded history in memory. */ }
    return nextState;
  } catch {
    return structuredClone(starterState);
  }
}

function mergeState(base, saved) {
  const savedGamesById = Object.fromEntries((saved.games || []).map((game) => [game.id, game]));
  const mergedDefaults = base.games.map((game) => {
    const savedGame = savedGamesById[game.id] || {};
    return {
      ...game,
      ...savedGame,
      scoring: { ...scoringForType(game.type), ...savedGame.scoring, ...game.scoring },
      logo: savedGame.logo || game.logo,
      officialUrl: savedGame.officialUrl || game.officialUrl
    };
  });
  const mergedGames = mergeCustomGames(mergedDefaults, saved.games);
  const mergedGameIds = new Set(mergedGames.map((game) => game.id));
  const entries = Object.fromEntries(
    Object.entries({ ...base.entries, ...saved.entries }).map(([date, dayEntries]) => [
      date,
      remapDayEntries(dayEntries, mergedGameIds)
    ])
  );
  const activeGameId = LEGACY_GAME_ID_MAP[saved.activeGameId] || saved.activeGameId;

  return {
    ...structuredClone(base),
    ...saved,
    profile: { ...base.profile, ...saved.profile },
    account: { ...base.account, ...saved.account },
    friendRequests: { ...base.friendRequests, ...saved.friendRequests },
    activeGameId: mergedGameIds.has(activeGameId) ? activeGameId : base.activeGameId,
    games: mergedGames,
    pinnedGameIds: (saved.pinnedGameIds || base.pinnedGameIds)
      .map((id) => LEGACY_GAME_ID_MAP[id] || id)
      .filter((id, index, ids) => mergedGameIds.has(id) && ids.indexOf(id) === index),
    friends: saved.friends || base.friends,
    entries
  };
}

function remapDayEntries(dayEntries, allowedIds) {
  return Object.entries(dayEntries).reduce((nextEntries, [gameId, entries]) => {
    const nextId = LEGACY_GAME_ID_MAP[gameId] || gameId;
    if (!allowedIds.has(nextId)) return nextEntries;
    nextEntries[nextId] = { ...(nextEntries[nextId] || {}), ...entries };
    return nextEntries;
  }, {});
}

function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  queueCloudSave();
}

function slugify(value) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

function uniqueId(base, existing) {
  const root = base || "item";
  let id = root;
  let index = 2;
  while (existing.includes(id)) {
    id = `${root}-${index}`;
    index += 1;
  }
  return id;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function flashButton(button, temporary, original) {
  button.textContent = temporary;
  setTimeout(() => {
    button.textContent = original;
  }, 1200);
}

function flashStatus(element, message) {
  element.textContent = message;
  const existingTimer = saveStatusTimers.get(element);
  if (existingTimer) clearTimeout(existingTimer);
  const timer = setTimeout(() => {
    element.textContent = "";
    saveStatusTimers.delete(element);
  }, 2200);
  saveStatusTimers.set(element, timer);
}

initCloudBackend();
render();
"""#
