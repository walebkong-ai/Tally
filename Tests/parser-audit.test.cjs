const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const app = fs.readFileSync(require('node:path').join(__dirname, '../dist/app.js'), 'utf8');
function context() {
  const c = vm.createContext({});
  vm.runInContext(app.slice(app.indexOf('function parseShareText('), app.indexOf('function renderSharePreview(')), c);
  return c;
}
function add(c, name) {
  const tail = app.slice(app.indexOf(`function ${name}(`));
  const next = /\n(?:async )?function \w+\(/.exec(tail);
  vm.runInContext(tail.slice(0, next?.index), c);
}

test('QA-02 rejects multiple Wordle headers and contradictory or damaged grids', () => {
  const c = context();
  for (const text of [
    'Wordle 123 2/6\nWordle 124 5/6',
    'Wordle 123 1/6\n⬛⬛⬛⬛⬛',
    'Wordle 123 2/6\n🟩🟩🟩🟩🟩\n🟩🟩🟩🟩🟩',
    'Wordle 123 2/6\n⬛⬛⬛⬛\n🟩🟩🟩🟩🟩',
    'Wordle 123 2/6\n⬛⬛⬛⬛⬛\n🟩🟩🟩🟩🟩🟩',
    'Wordle 123 X/6\n⬛⬛⬛⬛⬛',
    'Wordle 123 1/6 extra result 2/6'
  ]) {
    const result = c.parseShareText(text);
    assert.equal(result.parsed, null, text);
    assert.ok(result.error, text);
  }
});

test('Wordle keeps explicit header-only support, six-row misses and accessible grids', () => {
  const c = context();
  for (const score of ['1','2','3','4','5','6','X']) assert.equal(c.parseShareText(`Wordle 1,234 ${score}/6*`).parsed.score, `${score}/6`);
  assert.equal(c.parseShareText('Wordle 123 X/6\n'+Array(6).fill('⬛⬛⬛⬛⬛').join('\n')).parsed.result, 'missed');
  assert.equal(c.parseShareText('Wordle 123 2/6\n⬛🟦⬛⬛⬛\n🟧🟧🟧🟧🟧').parsed.result, 'solved');
});

test('QA-03 rejects malformed Connections rows without dropping mistakes', () => {
  const c = context(), solved = '🟨🟨🟨🟨\n🟩🟩🟩🟩\n🟦🟦🟦🟦\n🟪🟪🟪🟪';
  for (const row of ['🟨🟩🟦','🟨🟩🟦🟪🟨','🟨🟩🟦x','🟥🟥🟥🟥']) {
    const result = c.parseShareText(`Connections\n${row}\n${solved}`);
    assert.equal(result.parsed, null, row);
    assert.ok(result.error);
  }
  assert.equal(c.parseShareText(`Connections: Sports Edition\n🟡🟢🔵\n${solved}`).parsed, null);
  assert.equal(c.parseShareText('Connections\n'+Array(4).fill('🟨🟩🟦🟪').join('\n')+'\n🟨🟨🟨🟨').parsed, null);
});

test('QA-04 never infers a full Strands solve from the spangram alone or an unknown word total', () => {
  const c = context();
  for (const recap of ['🟡','🔵🟡','💡🔵🔵🟡🔵🔵🔵🔵']) {
    const result = c.parseShareText('Strands #123\n'+recap);
    assert.equal(result.parsed.result, 'played');
    assert.match(result.parsed.note, /completion.*unverified/i);
  }
  for (const recap of ['🟡🟡','🔵🟡x']) assert.equal(c.parseShareText('Strands #123\n'+recap).parsed, null);
});

test('QA-05 partial puzzles do not increase completion totals, while scored rounds do', () => {
  const c = context();
  add(c, 'isCompletedResult'); add(c, 'calculateTotalSolves'); add(c, 'scoreTier');
  const games = [{id:'wordle',type:'guesses'},{id:'connections',type:'mistakes'},{id:'strands',type:'mistakes'},{id:'krillion',type:'depth'}];
  c.visibleGames = () => games;
  c.state = { entries: { '2026-11-10': {
    wordle:{you:{result:'solved'}},connections:{you:{result:'played'}},strands:{you:{result:'played'}},krillion:{you:{result:'played'}}
  } } };
  assert.equal(c.calculateTotalSolves(), 2);
  assert.equal(c.isCompletedResult('played', games[1]), false);
  assert.equal(c.scoreTier({hasEntry:true,score:{value:0},entry:{result:'played'}},games[2]), 0);
});
