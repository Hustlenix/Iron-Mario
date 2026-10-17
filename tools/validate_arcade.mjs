import assert from 'node:assert/strict';
import fs from 'node:fs';import path from 'node:path';import{fileURLToPath}from'node:url';
import{GAMES}from'../onlyeducation/arcade/catalog.js';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'assets/shared_foundation/history_arcade/manifest.json')));
const ids=new Set(manifest.assets.map(a=>a.id)),seen=new Set();
const statuses=['PLANNED','IMPLEMENTING','PLAYABLE','TESTED','RELEASE READY'];
for(const g of GAMES){assert(!seen.has(g.id),'Duplicate cabinet '+g.id);seen.add(g.id);assert(statuses.includes(g.status),'Bad status '+g.id);assert(fs.existsSync(path.join(root,'assets/shared_foundation/history_arcade/concepts',g.art+'.png')),'Missing concept '+g.id);for(const id of g.assets||[])assert(ids.has(id),'Missing runtime asset '+id);if(['PLAYABLE','TESTED','RELEASE READY'].includes(g.status)){assert(g.module&&fs.existsSync(path.join(root,'onlyeducation/arcade',g.module)),'Missing module '+g.id);assert(g.controls&&g.description,'Missing controls '+g.id);}}
assert.equal(GAMES.length,20);
console.log(JSON.stringify({catalog:GAMES.length,states:Object.fromEntries(statuses.map(s=>[s,GAMES.filter(g=>g.status===s).length])),runtimeArt:new Set(GAMES.flatMap(g=>g.assets||[])).size}));
