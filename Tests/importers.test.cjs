const {test}=require('node:test');const assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process');const path=require('node:path');
const imports=require('../Assets/importers.mjs');const scoring=require('../Assets/game-scoring.mjs');
const fixtures=require('./fixtures/shares/representative.json');
const byId=id=>fixtures.find(f=>f.gameId===id).text;
const parsed=text=>{const out=imports.parseShareText(text);assert.ok(out.parsed,out.error);return out.parsed};
for(const {gameId,text}of fixtures)test(`independent module parses representative ${gameId} share`,()=>{
  assert.equal(parsed(text).gameId,gameId);
  assert.equal(parsed(' \n'+text.replaceAll('\n','\r\n  ')+'\n ').gameId,gameId);
});
test('paste support matches the active catalog without changing strict scoring profiles',()=>{
  const c=require('./helpers/import-review.cjs').setup();
  const games=c.state.games.filter(g=>!g.retired&&g.source!=='solvry');
  const supported=games.filter(g=>!g.manualOnly||g.pasteSupported).map(g=>g.id).sort();
  assert.deepEqual(Array.from(supported),[...imports.SUPPORTED_GAME_IDS].sort());assert.equal(games.length,43);assert.equal(supported.length,19);
  for(const id of ['contexto','costcodle','squirdle','poople','chainle']){
    const game=games.find(g=>g.id===id),p=parsed(byId(id));
    assert.equal(scoring.isRankable(game,p,scoring.catalogScore(game,p)),true,id);
  }
});
test('Contexto printed US date, failed attempts and hinted solves have explicit eligibility',()=>{
  const p=parsed(byId('contexto'));assert.equal(p.date,'2026-11-03');assert.equal(p.score,'17 guesses');
  assert.equal(parsed(byId('contexto').replace('and got it','but I gave up')).result,'missed');
  for(const text of [byId('contexto').replace('guesses.','guesses and 2 hints.'),byId('contexto').replace('11/03/2026','02/30/2026'),byId('contexto').replace('17 guesses','0 guesses'),byId('contexto').replace('17 guesses','1 guesses'),byId('contexto').replace('🟩🟩 4','4'),byId('contexto').split('\n')[0],byId('contexto').replace('🟩🟩 4','🟨🟨 4'),byId('contexto').replace('11/03/2026','unlimited')])assert.ok(imports.parseShareText(text).error,text);
});
test('Costcodle Classic publisher calendar uses its offset and rejects other editions or bad grids',()=>{
  assert.equal(parsed(byId('costcodle')).date,'2023-09-21');
  assert.equal(parsed('Costcodle Classic #3 X/6').date,'2023-09-22');
  assert.equal(parsed('Costcodle Classic #3 X/6').result,'missed');
  assert.equal(parsed(byId('costcodle').replace('⬆🟨','⬆️🟨')).score,'2 guesses');
  for(const text of ['Costcodle Checkout #3 2/6','Costcodle Classic #3 0/6','Costcodle Classic #3 7/6','Costcodle Classic #3 2/6\n✅','Costcodle Classic #3 X/6\n✅'])assert.ok(imports.parseShareText(text).error,text);
});
test('Squirdle accepts normal daily wins/losses and names, and rejects Stats or incomplete rows',()=>{
  const loss='Squirdle Daily 100 - X/9\n'+Array(9).fill('🟦❌❌🔼🔽').join('\n');assert.equal(parsed(loss).result,'missed');
  assert.equal(parsed(byId('squirdle').replace('🟦❌❌🔼🔽','🟦❌❌🔼🔽Mr. Mime')).score,'2 guesses');
  for(const text of [byId('squirdle').replace('2/9','2/12'),byId('squirdle').replace('Daily','Free Play'),byId('squirdle').replace('🟦❌❌🔼🔽','🟦❌❌🔼🔽✅'),byId('squirdle').replace('2/9','3/9'),loss.replace('X/9','9/9')])assert.ok(imports.parseShareText(text).error,text);
});
test('Poople numerator is moves and denominator is optimal path, including the starting row',()=>{
  const p=parsed(byId('poople'));assert.equal(p.score,'2 moves');assert.equal(p.optimalMoves,2);assert.equal(p.grid.length,3);
  for(const text of [byId('poople').replace('2/2','1/2'),byId('poople').replace('2/2','0/0'),byId('poople').replace('⬜🟫⬜🟫\n',''),byId('poople').replace('🟫🟫🟫🟫','⬜🟫🟫🟫')])assert.ok(imports.parseShareText(text).error,text);
});
test('Chainle validates five rounds and total against publisher color bands',()=>{
  assert.equal(parsed(byId('chainle')).score,'4200');assert.equal(parsed('Chainle #1 · 0 🔗\n🟥🟥🟥🟥🟥\nhttps://chainle.io').score,'0');
  for(const text of [byId('chainle').replace('#100','Unlimited'),byId('chainle').replace('4,200','5,001'),byId('chainle').replace('4,200','0'),byId('chainle').replace('🟩🟩🟨🟩🟨','🟩🟩🟩🟩')])assert.ok(imports.parseShareText(text).error,text);
});
test('semantic duplicates ignore presentation but distinguish puzzle, result, score, date and edition',()=>{
  const p=parsed(byId('wordle'));const e={source:'official-share',score:p.score,result:p.result,shareText:byId('wordle')};
  assert.equal(imports.sameResult(e,parsed(byId('wordle').replace('1,234','1234').replaceAll('\n','\r\n  ')),'2026-11-03'),true);
  for(const other of [{...p,score:'4/6'},{...p,result:'missed'},{...p,puzzleId:'1235'},{...p,gameId:'poople'}])assert.equal(imports.sameResult(e,other,'2026-11-03'),false);
  assert.equal(imports.sameResult({...e,source:'manual'},p,'2026-11-03'),false);
  const mini=parsed(byId('mini-crossword'));assert.equal(imports.sameResult({source:'official-share',score:'0:54',result:mini.result},mini,'2026-11-03'),true);
  const daily=parsed('Color Daily — Nov 3\n39.12/50\nhttps://dialed.gg/color?d=1');
  const challenge=parsed(byId('color'));assert.equal(imports.sameResult({source:'official-share',score:challenge.score,result:challenge.result,shareText:byId('color')},daily,'2026-11-03'),false);
});
test('known puzzle cannot silently appear on another day, but manual history is not inferred',()=>{
  const p=parsed(byId('wordle'));const entries={'2026-11-03':{wordle:{you:{source:'official-share',score:p.score,result:p.result,shareText:byId('wordle')}}}};
  assert.equal(imports.existingPuzzleDate(entries,p,'2026-11-04'),'2026-11-03');assert.equal(imports.existingPuzzleDate(entries,p,'2026-11-03'),'');
  entries['2026-11-03'].wordle.you.source='manual';assert.equal(imports.existingPuzzleDate(entries,p,'2026-11-04'),'');
});
test('historical dates, future protection, yearless daily shares and prose dates stay unambiguous',()=>{
  assert.equal(imports.dateError({},'2024-02-29','2026-11-03'),'');
  for(const date of ['2026-02-29','2026-13-01','2026-11-31','11/03/2026',''])assert.ok(imports.dateError({},date,'2026-11-03'));
  assert.match(imports.dateError({},'2026-11-04','2026-11-03'),/Future/);
  assert.equal(parsed('Wordle 1234 3/6').date,undefined);
  assert.equal(parsed(byId('color')+'\nSent Nov 3, 2026').date,undefined);
  assert.equal(parsed(byId('globle')+'\nSent Nov 4, 2026').date,'2026-11-03');
  const daily=parsed('Color Daily — Nov 3\n38/50\nhttps://dialed.gg/color?d=1');assert.equal(daily.date,undefined);
  assert.equal(imports.dateError(daily,'2025-11-03','2026-11-03'),'');assert.ok(imports.dateError(daily,'2026-10-03','2026-11-03'));
});
test('publisher calendar and literal dates are stable across DST and opposite time zones',()=>{
  for(const tz of ['America/Toronto','Pacific/Honolulu','Pacific/Kiritimati']){
    const result=spawnSync(process.execPath,['--input-type=module','-e',`import {parseShareText} from ${JSON.stringify('file://'+path.resolve('Assets/importers.mjs'))};console.log(JSON.stringify([parseShareText('Costcodle Classic #2 1/6').parsed.date,parseShareText(${JSON.stringify(byId('contexto'))}).parsed.date]));`],{env:{...process.env,TZ:tz},encoding:'utf8'});
    assert.equal(result.status,0,result.stderr);assert.deepEqual(JSON.parse(result.stdout),['2023-09-21','2026-11-03']);
  }
});
test('batch splitting retains unsupported/error cards, separates all fixtures and obeys bounds',()=>{
  const items=imports.splitResults([byId('wordle'),byId('connections'),byId('strands')].join('\n\n'));
  assert.deepEqual(items.map(i=>i.parsed.gameId),['wordle','connections','strands']);
  assert.equal(imports.splitResults(fixtures.map(f=>f.text).join('\n---\n')).length,1); // over ten, no truncated saves
  assert.ok(imports.splitResults('x'.repeat(12001))[0].error);
  for(let start=0;start<fixtures.length;start+=8) {
    const group=fixtures.slice(start,start+8);assert.deepEqual(imports.splitResults(group.map(f=>f.text).join('\n\n')).map(item=>item.parsed?.gameId),group.map(f=>f.gameId));
  }
  const mixed=imports.splitResults('unknown result\n---\n'+byId('wordle')+'\n---\nMinecraftle 2026-11-03 10/10');
  assert.equal(mixed.length,3);assert.ok(mixed[0].error);assert.ok(mixed[2].error);assert.equal(mixed[1].parsed.gameId,'wordle');
  assert.ok(imports.parseShareText(byId('wordle')+'\n'+byId('connections')).error);
});
