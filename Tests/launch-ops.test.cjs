const {test}=require('node:test');
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const ops=require('../Assets/launch-ops.mjs');
const backup=require('../Scripts/backup.cjs');
const monitoring=require('../Scripts/monitoring.cjs');
function storage() { const values=new Map();return {getItem:k=>values.get(k)||null,setItem:(k,v)=>values.set(k,v),values}; }
function reporter(send) {const store=storage(),timers=[];return {store,timers,r:ops.createReporter({storage:store,prefix:'scope',send,now:()=>10000,schedule:(fn,ms)=>{timers.push({fn,ms});return timers.length;},cancel:()=>{}})};}
test('operational errors use fixed fields and never transmit content or credentials',()=>{
  const secret='ANSWER EMAIL RAW NOTE TOKEN';
  const error={code:secret,message:secret,stack:secret,email:secret,note:secret,answer:secret,name:'constructor'};
  assert.deepEqual(ops.safeError(secret,error,secret),{area:'app',code:'unknown',route:'today'});
  assert.equal(ops.safeError('sync',{code:'firestore/unavailable'},'import').code,'unavailable');
  assert.equal(ops.safeError('app',new TypeError(secret),'game').code,'type-error');
  assert.doesNotThrow(()=>ops.safeError('app',{get code(){throw Error(secret);}},'game'));
});
test('diagnostics are account scoped and guest events are not uploaded',async()=>{
  const sent=[],{r,store}=reporter(async(uid,batch)=>{sent.push({uid,batch});return true;});
  r.error('app',Error('guest secret'),'today');await r.flush();assert.equal(sent.length,0);
  r.setAccount('a');r.count('scoreSave');r.error('sync',{code:'unavailable',message:'PRIVATE'},'game');
  r.setAccount('b');r.count('session');await r.flush();
  assert.equal(sent[0].uid,'b');assert.equal(sent[0].batch.counts.scoreSave,0);
  r.setAccount('a');await r.flush();assert.equal(sent[1].batch.counts.scoreSave,1);
  assert.equal(JSON.stringify([...store.values]).includes('PRIVATE'),false);
});
test('events arriving during upload are retained and old account acknowledgments cannot clear a new queue',async()=>{
  let finish;
  const {r}=reporter(()=>new Promise(resolve=>{finish=resolve;}));
  r.setAccount('a');r.count('scoreSave');const task=r.flush();await Promise.resolve();
  r.count('scoreSave');finish(true);await task;assert.equal(r.snapshot().counts.scoreSave,1);
  const next=r.flush();await Promise.resolve();r.setAccount('b');r.count('session');finish(true);await next;
  assert.equal(r.snapshot().counts.session,1);
});
test('reporting failures preserve the queue and never throw into the product',async()=>{
  const {r}=reporter(async()=>{throw Error('network offline');});
  r.setAccount('a');r.count('error');assert.equal(await r.flush(),false);assert.equal(r.snapshot().counts.error,1);
});
test('diagnostic expiry survives account reloads and discards old queues on next use',async()=>{
  let clock=1000;const store=storage(),sent=[];
  const make=()=>ops.createReporter({storage:store,prefix:'scope',now:()=>clock,send:async(uid,batch)=>{sent.push(batch);return true;},schedule:()=>1,cancel:()=>{}});
  const first=make();first.setAccount('a');first.count('scoreSave');
  clock+=6*86400000;const next=make();next.setAccount('a');next.count('session');
  assert.equal(next.snapshot().createdAt,1000);
  clock+=2*86400000;assert.equal(await next.flush(),false);assert.equal(sent.length,0);
  next.count('session');await next.flush();assert.equal(sent[0].counts.scoreSave,0);assert.equal(sent[0].counts.session,1);
  clock+=8*86400000;next.error('sync',{code:'unavailable'},'import');await next.flush();assert.equal(sent[1].lastError.code,'unavailable');
});
test('health writes respect server timestamps and defer to the five-minute limit',async()=>{
  let writes=0;
  const f={doc:()=>({}),runTransaction:async(_,fn)=>fn({get:async()=>({exists:()=>true,data:()=>({updatedAt:{toMillis:()=>9000}})}),set:()=>writes++})};
  const result=await ops.sendHealth({firestore:f,db:{},uid:'a',batch:{counts:ops.emptyCounts()},isCurrent:()=>true,now:()=>10000});
  assert.equal(result.retryAfter,299000);assert.equal(writes,0);
});
test('encrypted backups round-trip typed Firestore data and reject tampering/wrong keys',()=>{
  const key=crypto.randomBytes(32),data={documents:[{path:'a/b',fields:{when:{timestampValue:'2026-11-10T00:00:00Z'},count:{integerValue:'9007199254740993'},blob:{bytesValue:'AQID'},secret:{stringValue:'PRIVATE'}}}]};
  const encrypted=backup.seal(data,key);assert.equal(encrypted.includes(Buffer.from('PRIVATE')),false);
  assert.deepEqual(backup.open(encrypted,key),data);
  assert.throws(()=>backup.open(encrypted,crypto.randomBytes(32)));
  const corrupt=Buffer.from(encrypted);corrupt[corrupt.length-1]^=1;assert.throws(()=>backup.open(corrupt,key));
});
test('restore cannot target production or a remote service',()=>{
  assert.doesNotThrow(()=>backup.validateTarget('demo-solvry-restore','http://127.0.0.1:8099','http://127.0.0.1:9098'));
  for(const target of ['solvry-walebkong','demo-other','demo-solvry-restore/../../prod']) assert.throws(()=>backup.validateTarget(target,'http://127.0.0.1:8099','http://127.0.0.1:9098'));
  for(const host of ['http://127.0.0.1.evil:8099','https://firestore.googleapis.com','http://localhost:8099']) assert.throws(()=>backup.validateTarget('demo-solvry-restore',host,'http://127.0.0.1:9098'));
});
test('quota warning policies reference one owner channel and configured free-tier thresholds',()=>{
  const channel='projects/solvry-walebkong/notificationChannels/test';
  assert.equal(monitoring.warningPolicy('read',0.8,channel).conditions[0].conditionThreshold.thresholdValue,40000);
  assert.equal(monitoring.warningPolicy('write',0.95,channel).conditions[0].conditionThreshold.thresholdValue,19000);
  assert.deepEqual(monitoring.warningPolicy('read',0.95,channel).notificationChannels,[channel]);
});
