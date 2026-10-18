import assert from 'node:assert/strict';
import fs from 'node:fs';import path from 'node:path';import{fileURLToPath}from'node:url';
import{GAMES}from'../onlyeducation/arcade/catalog.js';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),arcade=path.join(root,'onlyeducation/arcade');
const shared=JSON.parse(fs.readFileSync(path.join(root,'assets/shared_foundation/history_arcade/manifest.json')));
const seen=new Set(),statuses=['PLANNED','IMPLEMENTING','PLAYABLE','TESTED','RELEASE READY'];
const local=p=>{const full=path.resolve(arcade,p);assert(full.startsWith(arcade+path.sep),'Asset outside arcade');return full;};
for(const g of GAMES){
 assert(!seen.has(g.id),'Duplicate cabinet '+g.id);seen.add(g.id);assert(statuses.includes(g.status),'Bad status '+g.id);
 assert(fs.existsSync(g.cover?local(g.cover):path.join(root,'assets/shared_foundation/history_arcade/concepts',g.art+'.png')),'Missing cover '+g.id);
 const manifest=g.assetManifest?JSON.parse(fs.readFileSync(local(g.assetManifest))):shared;
 const ids=new Set(manifest.assets.map(a=>a.id));
 for(const id of g.assets||[])assert(ids.has(id),'Missing runtime asset '+id);
 if(g.assetManifest)for(const a of manifest.assets){assert.equal(a.license,'project_original');assert(fs.existsSync(path.resolve(path.dirname(local(g.assetManifest)),a.file)),'Missing local art '+a.file);}
 if(['PLAYABLE','TESTED','RELEASE READY'].includes(g.status)){assert(g.module&&fs.existsSync(local(g.module)),'Missing module '+g.id);assert(g.controls&&g.description,'Missing controls '+g.id);const preview=path.join(arcade,'art/previews',g.id+'.png');assert(fs.existsSync(preview),'Missing gameplay preview '+g.id);const png=fs.readFileSync(preview);assert.equal(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a');assert.equal(png.readUInt32BE(16),480);assert.equal(png.readUInt32BE(20),320);}
}
assert.equal(GAMES.filter(g=>!g.bonus).length,20,'Preserve the original history collection');
console.log(JSON.stringify({catalog:GAMES.length,states:Object.fromEntries(statuses.map(s=>[s,GAMES.filter(g=>g.status===s).length])),runtimeArt:new Set(GAMES.flatMap(g=>g.assets||[])).size}));
