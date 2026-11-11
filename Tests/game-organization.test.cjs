const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const app = fs.readFileSync(require('node:path').join(__dirname, '../dist/app.js'), 'utf8');
function add(c, name) {
  const tail = app.slice(app.indexOf(`function ${name}(`));
  const next = /\n(?:async )?function \w+\(/.exec(tail);
  vm.runInContext(name === 'localDateKey' ? tail.slice(0,tail.indexOf('\n}')+2) : tail.slice(0,next?.index), c);
}
function setup(date = '2026-11-11') {
  const c = vm.createContext({today:date,SHOW_SOLVRY_GAMES:false,structuredClone});
  vm.runInContext(app.slice(app.indexOf('const ADDITIONAL_IMPORT_GAMES'), app.indexOf('let state = loadState()')),c);
  c.state = vm.runInContext('structuredClone(starterState)',c);
  c.state.entries = {}; c.state.pinnedGameIds = [];
  for (const name of ['localDateKey','gameCategory','gameStreak','getSortedGames','catalogSections','matchesGameSearch','visibleGames','gameSource','isCompletedResult','getActiveGame']) add(c,name);
  return c;
}
function save(c,date,id,result='solved') { ((c.state.entries[date] ||= {})[id] ||= {}).you = {result,score:'3/6'}; }
const plain = value => JSON.parse(JSON.stringify(value));

test('every active official game has exactly one category and no Immaculate editions remain visible',()=>{
  const c=setup(), games=c.visibleGames();
  const categories=vm.runInContext('GAME_CATEGORIES',c);
  assert.equal(games.length,43);
  for(const game of games) assert.equal(categories.filter(cat=>cat.games.includes(game.id)).length,1,game.id);
  assert.ok(!games.some(game=>/immaculate/i.test(game.id+' '+game.name)));
  assert.equal(c.state.games.filter(game=>game.retired).length,5);
});

test('active streaks span today or yesterday, ignore future dates and the selected viewing date',()=>{
  const c=setup(), game=c.state.games[0];
  c.state.selectedDate='2025-01-01';
  for(const date of ['2026-11-09','2026-11-10','2026-11-12']) save(c,date,game.id);
  assert.equal(c.gameStreak(game),2);
  save(c,'2026-11-11',game.id);assert.equal(c.gameStreak(game),3);
  delete c.state.entries['2026-11-10'];assert.equal(c.gameStreak(game),1);
  delete c.state.entries['2026-11-11'];assert.equal(c.gameStreak(game),0);
});

test('misses break streaks, unfinished guesses do not count, and a friend cannot create your streak',()=>{
  const c=setup(), game=c.state.games[0];
  save(c,'2026-11-10',game.id);save(c,'2026-11-11',game.id,'missed');
  assert.equal(c.gameStreak(game),0);
  save(c,'2026-11-11',game.id,'played');assert.equal(c.gameStreak(game),1);
  delete c.state.entries['2026-11-10'];assert.equal(c.gameStreak(game),0);
  c.state.entries['2026-11-11'][game.id]={friend:{result:'solved'}};
  assert.equal(c.gameStreak(game),0);
  const points=c.state.games.find(g=>g.id==='krillion');
  save(c,'2026-11-11',points.id,'played');assert.equal(c.gameStreak(points),1);
  const bee=c.state.games.find(g=>g.id==='spelling-bee');
  save(c,'2026-11-11',bee.id,'played');assert.equal(c.gameStreak(bee),1);
});

test('local calendar streaks cross month, year and daylight-saving boundaries',()=>{
  for(const [today,previous] of [['2027-01-01','2026-12-31'],['2026-11-01','2026-10-31'],['2026-03-09','2026-03-08']]) {
    const c=setup(today),game=c.state.games[0];save(c,today,game.id);save(c,previous,game.id);
    assert.equal(c.gameStreak(game),2,today);
  }
});

test('pinned games outrank all streaks, then longest streaks win with stable catalog order',()=>{
  const c=setup();
  c.state.games.push({id:'custom-favorite',name:'My game',source:'custom',type:'points'});
  c.state.pinnedGameIds=['globle','custom-favorite'];
  for(const date of ['2026-11-09','2026-11-10','2026-11-11']) save(c,date,'wordle');
  save(c,'2026-11-11','strands');save(c,'2026-11-11','connections');
  assert.deepEqual(plain(c.getSortedGames().slice(0,5).map(g=>g.id)),['globle','custom-favorite','wordle','connections','strands']);
  const sections=c.catalogSections();
  assert.equal(sections[0].title,'Pinned games');assert.equal(sections[1].title,'Keep your streak going');
  const ids=sections.flatMap(section=>section.games.map(game=>game.id));
  assert.equal(ids.length,44);assert.equal(new Set(ids).size,44);
});

test('category, alias search and pinned-only filters combine without leaking other games',()=>{
  const c=setup();c.state.pinnedGameIds=['globle','size-it-up','wordle'];
  save(c,'2026-11-11','maptap');
  assert.deepEqual(plain(c.catalogSections('', 'geography', true).flatMap(s=>s.games.map(g=>g.id))),['globle','size-it-up']);
  assert.deepEqual(plain(c.catalogSections('magnitudle','geography').flatMap(s=>s.games.map(g=>g.id))),['size-it-up']);
  assert.equal(c.catalogSections('wordle','geography').flatMap(s=>s.games).length,0);
  assert.deepEqual(plain(c.catalogSections('', 'geography').flatMap(s=>s.games.map(g=>g.id)).slice(0,3)),['globle','size-it-up','maptap']);
});

test('cached retirement flags cannot reactivate removed editions or delete historical records',()=>{
  const c=setup();
  c.LEGACY_GAME_ID_MAP={}; c.scoringForType=()=>({}); c.mergeCustomGames=games=>games;
  add(c,'mergeState');add(c,'remapDayEntries');
  const old=structuredClone(c.state),id='immaculate-baseball';
  old.games.find(g=>g.id===id).retired=false;old.activeGameId=id;old.pinnedGameIds=[id];
  old.entries={'2026-11-10':{[id]:{you:{score:'9/9 · rarity 75',result:'solved',note:'Preserve history'}}}};
  c.state=c.mergeState(c.state,old);
  assert.equal(c.state.games.find(g=>g.id===id).retired,true);
  assert.equal(c.state.activeGameId,'wordle');
  assert.equal(c.state.entries['2026-11-10'][id].you.note,'Preserve history');
  assert.ok(!c.visibleGames().some(g=>g.id===id));
  assert.ok(!c.catalogSections().flatMap(s=>s.games).some(g=>g.id===id));
});

test('a retired share preview disables saving while legacy history parsing remains available',()=>{
  const c=setup();let status='';
  const node=()=>({hidden:false,innerHTML:'',value:'',disabled:false,textContent:'',removeAttribute(){},setAttribute(){}});
  c.elements={shareTextInput:{...node(),value:'Immaculate Grid'},importPasteButton:node(),sharePreview:node(),importClearButton:node()};
  c.document={querySelector:()=>node()};
  c.parseShareText=()=>({parsed:{gameId:'immaculate-baseball'}});c.setImportStatus=message=>status=message;
  add(c,'previewImport');
  assert.equal(c.previewImport(true),null);assert.equal(c.elements.importPasteButton.disabled,true);
  assert.match(status,/no longer available/);
  // All new-entry selectors derive from the active catalog, including pasted-result examples.
  assert.match(app,/manualGameInput.innerHTML = visibleGames\(\)/);
  assert.match(app,/ADDITIONAL_IMPORT_GAMES.filter\(\(game\) => !game.manualOnly && !game.retired\)/);
});
