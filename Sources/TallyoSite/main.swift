import Foundation

@main
struct TallyoSite {
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

        print("Tallyo built at \(dist.path)")
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
    <title>Tallyo</title>
    <meta
      name="description"
      content="Tallyo is a social hub for tracking daily word and puzzle games with friends."
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
        <a class="brand" href="#today" aria-label="Tallyo home">
          <span class="brand-mark" aria-hidden="true">TY</span>
          <span>
            <strong>Tallyo</strong>
            <small>Daily games with friends</small>
          </span>
        </a>
        <nav class="topnav" aria-label="Primary">
          <a href="#today">Today</a>
          <a href="#friends">Friends</a>
          <a href="#answers">Answers</a>
        </nav>
        <label class="date-control">
          Date
          <input id="playDate" type="date" />
        </label>
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
            </div>
            <div class="status-stack">
              <span class="pill" id="friendCompletion">0 friends done</span>
              <span class="pill accent" id="privacyState">Answers hidden</span>
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
            <button class="icon-button" value="cancel" type="submit" aria-label="Close">x</button>
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
              <option value="complete">Complete</option>
            </select>
          </label>
          <button class="primary-button" value="default" type="submit">Add game</button>
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
  grid-template-columns: minmax(180px, 1fr) auto minmax(170px, 0.5fr);
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

.date-control {
  justify-self: end;
  display: grid;
  gap: 4px;
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 800;
  text-transform: uppercase;
}

.date-control input,
input,
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
  grid-template-columns: 40px 1fr auto;
  gap: 10px;
  align-items: center;
  width: 100%;
  padding: 12px;
  text-align: left;
  border-color: transparent;
}

.game-card:hover,
.game-card.active {
  border-color: var(--ink);
  background: var(--panel);
}

.game-icon {
  display: grid;
  width: 40px;
  height: 40px;
  place-items: center;
  border-radius: 8px;
  color: var(--ink);
  font-weight: 900;
}

.game-card:nth-child(4n + 1) .game-icon {
  background: var(--aqua);
}

.game-card:nth-child(4n + 2) .game-icon {
  background: #ffe28a;
}

.game-card:nth-child(4n + 3) .game-icon {
  background: #ffb1a7;
}

.game-card:nth-child(4n + 4) .game-icon {
  background: #c9c7ff;
}

.game-card strong,
.game-card span {
  display: block;
}

.game-card span {
  color: var(--muted);
  font-size: 0.8rem;
}

.game-score {
  font-size: 0.78rem;
  font-weight: 900;
  color: var(--green);
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

.play-surface {
  margin-top: 22px;
  padding: clamp(16px, 3vw, 24px);
  border: 1px solid var(--ink);
  border-radius: 8px;
  background:
    linear-gradient(90deg, rgba(255, 255, 255, 0.72), rgba(255, 255, 255, 0.28)),
    repeating-linear-gradient(45deg, rgba(20, 23, 25, 0.04) 0 1px, transparent 1px 16px);
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
  .date-control {
    justify-self: stretch;
  }

  .topnav {
    overflow-x: auto;
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
const STORAGE_KEY = "tallyo-state-v1";
const today = new Date().toISOString().slice(0, 10);

const starterState = {
  activeGameId: "wordle",
  selectedDate: today,
  profile: { name: "You", handle: "@tallyo" },
  games: [
    { id: "wordle", name: "Wordle", type: "guesses" },
    { id: "zip", name: "Zip", type: "time" },
    { id: "krillion", name: "Krillion", type: "complete" },
    { id: "queens", name: "Queens", type: "mistakes" }
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
      krillion: {
        nolan: { result: "solved", score: "Complete", answer: "289", note: "Math day", reveal: true }
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
  resetButton: document.querySelector("#resetButton"),
  addGameButton: document.querySelector("#addGameButton"),
  gameDialog: document.querySelector("#gameDialog"),
  gameForm: document.querySelector("#gameForm"),
  gameNameInput: document.querySelector("#gameNameInput"),
  gameTypeInput: document.querySelector("#gameTypeInput")
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

elements.gameForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const name = elements.gameNameInput.value.trim();
  if (!name) return;
  const id = uniqueId(slugify(name), state.games.map((game) => game.id));
  state.games.push({ id, name, type: elements.gameTypeInput.value });
  state.activeGameId = id;
  saveState();
  elements.gameDialog.close();
  render();
});

elements.copyButton.addEventListener("click", async () => {
  const activeGame = getActiveGame();
  const mine = getGameEntries(state.selectedDate, state.activeGameId).you;
  const recap = mine
    ? `Tallyo: ${activeGame.name} ${state.selectedDate} - ${mine.result}, ${mine.score}${mine.answer && mine.reveal ? `, answer ${mine.answer}` : ""}`
    : `Tallyo: ${activeGame.name} ${state.selectedDate} - no result yet`;

  try {
    await navigator.clipboard.writeText(recap);
    flashButton(elements.copyButton, "Copied", "Copy recap");
  } catch {
    flashButton(elements.copyButton, "Copy failed", "Copy recap");
  }
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
  elements.friendCompletion.textContent = `${friendEntries.length} friend${friendEntries.length === 1 ? "" : "s"} done`;
  elements.privacyState.textContent = myEntry?.reveal ? "Answer shown" : "Answers hidden";

  renderGameList();
  renderBoard(activeGame.name);
  renderForm(myEntry);
  renderMetrics();
  renderLeaderboard();
  renderAnswers();
}

function renderGameList() {
  elements.gameList.innerHTML = "";
  state.games.forEach((game) => {
    const entries = getGameEntries(state.selectedDate, game.id);
    const playedCount = Object.keys(entries).length;
    const card = document.createElement("button");
    card.type = "button";
    card.className = `game-card${game.id === state.activeGameId ? " active" : ""}`;
    card.innerHTML = `
      <span class="game-icon">${game.name.slice(0, 1).toUpperCase()}</span>
      <span>
        <strong>${escapeHtml(game.name)}</strong>
        <span>${scoreStyleLabel(game.type)}</span>
      </span>
      <span class="game-score">${playedCount}</span>
    `;
    card.addEventListener("click", () => {
      state.activeGameId = game.id;
      saveState();
      render();
    });
    elements.gameList.append(card);
  });
}

function renderBoard(seedText) {
  const letters = (seedText.toUpperCase().replace(/[^A-Z]/g, "") + "TALLYO").slice(0, 10);
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
  elements.resultInput.value = entry?.result || "solved";
  elements.scoreInput.value = entry?.score || "";
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
          ${entry.note ? `<small>${escapeHtml(entry.note)}</small>` : ""}
        </article>
      `;
    })
    .join("");
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
  return {
    guesses: "Fewest guesses",
    time: "Fastest time",
    mistakes: "Fewest mistakes",
    complete: "Completion"
  }[type];
}

function defaultScoreLabel(result) {
  return result === "missed" ? "Missed" : "Complete";
}

function loadState() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));
    return saved ? mergeState(starterState, saved) : structuredClone(starterState);
  } catch {
    return structuredClone(starterState);
  }
}

function mergeState(base, saved) {
  return {
    ...structuredClone(base),
    ...saved,
    profile: { ...base.profile, ...saved.profile },
    games: saved.games?.length ? saved.games : base.games,
    friends: saved.friends || base.friends,
    entries: { ...base.entries, ...saved.entries }
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
