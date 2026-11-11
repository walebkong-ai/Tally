const path = require('node:path');
const lib = path.join(__dirname,'../node_modules/firebase-tools/lib');
const auth = require(path.join(lib,'auth'));
const { requireAuth } = require(path.join(lib,'requireAuth'));
const { Client } = require(path.join(lib,'apiv2'));
const PROJECT = 'solvry-walebkong';
let ready;
async function client(service) {
  if(!['monitoring','firestore','identitytoolkit','cloudbilling','firebaserules'].includes(service)) throw Error('Unsupported Google service');
  if(!ready) ready = (async()=>{
    const account = auth.getProjectDefaultAccount(path.join(__dirname,'..'));
    if(!account) throw Error('Sign in with the Firebase CLI before running launch operations.');
    const options = {project:PROJECT}; auth.setActiveAccount(options,account); await requireAuth(options);
  })();
  await ready;
  return new Client({urlPrefix:'https://'+service+'.googleapis.com'});
}
module.exports = {client,PROJECT};
