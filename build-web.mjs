import {mkdir,cp,rm} from 'node:fs/promises';
const root=new URL('.',import.meta.url), out=new URL('www/',root);
await rm(out,{recursive:true,force:true}); await mkdir(out,{recursive:true});
for (const name of ['index.html','manifest.json','service-worker.js','styles','src','icons']) await cp(new URL(name,root),new URL(name,out),{recursive:true});
console.log('Browser files copied to www/');