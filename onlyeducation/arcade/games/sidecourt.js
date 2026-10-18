const clamp=(n,a,b)=>Math.max(a,Math.min(b,n));
const GROUND=278, GRAVITY=330;
export function createGame(api){
 const sound=n=>api.sound?.(n);
 const state={status:'playing',score:0,message:'Move under the ball. Hold ACTION to swing. UP lob / DOWN drive.',level:1,playerPoints:0,cpuPoints:0,playerX:104,cpuX:370,aim:'lob',ball:{x:120,y:220,vx:0,vy:0},lastHit:'cpu',bounceSide:null,bounces:0,serveOwner:'player',serveDelay:.7,serveReady:true,rally:0,swings:0,hits:0,swingTime:0,swingCooldown:0,cpuCooldown:0,cpuError:0,time:0,pointFlash:0,hitFlash:0,trail:[]};
 function resetPoint(owner){
  state.serveOwner=owner;state.serveDelay=.8;state.serveReady=true;state.playerX=104;state.cpuX=370;
  state.ball={x:owner==='player'?120:354,y:220,vx:0,vy:0};
  state.bounces=0;state.bounceSide=null;state.rally=0;state.trail=[];state.lastHit=owner==='player'?'cpu':'player';
  state.cpuError=(api.rng()-.5)*30;state.cpuCooldown=.2;state.swingCooldown=0;state.swingTime=0;
 }
 function point(player,why){
  if(player){state.playerPoints++;state.score+=100+state.rally*5;sound('score');}else{state.cpuPoints++;sound('lose');}
  state.level=1+Math.floor((state.playerPoints+state.cpuPoints)/3);state.pointFlash=.6;
  state.message=(player?'Your point! ':'Opponent point. ')+why;
  if(state.playerPoints>=5||state.cpuPoints>=5){
   state.status=state.playerPoints>=5?'won':'lost';
   if(state.status==='won')state.score+=500;
   state.message=state.status==='won'?'MATCH WON! Five points, well placed.':'Match over. Move early, then hold action near the ball.';
   sound(state.status==='won'?'win':'lose');
  }else resetPoint(player?'player':'cpu');
 }
 function hit(side,serve=false){
  const b=state.ball, player=side==='player',lob=player?state.aim==='lob':api.rng()>.4;
  const vx=lob?172:230,vy=lob?-243:-188;
  b.vx=(player?1:-1)*(vx+Math.min(26,state.rally*3));
  // Every return begins at the real impact point. Adjust the upward velocity so a
  // net-side contact still has enough height to clear the net without teleporting.
  const netTime=Math.max(.07,Math.abs(240-b.x)/Math.abs(b.vx));
  b.vy=Math.min(vy,(197-b.y-.5*GRAVITY*netTime*netTime)/netTime);
  b.vy=Math.max(-370,b.vy);
  state.lastHit=side;state.bounces=0;state.bounceSide=null;state.rally++;
  if(player){state.hits++;state.hitFlash=.28;if(!serve)state.score+=10;state.swingTime=.22;}
  state.cpuError=(api.rng()-.5)*(38-Math.min(18,state.level*3));
  state.cpuCooldown=.22;state.serveReady=false;state.trail=[];sound('hit');
 }
 function reachable(side){
  const b=state.ball,x=side==='player'?state.playerX:state.cpuX;
  return state.lastHit!==side&&(side==='player'?b.x<236:b.x>244)&&Math.abs(b.x-x)<58&&b.y>150&&b.y<GROUND-2;
 }
 function swing(){
  if(state.swingCooldown>0)return;
  state.swings++;state.swingTime=.18;state.swingCooldown=.27;
  if(state.serveReady&&state.serveOwner==='player'&&state.serveDelay<=0){state.ball.x=state.playerX+14;hit('player',true);}
  else if(!state.serveReady&&reachable('player'))hit('player');
  else sound('move');
 }
 function update(dt,input){
  if(state.status!=='playing')return;
  state.time+=dt;state.hitFlash=Math.max(0,state.hitFlash-dt);state.swingTime=Math.max(0,state.swingTime-dt);state.swingCooldown=Math.max(0,state.swingCooldown-dt);
  state.cpuCooldown=Math.max(0,state.cpuCooldown-dt);state.pointFlash=Math.max(0,state.pointFlash-dt);
  if(input.pressed('up'))state.aim='lob';if(input.pressed('down'))state.aim='drive';
  let move=Number(input.down('right'))-Number(input.down('left'));
  if(move)state.playerX=clamp(state.playerX+move*190*dt,32,213);
  else if(input.pointer?.active&&input.pointer.down)state.playerX=clamp(state.playerX+clamp(input.pointer.x-state.playerX,-220*dt,220*dt),32,213);
  const b=state.ball;
  let target=365;
  if(!state.serveReady&&b.x>210&&state.lastHit==='player'){
   const vy=b.vy,disc=vy*vy+2*GRAVITY*(235-b.y);
   const flight=disc>=0?Math.max(0,(-vy+Math.sqrt(disc))/GRAVITY):0;
   target=clamp(b.x+b.vx*Math.min(.4,flight)+state.cpuError,268,448);
  }
  state.cpuX=clamp(state.cpuX+clamp(target-state.cpuX,-(112+state.level*9)*dt,(112+state.level*9)*dt),267,448);
  if(state.serveReady){
   state.serveDelay=Math.max(0,state.serveDelay-dt);
   b.x=state.serveOwner==='player'?state.playerX+14:state.cpuX-14;b.y=220;
   if(state.serveOwner==='cpu'&&state.serveDelay===0)hit('cpu',true);
   else if(state.serveDelay===0&&(input.down('action')||input.pressed('action')||input.pointer?.active&&input.pointer.pressed))swing();
   return;
  }
  if(input.down('action')||input.pressed('action')||input.pointer?.active&&input.pointer.pressed)swing();
  if(reachable('cpu')&&state.cpuCooldown===0)hit('cpu');
  const steps=Math.max(1,Math.ceil(Math.max(Math.abs(b.vx),Math.abs(b.vy))*dt/3)),sub=dt/steps;
  for(let i=0;i<steps&&state.status==='playing'&&!state.serveReady;i++){
   const oldX=b.x;b.vy+=GRAVITY*sub;b.x+=b.vx*sub;b.y+=b.vy*sub;
   if(b.y<52){b.y=52;b.vy=Math.abs(b.vy)*.65;}
   if((oldX<236&&b.x>=236||oldX>244&&b.x<=244)&&b.y+4>=207){
    b.x=oldX<240?235:245;b.vx=-b.vx*.45;sound('hit');
   }
   if(b.y+4>=GROUND&&b.vy>0){
    const side=b.x<240?'player':'cpu';
    state.bounces=state.bounceSide===side?state.bounces+1:1;state.bounceSide=side;
    if(state.bounces>=2){point(side==='cpu','Two bounces on '+(side==='cpu'?'their':'your')+' court.');break;}
    b.y=GROUND-4;b.vy=-Math.abs(b.vy)*.72;sound('hit');
   }
   if(b.x<15||b.x>465){point(state.lastHit==='cpu','The return went out.');break;}
  }
  if(!state.serveReady){state.trail.push({x:b.x,y:b.y});if(state.trail.length>7)state.trail.shift();}
 }
 function person(c,x,color,flip,swinging){
  x=Math.round(x);c.fillStyle='#0d1b27';c.fillRect(x-12,276,26,3);
  c.fillStyle='#e2b080';c.fillRect(x-6,236,12,12);c.fillStyle='#fff0cf';c.fillRect(x-8,232,16,5);
  c.fillStyle=color;c.fillRect(x-10,249,20,17);c.fillStyle='#fff0cf';c.fillRect(x-10,266,7,10);c.fillRect(x+3,266,7,10);
  c.fillStyle='#152536';c.fillRect(x-12,275,10,3);c.fillRect(x+3,275,10,3);c.fillRect(x+(flip?-4:3),240,2,2);
  const rx=x+(flip?-20:15),ry=swinging?217:242;
  c.fillStyle='#ffc56a';c.fillRect(rx,ry,3,23);c.fillRect(rx-4,ry-6,12,13);c.fillStyle='#152536';c.fillRect(rx-2,ry-4,8,9);
 }
 function draw(c){
  c.imageSmoothingEnabled=false;c.fillStyle='#152536';c.fillRect(0,0,480,320);
  c.fillStyle='#fff0cf';c.font='bold 13px monospace';c.textAlign='left';c.fillText('SIDECOURT',16,21);
  c.fillStyle='#61d5c8';c.font='10px monospace';c.fillText('YOU '+state.playerPoints+'  :  '+state.cpuPoints+' CPU',16,38);
  c.textAlign='right';c.fillStyle='#ffc56a';c.font='bold 15px monospace';c.fillText(String(state.score).padStart(5,'0'),464,22);c.font='10px monospace';c.fillText('FIRST TO FIVE',464,38);
  c.fillStyle='#1b3940';c.fillRect(16,48,448,230);c.fillStyle='#21434a';
  for(let x=20;x<460;x+=20)c.fillRect(x,58,1,207);for(let y=58;y<276;y+=20)c.fillRect(20,y,440,1);
  c.fillStyle='#48766a';c.fillRect(16,278,448,24);c.fillStyle='#fff0cf';c.fillRect(16,278,448,3);
  c.fillStyle='#afc4cc';c.fillRect(238,207,4,71);c.fillRect(233,207,14,3);c.fillStyle='#537175';for(let y=216;y<278;y+=8)c.fillRect(234,y,12,1);
  person(c,state.playerX,'#61d5c8',false,state.swingTime>0);person(c,state.cpuX,'#fa8068',true,state.cpuCooldown>.12&&!state.serveReady);
  for(let i=0;i<state.trail.length;i++){const p=state.trail[i];c.fillStyle=i<4?'#43605d':'#81a78a';c.fillRect(Math.round(p.x)-2,Math.round(p.y)-2,4,4);}
  if(reachable('player')&&!state.serveReady){c.strokeStyle='#61d5c8';c.lineWidth=2;c.strokeRect(Math.max(16,state.playerX-58),150,Math.min(236,state.playerX+58)-Math.max(16,state.playerX-58),126);c.fillStyle='#61d5c8';c.font='bold 12px monospace';c.textAlign='center';c.fillText('SWING NOW',120,126);}
  if(state.hitFlash>0){c.fillStyle='#ffc56a';c.font='bold 12px monospace';c.textAlign='center';c.fillText('CLEAN CONTACT!',120,106);}
  c.fillStyle='#ffc56a';c.fillRect(Math.round(state.ball.x)-4,Math.round(state.ball.y)-4,8,8);c.fillStyle='#fff0cf';c.fillRect(Math.round(state.ball.x)-3,Math.round(state.ball.y)-3,3,3);
  c.textAlign='center';c.font='bold 11px monospace';c.fillStyle='#fff0cf';
  if(state.serveReady)c.fillText(state.serveDelay>0?'GET READY':state.serveOwner==='player'?'ACTION TO SERVE':'OPPONENT SERVES',240,94);
  c.font='10px monospace';c.fillStyle='#afc4cc';c.fillText('LEFT / RIGHT MOVE • ACTION SWING • '+state.aim.toUpperCase()+' SHOT',240,316);
  c.textAlign='left';
 }
 return{state,update,draw};
}
