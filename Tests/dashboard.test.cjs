const {test}=require('node:test');
const assert=require('node:assert/strict');
const {execFileSync}=require('node:child_process');
const path=require('node:path');
const {setup,add}=require('./helpers/dashboard.cjs');
const dashboard=require('../Assets/dashboard.mjs');
const management=require('../Assets/account-management.mjs');
const fixtures=require('./fixtures/shares/representative.json');
const share=id=>fixtures.find(f=>f.gameId===id).text;
const own=(c,date,game,score='3/6',result='solved')=>{c.state.entries[date]||={};c.state.entries[date][game]={you:{score,result,source:'manual',note:'PRIVATE NOTE',answer:'SECRET',reveal:false}};};

test('progress uses only visible unique pins and preserves pin order without truncation',()=>{
 const c=setup(),ids=c.visibleGames().slice(0,18).map(g=>g.id).reverse();c.state.pinnedGameIds=[...ids,ids[0],'missing','immaculate-baseball'];
 own(c,c.today,ids[0]);const model=c.dailyDashboard();assert.equal(model.total,18);assert.deepEqual(model.cards.map(x=>x.game.id),ids);
 c.renderQuickGames(model);assert.equal((c.elements.quickGames.innerHTML.match(/<article /g)||[]).length,18);
 c.dashboardPendingOnly=true;c.renderQuickGames(model);assert.equal((c.elements.quickGames.innerHTML.match(/<article /g)||[]).length,17);
 assert.deepEqual(c.dailyDashboard().cards.map(x=>x.game.id),ids);
});
test('zero pins offers customization while unpinned history remains available',()=>{
 const c=setup();c.state.pinnedGameIds=[];own(c,c.today,'wordle');c.renderMetrics();c.renderQuickGames();c.renderHome([]);
 assert.equal(c.dailyDashboard().total,0);assert.match(c.elements.quickGames.innerHTML,/Choose games/);
 assert.equal(c.nodes.get('#dailyProgressBar').hidden,true);assert.equal(c.nodes.get('#homeScoresDetails').hidden,false);
 assert.match(c.nodes.get('#homeScores').innerHTML,/Wordle/);assert.doesNotMatch(c.nodes.get('#homeScores').innerHTML,/SECRET|PRIVATE NOTE/);
});
test('valid solves, misses, unverified attempts and invalid results have distinct progress states',()=>{
 const c=setup();const cases=[['wordle','3/6','solved','Completed',true],['wordle','X/6','missed','Played · Not solved',false],['wordle','0/6','solved','Check result',false],['wordle','3/6','played','Played',false],['mini-crossword','00:00','solved','Check result',false],['mini-crossword','0:01','solved','Completed',true],['strands','No hints','played','Played',false],['strands','No hints','solved','Completed',true],['chainle','0','played','Scored',true],['spelling-bee','Genius','played','Rank recorded',true]];
 for(const [id,score,result,label,complete] of cases){const game=c.state.games.find(g=>g.id===id),entry={score,result,source:id==='strands'?'official-share':'manual'};const status=dashboard.resultStatus(game,entry,c.scoreEntryForGame);assert.equal(status.label,label,id+score);assert.equal(status.completed,complete,id+score);assert.equal(status.recorded,true);}
 assert.equal(dashboard.resultStatus(c.state.games[0],null,c.scoreEntryForGame).pending,true);
});
test('remaining includes failed attempts but pending means no attempt, unrelated scores do not change denominator',()=>{
 const c=setup();c.state.pinnedGameIds=['wordle','connections','mini-crossword'];own(c,c.today,'wordle');own(c,c.today,'connections','4 mistakes','missed');own(c,c.today,'krillion','100','played');
 const m=c.dailyDashboard();assert.equal(m.completed,1);assert.equal(m.total,3);assert.equal(m.remaining,2);assert.equal(m.played,1);assert.equal(m.pending,1);assert.equal(m.percent,33);
 c.renderMetrics(m);assert.equal(c.nodes.get('#dailyProgressBar').attrs['aria-valuenow'],'33');assert.match(c.nodes.get('#dailyProgressHelp').textContent,/1 not played · 1 played without completion/);
});
test('historical progress does not change the current activity streak; future entries are ignored',()=>{
 const c=setup();c.state.pinnedGameIds=['wordle'];own(c,'2026-11-15','wordle');own(c,'2026-10-11','wordle');own(c,'2026-11-17','wordle');c.state.selectedDate='2026-10-11';
 c.renderMetrics();assert.equal(c.dailyDashboard().completed,1);assert.equal(c.elements.streakMetric.textContent,1);assert.match(c.nodes.get('#dailyProgressTitle').textContent,/2026-10-11/);
 c.state.selectedDate='2026-11-17';assert.equal(c.dailyDashboard().completed,0);assert.equal(dashboard.activityWeek(c.visibleGames(),c.state.entries,c.state.selectedDate,c.today,c.scoreEntryForGame).at(-1).state,'future');
});
test('activity distinguishes completed, played, empty and future days without leaking private text or friend activity',()=>{
 const c=setup();own(c,'2026-11-16','wordle');own(c,'2026-11-15','wordle','X/6','missed');c.state.entries['2026-11-14']={wordle:{peer:{score:'2/6',result:'solved'}}};
 c.renderProgressDays();const html=c.elements.progressDays.innerHTML;assert.equal((html.match(/tabindex="0"/g)||[]).length,7);assert.match(html,/2026-11-15: 0 completed or scored, 1 played without completion/);assert.match(html,/2026-11-14: 0 completed or scored, 0 played without completion, no activity/);assert.doesNotMatch(html,/SECRET|PRIVATE NOTE/);assert.match(c.nodes.get('#activitySummary').textContent,/2 active days · 1 with completions/);
});
test('seven local calendar days survive DST, year boundaries and time zones',()=>{
 const modulePath=path.resolve(__dirname,'../Assets/dashboard.mjs');
 for(const tz of ['America/Toronto','Asia/Tokyo','Pacific/Honolulu','Pacific/Kiritimati'])for(const end of ['2026-03-09','2026-11-02','2027-01-01','2028-03-01']){
 const days=JSON.parse(execFileSync(process.execPath,['-e',`console.log(JSON.stringify(require(${JSON.stringify(modulePath)}).calendarDays(${JSON.stringify(end)}).map(d=>d.date)))`],{env:{...process.env,TZ:tz},encoding:'utf8'}));
 assert.equal(days.length,7,tz);assert.equal(days.at(-1),end);assert.equal(new Set(days).size,7);for(let i=1;i<7;i++)assert.equal((Date.parse(days[i])-Date.parse(days[i-1]))/86400000,1,tz);
 }
 for(const invalid of ['2026-02-30','garbage','2026-13-01'])assert.equal(dashboard.calendarDays(invalid).length,0);
 assert.equal(dashboard.calendarDays('2026-11-16',1.5).length,0);
});
test('midnight refresh updates derived progress and keeps yesterday activity active',()=>{
 const c=setup();c.state.pinnedGameIds=['wordle'];own(c,c.today,'wordle');assert.equal(c.dailyDashboard().completed,1);
 const RealDate=Date;class Tomorrow extends RealDate{constructor(...args){super(...(args.length?args:['2026-11-17T00:01:00']))}};
 c.Date=Tomorrow;c.document.querySelectorAll=()=>[];c.elements.manualDateInput.value=c.today;add(c,'refreshCurrentDate');c.render=()=>c.renderMetrics();
 assert.equal(c.refreshCurrentDate(),true);assert.equal(c.today,'2026-11-17');assert.equal(c.dailyDashboard().completed,0);assert.equal(c.elements.streakMetric.textContent,1);
});
test('v77 batch save and duplicate retries refresh every affected pinned card without reload',()=>{
 const c=setup();c.state.pinnedGameIds=['wordle','connections','strands'];const original=c.render;c.render=()=>{original();c.renderQuickGames();c.renderMetrics()};
 c.paste(share('wordle')+'\n'+share('connections')+'\n'+share('strands'));c.importShareText();
 assert.equal(c.dailyDashboard().completed,2);assert.equal(c.dailyDashboard().played,1);assert.equal(c.dailyDashboard().pending,0);assert.match(c.elements.quickGames.innerHTML,/Edit result/);
 const writes=c.writes;c.importShareText();assert.equal(c.writes,writes);assert.equal(c.dailyDashboard().recorded,3);
});
test('actual score date correction and deletion immediately refresh progress and activity',async()=>{
 const c=setup();c.state.pinnedGameIds=['wordle'];own(c,c.today,'wordle');c.saveState();
 Object.assign(c,{management,navigator:{onLine:true},cloudSession:()=>({uid:''}),showAppNotice:()=>{}});add(c,'submitScoreManagement');
 c.document.querySelector('#scoreManagementDialog').close=()=>{};c.document.querySelector('#scoreMoveDate').value='2026-11-15';
 c.scoreManagement={owner:'',action:'move',gameId:'wordle',fromDate:c.today,entry:structuredClone(c.state.entries[c.today].wordle.you)};
 c.render=()=>c.renderMetrics();await c.submitScoreManagement({preventDefault(){}});
 assert.equal(c.state.selectedDate,'2026-11-15');assert.equal(c.dailyDashboard().completed,1);assert.equal(c.state.entries[c.today].wordle.you,undefined);
 c.scoreManagement={owner:'',action:'delete',gameId:'wordle',fromDate:'2026-11-15',entry:structuredClone(c.state.entries['2026-11-15'].wordle.you)};await c.submitScoreManagement({preventDefault(){}});
 assert.equal(c.dailyDashboard().completed,0);assert.match(c.nodes.get('#activitySummary').textContent,/next result/);assert.equal(c.persisted().entries['2026-11-15'].wordle.you,undefined);
});
test('dashboard actions open existing importer with selected game/date and do not save',()=>{
 const c=setup();c.render=()=>{};c.state.selectedDate='2026-11-15';const action=id=>c.handleDashboardAction({target:{closest:()=>({dataset:{dashboardResult:id}})}});
 action('connections');assert.equal(c.location.hash,'#import');assert.equal(c.state.activeGameId,'connections');assert.equal(c.elements.importDate.value,'2026-11-15');assert.equal(c.scoreMethod,'paste');assert.equal(c.writes,0);
 own(c,c.state.selectedDate,'connections','0 mistakes');action('connections');assert.equal(c.scoreMethod,'manual');assert.equal(c.elements.manualDateInput.value,'2026-11-15');
 action('fine-print');assert.equal(c.scoreMethod,'manual');const active=c.state.activeGameId;action('immaculate-baseball');assert.equal(c.state.activeGameId,active);
});
test('an unfinished manual draft cannot be discarded by another dashboard game',()=>{
 const c=setup();c.manualFormDirty=true;c.state.activeGameId='wordle';c.elements.manualDateInput.value='2026-10-11';c.showAppNotice=message=>{c.notice=message};
 c.handleDashboardAction({target:{closest:()=>({dataset:{dashboardResult:'connections'}})}});
 assert.equal(c.state.activeGameId,'wordle');assert.equal(c.elements.manualDateInput.value,'2026-10-11');assert.equal(c.scoreMethod,'manual');assert.match(c.notice,/unfinished/);assert.equal(c.writes,0);
});
test('stored per-game paste drafts retain their dates when entering from the dashboard',()=>{
 const c=setup();c.importDrafts.set('connections',{text:'unfinished recap',date:'2026-11-14'});c.elements.shareTextInput.value='unfinished wordle';
 c.render=()=>{c.switchImportDraft('wordle',c.state.activeGameId);c.previewImport()};
 c.handleDashboardAction({target:{closest:()=>({dataset:{dashboardResult:'connections'}})}});
 assert.equal(c.elements.shareTextInput.value,'unfinished recap');assert.equal(c.elements.importDate.value,'2026-11-14');assert.equal(c.importDrafts.get('wordle').text,'unfinished wordle');assert.equal(c.writes,0);
});
test('friend preview shows three friends and own position even outside the top three with unchanged ties',()=>{
 const rows=[{id:'f1',rank:1},{id:'f2',rank:1},{id:'f3',rank:3},{id:'f4',rank:4},{id:'you',rank:5}];const friends=rows.filter(r=>r.id!=='you');const p=dashboard.friendPreview(rows,friends);
 assert.deepEqual(p.topFriends.map(r=>r.id),['f1','f2','f3']);assert.equal(p.yours.rank,5);assert.equal(p.topFriends[1].rank,1);
});
test('Today reuses accepted-owner visibility; removed, pending, foreign-owner and unready sessions cannot enter rankings',()=>{
 const c=setup();Object.assign(c.cloudBackend,{ready:true,syncReady:true,auth:{currentUser:{uid:'owner'}}});c.state.account={uid:'owner'};
 c.state.friends=[{id:'a',uid:'a',name:'Allowed',ownerUid:'owner',status:'accepted'},{id:'b',uid:'b',name:'Removed',ownerUid:'owner',status:'removed'},{id:'c',uid:'c',name:'Pending',ownerUid:'owner',status:'pending'},{id:'d',uid:'d',name:'Foreign',ownerUid:'other',status:'accepted'}];
 for(const f of c.state.friends)c.getGameEntries(c.today,'wordle')[f.id]={score:'2/6',result:'solved'};
 const rows=c.buildOverallLeaderboard(1,'placement');assert.deepEqual(Array.from(dashboard.friendPreview(rows,c.visibleFriends()).topFriends,r=>r.id),['a']);
 c.renderHome(rows);assert.match(c.nodes.get('#homeLeaderboard').innerHTML,/Allowed/);assert.doesNotMatch(c.nodes.get('#homeLeaderboard').innerHTML,/Removed|Pending|Foreign/);
 c.cloudBackend.syncReady=false;c.renderHome();assert.doesNotMatch(c.nodes.get('#homeLeaderboard').innerHTML,/Allowed/);assert.match(c.nodes.get('#homeLeaderboard').innerHTML,/Find your friends/);
});
test('friend preview names its current scoring method, date range and samples, and no friend data has an actionable empty state',()=>{
 const c=setup();c.leaderboardDays=7;c.leaderboardScoring='performance';c.state.showDemoFriends=true;c.renderHome([]);
 assert.match(c.nodes.get('#homeRankingDate').textContent,/Performance points · 2026-11-10 – 2026-11-16 · Available friend group · Includes samples/);
 assert.match(c.nodes.get('#homeLeaderboard').innerHTML,/href="#friends"/);
});
test('local progress never claims cloud confirmation; existing offline, pending and failed sync badges remain accurate',()=>{
 const c=setup();c.state.pinnedGameIds=['wordle'];own(c,c.today,'wordle');c.storageOwner='owner';Object.assign(c,{management,navigator:{onLine:false},pendingCloudChanges:()=>1});add(c,'updateSyncStatus');
 c.renderMetrics();c.updateSyncStatus();assert.equal(c.dailyDashboard().completed,1);assert.match(c.nodes.get('#syncSummary').textContent,/Offline/);assert.match(c.nodes.get('#dailyProgressHelp').textContent,/Device saves included; see sync status above/);
 c.navigator.onLine=true;c.updateSyncStatus();assert.doesNotMatch(c.nodes.get('#syncSummary').textContent,/Changes synced/);
 c.cloudBackend.error='permission-denied';c.updateSyncStatus();assert.match(c.nodes.get('#syncSummary').textContent,/attention/);
 c.cloudBackend.error='';c.cloudBackend.syncReady=true;c.pendingCloudChanges=()=>0;c.updateSyncStatus();assert.equal(c.nodes.get('#syncSummary').textContent,'Changes synced');
});
test('dashboard rendering is read-only and publisher actions reject executable URLs',()=>{
 const c=setup();c.state.pinnedGameIds=['connections','wordle'];own(c,c.today,'wordle');const before=JSON.stringify(c.state);c.renderQuickGames();c.renderMetrics();c.renderHome();
 assert.equal(JSON.stringify(c.state),before);assert.equal(c.writes,0);assert.doesNotMatch(c.elements.quickGames.innerHTML,/SECRET|PRIVATE NOTE/);
 assert.equal(dashboard.publisherUrl({officialUrl:'javascript:alert(1)'}),'');assert.equal(dashboard.publisherUrl({officialUrl:'https://example.com/game'}),'https://example.com/game');
 assert.match(c.elements.quickGames.innerHTML,/rel="noopener noreferrer"/);
});
test('tracking is independent of combined-ranking exclusions and a completed lineup has a clear filter empty state',()=>{
 const c=setup();c.state.games.push({id:'custom-negative',name:'My round',source:'custom',type:'points',minScore:-100});c.state.pinnedGameIds=['rngdle','custom-negative'];
 own(c,c.today,'rngdle','25.5','played');own(c,c.today,'custom-negative','-4','played');const m=c.dailyDashboard();assert.equal(m.total,2);assert.equal(m.completed,2);
 c.dashboardPendingOnly=true;c.renderQuickGames(m);assert.match(c.elements.quickGames.innerHTML,/Every pinned game has a result/);assert.match(c.elements.quickGames.innerHTML,/Turn off Not played/);
});
test('friend availability is explicit for offline, paused, loading and unready sessions without new reads',()=>{
 const c=setup();c.state.account={uid:'owner'};Object.assign(c.cloudBackend,{auth:{currentUser:{uid:'owner'}},ready:true,syncReady:true});
 c.renderHome([]);const node=c.nodes.get('#homeFriendAvailability');assert.match(node.textContent,/Refresh in Friends for the latest/);
 c.navigator.onLine=false;c.renderHomeFriendAvailability();assert.match(node.textContent,/Offline.*cached/);assert.equal(node.hidden,false);
 c.navigator.onLine=true;c.cloudBackend.requestsError='permission-denied';c.renderHomeFriendAvailability();assert.match(node.textContent,/updates paused.*out of date/);assert.doesNotMatch(node.textContent,/permission-denied/);
 c.cloudBackend.requestsError='';c.cloudBackend.requestsLoading=true;c.renderHomeFriendAvailability();assert.match(node.textContent,/Checking friend connections/);
 c.cloudBackend.syncReady=false;c.renderHomeFriendAvailability();assert.match(node.textContent,/Waiting for account sync/);
 c.state.account={};c.renderHomeFriendAvailability();assert.equal(node.hidden,true);assert.equal(c.writes,0);
});
