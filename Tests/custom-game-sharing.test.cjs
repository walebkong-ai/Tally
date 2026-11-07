const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const app = fs.readFileSync(require('node:path').join(__dirname, '../dist/app.js'), 'utf8');
function setup() {
  const c = vm.createContext({ URL, SCORING_STYLES: {}, location: { href: 'https://solvry.example/?private=1#games' } });
  for (const name of ['scoringForType','customScoringForType','safeCustomGameUrl','validateCustomGame','sameCustomGame','mergeCustomGames','customGameShareLink','parseCustomGameLink']) {
    const tail = app.slice(app.indexOf(`function ${name}(`));
    const next = /\n(?:async )?function \w+\(/.exec(tail);
    vm.runInContext(tail.slice(0, next.index), c);
  }
  return c;
}
const game = {id:'custom-1234-abcd',name:'Émile’s daily puzzle',source:'custom',type:'points',officialUrl:'https://example.com/play'};
test('share links preserve identity and rules but omit scores, profile, and page queries', () => {
  const c=setup();
  const link=c.customGameShareLink({...game,score:999,account:{email:'secret@example.com'},sharing:'personal'});
  const url=new URL(link);
  assert.equal(url.search,'');
  assert.ok(!link.includes('secret') && !link.includes('999'));
  const joined=c.parseCustomGameLink(url.hash);
  assert.equal(joined.id,game.id);
  assert.equal(joined.name,game.name);
  assert.equal(joined.officialUrl,game.officialUrl);
  assert.equal(joined.sharing,'friends');
  assert.equal(joined.dailyRanked,false);
});
test('all six custom scoring rules survive sharing', () => {
  const c=setup();
  for(const type of ['points','strokes','time','guesses','mistakes','complete']) {
    const joined=c.parseCustomGameLink(new URL(c.customGameShareLink({...game,type})).hash);
    assert.equal(joined.type,type);
  }
});
test('unsafe URLs, unsupported versions, malformed and oversized invites are rejected', () => {
  const c=setup();
  for(const officialUrl of ['javascript:alert(1)','data:text/html,hello','https://user:password@example.com','file:///tmp/a']) {
    assert.equal(c.validateCustomGame({...game,officialUrl}),null);
  }
  for(const hash of ['#join-game=%zz','#join-game='+encodeURIComponent(JSON.stringify({v:2,game})),'#join-game='+ 'a'.repeat(6000)]) assert.throws(()=>c.parseCustomGameLink(hash));
  assert.throws(()=>c.customGameShareLink({...game,id:'wordle'}));
});
test('legacy games become personal; duplicate IDs and conflicting rules cannot overwrite saved games', () => {
  const c=setup();
  const legacy=c.validateCustomGame({...game,officialUrl:undefined});
  assert.equal(legacy.sharing,'personal');
  assert.equal(legacy.dailyRanked,false);
  const joined=c.mergeCustomGames([legacy],[{...game,type:'time'}]);
  assert.equal(joined.length,1);
  assert.equal(joined[0].type,'points');
  assert.equal(c.sameCustomGame(game,{...game,type:'time'}),false);
});

function addFunction(c, name) {
  const match=new RegExp(`(?:async )?function ${name}\\(`).exec(app);
  const tail=app.slice(match.index);
  const next=/\n(?:async )?function \w+\(/.exec(tail);
  vm.runInContext(tail.slice(0,next.index),c);
}
test('loading cloud state preserves personal game pins absent from shared data', async()=>{
  const c=setup();
  c.state={profile:{},friends:[],games:[{...game,sharing:'personal'}],pinnedGameIds:[game.id],entries:{}};
  c.cloudBackend={modules:{firestore:{doc:()=>({}),getDoc:async()=>({exists:()=>true,data:()=>({pinnedGameIds:['wordle']})})}}};
  c.mergeEntries=(local)=>local;
  addFunction(c,'loadCloudState');
  await c.loadCloudState('owner');
  assert.ok(c.state.pinnedGameIds.includes(game.id));
  assert.ok(c.state.pinnedGameIds.includes('wordle'));
});
test('friend refresh only accepts custom scores for matching games explicitly joined', async()=>{
  const c=setup();
  const shared={...game,sharing:'friends'};
  c.state={games:[shared]};
  const remote={customGames:[shared,{...game,id:'custom-unjoined',sharing:'friends'}],entries:{'2026-11-06':{[game.id]:{you:{score:'85'}},'custom-unjoined':{you:{score:'99'}},wordle:{you:{score:'3/6'}}}}};
  c.cloudBackend={modules:{firestore:{doc:()=>({}),getDoc:async()=>({exists:()=>true,data:()=>remote})}}};
  let imported;
  c.mergeFriendEntries=(_,data)=>{imported=data;};
  addFunction(c,'loadFriendEntries');
  await c.loadFriendEntries({uid:'friend',id:'friend'});
  assert.equal(imported['2026-11-06'][game.id].you.score,'85');
  assert.equal(imported['2026-11-06']['custom-unjoined'],undefined);
  assert.equal(c.state.games.length,1);
  shared.sharing='personal';
  await c.loadFriendEntries({uid:'friend',id:'friend'});
  assert.equal(imported['2026-11-06'][game.id],undefined);
});
