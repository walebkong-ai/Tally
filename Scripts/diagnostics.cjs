const {client,PROJECT}=require('./cloud-access.cjs');
async function read() {
  const api=await client('firestore');
  const r=await api.get(`/v1/projects/${PROJECT}/databases/(default)/documents/clientHealth`,{queryParams:{pageSize:100}});
  return {project:PROJECT,reports:(r.body.documents||[]).map(doc=>({accountSuffix:doc.name.split('/').at(-1).slice(-6),release:doc.fields?.release?.stringValue,updatedAt:doc.fields?.updatedAt?.timestampValue,
    counts:Object.fromEntries(Object.entries(doc.fields?.counts?.mapValue?.fields||{}).map(([k,v])=>[k,Number(v.integerValue||0)])),
    lastError:Object.fromEntries(Object.entries(doc.fields?.lastError?.mapValue?.fields||{}).map(([k,v])=>[k,v.stringValue]))})),moreReportsAvailable:!!r.body.nextPageToken};
}
module.exports={read};
if(require.main===module) read().then(r=>console.log(JSON.stringify(r,null,2))).catch(e=>{console.error(e.message);process.exitCode=1});
