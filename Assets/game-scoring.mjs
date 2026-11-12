// Solvry performance scoring v1. These are published product conventions, not publisher scores.
// Raw results stay unchanged; derived points are recalculated when viewing a leaderboard.
export const RULE_VERSION = 1;
const rules = {};
function add(ids, rule) { for (const id of ids.split(' ')) rules[id] = Object.freeze({...rule}); }
add('wordle dsmdle flagle costcodle', {method:'bounded-guesses',min:1,max:6});
add('spotle minecraftle', {method:'bounded-guesses',min:1,max:10});
add('brandle', {method:'bounded-guesses',min:1,max:8});
add('metazooa', {method:'bounded-guesses',min:1,max:20});
add('genshindle', {method:'bounded-guesses',min:1,max:5});
add('quordle', {method:'bounded-guesses',min:4,max:9});
for (const [id,scale] of Object.entries({contexto:20,poople:5,feetle:5,terradle:10,travle:6,loldle:8,fibble:6,squirdle:8,globle:5})) add(id,{method:'guess-decay',min:1,scale});
add('connections connections-sports clevergoat-categories fine-print',{method:'mistakes',max:4});
add('minute-cryptic',{method:'par',base:70,step:10,floor:10});
add('mini-crossword',{method:'time',scale:60});
add('daily-crossword',{method:'time',scale:900});
add('unwordle murdle strands',{method:'completion'});
for(const [id,max] of Object.entries({pricepoint:25000,noillirk:2500,chainle:5000,'daily-tens':10,centumth:490,flagcognito:3000,'size-it-up':500,color:50,'buzzfeed-trivia':5})) add(id,{method:'points',max});
for(const [id,scale] of Object.entries({maptap:500,'enclose-horse':100,krillion:100})) add(id,{method:'points-decay',scale});
add('spelling-bee',{method:'rank',max:10});
add('rngdle',{method:'excluded'});
export const PERFORMANCE_RULES = Object.freeze(rules);
export function profile(game) { return game?.source === 'custom' || game?.retired ? null : PERFORMANCE_RULES[game?.id] || null; }
export function field(game) {
  const p=profile(game);
  const moves=['poople','feetle'].includes(game.id);
  const example=String(game.scoring?.example || '');
  const min=p?.min ?? game.minScore ?? (game.type==='guesses'?1:0);
  const max=game.maxScore ?? (p?.method==='bounded-guesses'?p.max:1000000);
  if(game.type==='guesses') return {label:moves?'Moves':game.id==='quordle'?'Total guesses':'Guesses',unit:moves?'moves':'guesses',example:String(Math.max(min,Number(example.match(/\d+/)?.[0])||4)),help:`${max<1000000?`${min}–${max}`:'Total'} ${moves?'moves':'guesses'} for the completed daily puzzle. Lower is better.`,min,max};
  if(game.type==='time') return {label:'Completion time',example:example||'12:03',help:'Use minutes:seconds or hours:minutes:seconds. Time must be greater than zero.',min:0,max:0};
  if(game.type==='complete') return {label:'Completion',example:'',help:'Choose Solved only after completing the daily puzzle.',min:0,max:0};
  if(game.type==='mistakes') return {label:game.id==='fine-print'?'Incorrect cuts':'Mistakes',example:'0',help:`0–${max-1} for a solve; ${max} is saved as a miss. Lower is better.`,min:0,max};
  if(game.type==='strokes') return {label:'Score vs par',example:'-1',help:'Use the signed recap score: -1, 0 or +2. Lower is better.',min:game.minScore??-1000,max};
  const label=game.id==='rngdle'?'Entropy points (EP)':game.id==='enclose-horse'?'Daily enclosure score':'Daily points';
  return {label,example:example.match(/^-?\d+(?:\.\d+)?/)?.[0]||'100',help:game.id==='rngdle'?'Daily roll EP, including decimals. This luck board stays outside combined totals.':game.id==='enclose-horse'?'Final score including bonuses and penalties; negative scores are allowed.':game.maxScore?`Final daily points, from 0 to ${game.maxScore.toLocaleString('en-US')}. Higher is better.`:'Final points shown by the daily game. Higher is better.',min:game.minScore??0,max};
}

// Read complete canonical strings instead of accepting arbitrary numeric prefixes in new games.
// Old move results were stored as "guesses"; retain them without rewriting history.
export function catalogScore(game,entry) {
  const text=String(entry?.score||'').trim();
  const invalid={value:Infinity,label:text||'—',detail:'Valid completed result needed'};
  if(!entry || !['solved','played','missed'].includes(entry.result)) return invalid;
  const f=field(game);
  let value,match;
  if(game.type==='complete') return entry.result==='solved' && text==='Complete'?{value:3,label:'Complete',detail:'Completed daily puzzle'}:invalid;
  if(game.type==='time') {
    if(!/^\d{1,3}:[0-5]\d(?::[0-5]\d)?$/.test(text)) return invalid;
    value=text.split(':').reduce((seconds,part)=>seconds*60+Number(part),0);
    return value>0?{value,label:text,detail:'Fastest completion time'}:invalid;
  }
  if(game.type==='guesses') {
    match=text.match(/^([1-9]\d*) (guess(?:es)?|moves?)$/);
    if(!match || match[2].startsWith('move') && f.unit!=='moves') return invalid;
    value=Number(match[1]);
  } else if(game.type==='mistakes') {
    match=text.match(/^(\d+) mistakes?$/);if(!match) return invalid;value=Number(match[1]);
    if(entry.result==='solved' && value>=f.max) return invalid;
  } else {
    match=text.match(/^([+-]?\d+(?:\.\d{1,6})?)(?:\/(\d+))?$/);
    if(!match || match[2] && (!game.maxScore || Number(match[2])!==game.maxScore)) return invalid;
    value=Number(match[1]);
    if(!game.decimalScore && !Number.isSafeInteger(value)) return invalid;
  }
  if(!Number.isFinite(value)||value<f.min||value>f.max) return invalid;
  const label=game.type==='guesses' && f.unit==='moves'?`${value} move${value===1?'':'s'}`:game.id==='minute-cryptic' && value>0?`+${value}`:text;
  return {value,label,detail:game.type==='guesses'?`Fewest ${f.unit}`:game.type==='strokes'?'Lowest score vs par':game.type==='mistakes'?`Fewest ${game.id==='fine-print'?'incorrect cuts':'mistakes'}`:game.id==='rngdle'?'Entropy points (EP)':'Most daily points'};
}

export function performancePoints(game,entry,score) {
  const p=profile(game), n=score?.value;
  if(!p || p.method==='excluded' || !entry || !['solved','played'].includes(entry.result) || !Number.isFinite(n)) return null;
  if(['bounded-guesses','guess-decay','mistakes','par','time','completion'].includes(p.method) && entry.result!=='solved') return null;
  let points;
  switch(p.method) {
    case 'bounded-guesses': if(n<p.min||n>p.max||!Number.isInteger(n)) return null; points=20+80*(p.max-n)/(p.max-p.min);break;
    case 'guess-decay': if(n<p.min||!Number.isInteger(n)) return null;points=100*p.scale/(p.scale+n-p.min);break;
    case 'mistakes': if(n<0||n>=p.max||!Number.isInteger(n)) return null;points=100*(p.max-n)/p.max;break;
    case 'par': if(!Number.isInteger(n)) return null;points=Math.max(p.floor,p.base-p.step*n);break;
    case 'time': if(n<=0) return null;points=100*p.scale/(p.scale+n);break;
    case 'completion': points=100;break;
    case 'points': if(n<0||n>p.max) return null;points=100*n/p.max;break;
    case 'points-decay': points=n<=0?0:100*n/(p.scale+n);break;
    case 'rank': if(n<1||n>p.max||!Number.isInteger(n)) return null;points=100*n/p.max;break;
    default:return null;
  }
  return Math.min(100,Math.max(0,Math.round(points)));
}

export function ruleDescription(game) {
  const p=profile(game);
  if(!p) return 'This game has its own board and does not earn combined Solvry points.';
  switch(p.method) {
    case 'bounded-guesses': return `${p.min} ${p.min===1?'guess':'guesses'} = 100 points; ${p.max} guesses = 20. Between them: 20 + 80 × (${p.max} − guesses) ÷ ${p.max-p.min}.`;
    case 'guess-decay': return `100 × ${p.scale} ÷ (${p.scale} + ${['poople','feetle'].includes(game.id)?'moves':'guesses'} − ${p.min}). One ${['poople','feetle'].includes(game.id)?'move':'guess'} = 100; ${p.scale+1} = 50. Lower counts earn more.`;
    case 'mistakes': return `0 / 1 / 2 / 3 ${game.id==='fine-print'?'incorrect cuts':'mistakes'} = 100 / 75 / 50 / 25 points. Four is a miss and earns 0.`;
    case 'par': return 'Par = 70 points. Each stroke under par adds 10; each over par subtracts 10. Completed scores stay between 10 and 100 points.';
    case 'time': return `100 × ${p.scale} ÷ (${p.scale} + seconds). ${p.scale===60?'1 minute':'15 minutes'} = 50 points. Faster earns more.`;
    case 'completion': return 'Completing the daily puzzle earns 100 points. All completed results tie; no timer or hint score is invented.';
    case 'points': return `100 × daily score ÷ ${p.max.toLocaleString('en-US')}. A maximum score earns 100 points.`;
    case 'points-decay': return `100 × positive daily score ÷ (${p.scale} + daily score). ${p.scale} earns 50 points; zero or negative scores earn 0. ${p.scale} is a Solvry benchmark, not a publisher maximum.`;
    case 'rank': return 'Beginner through Queen Bee earn 10, 20, 30, 40, 50, 60, 70, 80, 90 and 100 points.';
    case 'excluded': return 'RNGdle compares daily EP on its own board. This luck-based game earns no combined placement or performance points.';
  }
}
