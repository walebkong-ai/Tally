const {performance}=require('node:perf_hooks');const {setup}=require('./helpers/dashboard.cjs');
const c=setup();c.state.pinnedGameIds=['wordle','connections','strands','mini-crossword','spelling-bee','krillion'];
c.state.friends=[{id:'a',name:'Alice'},{id:'b',name:'Bob'},{id:'c',name:'Casey'}];
const cursor=new Date('2026-11-16T12:00:00');for(let i=0;i<1095;i++){const day=c.localDateKey(cursor);c.state.entries[day]={wordle:{you:{score:'3/6',result:'solved',source:'manual'},a:{score:'4/6',result:'solved'}}};cursor.setDate(cursor.getDate()-1);}
let calls=0;const visible=c.visibleGames;c.visibleGames=()=>{calls++;return visible()};
const render=()=>{c.renderMetrics();c.renderQuickGames();c.renderHome()};for(let i=0;i<10;i++)render();calls=0;
const samples=[];for(let i=0;i<50;i++){const start=performance.now();render();samples.push(performance.now()-start)}samples.sort((a,b)=>a-b);
console.log(JSON.stringify({historyDays:1095,pinned:6,runs:50,medianMs:+samples[25].toFixed(3),p95Ms:+samples[47].toFixed(3),visibleGameCallsPerRender:calls/50,scope:'Generated dashboard compute/string render in VM; excludes layout/network and other application views.'}));
