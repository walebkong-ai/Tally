const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const app = fs.readFileSync(require('node:path').join(__dirname, '../dist/app.js'), 'utf8');

function add(c, name) {
  const tail = app.slice(app.indexOf(`function ${name}(`));
  const next = /\n(?:async )?function \w+\(/.exec(tail);
  vm.runInContext(name === 'localDateKey' ? tail.slice(0, tail.indexOf('\n}') + 2) : tail.slice(0, next?.index), c);
}
function setup(day = '2026-11-16') {
  let now = `${day}T23:59:59`, renders = 0;
  class Clock extends Date { constructor(...args) { super(...(args.length ? args : [now])); } }
  const events = {}, fields = Array.from({ length: 5 }, () => ({ value: day, max: day }));
  const c = vm.createContext({
    Date: Clock, today: day, manualFormDirty: false, importDrafts: new Map(), importDraftRevision: 0,
    gameScoring: require('../Assets/game-scoring.mjs'), SHOW_SOLVRY_GAMES: false,
    state: { selectedDate: day, games: [{ id: 'wordle', type: 'guesses' }], entries: {} },
    elements: { playDate: fields[0], importDate: fields[1], manualDateInput: fields[2], shareTextInput: { value: '' } },
    document: { visibilityState: 'visible', querySelectorAll: () => fields, addEventListener: (name, fn) => { events[name] = fn; } },
    window: { addEventListener: (name, fn) => { events[name] = fn; }, setInterval: (fn, delay) => { events.timer = fn; assert.equal(delay, 30000); } },
    render: (focus) => { assert.equal(focus, false); renders++; }
  });
  for (const name of ['localDateKey', 'refreshCurrentDate', 'watchDateRollover', 'calculateStreak', 'hasUserPlayedDate', 'visibleGames', 'gameSource', 'gameStreak', 'scoreEntryForGame', 'parseGuessScore', 'parseNumberScore', 'parseTimeScore']) add(c, name);
  return { c, fields, events, setTime: (value) => { now = value; }, renders: () => renders };
}
function save(c, day, result = 'solved', score = '3/6') {
  c.state.entries[day] = { wordle: { you: { result, score } } };
}

test('midnight advances an undrafted current-day view and all date limits exactly once', () => {
  const h = setup(), { c } = h;
  save(c, '2026-11-16'); const before = JSON.stringify(c.state.entries);
  h.setTime('2026-11-17T00:00:01');
  assert.equal(c.refreshCurrentDate(), true);
  assert.equal(c.today, '2026-11-17'); assert.equal(c.state.selectedDate, '2026-11-17');
  assert.ok(h.fields.every(field => field.max === '2026-11-17'));
  assert.equal(c.elements.manualDateInput.value, '2026-11-17');
  assert.equal(c.importDraftRevision, 1); // An earlier asynchronous clipboard read is stale.
  assert.equal(JSON.stringify(c.state.entries), before);
  assert.equal(c.refreshCurrentDate(), false); assert.equal(h.renders(), 1);
  assert.equal(c.calculateStreak(), 1); assert.equal(c.gameStreak(c.state.games[0]), 1);
});

test('historical views and manual, paste, and inactive-game drafts retain their intended date', () => {
  for (const kind of ['history', 'manual', 'paste', 'inactive', 'manual-date', 'paste-date']) {
    const { c, setTime } = setup();
    if (kind === 'history') { c.state.selectedDate = '2026-10-11'; c.elements.playDate.value = '2026-10-11'; }
    if (kind === 'manual') c.manualFormDirty = true;
    if (kind === 'paste') c.elements.shareTextInput.value = 'Wordle 123 3/6';
    if (kind === 'inactive') c.importDrafts.set('connections', { text: 'unfinished recap', date: '2026-11-16' });
    if (kind === 'manual-date') c.elements.manualDateInput.value = '2026-10-11';
    if (kind === 'paste-date') c.elements.importDate.value = '2026-10-11';
    const before = JSON.stringify({ selectedDate: c.state.selectedDate, elements: c.elements, drafts: [...c.importDrafts] });
    setTime('2026-11-17T00:01:00'); c.refreshCurrentDate();
    assert.equal(c.today, '2026-11-17');
    const after = JSON.stringify({ selectedDate: c.state.selectedDate, elements: c.elements, drafts: [...c.importDrafts] });
    // Only max attributes may change; no draft or date value changes.
    assert.equal(after.replaceAll('"max":"2026-11-17"', '"max":"2026-11-16"'), before, kind);
  }
});

test('foreground timer, focus, pageshow and returning from a suspended background tab check the date', () => {
  for (const event of ['timer', 'focus', 'pageshow', 'visibilitychange']) {
    const h = setup(); h.c.watchDateRollover(); h.c.document.visibilityState = 'hidden';
    h.setTime('2026-11-19T09:00:00'); h.events.timer(); assert.equal(h.renders(), 0);
    h.c.document.visibilityState = 'visible'; h.events[event]();
    assert.equal(h.c.today, '2026-11-19', event); assert.equal(h.renders(), 1);
  }
});

test('a clipboard read started yesterday cannot populate a newly advanced date', async () => {
  const {c,setTime}=setup(); let deliver, click, previews=0;
  const waiting=new Promise(resolve=>{deliver=resolve;});
  c.state.activeGameId='wordle';
  c.navigator={clipboard:{readText:()=>waiting}};
  c.elements.importClipboardButton={disabled:false,addEventListener:(_,handler)=>{click=handler;}};
  c.previewImport=()=>{previews++;};
  const start=app.indexOf('elements.importClipboardButton.addEventListener("click"');
  vm.runInContext(app.slice(start,app.indexOf('elements.shareTextInput.addEventListener',start)),c);
  const reading=click(); setTime('2026-11-17T00:00:01'); c.refreshCurrentDate();
  deliver('Wordle 123 3/6'); await reading;
  assert.equal(c.elements.importDate.value,'2026-11-17');
  assert.equal(c.elements.shareTextInput.value,''); assert.equal(previews,0);
  assert.equal(c.elements.importClipboardButton.disabled,false);
});

test('activity and completion streaks both allow today to remain open, but only activity counts a miss', () => {
  const { c } = setup(); const game = c.state.games[0];
  save(c, '2026-11-14'); save(c, '2026-11-15'); save(c, '2026-11-18');
  assert.equal(c.calculateStreak(), 2); assert.equal(c.gameStreak(game), 2);
  save(c, '2026-11-16', 'missed', 'X/6');
  assert.equal(c.calculateStreak(), 3); assert.equal(c.gameStreak(game), 0);
  save(c, '2026-11-16', 'played', '3/6'); assert.equal(c.gameStreak(game), 2);
  save(c, '2026-11-16', 'solved', '0/6'); assert.equal(c.gameStreak(game), 2);
});

test('streaks expire after a skipped opportunity and ignore future or friend-only entries', () => {
  const { c, setTime } = setup(); save(c, '2026-11-15');
  c.state.entries['2026-11-16'] = { wordle: { friend: { result: 'solved', score: '1/6' } } };
  assert.equal(c.calculateStreak(), 1); assert.equal(c.gameStreak(c.state.games[0]), 1);
  setTime('2026-11-17T00:01:00'); c.refreshCurrentDate();
  assert.equal(c.calculateStreak(), 0); assert.equal(c.gameStreak(c.state.games[0]), 0);
});

test('rollover and streaks cross month/year and DST calendar boundaries', () => {
  for (const [previous, next] of [['2026-12-31', '2027-01-01'], ['2026-10-31', '2026-11-01'], ['2026-03-08', '2026-03-09']]) {
    const { c, setTime } = setup(previous); save(c, previous);
    setTime(`${next}T00:01:00`); c.refreshCurrentDate();
    assert.equal(c.today, next); assert.equal(c.gameStreak(c.state.games[0]), 1); assert.equal(c.calculateStreak(), 1);
  }
});

test('activity and completion metrics have distinct visible labels', () => {
  const html = fs.readFileSync(require('node:path').join(__dirname, '../dist/index.html'), 'utf8');
  assert.match(html, /<span>activity streak<\/span>/);
  assert.match(app, /-day completion streak/);
  assert.match(app, /failed attempts do not count/);
});
