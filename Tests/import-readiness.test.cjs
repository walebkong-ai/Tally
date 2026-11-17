const {test}=require('node:test');
const assert=require('node:assert/strict');
const vm=require('node:vm');
const {setup,add,app}=require('./helpers/import-review.cjs');
const imports=require('../Assets/importers.mjs');
const management=require('../Assets/account-management.mjs');
const fixtures=require('./fixtures/shares/representative.json');
const share=id=>fixtures.find(f=>f.gameId===id).text;
function asyncFunction(c,name){const start=app.indexOf(`async function ${name}(`),tail=app.slice(start),end=/\n(?:async )?function \w+\(/.exec(tail);vm.runInContext(tail.slice(0,end?.index),c);}
function moveContext(text='Wordle 1234 3/6') {
  const c=setup(),from='2026-11-14',to='2026-11-15';
  const parsed=imports.parseShareText(text).parsed,gameId=parsed.gameId;
  const entry={score:parsed.score,result:parsed.result,source:'official-share',shareText:text,note:'Keep private',answer:'',reveal:false};
  c.getGameEntries(from,gameId).you=entry;c.saveState();c.writes=0;
  const nodes={'#scoreManagementStatus':{textContent:''},'#confirmScoreManagement':{disabled:false},'#scoreMoveDate':{value:to},'#scoreManagementDialog':{close(){}}};
  c.document.querySelector=id=>nodes[id]||{textContent:''};
  c.scoreManagement={owner:'',action:'move',gameId,fromDate:from,entry:structuredClone(entry)};
  Object.assign(c,{management,localDateKey:()=>c.today,cloudSession:()=>({uid:''}),showAppNotice:message=>{c.notice=message},navigator:{onLine:true}});
  asyncFunction(c,'submitScoreManagement');return {c,nodes,from,to};
}
test('generated score-date controller moves an undated official share without import-card variables',async()=>{
  const {c,nodes,from,to}=moveContext();await c.submitScoreManagement({preventDefault(){}});
  assert.equal(nodes['#scoreManagementStatus'].textContent,'');assert.equal(c.state.entries[to]?.wordle.you.score,'3/6');
  assert.equal(c.state.entries[from].wordle.you,undefined);assert.equal(c.persisted().entries[to].wordle.you.note,'Keep private');
});
test('generated score-date controller preserves a printed date and rejects an occupied destination',async()=>{
  const {c,nodes,from,to}=moveContext('Color Daily — Nov 14, 2026\n38/50\nhttps://dialed.gg/color?d=1');
  await c.submitScoreManagement({preventDefault(){}});assert.match(nodes['#scoreManagementStatus'].textContent,/dated/);assert.ok(c.state.entries[from].color.you);assert.equal(c.state.entries[to]?.color.you,undefined);
  const d=moveContext();d.c.getGameEntries(d.to,'wordle').you={score:'5/6',result:'solved'};
  await d.c.submitScoreManagement({preventDefault(){}});assert.equal(d.c.state.entries[d.to].wordle.you.score,'5/6');assert.equal(d.c.state.entries[d.from].wordle.you.score,'3/6');
});
test('reload during a partial batch recovers the durable first score and retry does not create another copy',()=>{
  const c=setup('reload-account'),text=share('wordle')+'\n'+share('connections');c.paste(text);
  const write=c.localStorage.setItem;
  c.localStorage.setItem=(key,value)=>{if(c.writes===1)throw Error('quota');if(key.includes(':draft:'))write(key,value)};
  c.importShareText();assert.equal(c.importQueue[0].saved,true);assert.ok(c.importQueue[1].saveError);
  // Simulate restart with the base cache still old: the first card survives in its journal.
  c.state=c.persisted();c.storageBaseline=c.safety.localRecords(c.state);c.importQueue=[];c.importQueueText=null;
  c.localStorage.setItem=write;c.paste(text);assert.equal(c.importQueue[0].duplicate,true);c.importShareText();
  assert.equal(c.writes,2);const saved=c.persisted();assert.equal(saved.entries['2026-11-16'].wordle.you.score,'3/6');assert.equal(saved.entries['2026-11-16'].connections.you.score,'0 mistakes');
  assert.equal(Object.keys(c.safety.localRecords(saved)).filter(id=>id.includes('result_2026-11-16_wordle')).length,1);
});
for (const fixture of fixtures) test(`release matrix: ${fixture.gameId} detection, equivalent duplicate, mixed ambiguity and malformed outcome`,()=>{
  const p=imports.parseShareText(fixture.text).parsed;assert.equal(p.gameId,fixture.gameId);
  const old={source:'official-share',score:p.score,result:p.result,shareText:fixture.text};
  assert.equal(imports.sameResult(old,imports.parseShareText(fixture.text.replaceAll('\n','\r\n  ')).parsed,p.date||'2026-11-03'),true);
  assert.ok(imports.parseShareText(fixture.text+'\n'+(fixture.gameId==='wordle'?share('connections'):share('wordle'))).error);
  const malformed={wordle:'Wordle 123 0/6',connections:'Connections\n🟩🟩🟩','connections-sports':'Connections: Sports Edition\n🟢🟢🟢',strands:'Strands #123\n🟡🟡','mini-crossword':'Mini Crossword time: 00:00','spelling-bee':'Spelling Bee\nChampion','krillion':'Krillion #77\n10000','daily-tens':'DailyTens #1\n🏆🏆',centumth:'Centumth\nTotal: 491/490',globle:'Globle\n🟩 = 0',flagcognito:'Flagcognito\n3001/3000','size-it-up':'Magnitudle — Size It Up\nScore: 501/500',color:'51/50\nhttps://dialed.gg/color','buzzfeed-trivia':'I got 6 out of 5 on BuzzFeed Daily Trivia',contexto:share('contexto').replace('11/03/2026','02/30/2026'),costcodle:'Costcodle Classic #2 7/6',squirdle:'Squirdle Daily 1 - 10/9',poople:'Poople #1 0/0',chainle:'Chainle #1 · 5,001 🔗\n🟩🟩🟩🟩🟩'}[fixture.gameId];
  const invalid=imports.parseShareText(malformed);assert.equal(invalid.parsed,null,malformed);assert.ok(invalid.error);
});
test('legacy scalar shares reject negative, fractional and competing scores instead of extracting a substring',()=>{
  for(const text of ['Mini Crossword time: -0:54','Mini Crossword time: 0:54\nTime: 1:12','Krillion #77\nDepth: 1.5','Krillion #77\n110\n120','Spelling Bee\nBeginner\nQueen Bee'])assert.ok(imports.parseShareText(text).error,text);
});
test('a second save cannot replace the only durable journal while the cache remains unavailable',()=>{
  const c=setup('journal-only');const write=c.localStorage.setItem;
  c.localStorage.setItem=(key,value)=>{if(!key.includes(':draft:'))throw Error('cache quota');write(key,value)};
  c.paste(share('wordle')+'\n'+share('connections'));c.importShareText();
  assert.equal(c.importQueue[0].saved,true);assert.ok(c.importQueue[1].saveError);assert.equal(c.writes,1);
  assert.equal(c.persisted().entries['2026-11-16'].wordle.you.score,'3/6');
  c.localStorage.setItem=write;c.handleImportReviewClick({target:{closest:()=>({tagName:'BUTTON',dataset:{importAction:'retry',importIndex:'1'}})}});c.importShareText();
  assert.equal(c.persisted().entries['2026-11-16'].wordle.you.score,'3/6');assert.equal(c.persisted().entries['2026-11-16'].connections.you.score,'0 mistakes');
});
test('legacy header variants retain Connections puzzle identity for duplicate protection',()=>{
  for(const game of ['connections','connections-sports']){
    const standard=share(game),name=game==='connections'?'Connections':'Connections: Sports Edition';
    const variant=standard.replace(name+'\nPuzzle #123',name+' #123');
    const p=imports.parseShareText(variant).parsed;assert.equal(p.puzzleId,'123');
    assert.equal(imports.sameResult({source:'official-share',score:p.score,result:p.result,shareText:variant},imports.parseShareText(variant.replace('#123','#124')).parsed,'2026-11-16'),false);
  }
});
test('oversized but internally consistent recaps cannot become permanently unsyncable scores',()=>{
  const share='Poople #100 100/1\n'+Array(100).fill('⬜🟫🟫🟫').join('\n')+'\n🟫🟫🟫🟫';
  assert.match(imports.parseShareText(share).error,/100 rows/);
  assert.ok(imports.parseShareText('Krillion #77\nDepth: 1,000 points').error);
});
test('clipboard denial or an absent API retains direct paste and does not erase an existing draft',async()=>{
  for(const clipboard of [undefined,{readText:async()=>{throw Object.assign(Error('Denied'),{name:'NotAllowedError'})}}]){
    const c=setup();let click,focused=false;c.navigator={clipboard};
    c.elements.shareTextInput.focus=()=>{focused=true};c.elements.importClipboardButton={disabled:false,addEventListener:(_,handler)=>{click=handler}};
    const start=app.indexOf('elements.importClipboardButton.addEventListener("click"');vm.runInContext(app.slice(start,app.indexOf('elements.shareTextInput.addEventListener',start)),c);
    c.elements.shareTextInput.value='unfinished draft';await click();
    assert.equal(c.elements.shareTextInput.value,'unfinished draft');assert.match(c.status,/Paste directly/);assert.equal(focused,true);assert.equal(c.elements.importClipboardButton.disabled,false);
    c.paste('Wordle 4321 3/6');assert.equal(c.elements.importPasteButton.disabled,false);c.importShareText();assert.equal(c.persisted().entries['2026-11-16'].wordle.you.score,'3/6');
  }
});
