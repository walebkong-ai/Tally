const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

// Exercise the shipped parser after building the Swift site.
const app = fs.readFileSync(path.join(__dirname, '../dist/app.js'), 'utf8');
const parserSource = app.slice(app.indexOf('function parseShareText('), app.indexOf('function renderSharePreview('));
const context = vm.createContext({});
vm.runInContext(app.slice(app.indexOf("const ADDITIONAL_IMPORT_GAMES"), app.indexOf("const starterState")), context);
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

const newFixtures = [
  ['Connections: Sports Edition\nPuzzle #999\n🟨🟨🟨🟨\n🟩🟩🟩🟩\n🟦🟦🟦🟦\n🟪🟪🟪🟪', 'connections-sports', '0 mistakes'],
  ['DailyTens #999\n🏆 🏆\n🏆 ❌\n🏆 🏆\n❌ 🏆\n🏆 🏆', 'daily-tens', '8/10'],
  ['Centumth Nov 3, 2026 - Cities\nTotal: 490/490 🏆', 'centumth', '490/490'],
  ['🌎 Nov 3, 2026 🌍\n🔥 14 | Avg. Guesses: 3.2\n🟨🟥🟩 = 12\nhttps://globle-game.com\n#globle', 'globle', '12 guesses'],
  ['Flagcognito · Nov 3, 2026\n🇲🇲 Myanmar: 2 taps\n2,400 / 3,000\nhttps://guessdash.com/flagcognito', 'flagcognito', '2400/3000'],
  ['Magnitudle — Size It Up\nNov 3, 2026\nScore: 425/500\n🟥🟥🟥🟥⬜ 80\nhttps://magnitudle.com/size-it-up', 'size-it-up', '425/500'],
  ['39.12/50. I remember colors better than names.\nhttps://dialed.gg/color?c=abc', 'color', '39.12/50'],
  ['I got 4 out of 5 on today’s Daily Trivia. Can you beat my score? https://www.buzzfeed.com/daily-trivia', 'buzzfeed-trivia', '4/5'],
  ...[['⚾', 'baseball'], ['🏈', 'football'], ['🏀 (Men’s)', 'basketball-men'], ['🏀 (Women’s)', 'basketball-women'], ['🏒', 'hockey']].map(([sport,id]) => [`${sport} Immaculate Grid 123 9/9:\nRarity: 75\n🟩🟩🟩\n🟩🟩🟩\n🟩🟩🟩`, `immaculate-${id}`, '9/9 · rarity 75'])
];
for (const [text, id, score] of newFixtures) test(`new shared format ${id}`, () => {
  const output = parse(text);
  assert.ok(output.parsed, output.error);
  assert.equal(output.parsed.gameId, id);
  assert.equal(output.parsed.score, score);
});

test('zero is a real score in bounded points games', () => {
  for (const text of ['Centumth\nTotal: 0/490', 'Flagcognito\n0 / 3,000', 'Magnitudle — Size It Up\nScore: 0/500', '0/50\nhttps://dialed.gg/color', 'I got 0 out of 5 on BuzzFeed Daily Trivia']) {
    assert.ok(parse(text).parsed, text);
    assert.match(parse(text).parsed.score, /^0\//);
    assert.equal(parse(text).parsed.result, 'played');
  }
});

test('new imports reject incomplete, unsupported, ambiguous and out-of-range results', () => {
  for (const text of [
    'DailyTens #999\n🏆🏆', 'Centumth Nov 3, 2026', 'Centumth\nTotal: 491/490',
    'Globle\n🔥 14 | Avg. Guesses: 3.2\n-- = --', 'Globle Capitals\n🟩 = 2',
    'Flagcognito\n1,000 / 1,000', 'Flagcognito\n4,000 / 3,000',
    'Magnitudle — Size It Up\nPractice\nScore: 425/500', 'Magnitudle — Size It Up\nScore: 501/500',
    'https://dialed.gg/color?c=abc', '51/50\nhttps://dialed.gg/color',
    'I got 6 out of 5 on BuzzFeed Daily Trivia',
    'Immaculate Grid 123 9/9\nRarity: 75', '⚾ Immaculate Grid 123 9/9\nRarity: 75%',
    '⚾ Immaculate Grid 123 8/9\nRarity: 75\n🟩🟩🟩\n🟩🟩🟩\n🟩🟩🟩',
    '⚾ Immaculate Grid 123 9/9\nRarity: 901',
    'Connections\nConnections: Sports Edition\n🟨🟨🟨🟨',
    'Centumth\nTotal: 300/490\nFlagcognito\n2400/3000',
    'Wordle 123 4/6\nCentumth\nTotal: 300/490'
  ]) { const output = parse(text); assert.equal(output.parsed, null, text); assert.ok(output.error, text); }
});

test('manual new scores use the same storage and bounds as imports', () => {
  for (const [id, raw, rarity, score] of [
    ['connections-sports','2','','2 mistakes'], ['daily-tens','8','','8/10'],
    ['centumth','350','','350/490'], ['globle','12','','12 guesses'],
    ['flagcognito','2400','','2400/3000'], ['size-it-up','425','','425/500'],
    ['color','39.12','','39.12/50'], ['buzzfeed-trivia','4','','4/5'],
    ['immaculate-baseball','9','75','9/9 · rarity 75']
  ]) assert.equal(context.normalizeManualScore(id, 'solved', raw, '', rarity).score, score);
  for (const [id,raw,rarity] of [['color','50.01',''], ['daily-tens','11',''], ['globle','0',''], ['immaculate-baseball','9',''], ['immaculate-baseball','10','75'], ['immaculate-baseball','9','-1']]) assert.ok(context.normalizeManualScore(id, 'solved', raw, '', rarity).error);
});


test('decimal or signed malformed totals cannot be truncated into a valid score', () => {
  for (const text of ['-1/50\nhttps://dialed.gg/color', '1.234/50\nhttps://dialed.gg/color', '40/50.5\nhttps://dialed.gg/color', 'Centumth\nTotal: 350/490.5']) assert.ok(parse(text).error, text);
});

test('Sports Edition circle grids remain separate from regular Connections', () => {
  const output = parse('Connections: Sports Edition\n🟡🟡🟡🟡\n🟢🟢🟢🟢\n🔵🔵🔵🔵\n🟣🟣🟣🟣');
  assert.equal(output.parsed?.gameId, 'connections-sports');
  assert.equal(output.parsed?.score, '0 mistakes');
});
