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
      content="Solvry is a social hub for tracking daily word and puzzle games with friends."
    />
    <link
      rel="icon"
      type="image/svg+xml"
      href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='14' fill='%23141719'/%3E%3Cpath d='M14 18h36v28H14z' fill='%23f7f4ea'/%3E%3Cpath d='M18 22h8v8h-8zm10 0h8v8h-8zm10 0h8v8h-8z' fill='%2310a77a'/%3E%3Cpath d='M18 32h8v8h-8zm10 0h8v8h-8zm10 0h8v8h-8z' fill='%23efbd3a'/%3E%3C/svg%3E"
    />
    <link rel="stylesheet" href="styles.css" />
  </head>
  <body>
    <div class="app" id="app">
      <header class="topbar">
        <a class="brand" href="#today" aria-label="Solvry home">
          <span class="brand-mark" aria-hidden="true">SV</span>
          <span>
            <strong>Solvry</strong>
            <small>Daily games with friends</small>
          </span>
        </a>
        <nav class="topnav" aria-label="Primary">
          <a href="#today">Today</a>
          <a href="#friends">Friends</a>
          <a href="#import">Import</a>
          <a href="#answers">Answers</a>
        </nav>
        <div class="top-actions">
          <label class="date-control">
            Date
            <input id="playDate" type="date" />
          </label>
          <div class="account-controls" id="accountControls">
            <button class="ghost-button compact-button" type="button" data-account-action="login">Log in</button>
            <button class="primary-button compact-button" type="button" data-account-action="signup">Sign up</button>
          </div>
        </div>
      </header>

      <main class="workspace">
        <aside class="game-rail" aria-label="Tracked games">
          <div class="rail-title">
            <span>Games</span>
          </div>
          <div class="game-list" id="gameList"></div>
        </aside>

        <section class="panel tracker-panel" id="today">
          <div class="section-head">
            <div>
              <p class="eyebrow">Today’s tally</p>
              <h1 id="activeGameTitle">Wordle</h1>
              <p class="score-hint" id="scoreHint">Fewest guesses wins.</p>
            </div>
            <div class="status-stack">
              <span class="pill" id="friendCompletion">0 friends done</span>
              <span class="pill accent" id="privacyState">Answers hidden</span>
              <a class="official-link" id="officialLink" href="https://www.nytimes.com/games/wordle/index.html" target="_blank" rel="noopener">Play official</a>
            </div>
          </div>

          <div class="dashboard-strip" id="quickGames" aria-label="Pinned games"></div>

          <div class="play-surface" aria-live="polite">
            <div class="current-result" id="currentResult"></div>
            <div class="solvry-game" id="solvryGame" hidden></div>
            <div class="letter-board" id="letterBoard" aria-hidden="true"></div>
            <form class="entry-form" id="entryForm">
              <div class="field-grid">
                <label>
                  Result
                  <select id="resultInput">
                    <option value="solved">Solved</option>
                    <option value="missed">Missed</option>
                    <option value="played">Played</option>
                  </select>
                </label>
                <label>
                  Score
                  <input id="scoreInput" type="text" placeholder="4/6, 01:12, 3 mistakes" autocomplete="off" />
                  <small class="field-help" id="scoreHelp">Example: 4/6</small>
                </label>
                <label>
                  Answer
                  <input id="answerInput" type="text" placeholder="Optional" autocomplete="off" />
                  <small class="field-help">Only shared when reveal is on.</small>
                </label>
              </div>
              <label class="wide-label">
                Note
                <input id="noteInput" type="text" placeholder="Close call, lucky guess, weird clue..." autocomplete="off" />
              </label>
              <div class="form-actions">
                <label class="switch-row">
                  <input id="revealInput" type="checkbox" />
                  <span class="switch" aria-hidden="true"></span>
                  <span>Show my answer to friends</span>
                </label>
                <button class="primary-button" type="submit">Save result</button>
              </div>
              <div class="save-status" id="saveStatus" role="status"></div>
            </form>
          </div>

          <div class="import-surface" id="import">
            <div>
              <p class="eyebrow">Official results</p>
              <h2>Import a share result</h2>
            </div>
            <p class="import-copy">Play on the official site, use its Share button, then import the copied result here.</p>
          <div class="support-row">
              <span>Wordle import</span>
              <span>Connections import</span>
              <span>Strands import</span>
              <span>Mini import</span>
              <span>Spelling Bee import</span>
              <span>Krillion import</span>
            </div>
            <div class="import-actions">
              <button class="primary-button" id="importClipboardButton" type="button">Import copied result</button>
              <button class="ghost-button" id="importPasteButton" type="button">Import pasted text</button>
            </div>
            <label>
              Paste fallback
              <textarea id="shareTextInput" class="share-input" rows="6" placeholder="Wordle 1,234 4/6&#10;&#10;⬛🟨⬛🟩⬛&#10;🟩🟩🟩🟩🟩"></textarea>
            </label>
            <div class="import-status" id="importStatus" role="status">Ready for Wordle, Connections, Strands, Mini Crossword, Spelling Bee, or Krillion share text.</div>
            <div class="share-preview" id="sharePreview" hidden></div>
          </div>

          <div class="metrics" aria-label="Summary">
            <div>
              <strong id="playedMetric">0</strong>
              <span>played today</span>
            </div>
            <div>
              <strong id="solvedMetric">0</strong>
              <span>completed today</span>
            </div>
            <div>
              <strong id="streakMetric">0</strong>
              <span>day streak</span>
            </div>
            <div>
              <strong id="totalSolvesMetric">0</strong>
              <span>total solves</span>
            </div>
          </div>
          <div class="progress-days" id="progressDays" aria-label="Recent play history"></div>
        </section>

        <section class="panel social-panel" id="friends">
          <div class="section-head compact">
            <div>
              <p class="eyebrow">Circle</p>
              <h2>Scoreboards</h2>
            </div>
            <button class="ghost-button" id="resetButton" type="button">Reset demo</button>
          </div>
          <div class="scoreboard-stack">
            <section class="scoreboard-block" aria-labelledby="overallScoreboardTitle">
              <div class="scoreboard-head">
                <h3 id="overallScoreboardTitle">Solvry overall</h3>
                <span>Combined points</span>
              </div>
              <p class="scoreboard-note">Overall points come from each game’s daily ranking.</p>
              <div class="leaderboard" id="overallLeaderboard"></div>
            </section>
            <section class="scoreboard-block" aria-labelledby="gameScoreboardTitle">
              <div class="scoreboard-head">
                <h3 id="gameScoreboardTitle">Wordle scoreboard</h3>
                <span id="gameScoreboardMeta">Fewest guesses</span>
              </div>
              <p class="scoreboard-note" id="gameScoreboardNote">Lower guess counts rank higher.</p>
              <div class="leaderboard" id="gameLeaderboard"></div>
            </section>
          </div>
          <form class="friend-form" id="friendForm">
            <label>
              Friend name
              <input id="friendNameInput" type="text" placeholder="Avery" autocomplete="off" required />
            </label>
            <label>
              Handle
              <input id="friendHandleInput" type="text" placeholder="@averyplays" autocomplete="off" />
            </label>
            <button class="primary-button" type="submit">Add friend</button>
          </form>
        </section>

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
            <input id="gameNameInput" type="text" placeholder="Connections" required />
          </label>
          <label>
            Scoring style
            <select id="gameTypeInput">
              <option value="guesses">Guesses</option>
              <option value="time">Time</option>
              <option value="mistakes">Mistakes</option>
              <option value="points">Points</option>
              <option value="depth">Depth</option>
              <option value="rank">Rank</option>
              <option value="complete">Complete</option>
            </select>
          </label>
          <button class="primary-button" value="default" type="submit">Add game</button>
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
          <p class="account-note">For now this creates a prototype account on this device. Real Apple and Google sign-in can be connected when Solvry gets production OAuth credentials.</p>
        </form>
      </dialog>
    </div>
    <script src="app.js" type="module"></script>
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
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 254, 250, 0.76);
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

  body.solvry-holes-focus .daily-golf {
    width: 100%;
    max-width: 100%;
    height: min(660px, calc(100dvh - 14px));
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
  .strategy-actions,
  .play-actions.three {
    grid-template-columns: 1fr;
  }

  .play-card.primary.golf-map-card,
  .golf-map-card {
    gap: 12px;
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
    grid-template-columns: repeat(7, 58px);
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

  .golf-score-hole {
    padding-inline: 2px;
  }
}
"""#

let appScript = #"""
const STORAGE_KEY = "solvry-state-v1";
const LEGACY_STORAGE_KEY = "tallyo-state-v1";
const today = new Date().toISOString().slice(0, 10);
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
const GOLF_GAME_VERSION = 5;
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

const starterState = {
  activeGameId: "wordle",
  selectedDate: today,
  profile: { name: "You", handle: "@solvry" },
  account: { signedIn: false, provider: "", email: "" },
  pinnedGameIds: [],
  solvryPlays: {},
  games: [
    { id: "wordle", name: "Wordle", source: "official", type: "guesses", scoring: { label: "Fewest guesses", helper: "Guess count out of 6. Lower is better; X/6 is a miss.", example: "4/6" }, logo: "wordle", officialUrl: "https://www.nytimes.com/games/wordle/index.html" },
    { id: "connections", name: "Connections", source: "official", type: "mistakes", scoring: { label: "Fewest mistakes", helper: "Imported Connections grids rank by mistakes. Lower is better.", example: "0 mistakes" }, logo: "connections", officialUrl: "https://www.nytimes.com/games/connections" },
    { id: "strands", name: "Strands", source: "official", type: "complete", scoring: { label: "Completion", helper: "Imported Strands shares track completion and hints.", example: "Complete" }, logo: "strands", officialUrl: "https://www.nytimes.com/games/strands" },
    { id: "mini-crossword", name: "Mini Crossword", source: "official", type: "time", scoring: { label: "Fastest time", helper: "Imported Mini shares rank by completion time.", example: "00:54" }, logo: "mini-crossword", officialUrl: "https://www.nytimes.com/crosswords/game/mini" },
    { id: "spelling-bee", name: "Spelling Bee", source: "official", type: "rank", scoring: { label: "Best rank", helper: "Imported Spelling Bee shares rank by official level.", example: "Genius" }, logo: "spelling-bee", officialUrl: "https://www.nytimes.com/puzzles/spelling-bee" },
    { id: "krillion", name: "Krillion", source: "official", type: "depth", scoring: { label: "Highest depth", helper: "Rarer valid answers score more. Higher total depth points win.", example: "110" }, logo: "krillion", officialUrl: "https://krillion.io/" },
    { id: "solvry-holes", name: "Solvry Holes", source: "solvry", type: "strokes", scoring: { label: "Lowest strokes", helper: "Play nine tiny daily holes. Fewer total strokes win.", example: "38 strokes" }, logo: "holes", officialUrl: "" },
    { id: "solvry-hoops", name: "Solvry Hoops", source: "solvry", type: "points", scoring: { label: "Most points", helper: "Play nine daily basketball shots. Higher point total wins.", example: "24 points" }, logo: "hoops", officialUrl: "" }
  ],
  friends: [
    { id: "mira", name: "Mira", handle: "@mirasolves" },
    { id: "jay", name: "Jay", handle: "@jayplaysdaily" },
    { id: "nolan", name: "Nolan", handle: "@gridnolan" }
  ],
  entries: {
    [today]: {
      wordle: {
        you: { result: "solved", score: "4/6", answer: "", note: "Clean finish", reveal: false },
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
  friendNameInput: document.querySelector("#friendNameInput"),
  friendHandleInput: document.querySelector("#friendHandleInput"),
  answerFeed: document.querySelector("#answerFeed"),
  copyButton: document.querySelector("#copyButton"),
  importSurface: document.querySelector("#import"),
  officialLink: document.querySelector("#officialLink"),
  importClipboardButton: document.querySelector("#importClipboardButton"),
  importPasteButton: document.querySelector("#importPasteButton"),
  shareTextInput: document.querySelector("#shareTextInput"),
  importStatus: document.querySelector("#importStatus"),
  sharePreview: document.querySelector("#sharePreview"),
  resetButton: document.querySelector("#resetButton"),
  addGameButton: document.querySelector("#addGameButton"),
  closeGameDialogButton: document.querySelector("#closeGameDialogButton"),
  gameDialog: document.querySelector("#gameDialog"),
  gameForm: document.querySelector("#gameForm"),
  gameNameInput: document.querySelector("#gameNameInput"),
  gameTypeInput: document.querySelector("#gameTypeInput"),
  accountControls: document.querySelector("#accountControls"),
  accountDialog: document.querySelector("#accountDialog"),
  accountForm: document.querySelector("#accountForm"),
  accountTitle: document.querySelector("#accountTitle"),
  closeAccountDialogButton: document.querySelector("#closeAccountDialogButton")
};

elements.playDate.value = state.selectedDate;

window.addEventListener("hashchange", renderNav);

elements.playDate.addEventListener("change", (event) => {
  state.selectedDate = event.target.value || today;
  saveState();
  render();
});

elements.entryForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const gameEntries = getGameEntries(state.selectedDate, state.activeGameId);
  gameEntries.you = {
    result: elements.resultInput.value,
    score: elements.scoreInput.value.trim() || defaultScoreLabel(elements.resultInput.value),
    answer: elements.answerInput.value.trim(),
    note: elements.noteInput.value.trim(),
    reveal: elements.revealInput.checked
  };
  saveState();
  render();
  flashStatus(elements.saveStatus, "Saved. Scoreboards updated.");
});

elements.friendForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const name = elements.friendNameInput.value.trim();
  if (!name) return;
  state.friends.push({
    id: uniqueId(slugify(name), state.friends.map((friend) => friend.id)),
    name,
    handle: elements.friendHandleInput.value.trim() || `@${slugify(name)}`
  });
  elements.friendForm.reset();
  saveState();
  render();
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
  const name = elements.gameNameInput.value.trim();
  if (!name) return;
  const id = uniqueId(slugify(name), state.games.map((game) => game.id));
  const type = elements.gameTypeInput.value;
  state.games.push({ id, name, type, scoring: scoringForType(type), logo: "custom", officialUrl: "" });
  state.activeGameId = id;
  saveState();
  elements.gameDialog.close();
  render();
});

elements.accountControls.addEventListener("click", (event) => {
  const actionButton = event.target.closest("[data-account-action]");
  if (!actionButton) return;
  const action = actionButton.dataset.accountAction;
  if (action === "signout") {
    state.account = { signedIn: false, provider: "", email: "" };
    saveState();
    render();
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
  createPrototypeAccount(providerButton.dataset.provider);
});

elements.accountForm.addEventListener("submit", (event) => {
  event.preventDefault();
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
  try {
    const text = await navigator.clipboard.readText();
    elements.shareTextInput.value = text;
    importShareText(text);
  } catch {
    setImportStatus("Clipboard access was blocked. Paste the result below instead.", "error");
  }
});

elements.importPasteButton.addEventListener("click", () => {
  importShareText(elements.shareTextInput.value);
});

elements.resetButton.addEventListener("click", () => {
  state = structuredClone(starterState);
  state.selectedDate = today;
  saveState();
  elements.playDate.value = today;
  render();
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

function render() {
  const activeGame = getActiveGame();
  const gameEntries = getGameEntries(state.selectedDate, state.activeGameId);
  const myEntry = gameEntries.you;
  const friendEntries = state.friends.filter((friend) => gameEntries[friend.id]);

  document.body.classList.toggle("solvry-holes-focus", activeGame.id === "solvry-holes");
  elements.activeGameTitle.textContent = activeGame.name;
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
  renderBoard(activeGame.name);
  renderForm(myEntry);
  renderMetrics();
  renderScoreboards(activeGame);
  renderAnswers();
  focusHolesViewport(activeGame);
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
        <small>${escapeHtml(state.account.provider)} account</small>
      </span>
      <button class="ghost-button compact-button" type="button" data-account-action="signout">Sign out</button>
    `;
    return;
  }

  elements.accountControls.innerHTML = `
    <button class="ghost-button compact-button" type="button" data-account-action="login">Log in</button>
    <button class="primary-button compact-button" type="button" data-account-action="signup">Sign up</button>
  `;
}

function renderNav() {
  const activeHash = window.location.hash || "#today";
  elements.navLinks.forEach((link) => {
    link.classList.toggle("active", link.getAttribute("href") === activeHash);
  });
}

function openAccountDialog(mode) {
  elements.accountTitle.textContent = mode === "login" ? "Log in to Solvry" : "Create your Solvry account";
  elements.accountDialog.showModal();
}

function createPrototypeAccount(provider) {
  state.account = {
    signedIn: true,
    provider,
    email: provider === "Google" ? "google-account@solvry.local" : "apple-account@solvry.local"
  };
  saveState();
  elements.accountDialog.close();
  render();
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
    <span class="pill">${entry ? "Saved" : "Open"}</span>
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
  const target = getGolfTargetPointForAngle(play, hole, selectedClub, displayAimAngle);
  const scoreLabel = formatRelativeScore(getGolfRelativeScore(play));
  const showClubControls = phase !== "ball-flight" && phase !== "power-locked";

  return `
    <div class="daily-golf" data-shot-phase="${escapeHtml(phase)}">
      ${renderGolfGameHeader(play)}
      ${renderGolfScoreStrip(play)}
      <div class="daily-golf-board">
        <section class="play-card primary golf-map-card">
          <div class="golf-hud">
            <div class="golf-stat"><span>Hole ${hole.number} · Par ${hole.par}</span><strong>${hole.distance} yds</strong></div>
            <div class="golf-stat"><span>Wind</span><strong>${hole.wind.speed} mph ${windArrow(hole.wind.direction)}</strong></div>
          </div>
          ${renderGolfCourseSvg(play, hole, target, displayAimAngle, phase)}
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
                <button class="club-button${club.id === selectedClub.id ? " active" : ""}" type="button" data-play-action="club:${club.id}" ${phase !== "scouting" ? "disabled" : ""}>
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

  if (phase === "power-locked" || phase === "ball-flight") {
    return `
      <div class="shot-stage locked">
        <strong>${phase === "power-locked" ? "Power locked" : "Swinging"}</strong>
        <p>${phase === "power-locked" ? "Watch the shot." : "Controls hidden during flight."}</p>
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
  const birdies = play.holeResults.filter((result) => result.relative < 0).length;
  const water = play.shotLog.filter((shot) => shot.penalty).length;
  return `
    <div class="daily-golf">
      ${renderGolfGameHeader(play)}
      ${renderGolfScoreStrip(play)}
      <section class="results-card">
        <div class="play-topline">
          <div>
            <p class="eyebrow">Daily Golf ${escapeHtml(play.course.dailyNumber)}</p>
            <h3>${formatRelativeScore(relative)}</h3>
          </div>
          <span class="pill">Locked score</span>
        </div>
        <div class="results-grid">
          <div class="golf-stat"><span>Strokes</span><strong>${play.totalStrokes}</strong></div>
          <div class="golf-stat"><span>Birdies+</span><strong>${birdies}</strong></div>
          <div class="golf-stat"><span>Water penalties</span><strong>${water}</strong></div>
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
      <thead><tr><th>Hole</th><th>Par</th><th>Strokes</th><th>Score</th></tr></thead>
      <tbody>
        ${play.course.holes.map((hole, index) => {
          const result = play.holeResults[index];
          return `<tr><td>${hole.number}</td><td>${hole.par}</td><td>${result?.strokes || "-"}</td><td>${result ? formatRelativeScore(result.relative) : "-"}</td></tr>`;
        }).join("")}
      </tbody>
    </table>
  `;
}

function renderGolfCourseSvg(play, hole, target, displayAimAngle, phase) {
  const ball = play.ball;
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
  const lineLength = Math.min(42, visibleLineLength, Math.max(14, distance(ball, target)));
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
    <svg class="golf-course-map" viewBox="0 0 100 100" role="img" aria-label="${escapeHtml(hole.name)} course map">
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
      <circle cx="${hole.pin.x}" cy="${hole.pin.y}" r="${hole.puttZones.two}" fill="none" stroke="#fffefa" stroke-width="0.55" opacity="0.48"></circle>
      <circle cx="${hole.pin.x}" cy="${hole.pin.y}" r="${hole.puttZones.one}" fill="none" stroke="#224238" stroke-width="0.42" opacity="0.62"></circle>
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
  const apexY = Math.max(5, Math.min(start.y, landing.y) - 13);
  const controlOne = { x: start.x + (landing.x - start.x) * 0.3, y: apexY };
  const controlTwo = { x: start.x + (landing.x - start.x) * 0.76 + outcome.crossWind.x * 0.35, y: apexY + 2 };
  const arc = `M ${start.x} ${start.y} C ${controlOne.x} ${controlOne.y} ${controlTwo.x} ${controlTwo.y} ${landing.x} ${landing.y}`;
  const rollout = distance(landing, final) > 1.2 ? ` L ${final.x} ${final.y}` : "";
  const motionPath = `${arc}${rollout}`;
  return `
    <g class="golf-flight-preview" aria-hidden="true">
      <path d="${motionPath}" fill="none" stroke="#fffefa" stroke-width="1.05" opacity="0.58" stroke-linecap="round"></path>
      <path d="${motionPath}" fill="none" stroke="#9c2f23" stroke-width="0.54" opacity="0.74" stroke-linecap="round" stroke-dasharray="1.4 1.6"></path>
      <circle r="1.5" fill="#fffefa" stroke="#141719" stroke-width="0.48">
        <animateMotion path="${motionPath}" dur="0.72s" fill="freeze" calcMode="spline" keyTimes="0;1" keySplines="0.18 0.78 0.2 1"></animateMotion>
      </circle>
      <ellipse rx="2.7" ry="0.8" fill="#273c32" opacity="0.2">
        <animateMotion path="M ${start.x} ${start.y + 2.4} L ${landing.x} ${landing.y + 1.7}${rollout ? ` L ${final.x} ${final.y + 1.2}` : ""}" dur="0.72s" fill="freeze"></animateMotion>
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
    play.startedAt = new Date().toISOString();
    play.showHoleCard = true;
    play.message = "Ranked round started. Bad shots count, so choose the target first.";
    return;
  }

  if (action === "start-hole") {
    startCurrentGolfHole(play);
    return;
  }

  if (action.startsWith("club:")) {
    const phase = play.shotPhase || "scouting";
    if (phase !== "scouting") return;
    const club = getGolfClub(action.split(":")[1]);
    play.selectedClubId = club.id;
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
  setGolfAimCenterToPin(play, hole);
  play.shotPhase = "aiming";
  play.aimStartedAt = Date.now();
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
    }, 760);
  }, 560);
}

function computeGolfShotOutcome(play, powerPosition) {
  const hole = getCurrentGolfHole(play);
  const club = getGolfClub(play.selectedClubId);
  const window = play.powerWindow || getPowerWindow(play, hole, club);
  const quality = getPowerQuality(powerPosition, window);
  const start = { ...play.ball };
  const lie = GOLF_SURFACES[play.currentSurface] || GOLF_SURFACES.rough;
  const yardsPerUnit = hole.yardsPerUnit;
  const powerMultiplier = (0.48 + powerPosition / 100 * 0.88) * lie.power;
  const baselineCarryYards = club.carry * powerMultiplier;
  const lockedAngle = play.lockedAimAngle ?? play.aimAngle;
  const direction = golfVectorFromAngle(lockedAngle);
  const wind = golfWindVector(hole.wind, yardsPerUnit);
  const windAlong = wind.x * direction.x + wind.y * direction.y;
  const crossWind = {
    x: wind.x - direction.x * windAlong,
    y: wind.y - direction.y * windAlong
  };
  const windCarryYards = clamp(windAlong * yardsPerUnit * 0.42, -club.carry * 0.14, club.carry * 0.14);
  const carryYards = Math.max(8, baselineCarryYards + windCarryYards);
  const carryUnits = carryYards / yardsPerUnit;
  const landing = clampPoint({
    x: start.x + direction.x * carryUnits + crossWind.x,
    y: start.y + direction.y * carryUnits + crossWind.y
  });
  const landingSurface = getGolfSurfaceAtPoint(hole, landing);
  const waterPenalty = landingSurface === "water";
  const surface = GOLF_SURFACES[landingSurface] || GOLF_SURFACES.rough;
  const rolloutUnits = waterPenalty ? 0 : club.rollout * surface.rollout * quality.rollout / yardsPerUnit;
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
    final,
    finalSurface,
    penalty: endedInWater ? 1 : 0
  };
}

function playGolfSwing(play, game, powerPosition, preparedOutcome = null) {
  const outcome = preparedOutcome || computeGolfShotOutcome(play, powerPosition);
  const { hole, club, quality, start, carryYards, landing, final, finalSurface } = outcome;
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
    surface: finalSurface,
    penalty,
    summary: `${club.name} · ${quality.label} strike · ${Math.round(carryYards)} yd carry${penalty ? " · water penalty" : ""}`
  };
  play.shotLog.push(play.lastShot);

  if (finalSurface === "green" || yardsBetween(final, hole.pin, hole) <= hole.green.r * hole.yardsPerUnit) {
    completeGolfHole(play, game, hole);
    return;
  }

  if (play.holeStrokes >= getGolfMaxStrokes(hole)) {
    pickUpGolfHole(play, game, hole);
    return;
  }

  const remaining = Math.round(yardsBetween(final, hole.pin, hole));
  play.shotPhase = "scouting";
  play.powerWindow = null;
  play.lockedAimAngle = null;
  play.lockedPower = null;
  setGolfAimCenterToPin(play, hole);
  play.selectedClubId = recommendGolfClub(remaining);
  play.targetMode = "pin";
  play.message = penalty
    ? `WATER +1. ${remaining} yds left from ${surfaceLabel(finalSurface).toLowerCase()}.`
    : `${quality.label.toUpperCase()} · ${surfaceLabel(finalSurface).toUpperCase()} · ${remaining} yds left.`;
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
    holeResults: [],
    shotLog: [],
    lastShot: null,
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
    puttZones: { one: puttBase, two: puttBase * 2.5 },
    palette: { rough: env.rough },
    summary: `${primaryHazard}. ${windSpeed} mph wind ${windArrow(windDirection)}. Choose a safe landing zone or attack the pin.`
  };
}

function startCurrentGolfHole(play) {
  const hole = getCurrentGolfHole(play);
  play.showHoleCard = false;
  play.ball = { ...hole.tee };
  setGolfAimCenterToPin(play, hole);
  play.lockedAimAngle = null;
  play.lockedPower = null;
  play.powerWindow = null;
  play.flightPreview = null;
  play.shotPhase = "scouting";
  play.selectedClubId = recommendGolfClub(hole.distance);
  play.targetMode = "pin";
  play.currentSurface = "tee";
  play.holeStrokes = 0;
  play.lastShot = null;
  play.message = `Hole ${hole.number}: ${hole.distance} yards. Pick a club and time the swing.`;
}

function completeGolfHole(play, game, hole) {
  const proximity = yardsBetween(play.ball, hole.pin, hole);
  const onePuttYards = hole.puttZones.one * hole.yardsPerUnit;
  const twoPuttYards = hole.puttZones.two * hole.yardsPerUnit;
  const putts = proximity <= onePuttYards ? 1 : proximity <= twoPuttYards ? 2 : 3;
  play.holeStrokes += putts;
  play.totalStrokes += putts;
  const relative = play.holeStrokes - hole.par;
  const result = {
    holeId: hole.id,
    par: hole.par,
    strokes: play.holeStrokes,
    relative,
    completed: true,
    putts,
    shots: play.shotLog.filter((shot) => shot.hole === hole.number)
  };
  finishGolfHole(play, game, hole, result, `Hole ${hole.number} complete: ${play.holeStrokes} on a par ${hole.par} (${formatRelativeScore(relative)}). ${putts} putt${putts === 1 ? "" : "s"}.`);
}

function pickUpGolfHole(play, game, hole) {
  const maxStrokes = getGolfMaxStrokes(hole);
  if (play.holeStrokes > maxStrokes) {
    play.totalStrokes -= play.holeStrokes - maxStrokes;
    play.holeStrokes = maxStrokes;
  }
  const relative = play.holeStrokes - hole.par;
  const result = {
    holeId: hole.id,
    par: hole.par,
    strokes: play.holeStrokes,
    relative,
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
  play.holeResults[play.holeIndex] = result;
  play.shotPhase = "scouting";
  play.powerWindow = null;
  play.message = message;

  if (play.holeIndex >= play.course.holes.length - 1) {
    play.completed = true;
    play.completedAt = new Date().toISOString();
    const score = `${play.totalStrokes} strokes`;
    const note = `${formatRelativeScore(getGolfRelativeScore(play))} to par on ${play.course.name}`;
    saveSolvryResult(game, score, note);
    return;
  }

  play.holeIndex += 1;
  play.showHoleCard = true;
  const nextHole = getCurrentGolfHole(play);
  play.ball = { ...nextHole.tee };
  play.holeStrokes = 0;
  play.currentSurface = "tee";
  play.selectedClubId = recommendGolfClub(nextHole.distance);
  setGolfAimCenterToPin(play, nextHole);
  play.lockedAimAngle = null;
  play.lockedPower = null;
  play.powerWindow = null;
  play.flightPreview = null;
  play.shotPhase = "scouting";
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
  const carryUnits = club.carry / hole.yardsPerUnit;
  const vector = golfVectorFromAngle(angle);
  return clampPoint({
    x: play.ball.x + vector.x * carryUnits,
    y: play.ball.y + vector.y * carryUnits
  });
}

function getVisibleAimLineLength(origin, angle) {
  const vector = golfVectorFromAngle(angle);
  const limits = [];
  if (vector.x > 0) limits.push((94 - origin.x) / vector.x);
  if (vector.x < 0) limits.push((origin.x - 6) / -vector.x);
  if (vector.y > 0) limits.push((94 - origin.y) / vector.y);
  if (vector.y < 0) limits.push((origin.y - 6) / -vector.y);
  const available = Math.min(...limits.filter((value) => Number.isFinite(value) && value > 0));
  return clamp((Number.isFinite(available) ? available : 42) - 1.5, 8, 42);
}

function getActiveAimAngle(play) {
  const hole = getCurrentGolfHole(play);
  const elapsed = Date.now() - (play.aimStartedAt || Date.now());
  const phase = Math.sin((elapsed / getAimSweepDuration(play, hole)) * Math.PI * 2);
  return clamp((play.aimCenterAngle ?? play.aimAngle) + phase * getAimSweepRange(play, hole), -48, 48);
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

function getPowerWindow(play, hole, club) {
  const target = getGolfTargetPointForAngle(play, hole, club, play.lockedAimAngle ?? play.aimAngle);
  const targetYards = yardsBetween(play.ball, target, hole);
  const lie = GOLF_SURFACES[play.currentSurface] || GOLF_SURFACES.rough;
  const required = clamp(((targetYards / Math.max(1, club.carry * lie.power)) - 0.48) / 0.88 * 100, 8, 92);
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
  return clamp((radians * 180) / Math.PI, -42, 42);
}

function yardsBetween(a, b, hole) {
  return Math.hypot(a.x - b.x, a.y - b.y) * hole.yardsPerUnit;
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

function formatRelativeScore(value) {
  if (value === 0) return "E";
  return value > 0 ? `+${value}` : `${value}`;
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
  return gameSource(game) === "solvry" && ["solvry-holes", "solvry-hoops"].includes(game.id);
}

function clamp(value, minimum, maximum) {
  return Math.min(maximum, Math.max(minimum, value));
}

function renderQuickGames() {
  const pinned = state.games.filter((game) => state.pinnedGameIds.includes(game.id));
  const games = [...pinned, ...state.games.filter((game) => !state.pinnedGameIds.includes(game.id))].slice(0, 4);
  elements.quickGames.innerHTML = games
    .map((game) => {
      const entries = getGameEntries(state.selectedDate, game.id);
      const mine = entries.you;
      const friendCount = Object.keys(entries).filter((id) => id !== "you").length;
      const status = mine ? mine.score || defaultScoreLabel(mine.result) : `${friendCount} friend${friendCount === 1 ? "" : "s"}`;
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
      state.activeGameId = button.dataset.gameId;
      saveState();
      render();
    });
  });
}

function renderGameList() {
  elements.gameList.innerHTML = "";
  [
    { source: "official", title: "Official imports", detail: "Paste share results" },
    { source: "solvry", title: "Solvry games", detail: "In-app versions" }
  ].forEach((section) => {
    const games = getSortedGames().filter((game) => gameSource(game) === section.source);
    if (!games.length) return;
    const heading = document.createElement("div");
    heading.className = "game-section-label";
    heading.innerHTML = `<strong>${escapeHtml(section.title)}</strong><span>${escapeHtml(section.detail)}</span>`;
    elements.gameList.append(heading);
    games.forEach((game) => {
      elements.gameList.append(renderGameCard(game));
    });
  });
}

function renderGameCard(game) {
    const entries = getGameEntries(state.selectedDate, game.id);
    const playedCount = Object.keys(entries).length;
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
        <span class="game-score">${playedCount}</span>
      </button>
      <button class="pin-button${isPinned ? " active" : ""}" type="button" aria-pressed="${isPinned}" title="${isPinned ? "Unpin" : "Pin"} ${escapeHtml(game.name)}" aria-label="${isPinned ? "Unpin" : "Pin"} ${escapeHtml(game.name)}">
        ${pinIcon(isPinned)}
      </button>
    `;
    card.querySelector(".game-select").addEventListener("click", () => {
      state.activeGameId = game.id;
      saveState();
      render();
    });
    card.querySelector(".pin-button").addEventListener("click", () => {
      togglePin(game.id);
    });
    return card;
}

function getSortedGames() {
  const pinned = new Set(state.pinnedGameIds);
  return [...state.games].sort((a, b) => {
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
  return source === "official" ? 0 : 1;
}

function togglePin(gameId) {
  if (state.pinnedGameIds.includes(gameId)) {
    state.pinnedGameIds = state.pinnedGameIds.filter((id) => id !== gameId);
  } else {
    state.pinnedGameIds = [...state.pinnedGameIds, gameId];
  }
  saveState();
  render();
}

function gameLogo(game) {
  const logo = game.logo || game.id || "custom";
  const className = escapeHtml(slugify(logo));
  const initial = escapeHtml(game.name.slice(0, 1).toUpperCase());
  const icons = {
    wordle: `<svg viewBox="0 0 40 40" aria-hidden="true"><rect x="5" y="5" width="9" height="9" rx="2" fill="#141719"/><rect x="16" y="5" width="9" height="9" rx="2" fill="#10a77a"/><rect x="27" y="5" width="9" height="9" rx="2" fill="#efbd3a"/><rect x="5" y="16" width="9" height="9" rx="2" fill="#515957"/><rect x="16" y="16" width="9" height="9" rx="2" fill="#10a77a"/><rect x="27" y="16" width="9" height="9" rx="2" fill="#141719"/><rect x="5" y="27" width="9" height="9" rx="2" fill="#efbd3a"/><rect x="16" y="27" width="9" height="9" rx="2" fill="#141719"/><rect x="27" y="27" width="9" height="9" rx="2" fill="#10a77a"/></svg>`,
    connections: `<svg viewBox="0 0 40 40" aria-hidden="true"><rect x="6" y="6" width="12" height="12" rx="3" fill="#141719"/><rect x="22" y="6" width="12" height="12" rx="3" fill="#10a77a"/><rect x="6" y="22" width="12" height="12" rx="3" fill="#f26d5b"/><rect x="22" y="22" width="12" height="12" rx="3" fill="#5f5bd7"/></svg>`,
    strands: `<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M8 28c6-18 18 12 24-6" fill="none" stroke="#141719" stroke-width="4" stroke-linecap="round"/><circle cx="9" cy="28" r="4" fill="#10a77a"/><circle cx="20" cy="19" r="4" fill="#efbd3a"/><circle cx="32" cy="22" r="4" fill="#141719"/></svg>`,
    "mini-crossword": `<svg viewBox="0 0 40 40" aria-hidden="true"><rect x="6" y="6" width="28" height="28" rx="4" fill="#fffefa"/><path d="M6 15h28M6 25h28M15 6v28M25 6v28" stroke="#141719" stroke-width="2"/><rect x="15" y="15" width="10" height="10" fill="#141719"/></svg>`,
    "spelling-bee": `<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M20 4l8 5v9l-8 5-8-5V9z" fill="#efbd3a" stroke="#141719" stroke-width="2"/><path d="M12 22l8 5 8-5v9l-8 5-8-5z" fill="#ffe28a" stroke="#141719" stroke-width="2"/></svg>`,
    sudoku: `<svg viewBox="0 0 40 40" aria-hidden="true"><rect x="6" y="6" width="28" height="28" rx="3" fill="#fffefa"/><path d="M15 6v28M25 6v28M6 15h28M6 25h28" stroke="#141719" stroke-width="2"/><text x="20" y="24" text-anchor="middle" font-size="14" font-weight="900" fill="#10a77a">9</text></svg>`,
    queens: `<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M8 30h24l-3-16-6 7-3-10-3 10-6-7z" fill="#efbd3a" stroke="#141719" stroke-width="2" stroke-linejoin="round"/><path d="M12 34h16" stroke="#141719" stroke-width="3" stroke-linecap="round"/></svg>`,
    zip: `<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M8 30L16 12l8 18 8-20" fill="none" stroke="#141719" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><circle cx="8" cy="30" r="4" fill="#f26d5b"/><circle cx="16" cy="12" r="4" fill="#efbd3a"/><circle cx="24" cy="30" r="4" fill="#10a77a"/><circle cx="32" cy="10" r="4" fill="#5f5bd7"/></svg>`,
    crossclimb: `<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M13 33V7M27 33V7M13 14h14M13 22h14M13 30h14" stroke="#141719" stroke-width="4" stroke-linecap="round"/><path d="M10 30l20-16" stroke="#10a77a" stroke-width="3" stroke-linecap="round"/></svg>`,
    pinpoint: `<svg viewBox="0 0 40 40" aria-hidden="true"><circle cx="20" cy="20" r="14" fill="#fffefa" stroke="#141719" stroke-width="3"/><circle cx="20" cy="20" r="8" fill="none" stroke="#f26d5b" stroke-width="3"/><circle cx="20" cy="20" r="3" fill="#141719"/></svg>`,
    holes: `<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M11 30c4-6 14-8 22-4" fill="none" stroke="#141719" stroke-width="3" stroke-linecap="round"/><path d="M15 9v19" stroke="#141719" stroke-width="3" stroke-linecap="round"/><path d="M15 9l13 4-13 4z" fill="#f26d5b" stroke="#141719" stroke-width="2" stroke-linejoin="round"/><circle cx="27" cy="29" r="3" fill="#fffefa" stroke="#141719" stroke-width="2"/></svg>`,
    hoops: `<svg viewBox="0 0 40 40" aria-hidden="true"><circle cx="20" cy="21" r="13" fill="#f26d5b" stroke="#141719" stroke-width="3"/><path d="M7 21h26M20 8c5 7 5 19 0 26M20 8c-5 7-5 19 0 26" fill="none" stroke="#141719" stroke-width="2"/><path d="M12 10h16v5H12z" fill="#fffefa" stroke="#141719" stroke-width="2"/><path d="M15 15c2 5 8 5 10 0" fill="none" stroke="#fffefa" stroke-width="2"/></svg>`,
    "starting-five": `<svg viewBox="0 0 40 40" aria-hidden="true"><circle cx="20" cy="20" r="13" fill="#f26d5b" stroke="#141719" stroke-width="3"/><path d="M8 20h24M20 7c5 7 5 19 0 26M20 7c-5 7-5 19 0 26" fill="none" stroke="#141719" stroke-width="2"/><text x="20" y="24" text-anchor="middle" font-size="10" font-weight="900" fill="#fffefa">5</text></svg>`,
    matchday: `<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M20 6l12 7v14l-12 7-12-7V13z" fill="#fffefa" stroke="#141719" stroke-width="3" stroke-linejoin="round"/><path d="M20 6v28M8 13l24 14M32 13L8 27" stroke="#141719" stroke-width="2"/><circle cx="20" cy="20" r="5" fill="#10a77a" stroke="#141719" stroke-width="2"/></svg>`,
    krillion: `<svg viewBox="0 0 40 40" aria-hidden="true"><path d="M20 5c5 5 9 12 9 19a9 9 0 0 1-18 0c0-7 4-14 9-19z" fill="#10a77a" stroke="#141719" stroke-width="2"/><path d="M13 23h14M15 29h10" stroke="#fffefa" stroke-width="3" stroke-linecap="round"/><text x="20" y="20" text-anchor="middle" font-size="12" font-weight="900" fill="#141719">K</text></svg>`
  };

  return `<span class="game-logo ${className}">${icons[logo] || `<svg viewBox="0 0 40 40" aria-hidden="true"><rect x="7" y="7" width="26" height="26" rx="7" fill="#fffefa" stroke="#141719" stroke-width="3"/><text x="20" y="25" text-anchor="middle" font-size="16" font-weight="900" fill="#141719">${initial}</text></svg>`}</span>`;
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
  if (gameSource(getActiveGame()) === "solvry") {
    elements.letterBoard.hidden = true;
    elements.letterBoard.innerHTML = "";
    return;
  }

  elements.letterBoard.hidden = false;
  const letters = (seedText.toUpperCase().replace(/[^A-Z]/g, "") + "SOLVRY").slice(0, 10);
  const classes = ["hit", "warn", "miss", "", "hit", "", "warn", "hit", "miss", ""];
  elements.letterBoard.innerHTML = "";
  letters.split("").forEach((letter, index) => {
    const tile = document.createElement("span");
    tile.className = `letter-tile ${classes[index]}`.trim();
    tile.textContent = letter;
    elements.letterBoard.append(tile);
  });
}

function renderForm(entry) {
  const activeGame = getActiveGame();
  if (gameSource(activeGame) === "solvry") {
    elements.entryForm.hidden = true;
    return;
  }

  elements.entryForm.hidden = false;
  elements.resultInput.value = entry?.result || "solved";
  elements.scoreInput.value = entry?.score || "";
  elements.scoreInput.placeholder = scoreStyleExample(activeGame);
  elements.scoreHelp.textContent = `Example: ${scoreStyleExample(activeGame)} · ${scoreStyleLabel(activeGame)}`;
  elements.answerInput.value = entry?.answer || "";
  elements.noteInput.value = entry?.note || "";
  elements.revealInput.checked = Boolean(entry?.reveal);
}

function renderMetrics() {
  const dayEntries = state.entries[state.selectedDate] || {};
  let played = 0;
  let completed = 0;

  Object.values(dayEntries).forEach((gameEntries) => {
    const mine = gameEntries.you;
    if (!mine) return;
    played += 1;
    if (isCompletedResult(mine.result)) completed += 1;
  });

  elements.playedMetric.textContent = played;
  elements.solvedMetric.textContent = completed;
  elements.streakMetric.textContent = calculateStreak();
  elements.totalSolvesMetric.textContent = calculateTotalSolves();
  renderProgressDays();
}

function renderProgressDays() {
  const baseDate = new Date(`${state.selectedDate}T00:00:00`);
  const days = [];

  for (let offset = -4; offset <= 0; offset += 1) {
    const date = new Date(baseDate);
    date.setDate(baseDate.getDate() + offset);
    const key = date.toISOString().slice(0, 10);
    const played = hasUserPlayedDate(key);
    const isToday = key === today;
    days.push(`
      <div class="progress-day${played ? " done" : ""}${isToday ? " today" : ""}">
        <strong>${escapeHtml(shortWeekday(date))}</strong>
        <span>${played ? "done" : "open"}</span>
      </div>
    `);
  }

  elements.progressDays.innerHTML = days.join("");
}

function renderScoreboards(activeGame) {
  elements.gameScoreboardTitle.textContent = `${activeGame.name} scoreboard`;
  elements.gameScoreboardMeta.textContent = scoreStyleLabel(activeGame);
  elements.gameScoreboardNote.textContent = scoreStyleHelp(activeGame);

  const overallRows = buildOverallLeaderboard();
  const gameRows = buildGameLeaderboard(activeGame);
  elements.overallLeaderboard.innerHTML = renderRankRows(overallRows, "No scores yet");
  elements.gameLeaderboard.innerHTML = renderRankRows(gameRows, `No ${activeGame.name} scores yet`);
}

function renderRankRows(rows, emptyText) {
  if (!rows.length) {
    return `<article class="rank-row"><span class="rank">-</span><span><strong>${escapeHtml(emptyText)}</strong><small>Import or save a result to start ranking.</small></span><span class="points">0 pts</span></article>`;
  }

  return rows
    .map(
      (person, index) => `
      <article class="rank-row">
        <span class="rank">${index + 1}</span>
        <span>
          <strong>${escapeHtml(person.name)}</strong>
          <small>${escapeHtml(person.detail)}</small>
        </span>
        <span class="points">${escapeHtml(person.value)}${person.subvalue ? `<small>${escapeHtml(person.subvalue)}</small>` : ""}</span>
      </article>
    `
    )
    .join("");
}

function buildOverallLeaderboard() {
  const totals = new Map(
    getPeople().map((person) => [
      person.id,
      { ...person, solvryPoints: 0, completed: 0, wins: 0 }
    ])
  );

  state.games.forEach((game) => {
    const rows = buildGameLeaderboard(game).filter((row) => row.hasEntry && Number.isFinite(row.score.value) && resultWeight(row.entry?.result) > 0);
    rows.forEach((row, index) => {
      const total = totals.get(row.id);
      if (!total) return;
      const placementPoints = placementScore(index);
      total.solvryPoints += placementPoints;
      total.completed += 1;
      if (index === 0 && placementPoints > 0) total.wins += 1;
    });
  });

  return [...totals.values()]
    .filter((person) => person.completed > 0)
    .sort((a, b) => b.solvryPoints - a.solvryPoints || b.wins - a.wins || b.completed - a.completed || a.name.localeCompare(b.name))
    .map((person) => ({
      ...person,
      detail: `${person.completed} game${person.completed === 1 ? "" : "s"} scored · ${person.wins} win${person.wins === 1 ? "" : "s"}`,
      value: `${person.solvryPoints} pts`,
      subvalue: "Solvry"
    }));
}

function buildGameLeaderboard(game) {
  const entries = state.entries[state.selectedDate]?.[game.id] || {};
  return getPeople()
    .map((person) => {
      const entry = entries[person.id];
      const score = scoreEntryForGame(entry, game);
      return {
        ...person,
        entry,
        hasEntry: Boolean(entry),
        score,
        detail: entry ? `${score.detail} · ${entry.result}` : "Not played",
        value: entry ? score.label : "-",
        subvalue: entry ? scoreStyleLabel(game) : ""
      };
    })
    .filter((person) => person.hasEntry)
    .sort((a, b) => compareScoreRows(a, b, game));
}

function compareScoreRows(a, b, game) {
  const aValid = Number.isFinite(a.score.value);
  const bValid = Number.isFinite(b.score.value);
  if (aValid && bValid && a.score.value !== b.score.value) {
    return gameScoreDirection(game) === "high" ? b.score.value - a.score.value : a.score.value - b.score.value;
  }
  if (aValid !== bValid) return aValid ? -1 : 1;
  return resultWeight(b.entry?.result) - resultWeight(a.entry?.result) || a.name.localeCompare(b.name);
}

function scoreEntryForGame(entry, game) {
  if (!entry) {
    return { value: Number.POSITIVE_INFINITY, label: "-", detail: "Not played" };
  }

  const score = String(entry.score || "").trim();
  const type = game.type;
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
  const valid = parts.length >= 2 && parts.length <= 3 && parts.every((part) => Number.isFinite(part));
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
  const people = [state.profile, ...state.friends].map((person) => ({
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

function importShareText(text) {
  const parsed = parseShareText(text);
  if (!parsed) {
    elements.sharePreview.hidden = true;
    elements.sharePreview.innerHTML = "";
    setImportStatus("Could not read that result yet. Try Wordle, Connections, Strands, Mini Crossword, Spelling Bee, or Krillion share text.", "error");
    return;
  }

  const game = state.games.find((item) => item.id === parsed.gameId) || state.games[0];
  state.activeGameId = game.id;
  const gameEntries = getGameEntries(state.selectedDate, game.id);
  gameEntries.you = {
    result: parsed.result,
    score: parsed.score,
    answer: "",
    note: parsed.note,
    reveal: false,
    source: "official-share",
    grid: parsed.grid
  };

  saveState();
  render();
  renderSharePreview(parsed, game);
  setImportStatus(`Imported ${game.name}: ${parsed.score}.`, "success");
  flashStatus(elements.saveStatus, `${game.name} imported and saved.`);
}

function parseShareText(text) {
  const cleaned = String(text || "").trim();
  if (!cleaned) return null;

  const lines = cleaned.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  return parseWordleShare(lines)
    || parseConnectionsShare(lines)
    || parseStrandsShare(lines)
    || parseMiniCrosswordShare(lines)
    || parseSpellingBeeShare(lines)
    || parseKrillionShare(lines);
}

function parseWordleShare(lines) {
  const wordleLine = lines.find((line) => /^Wordle\s+[\d,]+\s+[1-6X]\/6\*?$/i.test(line));
  if (!wordleLine) return null;

  const scoreMatch = wordleLine.match(/^Wordle\s+([\d,]+)\s+([1-6X])\/6\*?$/i);
  if (!scoreMatch) return null;

  const gridPattern = /^[\u{1F7E9}\u{1F7E8}\u{2B1B}\u{2B1C}\u{1F7E6}]+$/u;
  const grid = lines.filter((line) => gridPattern.test(line));
  const rawScore = scoreMatch[2].toUpperCase();
  const score = `${rawScore}/6`;

  return {
    gameId: "wordle",
    score,
    result: rawScore === "X" ? "missed" : "solved",
    note: `Imported official Wordle #${scoreMatch[1]}${grid.length ? ` with ${grid.length} rows` : ""}`,
    grid
  };
}

function parseConnectionsShare(lines) {
  const header = lines.find((line) => /^Connections\b/i.test(line));
  if (!header) return null;

  const gridPattern = /^[\u{1F7E8}\u{1F7E9}\u{1F7E6}\u{1F7EA}]{4}$/u;
  const grid = lines.filter((line) => gridPattern.test(line));
  if (!grid.length) return null;

  const puzzleMatch = lines.join(" ").match(/#?([\d,]+)/);
  const solvedRows = grid.filter((line) => /^([\u{1F7E8}]{4}|[\u{1F7E9}]{4}|[\u{1F7E6}]{4}|[\u{1F7EA}]{4})$/u.test(line)).length;
  const mistakes = Math.max(0, grid.length - 4);

  return {
    gameId: "connections",
    score: `${mistakes} mistake${mistakes === 1 ? "" : "s"}`,
    result: solvedRows >= 4 ? "solved" : "played",
    note: `Imported official Connections${puzzleMatch ? ` #${puzzleMatch[1]}` : ""} with ${grid.length} rows`,
    grid
  };
}

function parseStrandsShare(lines) {
  const header = lines.find((line) => /^Strands\b/i.test(line));
  if (!header) return null;

  const grid = lines.filter((line) => /[\u{1F535}\u{1F7E1}\u{1F4A1}]/u.test(line));
  if (!grid.length) return null;

  const puzzleMatch = lines.join(" ").match(/#?([\d,]+)/);
  const hintCount = (grid.join("").match(/\u{1F4A1}/gu) || []).length;
  const foundSpangram = grid.some((line) => /\u{1F7E1}/u.test(line));
  const score = hintCount ? `${hintCount} hint${hintCount === 1 ? "" : "s"}` : "No hints";

  return {
    gameId: "strands",
    score,
    result: foundSpangram ? "solved" : "played",
    note: `Imported official Strands${puzzleMatch ? ` #${puzzleMatch[1]}` : ""}${foundSpangram ? " with spangram" : ""}`,
    grid
  };
}

function parseMiniCrosswordShare(lines) {
  const text = lines.join(" ");
  if (!/\b(Mini Crossword|The Mini)\b/i.test(text)) return null;

  const timeMatch = text.match(/\b(\d{1,2}:\d{2}(?::\d{2})?)\b/);
  if (!timeMatch) return null;

  return {
    gameId: "mini-crossword",
    score: normalizeTimeScore(timeMatch[1]),
    result: "solved",
    note: "Imported official Mini Crossword time",
    grid: []
  };
}

function parseSpellingBeeShare(lines) {
  const text = lines.join(" ");
  if (!/Spelling Bee/i.test(text)) return null;

  const ranks = ["Queen Bee", "Genius", "Amazing", "Great", "Nice", "Solid", "Good", "Moving", "Good Start", "Beginner"];
  const rank = ranks.find((item) => new RegExp(`\\b${item}\\b`, "i").test(text));
  if (!rank) return null;

  const pointMatch = text.match(/\b(\d{1,4})\s*(?:points?|pts?)\b/i);
  const score = pointMatch ? `${rank} · ${pointMatch[1]} pts` : rank;

  return {
    gameId: "spelling-bee",
    score,
    result: "played",
    note: `Imported official Spelling Bee rank: ${rank}`,
    grid: []
  };
}

function parseKrillionShare(lines) {
  const header = lines.find((line) => /^Krillion\s+#?[\d,]+/i.test(line));
  if (!header) return null;

  const headerIndex = lines.indexOf(header);
  const scoreLine = lines.slice(headerIndex + 1).find((line) => /^\d{1,4}$/.test(line));
  if (!scoreLine) return null;

  const numberMatch = header.match(/^Krillion\s+#?([\d,]+)/i);
  const grid = lines
    .slice(lines.indexOf(scoreLine) + 1)
    .filter((line) => !/^https?:\/\//i.test(line));

  return {
    gameId: "krillion",
    score: scoreLine,
    result: Number(scoreLine) > 0 ? "played" : "missed",
    note: `Imported official Krillion #${numberMatch?.[1] || "daily dive"} with ${scoreLine} depth points`,
    grid
  };
}

function normalizeTimeScore(score) {
  const parts = score.split(":");
  return parts.length === 2 ? score.padStart(5, "0") : score;
}

function renderSharePreview(parsed, game) {
  elements.sharePreview.hidden = false;
  elements.sharePreview.innerHTML = `
    <strong>${escapeHtml(game.name)} imported</strong>
    <small>${escapeHtml(parsed.score)} · saved for ${escapeHtml(state.selectedDate)}</small>
    ${parsed.grid.length ? `<div class="share-grid">${escapeHtml(parsed.grid.join("\n"))}</div>` : ""}
  `;
}

function setImportStatus(message, tone = "") {
  elements.importStatus.textContent = message;
  elements.importStatus.className = `import-status${tone ? ` ${tone}` : ""}`;
}

function getActiveGame() {
  return state.games.find((game) => game.id === state.activeGameId) || state.games[0];
}

function getGameEntries(date, gameId) {
  state.entries[date] ||= {};
  state.entries[date][gameId] ||= {};
  return state.entries[date][gameId];
}

function getPeople() {
  return [state.profile, ...state.friends].map((person) => ({
    id: person.id || "you",
    name: person.name,
    handle: person.handle
  }));
}

function placementScore(index) {
  return [10, 7, 5, 3, 2, 1][index] || 1;
}

function gameScoreDirection(game) {
  if (["points", "depth", "rank", "complete"].includes(game.type)) return "high";
  return "low";
}

function resultWeight(result) {
  return { solved: 3, played: 2, missed: 0 }[result] ?? 1;
}

function calculateCompleted(personId) {
  const dayEntries = state.entries[state.selectedDate] || {};
  return Object.values(dayEntries).filter((gameEntries) => gameEntries[personId]).length;
}

function isCompletedResult(result) {
  return result === "solved" || result === "played";
}

function hasUserPlayedDate(dateKey) {
  const dayEntries = state.entries[dateKey] || {};
  return Object.values(dayEntries).some((gameEntries) => gameEntries.you);
}

function calculateTotalSolves() {
  return Object.values(state.entries).reduce((total, dayEntries) => {
    return total + Object.values(dayEntries).filter((gameEntries) => {
      return isCompletedResult(gameEntries.you?.result);
    }).length;
  }, 0);
}

function calculateStreak() {
  const dates = Object.keys(state.entries).sort().reverse();
  let streak = 0;
  let cursor = new Date(`${today}T00:00:00`);

  for (const date of dates) {
    const expected = cursor.toISOString().slice(0, 10);
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

function defaultScoreLabel(result) {
  return result === "missed" ? "Missed" : "Complete";
}

function loadState() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || localStorage.getItem(LEGACY_STORAGE_KEY));
    const nextState = saved ? mergeState(starterState, saved) : structuredClone(starterState);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(nextState));
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
      scoring: { ...scoringForType(game.type), ...game.scoring, ...savedGame.scoring },
      logo: savedGame.logo || game.logo,
      officialUrl: savedGame.officialUrl || game.officialUrl
    };
  });
  const mergedGames = [...mergedDefaults];
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

render();
"""#
