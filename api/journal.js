import {createHash,timingSafeEqual} from 'node:crypto';
import {validatePosts} from '../lib/posts.mjs';
const digest=value=>createHash('sha256').update(value).digest();
export function authorized(header,secret){return typeof secret==='string'&&secret.length>=32&&typeof header==='string'&&header.length<512&&timingSafeEqual(digest(header),digest('Bearer '+secret));}
export default async function handler(req,res){
 res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');
 const reply=(status,payload)=>res.status(status).json(payload);
 const {BLOG_ADMIN_KEY,GITHUB_CONTENT_TOKEN,GITHUB_REPOSITORY='bondandawareness/Website',GITHUB_CONTENT_BRANCH='main'}=process.env;
 if(!['GET','PUT'].includes(req.method)){res.setHeader('Allow','GET, PUT');return reply(405,{error:'Metodo non supportato.'});}
 if(!BLOG_ADMIN_KEY||BLOG_ADMIN_KEY.length<32||!GITHUB_CONTENT_TOKEN)return reply(503,{error:'Pubblicazione non ancora configurata. Sono disponibili anteprima e copia di sicurezza locale.'});
 if(!authorized(req.headers.authorization,BLOG_ADMIN_KEY))return reply(401,{error:'Chiave di accesso non valida.'});
 if(!/^[\w.-]+\/[\w.-]+$/.test(GITHUB_REPOSITORY))return reply(503,{error:'Configurazione repository non valida.'});
 const endpoint=`https://api.github.com/repos/${GITHUB_REPOSITORY}/contents/content/posts.json`;
 const headers={Authorization:`Bearer ${GITHUB_CONTENT_TOKEN}`,Accept:'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28','Content-Type':'application/json'};
 try{
  if(req.method==='GET'){
   const upstream=await fetch(endpoint+'?ref='+encodeURIComponent(GITHUB_CONTENT_BRANCH),{headers,signal:AbortSignal.timeout(15000)});
   if(!upstream.ok)return reply(502,{error:'Impossibile leggere gli articoli da GitHub. Verifica configurazione e permessi.'});
   const data=await upstream.json();const posts=validatePosts(JSON.parse(Buffer.from(data.content,'base64').toString('utf8').replace(/^\uFEFF/,'')));
   return reply(200,{posts,sha:data.sha});
  }
  if(!String(req.headers['content-type']||'').startsWith('application/json'))return reply(415,{error:'Invia JSON.'});
  let body;try{body=typeof req.body==='string'?JSON.parse(req.body):req.body;}catch{return reply(400,{error:'JSON non valido.'});}
  if(!body||Buffer.byteLength(JSON.stringify(body))>900000)return reply(413,{error:'Archivio troppo grande.'});
  if(!/^[a-f0-9]{40}$/.test(body.sha||''))return reply(400,{error:'Ricarica gli articoli prima di salvare.'});
  let posts;try{posts=validatePosts(body.posts);}catch(e){return reply(400,{error:e.message});}
  // Validate cover IDs against the repository catalogue, never arbitrary remote URLs.
  const catalogResponse=await fetch(`https://api.github.com/repos/${GITHUB_REPOSITORY}/contents/products.json?ref=${encodeURIComponent(GITHUB_CONTENT_BRANCH)}`,{headers,signal:AbortSignal.timeout(15000)});
  if(!catalogResponse.ok)return reply(502,{error:'Impossibile verificare le copertine.'});
  const catalog=await catalogResponse.json();const ids=new Set(JSON.parse(Buffer.from(catalog.content,'base64').toString('utf8').replace(/^\uFEFF/,'')).map(p=>p[0]));
  if(posts.some(p=>!ids.has(p.image)))return reply(400,{error:'Una copertina non appartiene al catalogo.'});
  const upstream=await fetch(endpoint,{method:'PUT',headers,signal:AbortSignal.timeout(15000),body:JSON.stringify({message:'Update journal content from editorial dashboard',content:Buffer.from(JSON.stringify(posts,null,2)+'\n').toString('base64'),sha:body.sha,branch:GITHUB_CONTENT_BRANCH})});
  if(upstream.status===409||upstream.status===422)return reply(409,{error:'Gli articoli sono cambiati su GitHub. Esporta una copia e ricarica prima di riprovare.'});
  if(!upstream.ok)return reply(502,{error:'GitHub non ha confermato il salvataggio. Ricarica gli articoli per verificare lo stato.'});
  const result=await upstream.json();return reply(200,{sha:result.content.sha,commit:result.commit.sha,message:'Salvato su GitHub. La versione pubblica si aggiornerà al completamento del deploy Vercel.'});
 }catch{return reply(502,{error:'Connessione interrotta. Mantieni la bozza, esporta una copia e verifica lo stato prima di riprovare.'});}
}
