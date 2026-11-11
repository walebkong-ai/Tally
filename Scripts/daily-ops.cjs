const fs=require('node:fs/promises');
const path=require('node:path');
const backup=require('./backup.cjs');
const monitoring=require('./monitoring.cjs');
const local=path.join(__dirname,'../.local-ops');
async function daily() {
  const result={startedAt:new Date().toISOString(),retentionDays:14};
  try {
    result.backup=await backup.create();
    const cutoff=Date.now()-14*86400000;
    result.expiredCopiesRemoved=0;
    for(const name of await fs.readdir(local)) {
      if(!/^solvry-\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-\d{3}Z\.backup$/.test(name)) continue;
      const file=path.join(local,name),stat=await fs.lstat(file);
      if(stat.isFile()&&!stat.isSymbolicLink()&&stat.mtimeMs<cutoff) {await fs.unlink(file);result.expiredCopiesRemoved++;}
    }
    try {result.usage=await monitoring.status();} catch {result.usageCheck='unavailable';}
    result.status='succeeded';
  } catch(error) {result.status='failed';result.error=error.code||'backup-failed';process.exitCode=1;}
  result.completedAt=new Date().toISOString();
  await fs.mkdir(local,{recursive:true,mode:0o700});
  await fs.writeFile(path.join(local,'last-run.json'),JSON.stringify(result,null,2)+'\n',{mode:0o600});
  console.log(JSON.stringify(result));return result;
}
module.exports={daily};
if(require.main===module) daily().catch(()=>{console.error('Daily operations failed; inspect the private local job log.');process.exitCode=1;});
