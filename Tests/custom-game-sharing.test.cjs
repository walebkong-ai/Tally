const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const safety = require('../Assets/sync-safety.mjs');
const app = fs.readFileSync(require('node:path').join(__dirname, '../dist/app.js'), 'utf8');
function setup() {
  const c = vm.createContext({ URL, safety, structuredClone, storageOwner: 'owner', SCORING_STYLES: {}, location: { href: 'https://solvry.example/?private=1#games' } });
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
test('loading secure records preserves personal device pins and applies account pins', async()=>{
  const c=setup();
  c.state={profile:{name:'You',handle:'@solvry'},friends:[],games:[{id:'wordle',source:'official'}, {...game,sharing:'personal'}],pinnedGameIds:[game.id],entries:{},cloudBase:{},syncConflicts:[]};
  c.starterState={games:[{id:'wordle',source:'official'}]};
  c.showAppNotice=()=>{};
  c.parseShareText=()=>({});
  c.cloudBackend={generation:0,auth:{currentUser:{uid:'owner'}},modules:{firestore:{doc:()=>({}),collection:()=>({}),getDocFromServer:async()=>({exists:()=>true,data:()=>({accountDataVersion:2})}),getDocsFromServer:async()=>({docs:[{id:'pin_wordle',data:()=>({schemaVersion:2,revision:1,kind:'pin',gameId:'wordle',value:true,deleted:false})}]})}}};
  for(const name of ['cloudSession','currentCloudSession','accountRecords','loadCloudState'])addFunction(c,name);
  await c.loadCloudState('owner');
  assert.ok(c.state.pinnedGameIds.includes(game.id));
  assert.ok(c.state.pinnedGameIds.includes('wordle'));
});
test('friend refresh reads only shared result records for explicitly joined games', async()=>{
  const c=setup();
  const shared={...game,sharing:'friends'};
  c.state={games:[shared],friends:[{id:'friend',uid:'friend',status:'accepted'}]};
  const queries=[];
  c.cloudBackend={generation:0,auth:{currentUser:{uid:'owner'}},modules:{firestore:{collection:(_, ...path)=>path,query:path=>path,where:()=>({}),getDocs:async(path)=>{queries.push(path);return {docs:[{id:'2026-11-06',data:()=>({schemaVersion:2,ownerUid:'friend',gameId:game.id,date:'2026-11-06',score:'85',result:'played',source:'manual',reveal:false,answer:'must not copy',shareText:'must not copy'})}]};}}}};
  c.visibleGames=()=>c.state.games;
  c.visibleFriends=()=>c.state.friends;
  let imported;
  c.mergeFriendEntries=(_,data)=>{imported=data;};
  for(const name of ['cloudSession','currentCloudSession','loadFriendEntries'])addFunction(c,name);
  await c.loadFriendEntries({uid:'friend',id:'friend'});
  assert.equal(imported['2026-11-06'][game.id].you.score,'85');
  assert.equal(imported['2026-11-06'][game.id].you.answer,undefined);
  assert.equal(imported['2026-11-06'][game.id].you.shareText,undefined);
  assert.equal(queries[0][0],'sharedScores');
  assert.equal(c.state.games.length,1);
  shared.sharing='personal';
  c.visibleGames=()=>c.state.games.filter(g=>g.sharing==='friends');
  await c.loadFriendEntries({uid:'friend',id:'friend'});
  assert.equal(imported['2026-11-06'],undefined);
});

test('a previously shared personal score keeps its newer device edit on account reload',async()=>{
 const c=setup(),personal={...game,sharing:'personal'};
 const old={schemaVersion:2,revision:1,kind:'result',gameId:game.id,date:'2026-11-06',deleted:false,value:safety.privateEntry({score:'5',result:'played',source:'manual'})};
 c.state={profile:{name:'You',handle:'@solvry'},friends:[],games:[personal],pinnedGameIds:[],entries:{'2026-11-06':{[game.id]:{you:{...old.value,score:'8'}}}},cloudBase:{['result_2026-11-06_'+game.id]:old},syncConflicts:[]};
 c.starterState={games:[]};c.showAppNotice=()=>{};c.parseShareText=()=>({});
 c.cloudBackend={generation:0,auth:{currentUser:{uid:'owner'}},modules:{firestore:{doc:()=>({}),collection:()=>({}),getDocFromServer:async()=>({exists:()=>true,data:()=>({accountDataVersion:2})}),getDocsFromServer:async()=>({docs:[{id:'result_2026-11-06_'+game.id,data:()=>old}]})}}};
 for(const name of ['cloudSession','currentCloudSession','accountRecords','loadCloudState'])addFunction(c,name);
 await c.loadCloudState('owner');assert.equal(c.state.entries['2026-11-06'][game.id].you.score,'8');
});
