import {PAL,clamp,text,frame,banner,bot} from '../engine/presentation.js';
export function createGame(api){
 const s={status:'playing',score:0,level:1,lives:3,x:240,y:278,bugs:[],mushrooms:[],shots:[],shot:0,step:0,shield:1.5,time:0,kills:0,phase:'garden',wait:0,message:'Move inside the garden edge. Break bugs and clear mushroom cover.'};
 function wave(){s.bugs=Array.from({length:5+s.level*3},(_,n)=>({x:36+n*24,y:66,dir:1,dy:1}));s.mushrooms=[];for(let n=0;n<16;n++){const x=36+Math.floor(api.rng()*17)*24,y=98+Math.floor(api.rng()*7)*20;if(!s.mushrooms.some(m=>m.x===x&&m.y===y))s.mushrooms.push({x,y,hp:2});}s.shots=[];s.step=0;s.shield=1.5;s.phase='garden';}wave();
 function hurt(){if(s.shield>0)return;s.lives--;s.shield=1.5;api.sound('hit');s.message='Bug contact! Three hits ends the run.';if(!s.lives){s.status='lost';s.message='The garden bites back. Clear a firing lane next time.';}}
 function update(dt,i){if(s.status!=='playing'||!Number.isFinite(dt)||dt<=0)return;dt=Math.min(dt,.05);s.time+=dt;
  if(s.phase==='clear'){s.wait-=dt;if(s.wait<=0){s.level++;wave();}return;}
  s.shield=Math.max(0,s.shield-dt);s.x=clamp(s.x+((i.down('right')?1:0)-(i.down('left')?1:0))*190*dt,18,462);s.y=clamp(s.y+((i.down('down')?1:0)-(i.down('up')?1:0))*110*dt,242,284);if(i.pointer.down){s.x=clamp(i.pointer.x,18,462);s.y=clamp(i.pointer.y,242,284);}
  s.shot-=dt;if((i.down('action')||i.pressed('action')||i.pointer.down)&&s.shot<=0){s.shots.push({x:s.x,y:s.y-12});s.shot=.14;api.sound('shoot');}
  s.step+=dt;if(s.step>=.24-s.level*.025){s.step=0;for(const b of s.bugs){const nx=b.x+b.dir*12;if(nx<18||nx>462||s.mushrooms.some(m=>Math.abs(m.x-nx)<13&&Math.abs(m.y-b.y)<13)){b.dir*=-1;b.y+=16*b.dy;if(b.y>=274){b.y=274;b.dy=-1;}else if(b.y<=66){b.y=66;b.dy=1;}}else b.x=nx;}}
  for(const p of s.shots){const old=p.y;p.y-=350*dt;const targets=[...s.mushrooms.map(m=>({kind:'m',o:m,y:m.y})),...s.bugs.map(b=>({kind:'b',o:b,y:b.y}))].filter(t=>Math.abs(t.o.x-p.x)<13&&old>=t.y-10&&p.y<=t.y+10).sort((a,b)=>b.y-a.y);const t=targets[0];if(t){p.dead=true;if(t.kind==='m'){if(--t.o.hp<=0){s.mushrooms.splice(s.mushrooms.indexOf(t.o),1);s.score+=5;}}else{s.bugs.splice(s.bugs.indexOf(t.o),1);s.kills++;s.score+=40*s.level;if(!s.mushrooms.some(m=>Math.abs(m.x-t.o.x)<12&&Math.abs(m.y-t.o.y)<12)&&t.o.y<236)s.mushrooms.push({x:t.o.x,y:t.o.y,hp:1});api.sound('hit');}}}
  s.shots=s.shots.filter(p=>!p.dead&&p.y>32);for(const b of s.bugs)if(Math.hypot(b.x-s.x,b.y-s.y)<21)hurt();
  if(s.status==='playing'&&!s.bugs.length){s.score+=250*s.level;api.sound('win');if(s.level===3){s.status='won';s.message='Three gardens cleared. Pest control perfected!';}else{s.phase='clear';s.wait=1.4;s.message='Garden clear. A faster chain is approaching.';}}
 }
 function draw(c){frame(c,'BUG BLASTER',s.score,'ARROWS / DRAG MOVE  ·  HOLD ACTION FIRE');c.fillStyle='#203b3d';c.fillRect(0,238,480,57);c.strokeStyle=PAL.teal;c.setLineDash([4,5]);c.beginPath();c.moveTo(0,238);c.lineTo(480,238);c.stroke();c.setLineDash([]);
  for(const m of s.mushrooms){c.fillStyle=m.hp>1?PAL.violet:'#746786';c.fillRect(m.x-10,m.y-6,20,8);c.fillStyle=PAL.paper;c.fillRect(m.x-3,m.y+2,6,7);c.fillRect(m.x-6,m.y-4,3,3);}
  for(const b of s.bugs){bot(c,b.x,b.y,PAL.coral,16);c.fillStyle=PAL.gold;c.fillRect(b.x-11,b.y-6,3,3);c.fillRect(b.x+8,b.y+5,3,3);}
  c.fillStyle=PAL.gold;for(const p of s.shots)c.fillRect(p.x-1,p.y-5,3,10);
  if(!s.shield||Math.floor(s.time*10)%2){bot(c,s.x,s.y,PAL.teal,18);c.fillStyle=PAL.paper;c.fillRect(s.x-3,s.y-16,6,10);}
  text(c,'GARDEN '+s.level+'/3',12,49,10);text(c,'HULL '+s.lives+'  BUGS '+s.bugs.length,468,49,10,PAL.paper,'right');if(s.phase==='clear')banner(c,'GARDEN CLEAR','THE NEXT CHAIN IS ON ITS WAY',PAL.teal);
 }
 return {state:s,update,draw};
}
