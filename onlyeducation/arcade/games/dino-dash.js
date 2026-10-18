// Original OnlyEducation runner. All art and code are authored for this project.
export const RUNNER={floor:260,x:78,speed:180,maxSpeed:300,gravity:1200,jump:-440};
const C={ink:'#152536',paper:'#fff0cf',teal:'#61bda5',gold:'#ffc56a',coral:'#db6b4d',sand:'#e5c995'};
export function dinoBounds(s){return {x:RUNNER.x,y:s.bottom-(s.ducking?22:42),w:s.ducking?44:32,h:s.ducking?22:42};}
export function obstacleBounds(o){return {x:o.x+4,y:o.y+4,w:o.w-8,h:o.h-4};}
const intersects=(a,b)=>a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y;
export function createGame(api){
 const state={status:'playing',score:0,message:'SPACE / tap to jump. Hold DOWN or DUCK for low flyers.',elapsed:0,distance:0,speed:RUNNER.speed,bottom:RUNNER.floor,vy:0,grounded:true,ducking:false,jumpBuffer:0,spawnIn:1.5,spawned:0,cleared:0,level:1,obstacles:[]};
 const sound=n=>api.sound?.(n);
 function spawn(){
  const flyer=state.spawned>=5&&state.spawned%3===2;
  const w=flyer?36:state.spawned===0?22:22+Math.floor(api.rng()*3)*6;
  const h=flyer?18:state.spawned===0?28:28+Math.floor(api.rng()*3)*8;
  state.obstacles.push({x:500,y:flyer?214:RUNNER.floor-h,w,h,kind:flyer?'flyer':'thorn',passed:false});
  state.spawned++;
  state.spawnIn+=1.35+api.rng()*.45;
  if(flyer)state.message='Low flyer ahead! Hold DOWN or DUCK, or time a high jump.';
 }
 function update(dt,input){
  if(state.status!=='playing'||!Number.isFinite(dt)||dt<=0)return;
  const pointer=input.pointer;
  const jump=input.pressed('action')||input.pressed('up')||(pointer.active&&pointer.pressed);
  const duck=input.down('down')||input.down('secondary');
  if(jump)state.jumpBuffer=.12;
  const steps=Math.ceil(Math.min(dt,.1)*120),step=Math.min(dt,.1)/steps;
  for(let n=0;n<steps;n++){
   state.jumpBuffer=Math.max(0,state.jumpBuffer-step);
   state.ducking=state.grounded&&duck&&!jump;
   if(state.grounded&&state.jumpBuffer>0&&!state.ducking){state.vy=RUNNER.jump;state.grounded=false;state.jumpBuffer=0;sound('move');}
   state.elapsed+=step;state.speed=Math.min(RUNNER.maxSpeed,RUNNER.speed+state.elapsed*2);
   state.distance+=state.speed*step;
   if(!state.grounded){state.vy+=RUNNER.gravity*step;state.bottom+=state.vy*step;if(state.bottom>=RUNNER.floor){state.bottom=RUNNER.floor;state.vy=0;state.grounded=true;}}
   state.spawnIn-=step;if(state.spawnIn<=0)spawn();
   for(const o of state.obstacles){
    o.x-=state.speed*step;
    if(intersects(dinoBounds(state),obstacleBounds(o))){state.status='lost';state.message='A prehistoric bump! '+state.cleared+' hazards cleared. Jump or duck and try again.';sound('hit');return;}
    if(!o.passed&&o.x+o.w<RUNNER.x){o.passed=true;state.cleared++;state.level=1+Math.floor(state.cleared/5);if(state.cleared%5===0)sound('score');}
   }
   state.obstacles=state.obstacles.filter(o=>o.x+o.w>-10);
   state.score=Math.floor(state.distance/8)+state.cleared*25;
  }
 }
 function draw(ctx){
  ctx.fillStyle=C.paper;ctx.fillRect(0,0,480,320);
  // Deliberately stepped silhouettes: every landscape edge is on an integer grid.
  ctx.fillStyle=C.gold;ctx.fillRect(377,62,40,32);ctx.fillRect(381,58,32,40);
  for(let i=0;i<4;i++){const x=Math.round((i*155-state.distance*.12)%620+620)%620-90;ctx.fillStyle='#e7dbc0';ctx.fillRect(x,90+(i%2)*34,58,10);ctx.fillRect(x+12,82+(i%2)*34,30,8);}
  ctx.fillStyle='#c7cdaa';
  for(let i=0;i<6;i++){const x=Math.round((i*110-state.distance*.2)%660+660)%660-110;for(let j=0;j<5;j++)ctx.fillRect(x+j*10,232-j*8,100-j*20,28+j*8);}
  ctx.fillStyle='#789c7c';for(let i=0;i<8;i++){const x=Math.round((i*74-state.distance*.5)%592+592)%592-74;ctx.fillRect(x,242,40,18);ctx.fillRect(x+8,234,24,8);}
  ctx.fillStyle=C.ink;ctx.fillRect(0,RUNNER.floor,480,4);
  ctx.fillStyle=C.sand;ctx.fillRect(0,264,480,24);ctx.fillStyle='#ae966e';
  for(let i=0;i<22;i++){const x=Math.round((i*28-state.distance)%616+616)%616-28;ctx.fillRect(x,273+(i%3)*3,9,2);}
  for(const o of state.obstacles){
   const x=Math.round(o.x),y=o.y;ctx.fillStyle=C.ink;
   if(o.kind==='flyer'){
    const wing=Math.floor(state.elapsed*8)%2;ctx.fillRect(x+4,y+6,28,8);ctx.fillRect(x+24,y+2,10,8);ctx.fillRect(x+8,y+(wing?0:12),12,6);
    ctx.fillStyle=C.coral;ctx.fillRect(x+8,y+7,18,4);ctx.fillStyle=C.gold;ctx.fillRect(x+29,y+4,2,2);
   }else{
    ctx.fillRect(x+4,y,o.w-8,o.h);ctx.fillRect(x,y+12,o.w,10);
    ctx.fillStyle=C.coral;ctx.fillRect(x+7,y+3,o.w-14,o.h-3);ctx.fillRect(x+3,y+15,o.w-6,4);
    ctx.fillStyle=C.gold;ctx.fillRect(x+8,y+5,3,8);
   }
  }
  const frame=state.status==='lost'?4:!state.grounded?2:state.ducking?3:Math.floor(state.elapsed*10)%2;
  api.sprite?.(ctx,'dino_runner',60,Math.round(state.bottom)-64,{frame,scale:2});
  ctx.fillStyle=C.ink;ctx.font='bold 17px monospace';ctx.fillText('DINO DASH',20,28);
  ctx.font='10px monospace';ctx.fillText('67 MILLION YEARS AGO',270,25);
  ctx.font='bold 14px monospace';ctx.fillText('SCORE '+state.score,20,51);
  ctx.font='11px monospace';ctx.fillText(state.cleared+' HAZARDS / '+Math.floor(state.distance/10)+'m',270,48);
  const upcoming=state.obstacles.find(o=>!o.passed);
  if(upcoming){ctx.fillStyle=C.ink;ctx.font='bold 11px monospace';ctx.fillText(upcoming.kind==='flyer'?'DUCK / JUMP':'JUMP',340,184);}
  ctx.fillStyle=C.ink;ctx.font='10px monospace';ctx.fillText('SPACE / TAP: JUMP    DOWN / Z: HOLD TO DUCK',20,305);
 }
 return {state,update,draw};
}
