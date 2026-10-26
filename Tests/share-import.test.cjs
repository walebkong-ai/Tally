const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

// Exercise the shipped parser after building the Swift site.
const app = fs.readFileSync(path.join(__dirname, '../dist/app.js'), 'utf8');
const parserSource = app.slice(app.indexOf('function parseShareText('), app.indexOf('function renderSharePreview('));
const context = vm.createContext({});
vm.runInContext(parserSource, context);
const parse = (text) => context.parseShareText(text);

const fixtures = [
  ['Wordle 1,234 3/6*\n⬛🟨⬛⬛⬛\n🟩🟩🟨⬛⬛\n🟩🟩🟩🟩🟩', 'wordle', '3/6', 'solved'],
  ['Wordle 1,234 X/6', 'wordle', 'X/6', 'missed'],
  ['Connections\nPuzzle #123\n🟨🟨🟨🟨\n🟩🟩🟩🟩\n🟦🟦🟦🟦\n🟪🟪🟪🟪', 'connections', '0 mistakes', 'solved'],
  ['Connections\nPuzzle #124\n🟨🟩🟦🟪\n🟩🟨🟦🟪\n🟦🟨🟩🟪\n🟪🟨🟩🟦', 'connections', '4 mistakes', 'missed'],
  ['Connections\n🟨🟨🟨🟨\n🟨🟩🟦🟪', 'connections', '1 mistake', 'played'],
  ['Strands #123\n💡🔵🔵🟡🔵🔵🔵🔵', 'strands', '1 hint', 'solved'],
  ['I solved the Mini Crossword in 0:54!', 'mini-crossword', '00:54', 'solved'],
  ['Spelling Bee\nGood Start · 10 points', 'spelling-bee', 'Good Start · 10 pts', 'played'],
  ['Spelling Bee\nQueen Bee', 'spelling-bee', 'Queen Bee', 'solved'],
  ['Krillion #77\n110\n🫧🫧', 'krillion', '110', 'played']
];

for (const [text, gameId, score, result] of fixtures) {
  test(`${gameId}: ${score} / ${result}`, () => {
    const output = parse(text);
    assert.ok(output.parsed, output.error);
    assert.equal(output.parsed.gameId, gameId);
    assert.equal(output.parsed.score, score);
    assert.equal(output.parsed.result, result);
  });
}

for (const text of ['', 'hello', 'Wordle', 'Connections #123', 'Strands #123', 'The Mini 0:99', 'Spelling Bee', 'Krillion #77']) {
  test(`actionable error for ${JSON.stringify(text)}`, () => {
    const output = parse(text);
    assert.equal(output.parsed, null);
    assert.ok(output.error.length > 10);
  });
}

test('does not silently import one game from a mixed paste', () => {
  const output = parse('Wordle 1,234 4/6\nKrillion #77\n110');
  assert.equal(output.parsed, null);
  assert.match(output.error, /one result at a time/);
});

test('tolerates Windows line endings and emoji variation selectors', () => {
  assert.equal(parse('Connections\r\n🟨️ 🟨️ 🟨️ 🟨️\r\n🟩🟩🟩🟩\r\n🟦🟦🟦🟦\r\n🟪🟪🟪🟪').parsed.score, '0 mistakes');
});
