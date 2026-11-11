const fs=require('node:fs/promises');
const path=require('node:path');
const os=require('node:os');
const {execFileSync}=require('node:child_process');
const LABEL='com.solvry.local-backup';
function escape(value) {return value.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}
async function install() {
  if(process.platform!=='darwin') throw Error('This local scheduler installer is for macOS');
  const root=path.resolve(__dirname,'..'),local=path.join(root,'.local-ops'),filename=path.join(os.homedir(),'Library/LaunchAgents',LABEL+'.plist');
  const plist=`<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0"><dict>
<key>Label</key><string>${LABEL}</string>
<key>ProgramArguments</key><array><string>${escape(process.execPath)}</string><string>${escape(path.join(root,'Scripts/daily-ops.cjs'))}</string></array>
<key>WorkingDirectory</key><string>${escape(root)}</string>
<key>StartCalendarInterval</key><dict><key>Hour</key><integer>3</integer><key>Minute</key><integer>0</integer></dict>
<key>ProcessType</key><string>Background</string>
<key>StandardOutPath</key><string>${escape(path.join(local,'scheduler.log'))}</string>
<key>StandardErrorPath</key><string>${escape(path.join(local,'scheduler-error.log'))}</string>
</dict></plist>\n`;
  await fs.mkdir(path.dirname(filename),{recursive:true});await fs.mkdir(local,{recursive:true,mode:0o700});
  let exists=false;
  try {const old=await fs.readFile(filename,'utf8');exists=true;if(old!==plist)throw Error('An existing backup job differs; it was not overwritten');}catch(e){if(e.code!=='ENOENT')throw e;}
  if(!exists) await fs.writeFile(filename,plist,{mode:0o600,flag:'wx'});
  execFileSync('/usr/bin/plutil',['-lint',filename],{stdio:'pipe'});
  const service='gui/'+process.getuid()+'/'+LABEL;
  try {execFileSync('/bin/launchctl',['print',service],{stdio:'pipe'});}catch {execFileSync('/bin/launchctl',['bootstrap','gui/'+process.getuid(),filename],{stdio:'pipe'});}
  execFileSync('/bin/launchctl',['print',service],{stdio:'pipe'});
  return {label:LABEL,file:filename,loaded:true,schedule:'Daily at 03:00 local time; coalesced run after wake from sleep',requires:'This Mac, logged-in user, network, and the existing Firebase CLI session',retentionDays:14};
}
module.exports={install};
if(require.main===module) install().then(r=>console.log(JSON.stringify(r,null,2))).catch(e=>{console.error(e.message);process.exitCode=1});
