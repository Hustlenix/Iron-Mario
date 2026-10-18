import assert from 'node:assert/strict';
import fs from 'node:fs';
const results=[];
import {random} from '../onlyeducation/arcade/engine/math.js';
import {mazePath} from '../onlyeducation/arcade/games/dot-gobbler.js';
import {tankRoute} from '../onlyeducation/arcade/games/armored-arena.js';
const input=keys=>({down:k=>keys.includes(k),pressed:k=>keys.includes(k),pointer:{active:false,down:false,pressed:false,x:0,y:0}});
for(const id of ['orbit-duel','armored-arena','invader-patrol','dot-gobbler','bug-blaster']){const {createGame}=await import('../onlyeducation/arcade/games/'+id+'.js');for(let seed=1;seed<=3;seed++){const g=createGame({rng:random(seed),sound(){}}),s=g.state;for(let n=0;n<30000&&s.status==='playing';n++){let keys=[];
 if(id==='invader-patrol'){const a=s.aliens.reduce((a,b)=>!a||b.y>a.y?b:a,null);if(a){const flight=(264-a.y)/320,target=a.x+s.direction*(18+s.level*5+(30-s.aliens.length)*.8)*flight;if(target>s.x+4)keys.push('right');if(target<s.x-4)keys.push('left');}keys.push('action');}
 if(id==='bug-blaster'){const a=s.bugs.reduce((a,b)=>!a||b.y>a.y?b:a,null);if(a){if(a.x>s.x+5)keys.push('right');if(a.x<s.x-5)keys.push('left');}keys.push('action');}
 if(id==='dot-gobbler'){if(s.phase==='clear')keys=['action'];else{const targets=[...s.powers,...s.dots];let best=null;for(const t of targets){const p=mazePath(s.grid,s.player,t);if(p.length&&(!best||p.length<best.length))best=p;}if(best)keys=[best[0]];}}
 if(id==='armored-arena'){const aim=s.foes.find(f=>f.x===s.tank.x||f.y===s.tank.y);if(aim){keys.push(aim.x>s.tank.x?'right':aim.x<s.tank.x?'left':aim.y>s.tank.y?'down':'up');keys.push('action');}else{const f=s.foes[0],p=f&&tankRoute(s.grid,s.tank,f);if(p)keys.push(p.dir);keys.push('action');}}
 if(id==='orbit-duel'){const p=s.player,e=s.enemy;if(n<100){keys=['left'];}else if(n<180){keys=['up'];}else{const desired=Math.atan2(e.y+e.vy*.6-p.y,e.x+e.vx*.6-p.x),d=Math.atan2(Math.sin(desired-p.angle),Math.cos(desired-p.angle));keys=['down','action'];if(d>.025)keys.push('right');if(d<-.025)keys.push('left');}}
 g.update(1/60,input(keys));}const result={id,seed,status:s.status,score:s.score,level:s.level,lives:s.lives,remaining:s.bugs?.length??s.dots?.length??s.foes?.length??s.aliens?.length??s.wins};results.push(result);console.log(JSON.stringify(result));assert.equal(s.status,'won',id+' seed '+seed+' needs a winnable path');}}

fs.mkdirSync('build/arcade/twenty',{recursive:true});fs.writeFileSync('build/arcade/twenty/campaigns.json',JSON.stringify({scope:'legal-input deterministic simulation, not human or browser play',stateInjection:false,results},null,2));
