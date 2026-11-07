const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const app = fs.readFileSync(path.join(__dirname, '../dist/app.js'), 'utf8');

function setup() {
  const context = vm.createContext({
    structuredClone, SHOW_SOLVRY_GAMES: false,
    state: {
      profile: { id: 'you', name: 'You', handle: '@you' },
      friends: [{ id: 'a', name: 'Alice', handle: '@alice', status: 'local' }, { id: 'b', name: 'Bob', handle: '@bob', status: 'local' }],
      account: {}, friendRequests: { incoming: [], outgoing: [] },
      selectedDate: '2026-11-02', entries: {}, games: [{ id: 'wordle', type: 'guesses' }], pinnedGameIds: []
    },
    cloudBackend: { ready: false },
    scoreStyleLabel: () => 'Score', defaultScoreLabel: (result) => result,
    saveState: () => {}
  });
  const names = ['visibleGames', 'gameSource', 'getActiveGame', 'normalizeHandle', 'addOrUpdateFriend', 'cloudFriendsAvailable', 'isDemoFriend', 'visibleFriends', 'getPeople',
    'eligibleForDailyRanking', 'importDateError', 'placementScore', 'gameScoreDirection', 'resultWeight', 'leaderboardDates', 'buildOverallLeaderboard', 'buildGameLeaderboard',
    'scoreTier', 'compareScoreValues', 'compareScoreRows', 'scoreEntryForGame', 'parseGuessScore', 'parseTimeScore', 'parseNumberScore', 'parseRankScore',
    'friendRequestStatus', 'sendCloudFriendRequest', 'updateFriendRequest', 'applyAcceptedRequests', 'mergeFriendEntries', 'serializeCloudState'];
  for (const name of names) {
    const match = new RegExp(`(?:async )?function ${name}\\(`).exec(app);
    assert.ok(match, name);
    const tail = app.slice(match.index);
    const next = /\n(?:async )?function \w+\(/.exec(tail);
    vm.runInContext(tail.slice(0, next ? next.index : undefined), context);
  }
  vm.runInContext(app.slice(app.indexOf("function parseShareText("), app.indexOf("function renderSharePreview(")), context);
  return context;
}
const entry = (score, result = 'solved', source = 'import') => ({ score, result, source });
const plain = (value) => JSON.parse(JSON.stringify(value));

test('ties share places and combined points regardless of names', () => {
  const c = setup();
  c.state.entries['2026-11-02'] = { wordle: { you: entry('3/6', 'solved', 'manual'), a: entry('3/6'), b: entry('4/6') } };
  const rows = c.buildGameLeaderboard(c.state.games[0]);
  assert.deepEqual(plain(rows.map(({ id, rank }) => [id, rank])), [['a', 1], ['you', 1], ['b', 3]]);
  const overall = c.buildOverallLeaderboard();
  assert.equal(overall.find((row) => row.id === 'you').solvryPoints, 10);
  assert.match(overall.find((row) => row.id === 'you').detail, /Manual/);
  assert.equal(overall.find((row) => row.id === 'a').rank, 1);
  assert.equal(overall.find((row) => row.id === 'b').solvryPoints, 5);
});

test('failed, invalid, and unplayed results receive no rank or combined points', () => {
  const c = setup();
  c.state.games = [{ id: 'connections', type: 'mistakes' }];
  c.state.entries['2026-11-02'] = { connections: { you: entry('0 mistakes', 'missed'), a: entry('2 mistakes'), b: entry('bad') } };
  assert.equal(c.buildGameLeaderboard(c.state.games[0])[0].id, 'a');
  assert.equal(c.buildOverallLeaderboard().find((row) => row.id === 'you').rank, null);
  assert.equal(c.buildOverallLeaderboard().find((row) => row.id === 'b').solvryPoints, 0);
  c.state.entries = {};
  assert.ok(c.buildGameLeaderboard(c.state.games[0]).every((row) => row.rank === null));
});

test('complete puzzles rank above partial results; depth and points use highest score', () => {
  const c = setup();
  c.state.entries['2026-11-02'] = { connections: { you: entry('0 mistakes', 'played'), a: entry('3 mistakes') }, krillion: { you: entry('110', 'played'), a: entry('90') } };
  assert.equal(c.buildGameLeaderboard({ id: 'connections', type: 'mistakes' })[0].id, 'a');
  assert.equal(c.buildGameLeaderboard({ id: 'krillion', type: 'depth' })[0].id, 'you');
});

test('time, rank, and negative custom scores use their game-specific ordering', () => {
  const c = setup();
  c.state.entries['2026-11-02'] = { mini: { you: entry('1:99'), a: entry('01:10'), b: entry('00:59') }, bee: { you: entry('Good Start', 'played'), a: entry('Queen Bee') }, custom: { you: entry('-2.5'), a: entry('1') } };
  assert.equal(c.buildGameLeaderboard({ id: 'mini', type: 'time' })[0].id, 'b');
  assert.equal(c.buildGameLeaderboard({ id: 'mini', type: 'time' }).find((row) => row.id === 'you').rank, null);
  assert.equal(c.buildGameLeaderboard({ id: 'bee', type: 'rank' })[0].id, 'a');
  assert.equal(c.buildGameLeaderboard({ id: 'custom', type: 'strokes' })[0].id, 'you');
});

test('seven-day totals include exactly the selected day and six preceding dates', () => {
  const c = setup();
  for (const date of ['2026-10-26', '2026-10-27', '2026-11-01', '2026-11-02', '2026-11-03']) c.state.entries[date] = { wordle: { you: entry('2/6') } };
  assert.equal(c.buildOverallLeaderboard(7).find((row) => row.id === 'you').solvryPoints, 30);
  assert.equal(c.buildOverallLeaderboard(1).find((row) => row.id === 'you').solvryPoints, 10);
  assert.equal(c.state.selectedDate, '2026-11-02');
});

test('legacy sample friends are hidden by default and toggled without erasing scores', () => {
  const c = setup();
  c.state.friends.push({ id: 'mira', name: 'Mira', handle: '@mirasolves' });
  c.state.entries['2026-11-02'] = { wordle: { mira: entry('1/6'), you: entry('2/6') } };
  assert.equal(c.buildOverallLeaderboard()[0].id, 'you');
  c.state.showDemoFriends = true;
  assert.equal(c.buildOverallLeaderboard()[0].id, 'mira');
  c.state.showDemoFriends = false;
  assert.equal(c.state.entries['2026-11-02'].wordle.mira.score, '1/6');
});

test('adding two local friends does not merge them through undefined UID', () => {
  const c = setup();
  c.addOrUpdateFriend({ id: 'c', name: 'Casey', handle: '@casey' });
  c.addOrUpdateFriend({ id: 'd', name: 'Drew', handle: '@drew' });
  assert.equal(c.state.friends.length, 4);
  assert.equal(c.state.friends[0].name, 'Alice');
  c.addOrUpdateFriend({ id: 'c', name: 'Casey Updated', handle: '@casey' });
  assert.equal(c.state.friends.length, 4);
});

test('cached connected friends are excluded when signed out or owned by another account', () => {
  const c = setup();
  c.state.friends.push({ id: 'remote', uid: 'remote', status: 'accepted', ownerUid: 'owner' });
  assert.equal(c.visibleFriends().length, 2);
  c.cloudBackend.ready = true;
  c.cloudBackend.auth = { currentUser: { uid: 'owner' } };
  c.state.account.uid = 'owner';
  assert.equal(c.visibleFriends().length, 3);
  c.state.friends[2].ownerUid = 'different';
  assert.equal(c.visibleFriends().length, 2);
});

test('request actions enforce direction, participant, status, and allowed action', () => {
  const c = setup();
  const request = { fromUid: 'sender', toUid: 'receiver', status: 'pending' };
  assert.equal(c.friendRequestStatus('accept', request, 'receiver'), 'accepted');
  assert.equal(c.friendRequestStatus('reject', request, 'receiver'), 'rejected');
  assert.equal(c.friendRequestStatus('cancel', request, 'sender'), 'cancelled');
  for (const [action, uid] of [['accept', 'sender'], ['cancel', 'receiver'], ['reject', 'stranger'], ['garbage', 'receiver']]) assert.throws(() => c.friendRequestStatus(action, request, uid));
  assert.throws(() => c.friendRequestStatus('accept', { ...request, status: 'accepted' }, 'receiver'));
  assert.equal(c.friendRequestStatus('remove', { ...request, status: 'accepted' }, 'sender'), 'removed');
});

function mockCloud(c, initial) {
  let record = initial;
  let writes = 0;
  c.state.account.uid = 'owner';
  c.cloudBackend.ready = true;
  c.cloudBackend.auth = { currentUser: { uid: 'owner' } };
  c.cloudBackend.modules = { firestore: {
    collection: () => ({}), doc: () => ({}), query: () => ({}), where: () => ({}),
    getDocs: async () => ({ docs: [{ id: 'friend', data: () => ({ profile: { name: 'Friend', handle: '@friend' } }) }] }),
    runTransaction: async (_, action) => action({
      get: async () => ({ exists: () => !!record, data: () => record }),
      set: (_, value) => { record = value; writes++; },
      update: (_, value) => { record = { ...record, ...value }; writes++; }
    })
  } };
  return { record: () => record, writes: () => writes };
}

test('sending never overwrites an existing pending or accepted connection', async () => {
  for (const status of ['pending', 'accepted']) {
    const c = setup();
    const db = mockCloud(c, { status });
    await assert.rejects(c.sendCloudFriendRequest('', '@friend'), /pending|connected/);
    assert.equal(db.writes(), 0);
  }
});

test('send, accept, and remove update friend membership without touching score history', async () => {
  const c = setup();
  const db = mockCloud(c, null);
  await c.sendCloudFriendRequest('', '@friend');
  assert.equal(db.record().status, 'pending');
  await assert.rejects(c.updateFriendRequest('accept', 'request'), /isn't yours/);
  c.state.account.uid = 'friend';
  c.cloudBackend.auth.currentUser.uid = 'friend';
  await c.updateFriendRequest('accept', 'request');
  assert.equal(c.state.friends.find((friend) => friend.uid === 'owner').status, 'accepted');
  c.state.entries['2026-11-02'] = { wordle: { owner: entry('3/6') } };
  await c.updateFriendRequest('remove', 'request');
  assert.ok(!c.state.friends.some((friend) => friend.uid === 'owner'));
  assert.equal(c.state.entries['2026-11-02'].wordle.owner.score, '3/6');
});

test('refresh removes a deleted remote score but keeps other people’s scores', () => {
  const c = setup();
  c.state.entries['2026-11-02'] = { wordle: { you: entry('3/6'), a: entry('2/6') } };
  c.mergeFriendEntries('a', {});
  assert.equal(c.state.entries['2026-11-02'].wordle.a, undefined);
  assert.equal(c.state.entries['2026-11-02'].wordle.you.score, '3/6');
});

test('cloud payload excludes cached friend scores and sample people', () => {
  const c = setup();
  c.state.friends.push({ id: 'mira', handle: '@mirasolves' });
  c.state.entries['2026-11-02'] = { wordle: { you: entry('3/6'), a: entry('2/6') } };
  const payload = c.serializeCloudState();
  assert.deepEqual(Object.keys(payload.entries['2026-11-02'].wordle), ['you']);
  assert.ok(!payload.friends.some((friend) => friend.id === 'mira'));
});

test('hidden Solvry games preserve saved state but do not appear or award daily points', () => {
  const c = setup();
  c.state.games.push({ id: 'solvry-holes', source: 'solvry', type: 'strokes' }, { id: 'color', source: 'official', type: 'points', dailyRanked: false });
  c.state.activeGameId = 'solvry-holes';
  c.state.solvryPlays = { savedRound: { strokes: 35 } };
  c.state.entries['2026-11-02'] = { 'solvry-holes': { you: entry('35') }, color: { you: entry('49/50') } };
  assert.equal(c.getActiveGame().id, 'wordle');
  assert.equal(c.visibleGames().length, 2);
  assert.equal(c.buildOverallLeaderboard().find((row) => row.id === 'you').solvryPoints, 0);
  assert.equal(c.state.entries['2026-11-02']['solvry-holes'].you.score, '35');
  assert.equal(c.state.solvryPlays.savedRound.strokes, 35);
});

test('Immaculate ranks correct answers first, then lower rarity, with sport isolation', () => {
  const c = setup();
  const game = { id: 'immaculate-baseball', type: 'grid' };
  c.state.entries['2026-11-02'] = { 'immaculate-baseball': { you: entry('9/9 · rarity 150'), a: entry('8/9 · rarity 100'), b: entry('9/9 · rarity 75') }, 'immaculate-football': { a: entry('9/9 · rarity 0') } };
  assert.deepEqual(plain(c.buildGameLeaderboard(game).map((row) => row.id)), ['b', 'you', 'a']);
  c.state.entries['2026-11-02']['immaculate-baseball'].you.score = '9/9 · rarity 75';
  assert.equal(c.buildGameLeaderboard(game).find((row) => row.id === 'you').rank, 1);
});


test('Color Daily ranks independently of higher challenge scores and rejects wrong dates', () => {
  const c = setup();
  c.state.games = [{id:'color', type:'points', dailyRanked:false}];
  const daily = 'Color Daily — Nov 2\n38.69/50 🟨🟨🟧🟧🟨\nCan you beat it?\nhttps://dialed.gg/color?d=1&s=38.69&v=b';
  c.state.entries['2026-11-02'] = {color:{
    you:{...entry('38.69/50','played','official-share'),shareText:daily},
    a:{...entry('49/50','played','official-share'),shareText:'49/50.\nhttps://dialed.gg/color?c=abc'},
    b:{...entry('40/50','played','official-share'),shareText:daily.replace('38.69','40').replace('Nov 2','Nov 1')}
  }};
  const rows = c.buildOverallLeaderboard();
  assert.equal(rows.find(r=>r.id==='you').solvryPoints,10);
  assert.equal(rows.find(r=>r.id==='a').solvryPoints,0);
  assert.equal(rows.find(r=>r.id==='b').solvryPoints,0);
});

test('personal custom games and their scores never enter friend-readable cloud payloads', () => {
  const c=setup();
  c.state.games.push({id:'custom-private',source:'custom',type:'points',sharing:'personal'}, {id:'custom-shared',source:'custom',type:'points',sharing:'friends'});
  c.state.pinnedGameIds=['custom-private','custom-shared','wordle'];
  c.state.entries['2026-11-02']={wordle:{you:entry('2/6')},'custom-private':{you:entry('999')},'custom-shared':{you:entry('45')}};
  const payload=c.serializeCloudState();
  assert.equal(payload.entries['2026-11-02']['custom-private'],undefined);
  assert.equal(payload.entries['2026-11-02']['custom-shared'].you.score,'45');
  assert.deepEqual(plain(payload.customGames.map(g=>g.id)),['custom-shared']);
  assert.ok(!payload.pinnedGameIds.includes('custom-private'));
});

test('custom scores rank per game but never influence overall standings', () => {
  const c=setup();
  const game={id:'custom-quiz',source:'custom',type:'points',sharing:'friends'};
  c.state.games.push(game);
  c.state.entries['2026-11-02']={'custom-quiz':{you:entry('100'),a:entry('90')}};
  assert.equal(c.buildGameLeaderboard(game)[0].id,'you');
  assert.ok(c.buildOverallLeaderboard().every(row=>row.solvryPoints===0));
  game.sharing='personal';
  assert.deepEqual(plain(c.buildGameLeaderboard(game).map(p=>p.id)),['you']);
});
