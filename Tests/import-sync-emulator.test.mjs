import {before,after,test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {createRequire} from 'node:module';
import {initializeApp,deleteApp} from 'firebase/app';
import * as auth from 'firebase/auth';
import * as firestore from 'firebase/firestore';
import {initializeTestEnvironment,assertFails} from '@firebase/rules-unit-testing';
import * as safety from '../Assets/sync-safety.mjs';
import * as management from '../Assets/account-management.mjs';
const require=createRequire(import.meta.url),{setup,app}=require('./helpers/import-review.cjs');
const fixtures=require('./fixtures/shares/representative.json');
const projectId='demo-solvry-import-readiness',date='2026-11-16';
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8097'||process.env.FIREBASE_AUTH_EMULATOR_HOST!=='127.0.0.1:9097')throw Error('Refusing to run outside the dedicated loopback demo emulators.');
const clients=[],timers=new Set();let environment,credentials;
function plain(value){if(Array.isArray(value))return value.map(plain);if(value?.constructor?.name==='Object')return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,plain(v)]));return value;}
function load(c,name){const match=new RegExp(`(?:async )?function ${name}\\(`).exec(app);assert.ok(match,name);const tail=app.slice(match.index),end=/\n(?:async )?function \w+\(/.exec(tail);vm.runInContext(tail.slice(0,end?.index),c);}
async function client(name,email,password,create=false){
 const application=initializeApp({projectId,apiKey:'fake-emulator-key',authDomain:projectId+'.firebaseapp.com'},name);
 const identity=auth.initializeAuth(application,{persistence:auth.inMemoryPersistence});auth.connectAuthEmulator(identity,'http://127.0.0.1:9097',{disableWarnings:true});
 const db=firestore.getFirestore(application);firestore.connectFirestoreEmulator(db,'127.0.0.1',8097);
 await(create?auth.createUserWithEmailAndPassword(identity,email,password):auth.signInWithEmailAndPassword(identity,email,password));
 const value={application,identity,db};clients.push(value);return value;
}
function controller(client,stored){
 const uid=client.identity.currentUser.uid,c=setup(uid);c.management=management;c.navigator={onLine:true};
 if(stored){c.state=structuredClone(stored);c.state.account.uid=uid;c.state.localWriters={};c.localStorage.setItem(safety.storageKey('test',uid),JSON.stringify(c.state));c.storageBaseline=safety.localRecords(c.state);}
 else {c.state.profile={id:'you',name:'Import review',handle:'@import-'+uid.toLowerCase()};c.state.account={uid,signedIn:true};c.state.games=c.state.games.filter(g=>g.source!=='solvry');c.state.friends=[];c.state.pinnedGameIds=[];c.state.solvryPlays={};c.state.cloudBase={};c.state.syncConflicts=[];}
 c.cloudBackend={auth:client.identity,db:client.db,modules:{firestore:{...firestore,runTransaction:(db,callback)=>firestore.runTransaction(db,tx=>callback({get:ref=>tx.get(ref),set:(ref,value)=>tx.set(ref,plain(value)),delete:ref=>tx.delete(ref)}))}},ready:true,syncReady:true,generation:1,deletionPending:false,scoreBusy:false,error:'',unsubscribers:[]};
 c.window={setTimeout:(callback,ms)=>{const timer=setTimeout(()=>{timers.delete(timer);callback()},ms);timers.add(timer);return timer},clearTimeout:timer=>{timers.delete(timer);clearTimeout(timer)}};
 c.document={querySelector:()=>({textContent:'',dataset:{}})};c.updateAccountStatus=()=>{};c.renderFriendSync=()=>{};c.showAppNotice=message=>{c.notice=message};c.mergeCustomGames=(_,games)=>games;c.render=()=>{};
 for(const name of ['cloudSession','currentCloudSession','accountSessionMatches','cloudFriendsAvailable','accountRecords','loadCloudState','commitCloudRecord','persistCloudState','performCloudStateSave','pendingCloudChanges','queueCloudSave','retryAccountSync','performAccountSyncRetry','resolveSyncConflicts'])load(c,name);
 // The production queue is installed above; expose an explicit flush to avoid wall-clock guesses.
 c.flush=async()=>{clearTimeout(c.cloudBackend.saveTimer);timers.delete(c.cloudBackend.saveTimer);return c.persistCloudState()};
 return c;
}
const score=(c,id='wordle',day=date)=>c.state.entries[day]?.[id]?.you;
const resultRef=(client,uid,id='wordle',day=date)=>firestore.doc(client.db,`privateUsers/${uid}/records/${safety.resultRecordId(day,id)}`);
const share=id=>fixtures.find(f=>f.gameId===id).text;
before(async()=>{
 environment=await initializeTestEnvironment({projectId,firestore:{host:'127.0.0.1',port:8097,rules:fs.readFileSync(new URL('../firestore.rules',import.meta.url),'utf8')}});
 await environment.withSecurityRulesDisabled(c=>firestore.setDoc(firestore.doc(c.firestore(),'system/security'),{accountDataVersion:2}));
 credentials={email:'import-review@example.test',password:'Emulator-only-test-7!'};
});
after(async()=>{for(const timer of timers)clearTimeout(timer);await Promise.all(clients.map(c=>deleteApp(c.application)));await environment?.cleanup();});
test('authenticated connected save, cross-session retrieval, offline journal reload, failed-sync retry and revision conflict resolution',{timeout:90000},async()=>{
 const a=await client('review-device-a',credentials.email,credentials.password,true),uid=a.identity.currentUser.uid;
 const b=await client('review-device-b',credentials.email,credentials.password);assert.equal(b.identity.currentUser.uid,uid);
 const c=controller(a);c.paste(share('wordle'));c.importShareText();await c.flush();
 const first=await firestore.getDocFromServer(resultRef(a,uid));assert.equal(first.data().revision,1);assert.equal(first.data().value.score,'3/6');assert.equal(c.pendingCloudChanges(),0);
 // An independently authenticated application reads only its own private namespace.
 const second=controller(b);await second.loadCloudState(uid);assert.equal(score(second).score,'3/6');second.saveState(false);
 const fresh=controller(b,second.persisted());await fresh.loadCloudState(uid);assert.equal(score(fresh).score,'3/6');
 await c.flush();assert.equal((await firestore.getDocFromServer(resultRef(a,uid))).data().revision,1);
 // Temporarily disable the actual SDK network; local save must remain durable and pending.
 c.navigator.onLine=false;await firestore.disableNetwork(a.db);c.paste(share('connections'));c.importShareText();
 assert.equal(await c.flush(),false);assert.ok(c.pendingCloudChanges()>0);assert.equal(score(c,'connections').score,'0 mistakes');
 assert.equal((await firestore.getDocFromServer(resultRef(b,uid,'connections'))).exists(),false);
 const reload=controller(a,c.persisted());reload.navigator.onLine=false;assert.equal(score(reload,'connections').score,'0 mistakes');
 await firestore.enableNetwork(a.db);reload.navigator.onLine=true;await reload.retryAccountSync();assert.equal(reload.pendingCloudChanges(),0);
 assert.equal((await firestore.getDocFromServer(resultRef(b,uid,'connections'))).data().value.score,'0 mistakes');
 // A transient write failure is injected at the SDK boundary, leaving the existing account journal intact.
 reload.paste(share('chainle'));reload.importShareText();const original=reload.cloudBackend.modules.firestore.runTransaction;
 reload.cloudBackend.modules.firestore.runTransaction=async()=>{throw Object.assign(Error('Temporary emulator transport failure'),{code:'unavailable'})};
 await assert.rejects(reload.flush(),{code:'unavailable'});assert.match(reload.cloudBackend.error,/Temporary/);assert.ok(score(reload,'chainle'));
 reload.cloudBackend.modules.firestore.runTransaction=original;await reload.retryAccountSync();assert.equal(reload.pendingCloudChanges(),0);assert.equal(reload.cloudBackend.error,'');
 assert.equal((await firestore.getDocFromServer(resultRef(b,uid,'chainle'))).data().value.score,'4200');
 // Same base, two independent authenticated clients: preserve the losing edit for explicit resolution.
 const left=controller(a),right=controller(b);await left.loadCloudState(uid);await right.loadCloudState(uid);left.saveState(false);right.saveState(false);
 score(left).score='2/6';score(right).score='5/6';left.saveState(false);right.saveState(false);
 await Promise.all([left.flush(),right.flush()]);assert.equal(left.state.syncConflicts.length+right.state.syncConflicts.length,1);
 const loser=left.state.syncConflicts.length?left:right,conflict=loser.state.syncConflicts[0];assert.ok(['2/6','5/6'].includes(conflict.local.value.score));
 assert.notEqual(conflict.local.value.score,conflict.remote.value.score);assert.equal((await firestore.getDocFromServer(resultRef(b,uid))).data().revision,2);
 loser.resolveSyncConflicts(true);await loser.flush();assert.equal(loser.state.syncConflicts.length,0);assert.equal(loser.pendingCloudChanges(),0);
 assert.equal((await firestore.getDocFromServer(resultRef(b,uid))).data().value.score,conflict.local.value.score);
 assert.equal((await firestore.getDocFromServer(resultRef(b,uid))).data().revision,3);
 await loser.flush();assert.equal((await firestore.getDocFromServer(resultRef(b,uid))).data().revision,3);
 const peer=await client('review-other-account','other-import-review@example.test',credentials.password,true);
 await assertFails(firestore.getDocFromServer(resultRef(peer,uid)));
});
test('all 19 parsed formats pass unchanged cloud projection rules in an isolated authenticated account',{timeout:90000},async()=>{
 const clientA=await client('all-format-review','all-formats@example.test',credentials.password,true),c=controller(clientA),uid=clientA.identity.currentUser.uid;
 for(let start=0;start<fixtures.length;start+=8){c.paste(fixtures.slice(start,start+8).map(f=>f.text).join('\n---\n'));c.importShareText();await c.flush();assert.equal(c.pendingCloudChanges(),0);}
 for(const fixture of fixtures){const p=c.importers.parseShareText(fixture.text).parsed,day=p.date||date;const doc=await firestore.getDocFromServer(resultRef(clientA,uid,p.gameId,day));assert.ok(doc.exists(),fixture.gameId);assert.equal(doc.data().value.score,p.score);assert.equal(doc.data().revision,1);}
});
test('account switch while a real transaction read is suspended cannot write to either wrong namespace',{timeout:90000},async()=>{
 const a=await client('switch-review-a','switch-import-review@example.test',credentials.password,true),other=await client('switch-review-other','switch-other@example.test',credentials.password,true);
 const oldUid=a.identity.currentUser.uid,newUid=other.identity.currentUser.uid,c=controller(a);await c.flush();
 c.paste(share('wordle'));c.importShareText();clearTimeout(c.cloudBackend.saveTimer);
 const run=c.cloudBackend.modules.firestore.runTransaction;let release,entered;
 const ready=new Promise(resolve=>{entered=resolve}),pause=new Promise(resolve=>{release=resolve});
 c.cloudBackend.modules.firestore.runTransaction=(db,callback)=>run(db,transaction=>callback({...transaction,get:async ref=>{const snap=await transaction.get(ref);entered();await pause;return snap}}));
 const saving=c.flush();await ready;await auth.signOut(a.identity);await auth.signInWithEmailAndPassword(a.identity,'switch-other@example.test',credentials.password);
 c.storageOwner=newUid;c.cloudBackend.generation++;release();await saving;
 assert.equal((await firestore.getDocFromServer(resultRef(other,newUid))).exists(),false);
 const ownerAgain=await client('switch-review-owner-check','switch-import-review@example.test',credentials.password);
 assert.equal((await firestore.getDocFromServer(resultRef(ownerAgain,oldUid))).exists(),false);
});
