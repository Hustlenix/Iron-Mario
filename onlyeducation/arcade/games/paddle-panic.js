import {clamp} from '../engine/math.js';
export function createGame(api){
 const s={status:'playing',score:0,message:'First to five. Aim with the edge of your paddle.',player:0,cpu:0,rally:0,level:1,py:134,ay:134,ball:{x:240,y:160,vx:-170,vy:60},serve:.8,time:0,flash:0,trail:[]};
 function serve(dir){s.ball={x:240,y:100+api.rng()*120,vx:dir*(175+Math.min(70,s.player*12)),vy:(api.rng()-.5)*140};s.serve=.8;s.rally=0;s.trail=[];}
 function point(player){if(player){s.player++;s.score+=100;api.sound('score');}else{s.cpu++;api.sound('lose');}s.flash=.25;s.level=1+s.player;s.message=player?'Point! Find another angle.':'Opponent scores. Next serve incoming.';if(s.player>=5||s.cpu>=5){s.status=s.player>=5?'won':'lost';s.message=s.status==='won'?'MATCH WON. Sharp angles, steady hands.':'MATCH OVER. Try meeting the ball earlier.';if(s.status==='won')s.score+=500;}else serve(player?-1:1);}
 return {state:s,update(dt,i){
  if(s.status!=='playing')return;s.time+=dt;s.flash=Math.max(0,s.flash-dt);
  let dy=(i.down('down')?1:0)-(i.down('up')?1:0);
  if(dy)s.py+=dy*270*dt;else if(i.pointer.active)s.py+=clamp(i.pointer.y-26-s.py,-320*dt,320*dt);s.py=clamp(s.py,24,244);
  const target=s.ball.vx>0?s.ball.y-26+Math.sin(s.time*2.2)*22:134;
  s.ay+=clamp(target-s.ay,-(112+s.player*12)*dt,(112+s.player*12)*dt);s.ay=clamp(s.ay,24,244);
  if(s.serve>0){s.serve-=dt;return;}
  const b=s.ball,oldx=b.x;b.x+=b.vx*dt;b.y+=b.vy*dt;
  if(b.y<28){b.y=28;b.vy=Math.abs(b.vy);api.sound('hit');}if(b.y>292){b.y=292;b.vy=-Math.abs(b.vy);api.sound('hit');}
  const hit=(y,dir)=>{s.rally++;const speed=Math.min(350,180+s.rally*17+s.player*9),angle=clamp((b.y-(y+26))/30,-1,1)*1.05;b.vx=Math.cos(angle)*speed*dir;b.vy=Math.sin(angle)*speed;b.x=dir>0?40:440;s.score+=dir>0?5:0;api.sound('hit');};
  if(b.vx<0&&oldx>=40&&b.x<=40&&b.y>=s.py-4&&b.y<=s.py+56)hit(s.py,1);
  if(b.vx>0&&oldx<=440&&b.x>=440&&b.y>=s.ay-4&&b.y<=s.ay+56)hit(s.ay,-1);
  if(b.x<-8){point(false);return;}else if(b.x>488){point(true);return;}
  s.trail.push({x:b.x,y:b.y});if(s.trail.length>7)s.trail.shift();
 },draw(c){
  c.fillStyle='#152536';c.fillRect(0,0,480,320);c.fillStyle='#243d4b';for(let y=28;y<292;y+=16)c.fillRect(239,y,2,7);c.fillStyle='#fff0cf';c.fillRect(24,20,432,3);c.fillRect(24,297,432,3);
  c.font='bold 24px monospace';c.textAlign='center';c.fillText(s.player,180,54);c.fillStyle='#fa8068';c.fillText(s.cpu,300,54);c.font='10px monospace';c.fillStyle='#9aafb4';c.fillText('YOU',180,68);c.fillText('CPU',300,68);c.fillText('FIRST TO 5',240,312);
  c.fillStyle='#61d5c8';c.fillRect(27,Math.round(s.py),10,52);c.fillStyle='#b7f5dc';c.fillRect(27,Math.round(s.py),3,52);c.fillStyle='#fa8068';c.fillRect(443,Math.round(s.ay),10,52);
  if(!s.serve){s.trail.forEach((p,n)=>{c.fillStyle=n<4?'#37525b':'#607875';c.fillRect(Math.round(p.x)-2,Math.round(p.y)-2,4,4);});c.fillStyle='#ffc56a';c.fillRect(Math.round(s.ball.x)-4,Math.round(s.ball.y)-4,8,8);}else{c.fillStyle='#ffc56a';c.font='bold 12px monospace';c.fillText('READY...',240,163);}
  if(s.flash){c.strokeStyle='#ffc56a';c.lineWidth=3;c.strokeRect(4,4,472,312);}c.textAlign='left';
 }};
}
