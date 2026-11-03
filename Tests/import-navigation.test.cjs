const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const app = fs.readFileSync(path.join(__dirname, '../dist/app.js'), 'utf8');
function setup() {
  const c = vm.createContext({
    state: {selectedDate:'2026-11-03',entries:{}},
    elements: {shareTextInput:{value:''},importDate:{value:'2026-11-03'}},
    importDrafts:new Map(), importDraftRevision:0
  });
  vm.runInContext(app.slice(app.indexOf('function parseShareText('), app.indexOf('function renderSharePreview(')), c);
  for (const name of ['switchImportDraft','sameImportedScore','importDateError','localDateKey','loadState']) {
    const tail = app.slice(app.indexOf(`function ${name}(`));
    const next = /\n(?:async )?function \w+\(/.exec(tail);
    // localDateKey is followed by constants; retain just its function.
    vm.runInContext(name==='localDateKey' ? tail.slice(0,tail.indexOf('\n}')+2) : tail.slice(0,next.index),c);
  }
  return c;
}
const color = 'Color Daily — Nov 3\n38.69/50 🟨🟨🟧🟧🟨\nCan you beat it?\nhttps://dialed.gg/color?d=1&s=38.69&v=b';
test('switching games clears a saved Color result without changing its saved entry',()=>{
  const c=setup();
  c.elements.shareTextInput.value=color;
  c.state.entries['2026-11-03']={color:{you:{source:'official-share',result:'played',score:'38.69/50',shareText:color}}};
  c.switchImportDraft('color','size-it-up');
  assert.equal(c.elements.shareTextInput.value,'');
  c.switchImportDraft('size-it-up','color');
  assert.equal(c.elements.shareTextInput.value,'');
  assert.equal(c.state.entries['2026-11-03'].color.you.score,'38.69/50');
  assert.equal(c.importDraftRevision,2);
});
test('switching via any game selection preserves separate unsaved text and dates',()=>{
  const c=setup();
  c.elements.shareTextInput.value=color;
  c.switchImportDraft('color','size-it-up');
  assert.equal(c.elements.shareTextInput.value,'');
  c.elements.shareTextInput.value='incomplete Size It Up result';
  c.elements.importDate.value='2026-11-02';
  c.switchImportDraft('size-it-up','color');
  assert.equal(c.elements.shareTextInput.value,color);
  assert.equal(c.elements.importDate.value,'2026-11-03');
  c.switchImportDraft('color','size-it-up');
  assert.equal(c.elements.shareTextInput.value,'incomplete Size It Up result');
  assert.equal(c.elements.importDate.value,'2026-11-02');
});
test('a dated Color Daily paste cannot be silently saved under an unrelated date',()=>{
  const c=setup();const parsed=c.parseShareText(color).parsed;
  assert.match(c.importDateError(parsed,'2026-09-30'),/Change Played on/);
  assert.equal(c.importDateError(parsed,'2026-11-03'),'');
  const withYear=c.parseShareText(color.replace('Nov 3','Nov 3, 2025')).parsed;
  assert.ok(c.importDateError(withYear,'2026-11-03'));
  assert.equal(c.importDateError(withYear,'2025-11-03'),'');
});
test('new visits start today while retained historical entries remain intact',()=>{
  const c=setup();const previous={selectedDate:'2026-09-30',entries:{'2026-09-30':{color:{you:{score:'38.69/50'}}}}};
  Object.assign(c,{today:'2026-11-03',STORAGE_KEY:'state',LEGACY_STORAGE_KEY:'legacy',starterState:{},structuredClone,mergeState:(_,saved)=>saved,localStorage:{getItem:()=>JSON.stringify(previous),setItem:()=>{}}});
  const loaded=c.loadState();
  assert.equal(loaded.selectedDate,'2026-11-03');
  assert.equal(loaded.entries['2026-09-30'].color.you.score,'38.69/50');
});
test('today uses local calendar parts, including after UTC midnight',()=>{
  const c=setup();
  assert.equal(c.localDateKey({getFullYear:()=>2026,getMonth:()=>10,getDate:()=>3}),'2026-11-03');
});
