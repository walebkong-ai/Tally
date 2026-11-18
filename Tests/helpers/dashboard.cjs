const {setup:base,app}=require('./import-review.cjs');
const vm=require('node:vm'),fs=require('node:fs');
function add(c,name){const match=new RegExp(`(?:async )?function ${name}\\(`).exec(app);if(!match)throw Error(name);const tail=app.slice(match.index),next=/\n(?:async )?function \w+\(/.exec(tail);vm.runInContext(name==='localDateKey'?tail.slice(0,tail.indexOf('\n}')+2):tail.slice(0,next?.index),c);}
function node(){return {textContent:'',innerHTML:'',value:'',hidden:false,dataset:{},style:{},attrs:{},querySelectorAll:()=>[],setAttribute(k,v){this.attrs[k]=v},removeAttribute(k){delete this.attrs[k]},classList:{toggle(){}}};}
function setup(){const c=base(),nodes=new Map();
 c.document={querySelector:id=>{if(!nodes.has(id))nodes.set(id,node());return nodes.get(id)},querySelectorAll:()=>[]};
 for(const key of ['playedMetric','solvedMetric','streakMetric','totalSolvesMetric','progressDays','quickGames'])c.elements[key]=c.document.querySelector('#'+key);
 Object.assign(c,{URL,navigator:{onLine:true},leaderboardScoring:'placement',leaderboardDays:1,dashboardPendingOnly:false,roomyOverview:{matches:false},wideOverview:{matches:false},manualFormDirty:false,location:{hash:'#today'},navigateTo:view=>{c.location.hash='#'+view}});
 if(fs.existsSync(require('node:path').join(__dirname,'../../Assets/dashboard.mjs')))c.dashboard=require('../../Assets/dashboard.mjs');
 for(const name of ['visibleGames','gameSource','getSortedGames','gameStreak','localDateKey','scoreEntryForGame','parseGuessScore','parseTimeScore','parseNumberScore','parseRankScore','resultWeight','hasUserPlayedDate','calculateStreak','isCompletedResult','shortWeekday','defaultScoreLabel','placementScore','getPeople','visibleFriends','isDemoFriend','cloudFriendsAvailable','eligibleForDailyRanking','buildOverallLeaderboard','buildGameLeaderboard','leaderboardDates','scoreTier','compareScoreValues','compareScoreRows','gameScoreDirection','scoreStyleLabel','renderRankRows','renderQuickGames','renderMetrics','renderProgressDays','renderHome','renderHomeFriendAvailability'])add(c,name);
 for(const name of ['dailyDashboard','renderDashboardProgress','handleDashboardAction'])if(app.includes('function '+name+'('))add(c,name);
 c.nodes=nodes;return c;
}
module.exports={setup,add,app};
