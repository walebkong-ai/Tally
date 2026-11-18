// Derived Today data only: no DOM, persistence, authentication or network access.
import * as scoring from './game-scoring.mjs?v=2';

export function trackedGames(games, pinnedIds = []) {
  const catalog = new Map(games.filter(game => !game.retired && !game.id.startsWith('immaculate-')).map(game => [game.id, game]));
  return [...new Set(pinnedIds)].map(id => catalog.get(id)).filter(Boolean);
}

export function resultStatus(game, entry, scoreForGame) {
  if (!entry) return {state:'pending', label:'Not played', completed:false, recorded:false, pending:true, detail:'No result recorded.'};
  if (entry.result === 'missed') return {state:'missed', label:'Played · Not solved', completed:false, recorded:true, pending:false, detail:'A failed attempt is activity, not a completed puzzle.'};
  const valid = scoring.isRankable(game, entry, scoreForGame(entry, game));
  if (valid) return {state:'completed', label:entry.result === 'solved' ? 'Completed' : game.type === 'rank' ? 'Rank recorded' : 'Scored', completed:true, recorded:true, pending:false,
    detail:entry.result === 'solved' ? 'Valid completed puzzle.' : 'A valid scored round or rank counts toward daily progress.'};
  if (entry.result === 'played') return {state:'played', label:'Played', completed:false, recorded:true, pending:false,
    detail:game.id === 'strands' && entry.source === 'official-share' ? 'Share recorded; completion is unverified. Confirm a finished solve manually.' : 'Attempt recorded; completion is not confirmed.'};
  return {state:'review', label:'Check result', completed:false, recorded:true, pending:false, detail:'This result needs correction before it can count as complete.'};
}

export function dailyProgress(games, pinnedIds, entries, date, today, scoreForGame) {
  const cards = trackedGames(games, pinnedIds).map(game => {
    const entry = date <= today ? entries[date]?.[game.id]?.you : undefined;
    return {game, entry, ...resultStatus(game, entry, scoreForGame)};
  });
  const total = cards.length, completed = cards.filter(card => card.completed).length;
  const recorded = cards.filter(card => card.recorded).length, pending = total - recorded;
  return {cards, total, completed, recorded, pending, played:recorded-completed,
    remaining:total-completed, percent:total ? Math.round(100*completed/total) : 0};
}

export function calendarDays(end, count = 7) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(end || '') || !Number.isInteger(count) || count < 1 || count > 31) return [];
  const cursor = new Date(`${end}T12:00:00`);
  const key = date => `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`;
  if (!Number.isFinite(cursor.getTime()) || key(cursor) !== end) return [];
  return Array.from({length:count}, (_,i) => {
    const day = new Date(cursor); day.setDate(cursor.getDate()-(count-1-i));
    return {date:key(day), weekday:day.toLocaleDateString(undefined,{weekday:'short'}), day:day.getDate()};
  });
}

export function activityWeek(games, entries, end, today, scoreForGame) {
  return calendarDays(end).map(day => {
    const future = day.date > today, own = future ? [] : games.filter(game => entries[day.date]?.[game.id]?.you);
    const completed = own.filter(game => resultStatus(game, entries[day.date][game.id].you, scoreForGame).completed).length;
    return {...day, recorded:own.length, completed, played:own.length-completed, today:day.date===today, future,
      state:future?'future':completed?'completed':own.length?'played':'empty'};
  });
}

export function friendPreview(rows, friends) {
  const ids = new Set(friends.map(friend => friend.id));
  return {topFriends:rows.filter(row => row.id !== 'you' && ids.has(row.id) && row.rank).slice(0,3),
    yours:rows.find(row => row.id === 'you'), hasFriends:ids.size>0};
}

export function publisherUrl(game) {
  try { const url = new URL(game.officialUrl); return ['https:','http:'].includes(url.protocol) ? url.href : ''; }
  catch { return ''; }
}
