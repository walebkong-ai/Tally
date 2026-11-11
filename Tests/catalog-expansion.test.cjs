const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const safety = require('../Assets/sync-safety.mjs');
const app = fs.readFileSync(path.join(__dirname, '../dist/app.js'), 'utf8');
function setup() {
  const c = vm.createContext({ today: '2026-11-11' });
  vm.runInContext(app.slice(app.indexOf('const ADDITIONAL_IMPORT_GAMES'), app.indexOf('let state = loadState()')), c);
  vm.runInContext(app.slice(app.indexOf('function normalizeManualScore('), app.indexOf('function saveManualScore(')), c);
  for (const name of ['matchesGameSearch', 'scoreTier', 'scoreEntryForGame', 'parseGuessScore', 'parseTimeScore', 'parseNumberScore', 'resultWeight', 'eligibleForDailyRanking']) {
    const tail = app.slice(app.indexOf(`function ${name}(`));
    const next = /\n(?:async )?function \w+\(/.exec(tail);
    vm.runInContext(tail.slice(0, next?.index), c);
  }
  return { c, games: vm.runInContext('starterState.games.filter(g => g.source === "official")', c) };
}
const newIds = ['poople','flagle','terradle','spotle','daily-crossword','brandle','pricepoint','metazooa','travle','unwordle','feetle','loldle','murdle','noillirk','maptap','fibble','chainle','costcodle','minecraftle','enclose-horse','genshindle','squirdle','minute-cryptic','clevergoat-categories','rngdle','dsmdle','quordle','contexto','fine-print'];

test('the actual starter catalog contains each requested verified daily once, preserving existing IDs', () => {
  const { games } = setup();
  assert.equal(games.length, 48);
  assert.equal(new Set(games.map(g => g.id)).size, games.length);
  assert.equal(new Set(games.map(g => g.name.toLowerCase())).size, games.length);
  for (const id of newIds) assert.equal(games.filter(g => g.id === id && g.manualOnly).length, 1, id);
  for (const id of ['wordle','connections','krillion','globle','strands','mini-crossword','size-it-up']) assert.equal(games.filter(g => g.id === id).length, 1, id);
  assert.ok(games.every(g => new URL(g.officialUrl).protocol === 'https:'));
});

test('name aliases find existing canonical entries instead of creating duplicates', () => {
  const { c, games } = setup();
  for (const [query, id] of [['magnitudle','size-it-up'],['squirtle','squirdle'],['genshidle','genshindle'],['costcodle','costcodle'],['mini crossword','mini-crossword']]) {
    const found = games.filter(g => c.matchesGameSearch(g, query));
    assert.equal(found.length, 1, query);
    assert.equal(found[0].id, id, query);
  }
});

test('all added daily games can normalize a valid manual result using their actual scoring style', () => {
  const { c, games } = setup();
  for (const g of games.filter(g => g.manualOnly)) {
    const value = g.type === 'time' ? '12:03' : g.type === 'complete' ? '' : String(Math.max(3,g.minScore || 0));
    const saved = c.normalizeManualScore(g.id, 'solved', value, '');
    assert.equal(saved.result, 'solved', g.id);
    assert.ok(!saved.error && saved.score, g.id);
    const scored = c.scoreEntryForGame(saved, g);
    assert.ok(Number.isFinite(scored.value), g.id);
    assert.ok(c.scoreTier({ hasEntry: true, entry: saved, score: scored }, g), g.id);
  }
});

test('publisher guess limits and point totals reject invalid scores without changing old formats', () => {
  const { c } = setup();
  for (const [id, valid, bad] of [['spotle','10','11'],['brandle','8','9'],['metazooa','20','21'],['costcodle','6','7'],['minecraftle','10','11'],['genshindle','5','6'],['chainle','5000','5001'],['pricepoint','25000','25001'],['noillirk','2500','2501']]) {
    assert.ok(!c.normalizeManualScore(id,'solved',valid,'').error, id);
    assert.ok(c.normalizeManualScore(id,'solved',bad,'').error, id);
  }
  for (const raw of ['','-1','1.5','1e3','Infinity','NaN','3 guesses']) assert.ok(c.normalizeManualScore('poople','solved',raw,'').error, raw);
  assert.equal(c.normalizeManualScore('enclose-horse','played','-5','').score, '-5');
  assert.ok(c.normalizeManualScore('maptap','solved','-5','').error);
  assert.ok(c.normalizeManualScore('daily-crossword','solved','12:99','').error);
  assert.equal(c.normalizeManualScore('daily-crossword','solved','1:02:30','').score, '1:02:30');
  assert.equal(c.normalizeManualScore('wordle','solved','3','').score, '3/6');
});

test('missed and unfinished daily puzzles save honestly without earning ranking points', () => {
  const { c, games } = setup();
  for (const g of games.filter(g => g.manualOnly)) {
    const saved = c.normalizeManualScore(g.id, 'missed', '', '');
    assert.equal(saved.score, 'Missed', g.id);
    const scored = c.scoreEntryForGame(saved, g);
    assert.equal(c.scoreTier({ hasEntry: true, entry: saved, score: scored }, g), 0, g.id);
    if (['guesses','time','complete','strokes','mistakes'].includes(g.type)) {
      const partial = c.normalizeManualScore(g.id, 'played', '', '');
      assert.equal(partial.score, 'Played', g.id);
      assert.equal(c.scoreTier({ hasEntry: true, entry: partial, score: c.scoreEntryForGame(partial,g) },g),0,g.id);
    }
  }
});

test('new game IDs retain the existing private/shared split when journaled for sync', () => {
  const { c, games } = setup();
  for (const game of games.filter(g => g.manualOnly)) {
    const entry = { ...c.normalizeManualScore(game.id,'solved',game.type === 'time' ? '1:03' : game.type === 'complete' ? '' : String(Math.max(3,game.minScore || 0)),''), source:'manual',answer:'PRIVATE',note:'PRIVATE NOTE',reveal:false };
    const state = { games,profile:{},pinnedGameIds:[],entries:{'2026-11-11':{[game.id]:{you:entry}}} };
    const record = safety.localRecords(state)[safety.resultRecordId('2026-11-11',game.id)];
    const projection = safety.sharedResult(record,'owner');
    assert.equal(record.value.answer, 'PRIVATE');
    assert.equal(projection.gameId, game.id);
    assert.ok(!('answer' in projection) && !('note' in projection));
  }
});

test('Minute Cryptic accepts signed par, Categories handles its last life and Quordle requires four solved words', () => {
  const { c } = setup();
  for (const [raw, score] of [['-2','-2'],['0','0'],['+2','2']]) assert.equal(c.normalizeManualScore('minute-cryptic','solved',raw,'').score,score);
  assert.ok(c.normalizeManualScore('minute-cryptic','solved','-1.5','').error);
  assert.equal(c.normalizeManualScore('clevergoat-categories','solved','0','').score,'0 mistakes');
  assert.equal(c.normalizeManualScore('clevergoat-categories','solved','4','').result,'missed');
  assert.ok(c.normalizeManualScore('quordle','solved','3','').error);
  assert.equal(c.normalizeManualScore('quordle','solved','7','').score,'7 guesses');
});

test('luck-based RNGdle compares daily EP on its board without entering the combined leaderboard', () => {
  const { c, games } = setup(), game = games.find(g => g.id === 'rngdle');
  const entry = c.normalizeManualScore('rngdle','played','25.5','');
  assert.equal(entry.score,'25.5');
  const scored = c.scoreEntryForGame(entry, game);
  assert.equal(scored.value,25.5);
  assert.equal(c.scoreTier({hasEntry:true,entry,score:scored},game),1);
  assert.equal(c.eligibleForDailyRanking(game,entry,'2026-11-11'),false);
  assert.ok(c.normalizeManualScore('rngdle','played','-2','').error);
  assert.ok(c.normalizeManualScore('rngdle','played','1e6','').error);
});

test('saving after a catalog upgrade preserves new official games, old scores and concurrent custom definitions', () => {
  const { games } = setup();
  const custom = {id:'custom-kept',name:'My daily',source:'custom',type:'points',sharing:'personal'};
  const old = {games:[{id:'wordle',name:'Wordle',source:'official',type:'guesses'},custom],profile:{name:'You'},entries:{'2026-11-10':{wordle:{you:{score:'3/6',result:'solved',source:'manual',reveal:false}}}},pinnedGameIds:[]};
  const baseline = safety.localRecords(old);
  const stored = structuredClone(old);
  stored.games[1].name = 'Edited in another tab';
  const values = new Map([['catalog',JSON.stringify(stored)]]);
  const storage = {getItem:key=>values.get(key) ?? null,setItem:(key,value)=>values.set(key,value),removeItem:key=>values.delete(key),get length(){return values.size;},key:i=>[...values.keys()][i]};
  const current = {...structuredClone(old),games:[...JSON.parse(JSON.stringify(games)),custom],activeGameId:'fine-print',selectedDate:'2026-11-11'};
  const saved = safety.writeLocal(storage,'catalog','new-release',baseline,current,current);
  assert.equal(saved.activeGameId,'fine-print');
  assert.equal(saved.games.filter(g=>g.source==='official').length,48);
  assert.ok(saved.games.find(g=>g.id==='fine-print')?.manualOnly);
  assert.equal(saved.games.find(g=>g.id===custom.id).name,'Edited in another tab');
  assert.equal(saved.entries['2026-11-10'].wordle.you.score,'3/6');
  assert.equal(JSON.parse(values.get('catalog')).games.length,49);
});
