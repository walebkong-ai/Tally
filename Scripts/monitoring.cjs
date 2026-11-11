const fs = require('node:fs/promises');
const path = require('node:path');
const {client,PROJECT} = require('./cloud-access.cjs');
const BASE = '/v3/projects/'+PROJECT;
const EMAIL = 'walebkong@gmail.com';
const THRESHOLDS = {read:50000,write:20000};
function warningPolicy(kind,fraction,channel) {
  return {displayName:`Solvry ${kind}s ${Math.round(fraction*100)}% free-quota warning`,enabled:true,combiner:'OR',
    notificationChannels:[channel],userLabels:{app:'solvry',purpose:'spark-quota'},
    documentation:{mimeType:'text/markdown',content:`Solvry document ${kind} usage is high. Spark billing stays disabled. This conservative 24-hour metric window is an operational estimate, not a billing meter. Check Firebase Usage for the Pacific-day quota. Metrics and email delivery can lag. See the launch operations runbook.`},
    conditions:[{displayName:`Document ${kind}s in 24-hour alignment window`,conditionThreshold:{
      filter:`resource.type="firestore_instance" AND resource.labels.project_id="solvry-walebkong" AND metric.type="firestore.googleapis.com/document/${kind}_count"`,
      comparison:'COMPARISON_GT',thresholdValue:THRESHOLDS[kind]*fraction,duration:'0s',trigger:{count:1},
      aggregations:[{alignmentPeriod:'86400s',perSeriesAligner:'ALIGN_SUM',crossSeriesReducer:'REDUCE_SUM'}]
    }}],alertStrategy:{autoClose:'1800s'}};
}
function dashboard() {
  return {displayName:'Solvry launch operations',gridLayout:{columns:'2',widgets:['read','write','delete'].map(kind=>({
    title:'Firestore document '+kind+'s / minute',xyChart:{chartOptions:{mode:'COLOR'},dataSets:[{plotType:'LINE',timeSeriesQuery:{timeSeriesFilter:{
      filter:`resource.type="firestore_instance" AND metric.type="firestore.googleapis.com/document/${kind}_count"`,
      aggregation:{alignmentPeriod:'60s',perSeriesAligner:'ALIGN_SUM',crossSeriesReducer:'REDUCE_SUM'}
    }}}]}
  }))}};
}
async function apply() {
  const api=await client('monitoring'),billing=await client('cloudbilling');
  const info=(await billing.get('/v1/projects/'+PROJECT+'/billingInfo')).body;
  if(info.billingEnabled) throw Error('This configuration requires Spark billing to remain disabled.');
  const channels=(await api.get(BASE+'/notificationChannels')).body.notificationChannels||[];
  let channel=channels.find(c=>c.type==='email'&&c.labels?.email_address===EMAIL);
  if(!channel) channel=(await api.post(BASE+'/notificationChannels',{displayName:'Solvry owner quota warnings',type:'email',labels:{email_address:EMAIL},enabled:true})).body;
  const existing=(await api.get(BASE+'/alertPolicies')).body.alertPolicies||[];
  const policies=[];
  for(const kind of ['read','write']) for(const fraction of [0.8,0.95]) {
    const desired=warningPolicy(kind,fraction,channel.name),old=existing.find(p=>p.displayName===desired.displayName);
    const result=old ? await api.patch('/v3/'+old.name,{...desired,name:old.name},{queryParams:{updateMask:'displayName,enabled,combiner,notificationChannels,documentation,conditions,alertStrategy,userLabels'}}) : await api.post(BASE+'/alertPolicies',desired);
    policies.push({name:result.body.name,displayName:result.body.displayName,enabled:result.body.enabled});
  }
  const dashboards=(await api.get('/v1/projects/'+PROJECT+'/dashboards')).body.dashboards||[];
  let board=dashboards.find(d=>d.displayName==='Solvry launch operations');
  if(!board) board=(await api.post('/v1/projects/'+PROJECT+'/dashboards',dashboard())).body;
  const result={project:PROJECT,billingEnabled:false,notificationChannel:channel.name,channelVerificationStatus:channel.verificationStatus||'not-required-or-unspecified',dashboard:board.name,policies};
  await fs.mkdir(path.join(__dirname,'../Operations'),{recursive:true});
  await fs.writeFile(path.join(__dirname,'../Operations/monitoring-state.json'),JSON.stringify(result,null,2)+'\n');
  return result;
}
async function status() {
  const api=await client('monitoring'),now=new Date(),start=new Date(now.getTime()-86400000),usage={};
  for(const kind of ['read','write']) {
    const result=await api.get(BASE+'/timeSeries',{queryParams:{filter:`resource.type="firestore_instance" AND resource.labels.project_id="solvry-walebkong" AND metric.type="firestore.googleapis.com/document/${kind}_count"`,'interval.startTime':start.toISOString(),'interval.endTime':now.toISOString(),'aggregation.alignmentPeriod':'60s','aggregation.perSeriesAligner':'ALIGN_SUM','aggregation.crossSeriesReducer':'REDUCE_SUM'}});
    const series=result.body.timeSeries||[];
    const count=series.flatMap(s=>s.points||[]).reduce((sum,p)=>sum+Number(p.value.int64Value||0),0);
    usage[kind]={observedLast24Hours:count,freeDailyAllowance:THRESHOLDS[kind],fractionOfDailyAllowance:count/THRESHOLDS[kind],dataPresent:series.length>0};
  }
  return {project:PROJECT,checkedAt:now.toISOString(),usage,notice:'Rolling 24-hour document metrics are approximate; quota reset and billable index/rule reads can differ.'};
}
async function canary() {
  const api=await client('monitoring'),state=JSON.parse(await fs.readFile(path.join(__dirname,'../Operations/monitoring-state.json'),'utf8'));
  const desired=warningPolicy('read',0,state.notificationChannel);
  desired.displayName='Solvry quota email delivery canary'; desired.userLabels.purpose='delivery-test';
  desired.conditions[0].conditionThreshold.aggregations[0].alignmentPeriod='3600s';
  desired.documentation.content='Test notification for the owner-requested Solvry launch operations setup. No quota was intentionally consumed and billing remains disabled. This temporary policy will be removed after the delivery check.';
  return (await api.post(BASE+'/alertPolicies',desired)).body;
}
module.exports={warningPolicy,dashboard,status,apply,canary};
if(require.main===module) {
  const action=process.argv[2]||'status';
  if(!['status','apply','canary'].includes(action)) throw Error('Use status, apply or canary');
  module.exports[action]().then(r=>console.log(JSON.stringify(r,null,2))).catch(e=>{console.error(e.message);process.exitCode=1});
}
