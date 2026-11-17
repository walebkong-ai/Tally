const {test}=require('node:test'),assert=require('node:assert/strict');
const {setup,add}=require('./helpers/import-review.cjs');const fixtures=require('./fixtures/shares/representative.json');
const share=id=>fixtures.find(f=>f.gameId===id).text;
function entry(c,id='wordle',day='2026-11-16'){return c.state.entries[day]?.[id]?.you;}
function confirm(c,item){c.handleImportReviewChange({target:{dataset:{importAction:'replace',importIndex:String(item.index)},checked:true}});}
function click(c,item,action){c.handleImportReviewClick({target:{closest:()=>({tagName:'BUTTON',dataset:{importAction:action,importIndex:String(item.index)}})}});}
function seed(c,id,score='4/6',day='2026-11-16'){
  c.getGameEntries(day,id).you={source:'manual',score,result:'solved',answer:'PRIVATE',note:'MY NOTE',reveal:false};
  c.saveState();c.writes=0;
}
test('one paste detects/preselects and saves through the existing durable namespace and sync queue',()=>{
  const c=setup('account-A');c.paste(share('wordle'));assert.equal(c.elements.importPasteButton.disabled,false);
  c.importShareText(share('wordle'));assert.equal(c.writes,1);assert.equal(entry(c).score,'3/6');assert.equal(c.persisted().entries['2026-11-16'].wordle.you.score,'3/6');
  assert.match(c.status,/Saved on this device/);assert.equal(c.elements.importPasteButton.disabled,true);
  c.paste(share('wordle').replace('1,234','1234').replaceAll('\n','\r\n  '));assert.match(c.status,/Already saved/);c.importShareText();assert.equal(c.writes,1);
  c.paste(share('poople'));assert.equal(c.state.activeGameId,'poople');
});
test('manual draft cannot be overwritten by detection or manual fallback',()=>{
  const c=setup();c.manualFormDirty=true;c.paste(share('poople'));assert.equal(c.state.activeGameId,'wordle');
  click(c,c.importQueue[0],'manual');assert.equal(c.scoreMethod,'paste');assert.match(c.status,/manual draft/);
});
test('replacement is opt-in, describes old/new values, preserves private fields and resets on new data',()=>{
  const c=setup();seed(c,'wordle');c.paste(share('wordle'));assert.equal(c.elements.importPasteButton.disabled,true);
  assert.match(c.elements.sharePreview.innerHTML,/4\/6 → 3\/6/);assert.match(c.elements.sharePreview.innerHTML,/Manual entry → official share/);
  c.importShareText();assert.equal(entry(c).score,'4/6');assert.equal(c.writes,0);
  confirm(c,c.importQueue[0]);assert.equal(c.elements.importPasteButton.disabled,false);
  c.importShareText();assert.equal(entry(c).score,'3/6');assert.equal(entry(c).answer,'PRIVATE');assert.equal(entry(c).note,'MY NOTE');assert.equal(entry(c).reveal,false);assert.equal(c.writes,1);
  c.paste('Wordle 1235 3/6');assert.equal(c.importQueue[0].confirmed,false);assert.equal(c.elements.importPasteButton.disabled,true);
  entry(c).note='';c.previewImport();confirm(c,c.importQueue[0]);c.importShareText();assert.equal(entry(c).note,'');
});
test('a cloud/refreshed result change invalidates prior replacement confirmation',()=>{
  const c=setup();seed(c,'wordle');c.paste(share('wordle'));confirm(c,c.importQueue[0]);
  entry(c).score='2/6';c.importShareText();assert.equal(entry(c).score,'2/6');assert.equal(c.writes,0);assert.equal(c.importQueue[0].confirmed,false);
});
test('commit guard rejects an entry changed since review and an authentication mismatch',()=>{
  const c=setup('account-A');seed(c,'wordle');c.paste(share('wordle'));confirm(c,c.importQueue[0]);
  entry(c).score='2/6';assert.throws(()=>c.saveReviewedImport(c.importQueue[0],'account-A'),/changed/);
  c.previewImport();confirm(c,c.importQueue[0]);c.cloudBackend.auth.currentUser.uid='account-B';
  assert.throws(()=>c.saveReviewedImport(c.importQueue[0],'account-A'),/active account changed/);assert.equal(entry(c).score,'2/6');assert.equal(c.writes,0);
});
test('account transition clears private review queue and cannot commit an old item',()=>{
  const c=setup('account-A');c.paste(share('contexto'));const old=c.importQueue[0];
  c.storageOwner='account-B';c.cloudBackend.auth.currentUser.uid='account-B';c.previewImport();
  assert.equal(c.importQueue.length,0);assert.equal(c.elements.shareTextInput.value,'');
  assert.throws(()=>c.saveReviewedImport(old,'account-A'),/account changed/);assert.equal(c.writes,0);
});
test('storage failure rolls back replacement and retains raw text, date and retry controls',()=>{
  const c=setup();seed(c,'wordle');c.paste(share('wordle'));confirm(c,c.importQueue[0]);
  const write=c.localStorage.setItem;c.localStorage.setItem=()=>{throw Error('quota')};c.importShareText();
  assert.equal(entry(c).score,'4/6');assert.equal(c.importQueue[0].saved,false);assert.match(c.importQueue[0].saveError,/still here/);assert.equal(c.elements.shareTextInput.value,share('wordle'));
  c.localStorage.setItem=write;click(c,c.importQueue[0],'retry');confirm(c,c.importQueue[0]);c.importShareText();assert.equal(entry(c).score,'3/6');assert.equal(c.writes,1);
});
test('batch save keeps successful, unrecognized and storage-failed cards; retry saves only the failed card',()=>{
  const c=setup();const text=share('wordle')+'\n\n'+share('connections')+'\n---\nunrecognized puzzle';c.paste(text);
  assert.equal(c.importQueue.length,3);assert.match(c.elements.importPasteButton.textContent,/Save 2/);
  const write=c.localStorage.setItem;c.localStorage.setItem=(...args)=>{if(c.writes===1)throw Error('quota');write(...args)};
  c.importShareText();assert.equal(entry(c).score,'3/6');assert.equal(entry(c,'connections'),undefined);assert.equal(c.writes,1);
  assert.equal(c.importQueue[0].saved,true);assert.ok(c.importQueue[1].saveError);assert.ok(c.importQueue[2].error);assert.equal(c.elements.shareTextInput.value,text);
  c.localStorage.setItem=write;click(c,c.importQueue[1],'retry');c.importShareText();assert.equal(c.writes,2);assert.equal(entry(c,'connections').score,'0 mistakes');assert.equal(c.importQueue[2].saved,false);
});
test('equivalent batch cards save once; conflicting results stay blocked until one is removed',()=>{
  const c=setup();c.paste(share('wordle')+'\n'+share('wordle'));c.importShareText();assert.equal(c.writes,1);
  const d=setup();d.paste('Wordle 1234 3/6\nWordle 1234 4/6');assert.equal(d.previewImport().length,0);
  click(d,d.importQueue[1],'remove');assert.equal(d.previewImport().length,1);d.importShareText();assert.equal(d.writes,1);
});
test('future, malformed, conflicting printed and duplicate puzzle dates cannot write',()=>{
  const c=setup();c.paste(share('contexto'));assert.equal(c.importQueue[0].date,'2026-11-03');
  c.handleImportReviewChange({target:{dataset:{importAction:'date',importIndex:'0'},value:'2026-11-04'}});assert.equal(c.previewImport().length,0);
  c.paste('Wordle 1234 3/6');c.importQueue[0].date='2026-11-17';c.importShareText();assert.equal(c.writes,0);
  c.importQueue[0].date='2026-11-16';c.importShareText();assert.equal(c.writes,1);
  c.paste('Wordle 1234 4/6');c.importQueue[0].date='2026-11-15';assert.equal(c.previewImport().length,0);assert.equal(c.importQueue[0].puzzleDate,'2026-11-16');
  click(c,c.importQueue[0],'use-date');assert.equal(c.importQueue[0].date,'2026-11-16');assert.equal(c.importQueue[0].confirmed,false);
});
test('same puzzle on different batch dates is blocked on both cards',()=>{
  const c=setup();c.paste('Wordle 1234 3/6\nWordle 1234 3/6');c.importQueue[1].date='2026-11-15';
  assert.equal(c.previewImport().length,0);assert.ok(c.importQueue.every(i=>/two dates/.test(i.reviewError)));
});
test('multi-card draft dates survive game navigation and local midnight rollover',()=>{
  const c=setup();c.paste(share('wordle')+'\n'+share('connections'));c.importQueue[1].date='2026-11-15';
  c.switchImportDraft('wordle','poople');c.state.activeGameId='poople';c.resetImportReview();c.paste(share('poople'));
  c.switchImportDraft('poople','wordle');c.state.activeGameId='wordle';c.resetImportReview();c.previewImport();
  assert.equal(c.importQueue[1].date,'2026-11-15');assert.equal(c.importQueue[0].date,'2026-11-16');
  add(c,'localDateKey');add(c,'refreshCurrentDate');c.document.querySelectorAll=()=>[];c.elements.manualDateInput.value='2026-11-16';
  c.refreshCurrentDate(new Date(2026,10,17,0,1));assert.equal(c.today,'2026-11-17');assert.equal(c.importQueue[0].date,'2026-11-16');assert.equal(c.importQueue[1].date,'2026-11-15');assert.equal(c.writes,0);
});
test('raw result HTML is escaped and invalid or unsupported cards cannot save',()=>{
  const c=setup();c.paste('<img src=x onerror=alert(1)>\n---\nI solved the Mini Crossword in 00:00!');assert.equal(c.previewImport().length,0);
  assert.ok(!c.elements.sharePreview.innerHTML.includes('<img'));assert.match(c.elements.sharePreview.innerHTML,/&lt;img/);c.importShareText();assert.equal(c.writes,0);
});
test('known bad-format parser fallback selects the right manual game without saving',()=>{
  const c=setup();c.paste('Costcodle Checkout #2 2/6');click(c,c.importQueue[0],'manual');
  assert.equal(c.state.activeGameId,'costcodle');assert.equal(c.scoreMethod,'manual');assert.equal(c.writes,0);
});

test('another tab editing the same account result is protected by the existing journal conflict guard',()=>{
  const c=setup('account-A');seed(c,'wordle');c.paste(share('wordle'));confirm(c,c.importQueue[0]);
  const other=structuredClone(c.state),base=c.safety.localRecords(other);other.entries['2026-11-16'].wordle.you.score='2/6';
  c.safety.writeLocal(c.localStorage,c.safety.storageKey('test','account-A'),'other-tab',base,other,other);
  c.importShareText();assert.equal(c.persisted().entries['2026-11-16'].wordle.you.score,'2/6');assert.equal(c.writes,0);
  assert.match(c.importQueue[0].saveError,/Another tab/);assert.equal(c.importQueue[0].text,share('wordle'));
});
test('a named manual-only game keeps its own fallback and partial date in the review',()=>{
  const c=setup();c.paste('Minecraftle 2026-11-16 10/10');assert.equal(c.previewImport().length,0);
  assert.match(c.status,/manual entry/);click(c,c.importQueue[0],'manual');assert.equal(c.state.activeGameId,'minecraftle');
});
test('saving a pasted score keeps an unsaved manual draft on its original game and date',()=>{
  const c=setup();c.manualFormDirty=true;c.manualFormKey='wordle:2026-11-14';c.elements.manualDateInput.value='2026-11-14';
  c.paste(share('poople'));c.importShareText();assert.equal(c.writes,1);assert.equal(entry(c,'poople').score,'2 moves');
  assert.equal(c.manualFormDirty,true);assert.equal(c.state.activeGameId,'wordle');assert.equal(c.elements.manualDateInput.value,'2026-11-14');assert.equal(c.manualFormKey,'wordle:2026-11-14');
});

test('invalid supported time shares retain the correct manual fallback',()=>{
  const c=setup();c.paste('I solved the Mini Crossword in 00:00!');assert.equal(c.previewImport().length,0);
  click(c,c.importQueue[0],'manual');assert.equal(c.state.activeGameId,'mini-crossword');assert.equal(c.writes,0);
});
test('older cached catalogs gain verified paste capability without rewriting saved scores',()=>{
  const c=setup();seed(c,'wordle');const old=structuredClone(c.state);
  for(const game of old.games)delete game.pasteSupported;
  c.LEGACY_GAME_ID_MAP={};c.scoringForType=()=>({});c.mergeCustomGames=games=>games;add(c,'mergeState');add(c,'remapDayEntries');
  const merged=c.mergeState(c.state,old);
  for(const id of ['contexto','costcodle','squirdle','poople','chainle'])assert.equal(merged.games.find(g=>g.id===id).pasteSupported,true);
  assert.equal(merged.entries['2026-11-16'].wordle.you.score,'4/6');
});
