const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const app=fs.readFileSync(path.join(__dirname,'../../dist/app.js'),'utf8');
function add(c,name) {
  const tail=app.slice(app.indexOf(`function ${name}(`));
  const next=/\n(?:async )?function \w+\(/.exec(tail);
  vm.runInContext(name==='localDateKey'?tail.slice(0,tail.indexOf('\n}')+2):tail.slice(0,next?.index),c);
}
function node(){const label={hidden:false};return {value:'',hidden:false,disabled:false,innerHTML:'',textContent:'',attrs:{},closest:()=>label,removeAttribute(k){delete this.attrs[k]},setAttribute(k,v){this.attrs[k]=v}};}
function setup(owner='') {
  const memory=new Map();const c=vm.createContext({
    importers:require('../../Assets/importers.mjs'),gameScoring:require('../../Assets/game-scoring.mjs'),safety:require('../../Assets/sync-safety.mjs'),structuredClone,
    today:'2026-11-16',SHOW_SOLVRY_GAMES:false,storageOwner:owner,STORAGE_KEY:'test',storageWriter:'import-test',storageProblem:'',storageBaseline:{},
    cloudBackend:{auth:owner?{currentUser:{uid:owner}}:null,deletionPending:false,scoreBusy:false},
    localStorage:{get length(){return memory.size},key:i=>[...memory.keys()][i],getItem:k=>memory.get(k)||null,setItem:(k,v)=>memory.set(k,v),removeItem:k=>memory.delete(k)},
    importQueue:[],importQueueText:null,importQueueOwner:owner,importDateTouched:false,importDrafts:new Map(),importDraftRevision:0,
    manualFormDirty:false,manualFormKey:'',scoreMethod:'paste',lastRenderedGameId:'wordle',writes:0,status:'',
    elements:Object.fromEntries(['shareTextInput','sharePreview','importDate','importPasteButton','importClearButton','manualGameInput','playDate','manualDateInput'].map(k=>[k,node()])),
    document:{querySelector:()=>node()},escapeHtml:s=>String(s??'').replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;'),gameLogo:()=>'',
    queueCloudSave:()=>{c.writes++},updateSyncStatus(){},setImportStatus:(message)=>{c.status=message},setScoreMethod:method=>{c.scoreMethod=method}
  });
  vm.runInContext(app.slice(app.indexOf('const ADDITIONAL_IMPORT_GAMES'),app.indexOf('let state = loadState()')),c);
  c.state=vm.runInContext('structuredClone(starterState)',c);c.state.entries={};c.state.activeGameId='wordle';c.state.selectedDate='2026-11-16';
  memory.set(c.safety.storageKey('test',owner),JSON.stringify(c.state));c.storageBaseline=c.safety.localRecords(c.state);c.elements.importDate.value=c.state.selectedDate;
  for(const name of ['parseShareText','importDateError','sameImportedScore','switchImportDraft','resetImportReview','syncImportReview','evaluateImportReview','previewImport','saveReviewedImport','importShareText','handleImportReviewChange','handleImportReviewClick','renderSharePreview','getGameEntries','saveState'])add(c,name);
  c.render=()=>c.previewImport();
  c.paste=(text)=>{c.elements.shareTextInput.value=text;return c.previewImport()};
  c.persisted=()=>c.safety.readLocal(c.localStorage,c.safety.storageKey('test',owner),c.state);
  return c;
}
module.exports={setup,add,app};
