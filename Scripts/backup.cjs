const fs=require('node:fs/promises');
const path=require('node:path');
const crypto=require('node:crypto');
const zlib=require('node:zlib');
const {client,PROJECT}=require('./cloud-access.cjs');
const ROOT=`projects/${PROJECT}/databases/(default)/documents`;
const LOCAL=path.join(__dirname,'../.local-ops');
const MAGIC=Buffer.from('SOLVRYBK1');
function seal(snapshot,key) {
  const iv=crypto.randomBytes(12),cipher=crypto.createCipheriv('aes-256-gcm',key,iv);
  const encrypted=Buffer.concat([cipher.update(zlib.gzipSync(Buffer.from(JSON.stringify(snapshot)))),cipher.final()]);
  return Buffer.concat([MAGIC,iv,cipher.getAuthTag(),encrypted]);
}
function open(bytes,key) {
  if(!bytes.subarray(0,9).equals(MAGIC)) throw Error('Invalid backup header');
  const cipher=crypto.createDecipheriv('aes-256-gcm',key,bytes.subarray(9,21));
  cipher.setAuthTag(bytes.subarray(21,37));
  return JSON.parse(zlib.gunzipSync(Buffer.concat([cipher.update(bytes.subarray(37)),cipher.final()]),{maxOutputLength:50*1024*1024}).toString());
}
function canonical(value) {
  if(Array.isArray(value)) return value.map(canonical);
  if(value&&typeof value==='object') return Object.fromEntries(Object.keys(value).sort().map(key=>[key,canonical(value[key])]));
  return value;
}
function digest(documents) {
  return crypto.createHash('sha256').update(JSON.stringify(canonical([...documents].sort((a,b)=>a.path.localeCompare(b.path))))).digest('hex');
}
function identityShape(user) {
  return {localId:user.localId,email:user.email||'',emailVerified:!!user.emailVerified,disabled:!!user.disabled,displayName:user.displayName||'',
    providers:(user.providerUserInfo||[]).map(p=>({providerId:p.providerId,rawId:p.rawId||'',email:p.email||''})).sort((a,b)=>a.providerId.localeCompare(b.providerId))};
}
async function walk(api,root,readTime) {
  const result=[];
  async function visit(parent,depth=0) {
    if(depth>100) throw Error('Firestore nesting exceeds backup limit');
    let pageToken;
    do {
      const page=(await api.post('/v1/'+parent+':listCollectionIds',{pageSize:100,...(readTime?{readTime}:{}),...(pageToken?{pageToken}:{})})).body;
      for(const collection of page.collectionIds||[]) {
        let token;
        do {
          const docs=(await api.get('/v1/'+parent+'/'+encodeURIComponent(collection),{queryParams:{pageSize:100,showMissing:true,...(readTime?{readTime}:{}),...(token?{pageToken:token}:{})}})).body;
          for(const doc of docs.documents||[]) {
            if(doc.updateTime) result.push({path:doc.name.slice(root.length+1),fields:doc.fields||{}});
            if(result.length>10000) throw Error('Backup stopped before exceeding the configured 10,000-document safety limit');
            await visit(doc.name,depth+1);
          }
          token=docs.nextPageToken;
        } while(token);
      }
      pageToken=page.nextPageToken;
    } while(pageToken);
  }
  await visit(root); return result;
}
async function key() {
  await fs.mkdir(LOCAL,{recursive:true,mode:0o700});
  const filename=path.join(LOCAL,'backup.key');
  try { await fs.writeFile(filename,crypto.randomBytes(32),{mode:0o600,flag:'wx'}); } catch(error) {if(error.code!=='EEXIST') throw error;}
  const value=await fs.readFile(filename);
  if(value.length!==32) throw Error('Invalid local backup key');
  return value;
}
async function create() {
  const api=await client('firestore'),auth=await client('identitytoolkit'),rules=await client('firebaserules');
  const readTime=new Date(Date.now()-10000).toISOString(),documents=await walk(api,ROOT,readTime),users=[];
  let token;
  do {
    const page=(await auth.get('/v1/projects/'+PROJECT+'/accounts:batchGet',{queryParams:{maxResults:1000,...(token?{nextPageToken:token}:{})}})).body;
    for(const u of page.users||[]) {
      if(u.passwordHash || (u.providerUserInfo||[]).some(p=>p.providerId!=='google.com')) throw Error('Auth backup currently supports Google-only accounts; no partial backup was saved.');
      users.push(Object.fromEntries(['localId','email','emailVerified','displayName','photoUrl','disabled','providerUserInfo','createdAt','lastLoginAt'].filter(k=>u[k]!==undefined).map(k=>[k,u[k]])));
    }
    token=page.nextPageToken;
  } while(token);
  const release=(await rules.get('/v1/projects/'+PROJECT+'/releases/cloud.firestore')).body;
  const ruleSet=(await rules.get('/v1/'+release.rulesetName)).body;
  const indexes=(await api.get('/v1/projects/'+PROJECT+'/databases/(default)/collectionGroups/-/indexes')).body;
  const snapshot={format:'solvry-encrypted-backup',version:1,project:PROJECT,createdAt:new Date().toISOString(),firestoreReadTime:readTime,documents,authUsers:users,liveRules:ruleSet.source,liveRuleRelease:release.rulesetName,indexes,documentHash:digest(documents),scope:'Point-in-time Firestore snapshot and separately fetched Google Auth identity metadata; not a cross-service atomic snapshot.'};
  const bytes=seal(snapshot,await key()),filename=path.join(LOCAL,'solvry-'+snapshot.createdAt.replace(/[:.]/g,'-')+'.backup');
  await fs.writeFile(filename,bytes,{flag:'wx',mode:0o600});
  const verified=open(await fs.readFile(filename),await key());
  if(digest(verified.documents)!==snapshot.documentHash) throw Error('Encrypted backup verification failed');
  return {file:filename,documents:documents.length,googleIdentities:users.length,firestoreReadTime:readTime,encryptedBytes:bytes.length,documentHash:snapshot.documentHash,keyFile:path.join(LOCAL,'backup.key')};
}
function validateTarget(target,firestoreUrl,authUrl) {
  if(!/^demo-solvry-restore(?:-[a-z0-9-]+)?$/.test(target)) throw Error('Restore is restricted to a disposable demo-solvry-restore project');
  for(const [value,port] of [[firestoreUrl,'8099'],[authUrl,'9098']]) {
    const url=new URL(value);
    if(url.protocol!=='http:' || url.hostname!=='127.0.0.1' || url.port!==port || url.username || url.password || url.pathname!=='/') throw Error('Restore accepts only the dedicated loopback emulators');
  }
}
function rewrite(value,targetRoot) {
  if(Array.isArray(value)) return value.map(item=>rewrite(item,targetRoot));
  if(value&&typeof value==='object') return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,k==='referenceValue'&&typeof v==='string'&&v.startsWith(ROOT+'/')?targetRoot+v.slice(ROOT.length):rewrite(v,targetRoot)]));
  return value;
}
async function restore(filename,{target='demo-solvry-restore',firestoreUrl='http://127.0.0.1:8099',authUrl='http://127.0.0.1:9098'}={}) {
  validateTarget(target,firestoreUrl,authUrl);
  const data=open(await fs.readFile(filename),await key());
  if(data.project!==PROJECT||data.format!=='solvry-encrypted-backup'||data.version!==1||digest(data.documents)!==data.documentHash) throw Error('Backup integrity or project check failed');
  if(data.documents.some(d=>!d.path||d.path.includes('..')||d.path.startsWith('/')||d.path.split('/').length%2)) throw Error('Invalid document path');
  const targetRoot=`projects/${target}/databases/(default)/documents`;
  const adapter=base=>({
    get:async(p,o={})=>request(base,p,null,o.queryParams),
    post:async(p,body)=>request(base,p,body)
  });
  async function request(base,p,body,query) {
    const url=new URL(p,base);for(const [k,v] of Object.entries(query||{})) url.searchParams.set(k,String(v));
    const r=await fetch(url,{method:body?'POST':'GET',headers:{'content-type':'application/json',authorization:'Bearer owner'},...(body?{body:JSON.stringify(body)}:{})});
    if(!r.ok) throw Error('Emulator restore request failed: HTTP '+r.status);
    return {body:await r.json()};
  }
  const local=adapter(firestoreUrl);
  const existing=await local.post('/v1/'+targetRoot+':listCollectionIds',{});
  if(existing.body.collectionIds?.length) throw Error('Restore target must be empty; existing data was kept');
  const authBase=authUrl+'/identitytoolkit.googleapis.com';
  const before=await request(authBase,'/identitytoolkit.googleapis.com/v1/projects/'+target+'/accounts:batchGet',null,{maxResults:1});
  if(before.body.users?.length) throw Error('Auth emulator target must be empty');
  for(let i=0;i<data.documents.length;i+=200) {
    const writes=data.documents.slice(i,i+200).map(d=>({update:{name:targetRoot+'/'+d.path,fields:rewrite(d.fields,targetRoot)},currentDocument:{exists:false}}));
    const response=await local.post('/v1/'+targetRoot+':batchWrite',{writes});
    if(response.body.status?.some(s=>s.code)) throw Error('Emulator rejected a restore write');
  }
  if(data.authUsers.length) {
    const imported=await request(authUrl,'/identitytoolkit.googleapis.com/v1/projects/'+target+'/accounts:batchCreate',{users:data.authUsers});
    if(imported.body.error?.length) throw Error('Auth identity restore failed');
  }
  const restored=await walk(local,targetRoot),expected=data.documents.map(d=>({...d,fields:rewrite(d.fields,targetRoot)}));
  if(digest(restored)!==digest(expected)) throw Error('Restored Firestore data differs from the backup');
  const identities=(await request(authUrl,'/identitytoolkit.googleapis.com/v1/projects/'+target+'/accounts:batchGet',null,{maxResults:1000})).body.users||[];
  const ids=identities.map(u=>u.localId).sort();
  if(JSON.stringify(ids)!==JSON.stringify(data.authUsers.map(u=>u.localId).sort())) throw Error('Restored identity IDs differ');
  if(JSON.stringify(canonical(identities.map(identityShape).sort((a,b)=>a.localId.localeCompare(b.localId))))!==JSON.stringify(canonical(data.authUsers.map(identityShape).sort((a,b)=>a.localId.localeCompare(b.localId))))) throw Error('Restored Google identity metadata differs');
  return {target,documents:restored.length,googleIdentities:ids.length,firestoreHashMatches:true,identityIdsMatch:true,identityMetadataMatches:true,productionWrites:0};
}
module.exports={seal,open,digest,validateTarget,create,restore};
if(require.main===module) {
  const command=process.argv[2]||'create';
  const action=command==='create'?create:command==='restore-emulator'?()=>restore(process.argv[3]):null;
  if(!action) throw Error('Use create or restore-emulator <encrypted-file>');
  action().then(r=>console.log(JSON.stringify(r,null,2))).catch(e=>{console.error(e.message);process.exitCode=1});
}
