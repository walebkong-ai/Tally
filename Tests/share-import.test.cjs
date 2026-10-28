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
vm.runInContext(app.slice(app.indexOf('function normalizeManualScore('), app.indexOf('function saveManualScore(')), context);

test('custom game scoring supports every offered scoring style', () => {
  for (const [type, raw, expected] of [
    ['points', '103.5', '103.5'], ['strokes', '-2.5', '-2.5'],
    ['time', '1:02:30', '1:02:30'], ['time', '0:54', '00:54'],
    ['guesses', '12', '12 guesses'], ['mistakes', '0', '0 mistakes'],
    ['complete', '', 'Complete']
  ]) assert.equal(context.normalizeCustomScore(type, 'solved', raw).score, expected);
  assert.equal(context.normalizeCustomScore('complete', 'missed', '').score, 'Missed');
});

test('custom game scoring rejects malformed values', () => {
  for (const [type, raw] of [['time','1:99'], ['points',''], ['points','Infinity'],
    ['guesses','3.2'], ['guesses','0'], ['mistakes','-1'], ['points','1000000001']]) {
    assert.ok(context.normalizeCustomScore(type, 'solved', raw).error);
  }
});

test('custom game definitions survive merges without replacing built-in games', () => {
  context.scoringForType = () => ({});
  vm.runInContext(app.slice(app.indexOf('function customScoringForType('), app.indexOf('function defaultScoreLabel(')), context);
  const base = [{ id: 'wordle', name: 'Wordle', source: 'official' }];
  const custom = { id: 'custom-my-puzzle-points', name: 'My Puzzle', source: 'custom', type: 'points' };
  const merged = context.mergeCustomGames(base, [custom, custom, { ...custom, id: 'wordle' }, { ...custom, id: 'custom-invalid', type: 'unknown' }]);
  assert.equal(merged.length, 2);
  assert.equal(merged[0].source, 'official');
  assert.equal(merged[1].name, 'My Puzzle');
  assert.equal(merged[1].scoring.label, 'Highest score');
});

test('manual scores normalize to existing leaderboard formats', () => {
  const fixtures = [
    ['wordle', 'solved', '3', '', '3/6'],
    ['wordle', 'missed', '', '', 'X/6'],
    ['connections', 'solved', '2', '', '2 mistakes'],
    ['strands', 'solved', '0', '', 'No hints'],
    ['mini-crossword', 'solved', '0:54', '', '00:54'],
    ['spelling-bee', 'played', '', 'Good Start', 'Good Start'],
    ['krillion', 'played', '110', '', '110']
  ];
  for (const [game, result, value, rank, expected] of fixtures) {
    assert.equal(context.normalizeManualScore(game, result, value, rank).score, expected);
  }
  assert.equal(context.normalizeManualScore('connections', 'solved', '4', '').result, 'missed');
  assert.equal(context.normalizeManualScore('spelling-bee', 'played', '', 'Queen Bee').result, 'solved');
});

test('manual validation rejects missing, malformed, and out-of-range scores', () => {
  for (const [game, value, rank] of [
    ['wordle', '7', ''], ['wordle', '0', ''], ['wordle', '3.5', ''],
    ['connections', '-1', ''], ['connections', '5', ''], ['krillion', '', ''],
    ['mini-crossword', '0:99', ''], ['mini-crossword', 'abc', ''],
    ['spelling-bee', '', 'Champion'], ['solvry-holes', '20', '']
  ]) assert.ok(context.normalizeManualScore(game, 'solved', value, rank).error);
});

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
