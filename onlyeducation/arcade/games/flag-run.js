const COLS=23,ROWS=13,CELL=20,X0=10,Y0=47;
const D={up:{x:0,y:-1},down:{x:0,y:1},left:{x:-1,y:0},right:{x:1,y:0}};
const same=(a,b)=>a.x===b.x&&a.y===b.y,key=p=>p.x+','+p.y,dist=(a,b)=>Math.abs(a.x-b.x)+Math.abs(a.y-b.y);
export function createGame(api){
 const sound=n=>api.sound?.(n);
 const state={status:'playing',score:0,message:'Collect six flags, then return to the glowing exit. ACTION leaves smoke.',level:1,lives:3,fuel:100,car:{x:1,y:11,dir:'up'},grid:[],flags:[],fuelCans:[],enemies:[],smoke:[],moveClock:0,enemyClock:0,smokeCooldown:0,invulnerable:1.4,time:0,collected:0,totalFlags:0,exit:{x:1,y:11},pulse:0};
 function road(x,y){return x>=0&&y>=0&&x<COLS&&y<ROWS&&state.grid[y][x]===0;}
 function freeNeighbors(p){return Object.entries(D).map(([name,d])=>({x:p.x+d.x,y:p.y+d.y,dir:name})).filter(p=>road(p.x,p.y));}
 function route(start,target){
  const queue=[{x:start.x,y:start.y,first:null}],seen=new Set([key(start)]);
  for(let at=0;at<queue.length;at++){
   const p=queue[at];if(same(p,target))return p.first;
   for(const n of freeNeighbors(p))if(!seen.has(key(n))){seen.add(key(n));queue.push({...n,first:p.first||n});}
  }
  return null;
 }
 function makeMap(){
  state.grid=Array.from({length:ROWS},(_,y)=>Array.from({length:COLS},(_,x)=>x===0||y===0||x===COLS-1||y===ROWS-1?1:0));
  const layouts=[
   [[3,3,4,2],[9,2,4,3],[16,3,4,2],[3,8,4,2],[10,8,3,3],[16,8,4,2]],
   [[3,2,3,4],[9,3,5,2],[17,2,3,4],[3,8,4,2],[10,8,3,3],[17,8,3,2]],
   [[3,3,4,2],[10,2,3,4],[17,3,3,2],[3,8,3,3],[9,8,5,2],[17,8,3,3]]
  ];
  for(const[x,y,w,h]of layouts[state.level-1])for(let yy=y;yy<y+h;yy++)for(let xx=x;xx<x+w;xx++)state.grid[yy][xx]=1;
 }
 function placeEnemies(){
  const spots=[{x:21,y:1},{x:21,y:11},{x:11,y:6},{x:1,y:1}];
  state.enemies=spots.slice(0,state.level+1).map((p,i)=>({...p,dir:'down',stunned:0,id:i,clock:i*.06}));
  state.enemyClock=0;
 }
 function startDistrict(){
  makeMap();state.car={x:1,y:11,dir:'up'};state.exit={x:1,y:11};
  state.flags=[{x:1,y:1},{x:11,y:1},{x:21,y:1},{x:21,y:11},{x:7,y:6},{x:15,y:6}].map(p=>({...p,taken:false}));
  state.fuelCans=[{x:1,y:6},{x:21,y:6}].map(p=>({...p,taken:false}));
  state.fuel=100;state.collected=0;state.smoke=[];state.smokeCooldown=0;state.invulnerable=1.4;state.moveClock=0;placeEnemies();
  state.message='District '+state.level+': six flags, two fuel cans, one exit.';
 }
 function crash(reason){
  if(state.invulnerable>0||state.status!=='playing')return;
  state.lives--;sound('lose');
  if(state.lives<=0){state.status='lost';state.message=reason+' The rally ends with '+state.totalFlags+' flags.';return;}
  state.car={x:1,y:11,dir:'up'};state.fuel=Math.max(65,state.fuel);state.invulnerable=1.6;state.smoke=[];state.smokeCooldown=0;state.moveClock=0;placeEnemies();
  state.message=reason+' '+state.lives+' lives left. Collected flags stay safe.';
 }
 function smoke(){
  if(state.smokeCooldown>0){state.message='Smoke recharging. Cost: 12 fuel.';return;}if(state.fuel<12){state.message='Smoke needs 12 fuel. Find a fuel can first.';return;}
  state.fuel-=12;state.smokeCooldown=1.1;state.message='Smoke deployed · 12 fuel spent.';
  state.smoke.push({x:state.car.x,y:state.car.y,remaining:3.4});sound('move');
 }
 function pickups(){
  for(const flag of state.flags)if(!flag.taken&&same(flag,state.car)){
   flag.taken=true;state.collected++;state.totalFlags++;state.fuel=Math.min(100,state.fuel+6);state.score+=100*state.level;state.pulse=.25;sound('score');
   state.message=state.collected===6?'All flags! Return to the green exit at bottom left.':state.collected+' / 6 flags collected.';
  }
  for(const can of state.fuelCans)if(!can.taken&&same(can,state.car)){can.taken=true;state.fuel=Math.min(100,state.fuel+30);state.score+=25;sound('score');}
  if(state.collected===6&&same(state.car,state.exit)){
   state.score+=300*state.level+Math.floor(state.fuel)*2;
   if(state.level===3){state.status='won';state.message='RALLY COMPLETE! All 18 flags delivered across three districts.';sound('win');return;}
   state.level++;sound('win');startDistrict();
  }
 }
 function collide(){
  if(state.invulnerable>0)return;
  if(state.enemies.some(e=>e.stunned<=0&&same(e,state.car)))crash('A pursuer caught your bumper.');
 }
 function update(dt,input){
  if(state.status!=='playing')return;
  state.time+=dt;state.invulnerable=Math.max(0,state.invulnerable-dt);state.smokeCooldown=Math.max(0,state.smokeCooldown-dt);state.pulse=Math.max(0,state.pulse-dt);
  for(const cloud of state.smoke)cloud.remaining-=dt;state.smoke=state.smoke.filter(c=>c.remaining>0);
  state.fuel=Math.max(0,state.fuel-dt*(1.3+(state.level-1)*.2));
  if(state.fuel===0){state.invulnerable=0;crash('Out of fuel.');return;}
  if(input.pressed('action'))smoke();
  let wanted=null;
  for(const name of ['up','down','left','right'])if(input.pressed(name)){wanted=name;break;}
  if(!wanted)for(const name of ['up','down','left','right'])if(input.down(name)){wanted=name;break;}
  if(!wanted&&input.pointer?.active&&input.pointer.down){
   const dx=input.pointer.x-(X0+state.car.x*CELL+10),dy=input.pointer.y-(Y0+state.car.y*CELL+10);
   if(Math.abs(dx)+Math.abs(dy)>8)wanted=Math.abs(dx)>Math.abs(dy)?dx>0?'right':'left':dy>0?'down':'up';
  }
  state.moveClock=Math.max(0,state.moveClock-dt);
  if(wanted&&state.moveClock===0){
   state.car.dir=wanted;const d=D[wanted],next={x:state.car.x+d.x,y:state.car.y+d.y};
   if(road(next.x,next.y)){
    state.car.x=next.x;state.car.y=next.y;state.fuel=Math.max(0,state.fuel-.14);
    state.moveClock=.12;pickups();collide();
   }else state.moveClock=.05;
  }
  if(state.status!=='playing')return;
  for(const enemy of state.enemies){
   enemy.stunned=Math.max(0,enemy.stunned-dt);
   if(state.smoke.some(c=>same(c,enemy))){enemy.stunned=2;continue;}
   if(enemy.stunned>0)continue;
   enemy.clock-=dt;if(enemy.clock>0)continue;
   enemy.clock=Math.max(.16,.31-state.level*.035);
   // Distance field pursuit follows the roads instead of sliding through blocks.
   // The lead car follows the current location; later cars try a reachable point ahead.
   const d=D[state.car.dir],ahead={x:state.car.x+d.x*(enemy.id?2:0),y:state.car.y+d.y*(enemy.id?2:0)};
   const target=road(ahead.x,ahead.y)?ahead:state.car;
   let step=route(enemy,target);if(!step)step=route(enemy,state.car);
   if(step){enemy.x=step.x;enemy.y=step.y;enemy.dir=step.dir;}
   if(state.smoke.some(c=>same(c,enemy))){enemy.stunned=2;sound('hit');}
  }
  collide();
 }
 function drawCar(c,p,color,enemy=false){
  const x=X0+p.x*CELL,y=Y0+p.y*CELL,vertical=p.dir==='up'||p.dir==='down';
  c.fillStyle='#0d1b27';c.fillRect(x+2,y+3,16,16);
  c.fillStyle=color;c.fillRect(x+(vertical?5:2),y+(vertical?2:5),vertical?10:16,vertical?16:10);
  c.fillStyle='#fff0cf';
  const front=p.dir==='up'?{x:x+6,y:y+3,w:8,h:3}:p.dir==='down'?{x:x+6,y:y+14,w:8,h:3}:p.dir==='left'?{x:x+3,y:y+6,w:3,h:8}:{x:x+14,y:y+6,w:3,h:8};
  c.fillRect(front.x,front.y,front.w,front.h);
  c.fillStyle=enemy?'#152536':'#295e73';c.fillRect(x+7,y+7,6,6);
 }
 function draw(c){
  c.imageSmoothingEnabled=false;c.fillStyle='#152536';c.fillRect(0,0,480,320);
  c.fillStyle='#fff0cf';c.font='bold 13px monospace';c.textAlign='left';c.fillText('FLAG RUN',12,18);
  c.fillStyle='#61d5c8';c.font='10px monospace';c.fillText('D'+state.level+' / 3  LIVES '+state.lives+'  FLAGS '+state.collected+'/6',12,34);
  c.textAlign='right';c.fillStyle='#ffc56a';c.font='bold 15px monospace';c.fillText(String(state.score).padStart(5,'0'),468,19);
  c.fillStyle='#3a4c5a';c.fillRect(328,28,140,7);c.fillStyle=state.fuel<25?'#fa8068':'#ffc56a';c.fillRect(328,28,Math.round(140*state.fuel/100),7);
  for(let y=0;y<ROWS;y++)for(let x=0;x<COLS;x++){
   const px=X0+x*CELL,py=Y0+y*CELL;
   c.fillStyle=state.grid[y][x]?'#2c5b4c':'#273d4d';c.fillRect(px,py,CELL,CELL);
   if(state.grid[y][x]){
    c.fillStyle='#436f54';c.fillRect(px+2,py+2,16,12);c.fillStyle='#6f8c65';c.fillRect(px+4,py+4,5,3);
   }else{c.fillStyle='#566b73';c.fillRect(px+9,py+9,2,2);}
  }
  const ex=X0+state.exit.x*CELL,ey=Y0+state.exit.y*CELL;
  c.fillStyle=state.collected===6?'#ffc56a':'#61d5c8';c.fillRect(ex+1,ey+1,18,18);c.fillStyle='#152536';c.fillRect(ex+4,ey+4,12,12);
  c.fillStyle='#61d5c8';c.fillRect(ex+6,ey+6,8,2);c.fillRect(ex+6,ey+9,6,2);c.fillRect(ex+6,ey+12,8,2);
  for(const flag of state.flags)if(!flag.taken){
   const x=X0+flag.x*CELL,y=Y0+flag.y*CELL;c.fillStyle='#fff0cf';c.fillRect(x+5,y+3,2,15);c.fillStyle='#ffc56a';c.fillRect(x+7,y+3,10,7);c.fillStyle='#d28a42';c.fillRect(x+9,y+9,8,2);
  }
  for(const f of state.fuelCans)if(!f.taken){const x=X0+f.x*CELL,y=Y0+f.y*CELL;c.fillStyle='#b7a3e8';c.fillRect(x+5,y+6,10,12);c.fillRect(x+7,y+3,6,3);c.fillStyle='#fff0cf';c.fillRect(x+9,y+8,2,7);c.fillRect(x+7,y+10,6,2);}
  for(const enemy of state.enemies)drawCar(c,enemy,enemy.stunned>0?'#8b9ba5':'#fa8068',true);
  if(state.invulnerable===0||Math.floor(state.time*12)%2===0)drawCar(c,state.car,state.pulse?'#fff0cf':'#61d5c8');
  for(const cloud of state.smoke){
   const x=X0+cloud.x*CELL,y=Y0+cloud.y*CELL;c.fillStyle='#bbc3bd';c.fillRect(x+1,y+6,18,10);c.fillRect(x+5,y+2,10,16);c.fillStyle='#dee2cd';c.fillRect(x+5,y+5,5,5);
  }
  c.font='9px monospace';c.textAlign='center';c.fillStyle='#afc4cc';c.fillText('ARROWS / D-PAD DRIVE • ACTION SMOKE (-12 FUEL) • RETURN TO E',240,318);c.textAlign='left';
 }
 startDistrict();return{state,update,draw};
}
