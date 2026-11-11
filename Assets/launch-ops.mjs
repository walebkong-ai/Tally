// First-party operational diagnostics. Never accept message text, stack traces,
// URLs, email addresses, answers, notes, pasted results or arbitrary properties.
export const RELEASE = 'solvry-2026.11.10-ops2';
export const EVENTS = ['session','scoreSave','importRejected','syncSuccess','syncFailure','friendAction','error'];
export const AREAS = ['app','auth','sync','friends','import','storage'];
export const ROUTES = ['today','games','game','leaderboard','friends','import','privacy'];
export const CODES = ['unknown','unavailable','permission-denied','deadline-exceeded','resource-exhausted','failed-precondition','aborted','internal','invalid-argument','network-request-failed','popup-closed-by-user','popup-blocked','operation-not-allowed','requires-recent-login','quota-exceeded','type-error','syntax-error','range-error','script-error'];
export const emptyCounts = () => Object.fromEntries(EVENTS.map(key => [key, 0]));
export function safeError(area, error, route) {
  let code = 'unknown';
  try {
    const raw = typeof error?.code === 'string' ? error.code.replace(/^(?:auth|firestore)\//, '') : '';
    const kinds = {TypeError:'type-error',SyntaxError:'syntax-error',RangeError:'range-error',QuotaExceededError:'quota-exceeded'};
    code = CODES.includes(raw) ? raw : Object.hasOwn(kinds,error?.name) ? kinds[error.name] : 'unknown';
  } catch {}
  return {area:AREAS.includes(area)?area:'app',code,route:ROUTES.includes(route)?route:'today'};
}

export function createReporter({storage, prefix, send, now = Date.now, schedule = setTimeout, cancel = clearTimeout}) {
  let uid = '', generation = 0, timer = null, flight = null;
  let pending = {counts:emptyCounts(),lastError:safeError('app',null,'today'),createdAt:now()};
  const key = () => prefix + ':account:' + encodeURIComponent(uid) + ':ops';
  const persist = () => { if(uid) try { storage.setItem(key(),JSON.stringify(pending)); } catch {} };
  const later = (ms = 10000) => {
    if (!uid || timer !== null) return;
    timer = schedule(() => { timer = null; flush().catch(() => {}); }, ms);
  };
  function setAccount(nextUid) {
    generation++; if(timer !== null) cancel(timer); timer = null; flight = null;
    uid = nextUid || ''; pending = {counts:emptyCounts(),lastError:safeError('app',null,'today'),createdAt:now()};
    if(uid) try {
      const saved = JSON.parse(storage.getItem(key()) || 'null');
      if(saved && Number.isFinite(saved.createdAt) && now()-saved.createdAt >= 0 && now()-saved.createdAt < 7*86400000) {
        pending.createdAt = saved.createdAt;
        for(const event of EVENTS) pending.counts[event] = Math.min(1000000,Math.max(0,Math.trunc(Number(saved.counts?.[event])||0)));
        pending.lastError = safeError(saved.lastError?.area,{code:saved.lastError?.code},saved.lastError?.route);
      }
    } catch {}
    if(uid) persist();
  }
  function count(event) {
    if(!uid || !EVENTS.includes(event)) return;
    if(now()-pending.createdAt >= 7*86400000) pending = {counts:emptyCounts(),lastError:safeError('app',null,'today'),createdAt:now()};
    pending.counts[event] = Math.min(1000000,pending.counts[event]+1); persist(); later();
  }
  function error(area, failure, route) {
    if(!uid) return;
    count('error'); pending.lastError = safeError(area,failure,route); persist();
  }
  function flush() {
    if(flight) return flight;
    if(now()-pending.createdAt >= 7*86400000) { pending = {counts:emptyCounts(),lastError:safeError('app',null,'today'),createdAt:now()}; persist(); }
    if(!uid || !EVENTS.some(event=>pending.counts[event])) return Promise.resolve(false);
    const owner = uid, epoch = generation, batch = structuredClone(pending);
    const current = () => owner === uid && epoch === generation;
    const task = Promise.resolve().then(()=>send(owner,batch,current)).then(result=>{
      if(!current()) return false;
      if(result?.retryAfter) { later(result.retryAfter); return false; }
      if(result !== true) return false;
      for(const event of EVENTS) pending.counts[event] = Math.max(0,pending.counts[event]-batch.counts[event]);
      persist(); if(EVENTS.some(event=>pending.counts[event])) later(300000);
      return true;
    }).catch(()=>{ if(current()) later(300000); return false; }).finally(()=>{ if(flight===task) flight=null; });
    flight = task; return task;
  }
  return {setAccount,count,error,flush,snapshot:()=>structuredClone(pending)};
}

export async function sendHealth({firestore:f,db,uid,batch,isCurrent,now=Date.now}) {
  return f.runTransaction(db, async transaction => {
    const ref = f.doc(db,'clientHealth',uid), previous = await transaction.get(ref);
    if(!isCurrent()) return false;
    const old = previous.exists()?previous.data():null;
    const age = old?.updatedAt?.toMillis ? now()-old.updatedAt.toMillis() : Infinity;
    if(age < 300000) return {retryAfter:Math.max(1000,300000-age)};
    const counts = emptyCounts();
    for(const key of EVENTS) counts[key] = Math.min(1000000,(old?.counts?.[key]||0)+batch.counts[key]);
    transaction.set(ref,{schemaVersion:1,release:RELEASE,updatedAt:f.serverTimestamp(),counts,lastError:batch.counts.error?batch.lastError:old?.lastError||batch.lastError});
    return true;
  });
}
