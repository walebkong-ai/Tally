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
            <button class="icon-button" id="addGameButton" type="button" title="Add game" aria-label="Add game">+</button>
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

          <div class="play-surface" aria-live="polite">
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
                </label>
                <label>
                  Answer
                  <input id="answerInput" type="text" placeholder="Optional" autocomplete="off" />
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
            </form>
          </div>

          <div class="import-surface" id="import">
            <div>
              <p class="eyebrow">Official results</p>
              <h2>Import a share result</h2>
            </div>
            <p class="import-copy">Play on the official site, use its Share button, then import the copied result here.</p>
            <div class="import-actions">
              <button class="primary-button" id="importClipboardButton" type="button">Import copied result</button>
              <button class="ghost-button" id="importPasteButton" type="button">Import pasted text</button>
            </div>
            <label>
              Paste fallback
              <textarea id="shareTextInput" class="share-input" rows="6" placeholder="Wordle 1,234 4/6&#10;&#10;⬛🟨⬛🟩⬛&#10;🟩🟩🟩🟩🟩"></textarea>
            </label>
            <div class="import-status" id="importStatus" role="status">Ready for a Wordle or Krillion share result.</div>
            <div class="share-preview" id="sharePreview" hidden></div>
          </div>

          <div class="metrics" aria-label="Summary">
            <div>
              <strong id="playedMetric">0</strong>
              <span>played</span>
            </div>
            <div>
              <strong id="solvedMetric">0</strong>
              <span>solved</span>
            </div>
            <div>
              <strong id="streakMetric">0</strong>
              <span>day streak</span>
            </div>
          </div>
        </section>

        <section class="panel social-panel" id="friends">
          <div class="section-head compact">
            <div>
              <p class="eyebrow">Circle</p>
              <h2>Friend leaderboard</h2>
            </div>
            <button class="ghost-button" id="resetButton" type="button">Reset demo</button>
          </div>
          <div class="leaderboard" id="leaderboard"></div>
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
  --shadow: 0 22px 60px rgba(20, 23, 25, 0.12);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

* {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
}

body {
  margin: 0;
  min-width: 320px;
  background:
    linear-gradient(135deg, rgba(16, 167, 122, 0.12), transparent 34%),
    radial-gradient(circle at 90% 10%, rgba(239, 189, 58, 0.22), transparent 26%),
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
  background: var(--ink);
  color: var(--paper);
  font-size: 0.78rem;
  font-weight: 900;
  letter-spacing: 0;
}

.brand strong,
.brand small {
  display: block;
}

.brand strong {
  font-size: 1rem;
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
  grid-template-columns: 240px minmax(360px, 1.5fr) minmax(320px, 0.95fr);
  grid-template-areas:
    "rail tracker social"
    "rail tracker answers";
  gap: 18px;
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
}

.game-card:hover,
.game-card.active {
  border-color: var(--ink);
  background: var(--panel);
}

.game-card.pinned {
  border-color: rgba(16, 167, 122, 0.45);
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
  background: #ffe28a;
}

.game-logo.strands,
.game-logo.queens {
  background: #ffb1a7;
}

.game-logo.mini-crossword,
.game-logo.crossclimb {
  background: #c9c7ff;
}

.game-logo.sudoku,
.game-logo.zip {
  background: #bdeee2;
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
  background: var(--paper);
  color: var(--ink);
}

.pin-button svg {
  width: 18px;
  height: 18px;
}

.panel {
  padding: clamp(18px, 3vw, 26px);
}

.tracker-panel {
  grid-area: tracker;
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
h2 {
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
  grid-template-columns: repeat(3, 1fr);
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
  padding: 16px;
}

.metrics strong,
.metrics span {
  display: block;
}

.metrics strong {
  font-size: 1.8rem;
}

.metrics span {
  color: var(--muted);
  font-weight: 800;
}

.leaderboard,
.answer-feed {
  display: grid;
  gap: 10px;
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

@media (max-width: 1080px) {
  .workspace {
    grid-template-columns: 210px 1fr;
    grid-template-areas:
      "rail tracker"
      "social answers";
  }
}

@media (max-width: 780px) {
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

  .workspace {
    grid-template-columns: 1fr;
    grid-template-areas:
      "rail"
      "tracker"
      "social"
      "answers";
  }

  .game-rail {
    position: static;
  }

  .game-list {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .section-head,
  .form-actions {
    align-items: flex-start;
    flex-direction: column;
  }

  .field-grid,
  .import-actions,
  .metrics {
    grid-template-columns: 1fr;
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

  .letter-board {
    grid-template-columns: repeat(5, minmax(0, 1fr));
  }
}
"""#

let appScript = #"""
const STORAGE_KEY = "solvry-state-v1";
const LEGACY_STORAGE_KEY = "tallyo-state-v1";
const DEPRECATED_DEFAULT_GAME_IDS = new Set();
const today = new Date().toISOString().slice(0, 10);

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

const starterState = {
  activeGameId: "wordle",
  selectedDate: today,
  profile: { name: "You", handle: "@solvry" },
  account: { signedIn: false, provider: "", email: "" },
  pinnedGameIds: [],
  games: [
    { id: "wordle", name: "Wordle", type: "guesses", scoring: { label: "Fewest guesses", helper: "Guess count out of 6. Lower is better; X/6 is a miss.", example: "4/6" }, logo: "wordle", officialUrl: "https://www.nytimes.com/games/wordle/index.html" },
    { id: "connections", name: "Connections", type: "mistakes", scoring: { label: "Fewest mistakes", helper: "Mistakes before solving. Lower is better, with 0 mistakes as perfect.", example: "0 mistakes" }, logo: "connections", officialUrl: "https://www.nytimes.com/games/connections" },
    { id: "strands", name: "Strands", type: "complete", scoring: { label: "Completion", helper: "Track completion, then use notes for hints, theme words, or spangram details.", example: "Complete" }, logo: "strands", officialUrl: "https://www.nytimes.com/games/strands" },
    { id: "mini-crossword", name: "Mini Crossword", type: "time", scoring: { label: "Fastest time", helper: "Completion time wins. Lower times rank better.", example: "00:54" }, logo: "mini-crossword", officialUrl: "https://www.nytimes.com/crosswords/game/mini" },
    { id: "spelling-bee", name: "Spelling Bee", type: "rank", scoring: { label: "Best rank", helper: "Official rank wins. Queen Bee beats Genius, which beats lower ranks.", example: "Genius" }, logo: "spelling-bee", officialUrl: "https://www.nytimes.com/puzzles/spelling-bee" },
    { id: "sudoku", name: "Sudoku", type: "time", scoring: { label: "Fastest time", helper: "Completion time wins. Lower times rank better.", example: "05:21" }, logo: "sudoku", officialUrl: "https://www.nytimes.com/puzzles/sudoku" },
    { id: "queens", name: "Queens", type: "mistakes", scoring: { label: "Fewest mistakes", helper: "Mistakes before finishing. Lower is better.", example: "0 mistakes" }, logo: "queens", officialUrl: "https://www.linkedin.com/games/" },
    { id: "zip", name: "Zip", type: "time", scoring: { label: "Fastest time", helper: "Completion time wins. Lower times rank better.", example: "01:48" }, logo: "zip", officialUrl: "https://www.linkedin.com/games/" },
    { id: "crossclimb", name: "Crossclimb", type: "time", scoring: { label: "Fastest time", helper: "Completion time wins. Lower times rank better.", example: "02:04" }, logo: "crossclimb", officialUrl: "https://www.linkedin.com/games/" },
    { id: "pinpoint", name: "Pinpoint", type: "guesses", scoring: { label: "Fewest guesses", helper: "Fewer clues or guesses wins.", example: "3 guesses" }, logo: "pinpoint", officialUrl: "https://www.linkedin.com/games/" },
    { id: "krillion", name: "Krillion", type: "depth", scoring: { label: "Highest depth", helper: "Rarer valid answers score more. Higher total depth points win.", example: "110" }, logo: "krillion", officialUrl: "https://krillion.io/" }
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
      zip: {
        mira: { result: "played", score: "01:48", answer: "Loop path", note: "One tricky turn", reveal: true },
        jay: { result: "played", score: "02:04", answer: "Loop path", note: "Good route", reveal: false }
      },
      queens: {
        you: { result: "played", score: "2 mistakes", answer: "", note: "", reveal: false },
        mira: { result: "played", score: "0 mistakes", answer: "Board clear", note: "Locked in", reveal: true }
      }
    }
  }
};

let state = loadState();

const elements = {
  playDate: document.querySelector("#playDate"),
  gameList: document.querySelector("#gameList"),
  activeGameTitle: document.querySelector("#activeGameTitle"),
  scoreHint: document.querySelector("#scoreHint"),
  friendCompletion: document.querySelector("#friendCompletion"),
  privacyState: document.querySelector("#privacyState"),
  letterBoard: document.querySelector("#letterBoard"),
  entryForm: document.querySelector("#entryForm"),
  resultInput: document.querySelector("#resultInput"),
  scoreInput: document.querySelector("#scoreInput"),
  answerInput: document.querySelector("#answerInput"),
  noteInput: document.querySelector("#noteInput"),
  revealInput: document.querySelector("#revealInput"),
  playedMetric: document.querySelector("#playedMetric"),
  solvedMetric: document.querySelector("#solvedMetric"),
  streakMetric: document.querySelector("#streakMetric"),
  leaderboard: document.querySelector("#leaderboard"),
  friendForm: document.querySelector("#friendForm"),
  friendNameInput: document.querySelector("#friendNameInput"),
  friendHandleInput: document.querySelector("#friendHandleInput"),
  answerFeed: document.querySelector("#answerFeed"),
  copyButton: document.querySelector("#copyButton"),
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

elements.addGameButton.addEventListener("click", () => {
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

function render() {
  const activeGame = getActiveGame();
  const gameEntries = getGameEntries(state.selectedDate, state.activeGameId);
  const myEntry = gameEntries.you;
  const friendEntries = state.friends.filter((friend) => gameEntries[friend.id]);

  elements.activeGameTitle.textContent = activeGame.name;
  elements.scoreHint.textContent = scoreStyleHelp(activeGame);
  elements.friendCompletion.textContent = `${friendEntries.length} friend${friendEntries.length === 1 ? "" : "s"} done`;
  elements.privacyState.textContent = myEntry?.reveal ? "Answer shown" : "Answers hidden";

  renderAccount();
  renderGameList();
  renderOfficialLink(activeGame);
  renderBoard(activeGame.name);
  renderForm(myEntry);
  renderMetrics();
  renderLeaderboard();
  renderAnswers();
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

function renderGameList() {
  elements.gameList.innerHTML = "";
  getSortedGames().forEach((game) => {
    const entries = getGameEntries(state.selectedDate, game.id);
    const playedCount = Object.keys(entries).length;
    const isPinned = state.pinnedGameIds.includes(game.id);
    const card = document.createElement("article");
    card.className = `game-card${game.id === state.activeGameId ? " active" : ""}${isPinned ? " pinned" : ""}`;
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
    elements.gameList.append(card);
  });
}

function getSortedGames() {
  const pinned = new Set(state.pinnedGameIds);
  return [...state.games].sort((a, b) => {
    const pinDelta = Number(pinned.has(b.id)) - Number(pinned.has(a.id));
    if (pinDelta) return pinDelta;
    return state.games.findIndex((game) => game.id === a.id) - state.games.findIndex((game) => game.id === b.id);
  });
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
  elements.resultInput.value = entry?.result || "solved";
  elements.scoreInput.value = entry?.score || "";
  elements.scoreInput.placeholder = scoreStyleExample(activeGame);
  elements.answerInput.value = entry?.answer || "";
  elements.noteInput.value = entry?.note || "";
  elements.revealInput.checked = Boolean(entry?.reveal);
}

function renderMetrics() {
  const dayEntries = state.entries[state.selectedDate] || {};
  let played = 0;
  let solved = 0;

  Object.values(dayEntries).forEach((gameEntries) => {
    const mine = gameEntries.you;
    if (!mine) return;
    played += 1;
    if (mine.result === "solved") solved += 1;
  });

  elements.playedMetric.textContent = played;
  elements.solvedMetric.textContent = solved;
  elements.streakMetric.textContent = calculateStreak();
}

function renderLeaderboard() {
  const rows = [state.profile, ...state.friends]
    .map((person) => ({
      ...person,
      points: calculatePoints(person.id || "you"),
      completed: calculateCompleted(person.id || "you")
    }))
    .sort((a, b) => b.points - a.points || b.completed - a.completed);

  elements.leaderboard.innerHTML = rows
    .map(
      (person, index) => `
      <article class="rank-row">
        <span class="rank">${index + 1}</span>
        <span>
          <strong>${escapeHtml(person.name)}</strong>
          <small>${escapeHtml(person.handle)} · ${person.completed} today</small>
        </span>
        <span class="points">${person.points} pts</span>
      </article>
    `
    )
    .join("");
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
    setImportStatus("Could not read that result yet. Wordle and Krillion share text work right now.", "error");
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
}

function parseShareText(text) {
  const cleaned = String(text || "").trim();
  if (!cleaned) return null;

  const lines = cleaned.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
  return parseWordleShare(lines) || parseKrillionShare(lines);
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

function calculatePoints(personId) {
  const dayEntries = state.entries[state.selectedDate] || {};
  return Object.values(dayEntries).reduce((total, gameEntries) => {
    const entry = gameEntries[personId];
    if (!entry) return total;
    if (entry.result === "solved") return total + 3;
    if (entry.result === "played") return total + 1;
    return total;
  }, 0);
}

function calculateCompleted(personId) {
  const dayEntries = state.entries[state.selectedDate] || {};
  return Object.values(dayEntries).filter((gameEntries) => gameEntries[personId]).length;
}

function calculateStreak() {
  const dates = Object.keys(state.entries).sort().reverse();
  let streak = 0;
  let cursor = new Date(`${today}T00:00:00`);

  for (const date of dates) {
    const expected = cursor.toISOString().slice(0, 10);
    const dayEntries = state.entries[date] || {};
    const played = Object.values(dayEntries).some((gameEntries) => gameEntries.you);
    if (date === expected && played) {
      streak += 1;
      cursor.setDate(cursor.getDate() - 1);
    }
  }

  return streak;
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
  const baseGamesById = Object.fromEntries(base.games.map((game) => [game.id, game]));
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
  const customGames = (saved.games || [])
    .filter((game) => !baseGamesById[game.id] && !DEPRECATED_DEFAULT_GAME_IDS.has(game.id))
    .map((game) => ({
      ...game,
      scoring: { ...scoringForType(game.type), ...game.scoring }
    }));
  const mergedGames = [...mergedDefaults, ...customGames];
  const mergedGameIds = new Set(mergedGames.map((game) => game.id));
  const entries = Object.fromEntries(
    Object.entries({ ...base.entries, ...saved.entries }).map(([date, dayEntries]) => [
      date,
      Object.fromEntries(Object.entries(dayEntries).filter(([gameId]) => !DEPRECATED_DEFAULT_GAME_IDS.has(gameId)))
    ])
  );

  return {
    ...structuredClone(base),
    ...saved,
    profile: { ...base.profile, ...saved.profile },
    account: { ...base.account, ...saved.account },
    games: mergedGames,
    pinnedGameIds: (saved.pinnedGameIds || base.pinnedGameIds).filter((id) => mergedGameIds.has(id)),
    friends: saved.friends || base.friends,
    entries
  };
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

render();
"""#
