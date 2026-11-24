import http from 'node:http';
import {readFile,stat} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import journal from './api/journal.js';
const root=fileURLToPath(new URL('./dist/',import.meta.url));
const mime={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.json':'application/json','.jpg':'image/jpeg','.png':'image/png','.svg':'image/svg+xml'};
http.createServer(async(req,res)=>{try{const url=new URL(req.url,'http://localhost');if(url.pathname==='/api/journal'){let body='';for await(const chunk of req){body+=chunk;if(body.length>950000){res.writeHead(413);res.end();return;}}req.body=body||undefined;res.status=n=>{res.statusCode=n;return res;};res.json=p=>{res.setHeader('Content-Type','application/json');res.end(JSON.stringify(p));};await journal(req,res);return;}
const requested=decodeURIComponent(url.pathname);let filename=path.resolve(root,'.'+(requested==='/'?'/index.html':requested));if(!filename.startsWith(root)){res.writeHead(403);res.end();return;}if(!path.extname(filename))filename+='.html';try{await stat(filename);}catch{res.statusCode=404;filename=path.join(root,'404.html');}res.setHeader('Cache-Control','no-store');res.setHeader('Content-Type',mime[path.extname(filename)]||'application/octet-stream');res.end(await readFile(filename));}catch{res.statusCode=500;res.end('Unable to load page.');}}).listen(4180,'127.0.0.1',()=>console.log('http://127.0.0.1:4180'));
