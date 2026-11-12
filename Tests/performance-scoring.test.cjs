const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const scoring=require('../Assets/game-scoring.mjs');
const app=fs.readFileSync(path.join(__dirname,'../dist/app.js'),'utf8');
function add(c,name) {
  const tail=app.slice(app.indexOf(`function ${name}(`));
  const next=/\n(?:async )?function \w+\(/.exec(tail);
  vm.runInContext(tail.slice(0,next?.index),c);
}
function setup() {
  const c=vm.createContext({today:'2026-11-11',gameScoring:scoring,structuredClone,SHOW_SOLVRY_GAMES:false});
  vm.runInContext(app.slice(app.indexOf('const ADDITIONAL_IMPORT_GAMES'),app.indexOf('let state = loadState()')),c);
  c.state=vm.runInContext('structuredClone(starterState)',c);c.state.entries={};c.state.selectedDate='2026-11-11';
  c.getPeople=()=>[{id:'you',name:'You'},{id:'a',name:'Alice'},{id:'b',name:'Bob'}];
  for(const name of ['normalizeManualScore','normalizeCatalogScore','normalizeCustomScore','scoreEntryForGame','parseGuessScore','parseTimeScore','parseNumberScore','parseRankScore','resultWeight','scoreTier','gameScoreDirection','compareScoreValues','compareScoreRows','placementScore','leaderboardDates','eligibleForDailyRanking','buildGameLeaderboard','buildOverallLeaderboard','visibleGames','gameSource','scoreStyleLabel']) add(c,name);
  c.SCORING_STYLES={};
  return c;
}
const game=(c,id)=>c.state.games.find(g=>g.id===id);
function normalized(c,id,raw,result='solved') {return c.normalizeManualScore(id,result,raw,'');}
function points(c,id,raw,result='solved') {const g=game(c,id),e=normalized(c,id,raw,result);assert.ok(!e.error,e.error);return scoring.performancePoints(g,e,c.scoreEntryForGame(e,g));}
function put(c,id,person,raw,result='solved',date='2026-11-11') {((c.state.entries[date]||={})[id]||={})[person]={...normalized(c,id,raw,result),source:'manual'};}

test('every active official game has a scoring profile, covering all 29 new editions',()=>{
  const c=setup(),games=c.visibleGames();assert.equal(games.length,43);assert.equal(games.filter(g=>g.manualOnly).length,29);
  for(const g of games) assert.ok(scoring.profile(g),g.id);
  assert.equal(scoring.profile({id:'wordle',source:'custom'}),null);
  assert.equal(scoring.profile({id:'wordle',retired:true}),null);
  assert.ok(!Object.keys(scoring.PERFORMANCE_RULES).some(id=>id.startsWith('immaculate')));
});

test('bounded guess formulas reward the minimum and maximum fairly and stay monotonic',()=>{
  const c=setup();
  for(const g of c.visibleGames().filter(g=>scoring.profile(g).method==='bounded-guesses')) {
    const p=scoring.profile(g);assert.equal(points(c,g.id,String(p.min)),100,g.id);assert.equal(points(c,g.id,String(p.max)),20,g.id);
    let previous=101;for(let n=p.min;n<=p.max;n++){const value=points(c,g.id,String(n));assert.ok(value<previous,g.id);previous=value;}
  }
  assert.equal(points(c,'spotle','4'),73);assert.equal(points(c,'quordle','7'),52);
  assert.ok(normalized(c,'flagle','7').error);assert.ok(normalized(c,'quordle','3').error);
});

test('open-ended guesses and moves use disclosed benchmarks without treating them as score caps',()=>{
  const c=setup();
  for(const g of c.visibleGames().filter(g=>scoring.profile(g).method==='guess-decay')) {
    const p=scoring.profile(g);assert.equal(points(c,g.id,'1'),100,g.id);assert.equal(points(c,g.id,String(p.scale+1)),50,g.id);
    assert.ok(points(c,g.id,'2')>points(c,g.id,'3'),g.id);assert.ok(!normalized(c,g.id,String(p.scale+100)).error,g.id);
  }
});

test('word ladders store moves while accepting historical guess-labeled results',()=>{
  const c=setup();for(const id of ['poople','feetle']) {
    const g=game(c,id);assert.equal(normalized(c,id,'5').score,'5 moves');
    assert.equal(c.scoreEntryForGame({score:'5 guesses',result:'solved'},g).value,5);
    assert.equal(c.scoreEntryForGame({score:'5 moves',result:'solved'},g).label,'5 moves');
  }
  assert.equal(c.scoreEntryForGame({score:'5 moves',result:'solved'},game(c,'contexto')).value,Infinity);
});

test('strikes, misses and signed par have explicit point schedules',()=>{
  const c=setup();for(const id of ['fine-print','clevergoat-categories']) {
    assert.deepEqual([0,1,2,3].map(n=>points(c,id,String(n))),[100,75,50,25]);
    assert.equal(normalized(c,id,'4').result,'missed');assert.equal(points(c,id,'4'),null);
  }
  assert.deepEqual([-4,-3,-2,-1,0,1,2,6,7].map(n=>points(c,'minute-cryptic',String(n))),[100,100,90,80,70,60,50,10,10]);
  assert.equal(c.scoreEntryForGame(normalized(c,'minute-cryptic','+2'),game(c,'minute-cryptic')).detail,'Lowest score vs par');
});

test('bounded point totals scale to 100 using their own units',()=>{
  const c=setup();for(const id of ['pricepoint','chainle','noillirk']) {
    const max=game(c,id).maxScore;assert.equal(points(c,id,'0'),0);assert.equal(points(c,id,String(max/2)),50);assert.equal(points(c,id,String(max)),100);
    assert.ok(normalized(c,id,String(max+1)).error,id);
  }
  assert.equal(points(c,'pricepoint','20000'),80);
});

test('open point totals disclose benchmarks, accept penalties, and cap derived points',()=>{
  const c=setup();assert.equal(points(c,'enclose-horse','-5','played'),0);assert.equal(points(c,'enclose-horse','100','played'),50);
  assert.equal(points(c,'maptap','500','played'),50);assert.equal(points(c,'maptap','1500','played'),75);
  assert.match(scoring.ruleDescription(game(c,'maptap')),/benchmark, not a publisher maximum/);
});

test('time scoring uses seconds consistently and rejects zero, malformed or partial times',()=>{
  const c=setup();assert.equal(points(c,'daily-crossword','15:00'),50);assert.equal(points(c,'daily-crossword','1:00:00'),20);
  assert.ok(points(c,'daily-crossword','5:00')>points(c,'daily-crossword','6:00'));
  for(const raw of ['00:00','0:00:00','12:99','1e2:00','12:00junk']) assert.ok(normalized(c,'daily-crossword',raw).error,raw);
  assert.equal(points(c,'daily-crossword','','played'),null);
});

test('completion-only puzzles award equal points without invented speed or hint rankings',()=>{
  const c=setup();for(const id of ['murdle','unwordle']) {
    assert.equal(points(c,id,''),100);assert.equal(points(c,id,'','played'),null);assert.equal(points(c,id,'','missed'),null);
    assert.equal(scoring.catalogScore(game(c,id),{score:'2 seconds',result:'solved'}).value,Infinity);
  }
});

test('new-game rank reading rejects numeric prefixes, wrong units, denominators and out-of-range records',()=>{
  const c=setup();
  for(const [id,score] of [['pricepoint','999999'],['pricepoint','25000/5'],['pricepoint','20000junk'],['maptap','1e6'],['enclose-horse','10.5'],['spotle','11 guesses'],['spotle','4 guesses junk'],['quordle','3 guesses'],['fine-print','4 mistakes'],['rngdle','25.5pts'],['minute-cryptic','-2 strokes']]) {
    assert.equal(c.scoreEntryForGame({score,result:'solved'},game(c,id)).value,Infinity,`${id}: ${score}`);
  }
});

test('every new game ranks valid scores honestly and rejects missed or unfinished solves',()=>{
  const c=setup();for(const g of c.visibleGames().filter(g=>g.manualOnly)) {
    const f=scoring.field(g),raw=g.type==='time'?'12:03':g.type==='complete'?'':String(Math.max(f.min,3));
    const e=normalized(c,g.id,raw),parsed=c.scoreEntryForGame(e,g);
    assert.ok(Number.isFinite(parsed.value),g.id);
    const n=scoring.performancePoints(g,e,parsed);
    assert.ok(g.id==='rngdle'?n===null:Number.isInteger(n)&&n>=0&&n<=100,g.id);
    assert.equal(points(c,g.id,'','missed'),null,g.id);
    if(['guesses','time','complete','mistakes','strokes'].includes(g.type)) assert.equal(points(c,g.id,'','played'),null,g.id);
  }
});

test('placement and performance leaderboards offer separate totals and identical raw-score ties',()=>{
  const c=setup();c.state.games=[game(c,'spotle')];put(c,'spotle','you','2');put(c,'spotle','a','2');put(c,'spotle','b','6');
  const placement=c.buildOverallLeaderboard(1,'placement'),performance=c.buildOverallLeaderboard(1,'performance');
  assert.equal(placement.find(r=>r.id==='you').solvryPoints,10);assert.equal(placement.find(r=>r.id==='b').solvryPoints,5);
  assert.equal(performance.find(r=>r.id==='you').solvryPoints,91);assert.equal(performance.find(r=>r.id==='a').rank,1);assert.equal(performance.find(r=>r.id==='b').solvryPoints,56);
  assert.equal(performance.find(r=>r.id==='b').rank,3);
});

test('performance is independent of opponents, rounds per game, sums seven days and leaves records unchanged',()=>{
  const c=setup();c.state.games=[game(c,'spotle')];put(c,'spotle','you','4');put(c,'spotle','you','10','solved','2026-11-10');
  const before=JSON.stringify(c.state);assert.equal(c.buildOverallLeaderboard(7,'performance').find(r=>r.id==='you').solvryPoints,93);
  assert.equal(JSON.stringify(c.state),before);
  put(c,'spotle','a','1');assert.equal(c.buildOverallLeaderboard(7,'performance').find(r=>r.id==='you').solvryPoints,93);
  assert.equal(c.buildOverallLeaderboard(1,'placement').find(r=>r.id==='you').solvryPoints,7);
});

test('a valid zero-point result ranks ahead of unplayed accounts without assigning them a rank',()=>{
  const c=setup();c.state.games=[game(c,'enclose-horse')];put(c,'enclose-horse','b','-5','played');
  const rows=c.buildOverallLeaderboard(1,'performance');assert.equal(rows[0].id,'b');assert.equal(rows[0].rank,1);assert.equal(rows[0].solvryPoints,0);
  assert.ok(rows.slice(1).every(r=>r.rank===null));
});

test('RNGdle retains its EP board and stays outside both combined scoring modes',()=>{
  const c=setup();c.state.games=[game(c,'rngdle')];put(c,'rngdle','you','25.5','played');
  assert.equal(c.buildGameLeaderboard(c.state.games[0]).find(r=>r.id==='you').rank,1);
  for(const mode of ['placement','performance']) assert.equal(c.buildOverallLeaderboard(7,mode).find(r=>r.id==='you').rank,null);
});

test('current score metadata wins over stale cached builtin limits without rewriting old results',()=>{
  const c=setup();c.LEGACY_GAME_ID_MAP={};c.scoringForType=()=>({});c.mergeCustomGames=games=>games;add(c,'mergeState');add(c,'remapDayEntries');
  const base=structuredClone(c.state),saved=structuredClone(c.state),old=game({state:saved},'flagle');old.maxScore=1000000;old.type='points';old.manualOnly=false;
  saved.entries={'2026-11-10':{flagle:{you:{score:'3 guesses',result:'solved'}}}};
  const merged=c.mergeState(base,saved),flag=game({state:merged},'flagle');assert.equal(flag.maxScore,6);assert.equal(flag.type,'guesses');assert.equal(flag.manualOnly,true);
  assert.equal(merged.entries['2026-11-10'].flagle.you.score,'3 guesses');
});

test('Color challenge entries remain outside both totals while matching dated daily shares qualify',()=>{
  const c=setup();c.state.games=[game(c,'color')];c.parseShareText=()=>({parsed:null});
  c.state.entries={'2026-11-11':{color:{you:{score:'25/50',result:'played',source:'manual'}}}};
  for(const mode of ['placement','performance']) assert.equal(c.buildOverallLeaderboard(1,mode).find(r=>r.id==='you').rank,null);
  Object.assign(c.state.entries['2026-11-11'].color.you,{source:'official-share',dailyDate:'2026-11-11'});
  assert.equal(c.buildOverallLeaderboard(1,'placement').find(r=>r.id==='you').solvryPoints,10);
  assert.equal(c.buildOverallLeaderboard(1,'performance').find(r=>r.id==='you').solvryPoints,50);
});

test('malformed new-game stored results cannot earn points under either mode',()=>{
  const c=setup();c.state.games=[game(c,'pricepoint')];
  c.state.entries={'2026-11-11':{pricepoint:{you:{score:'25000/1',result:'solved',source:'manual'}}}};
  for(const mode of ['placement','performance']) assert.equal(c.buildOverallLeaderboard(1,mode).find(r=>r.id==='you').rank,null);
});

test('the public scoring guide covers exactly the active catalog, with no duplicate or retired game rows',()=>{
  const c=setup();const html=fs.readFileSync(path.join(__dirname,'../Assets/scoring-rules.html'),'utf8');
  const ids=[...html.matchAll(/<tr data-game="([^"]+)"/g)].map(m=>m[1]);
  assert.equal(ids.length,43);assert.equal(new Set(ids).size,43);
  assert.deepEqual(ids.sort(),Array.from(c.visibleGames(),g=>g.id).sort());
});
