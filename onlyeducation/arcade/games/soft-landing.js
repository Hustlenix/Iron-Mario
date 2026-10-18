import {PAL,clamp,text,frame,banner} from '../engine/presentation.js';
export const PADS=[{x:240,w:120},{x:108,w:100},{x:370,w:84}];
export function terrainY(x,level){const p=PADS[level-1];if(Math.abs(x-p.x)<=p.w/2+8)return 260;return 244-12*Math.sin(x*.035)-7*Math.cos(x*.071);}
export function createGame(api){
 const s={status:'playing',score:0,level:1,lives:3,phase:'flight',x:240,y:68,vx:0,vy:0,angle:0,fuel:100,time:0,thrust:false,message:'Level the feet. Land below 28 vertical / 20 sideways.'};
 const reset=()=>{Object.assign(s,{x:240,y:68,vx:0,vy:0,angle:0,fuel:100,phase:'flight',thrust:false});};
 function crash(){s.lives--;s.thrust=false;api.sound('hit');s.message='Hard landing. Slow down and keep the feet level.';if(s.lives<=0)s.status='lost';else s.phase='crashed';}
 function update(dt,i){if(s.status!=='playing'||!Number.isFinite(dt)||dt<=0)return;dt=Math.min(dt,.05);
  if(s.phase!=='flight'){if(i.pressed('action')||i.pointer.pressed){if(s.phase==='landed'){s.level++;reset();}else reset();}return;}
  s.time+=dt;s.angle=clamp(s.angle+((i.down('right')?1:0)-(i.down('left')?1:0))*1.3*dt,-.65,.65);
  if(i.down('down')||i.down('secondary'))s.angle*=Math.exp(-7*dt);
  s.thrust=s.fuel>0&&(i.down('up')||i.down('action')||i.pointer.down);
  if(s.thrust){s.vx+=Math.sin(s.angle)*72*dt;s.vy-=Math.cos(s.angle)*72*dt;s.fuel=Math.max(0,s.fuel-5*dt);}
  s.vy+=28*dt;s.x+=s.vx*dt;s.y+=s.vy*dt;
  if(s.y<44){s.y=44;s.vy=Math.max(0,s.vy);}if(s.x<12||s.x>468){s.x=clamp(s.x,12,468);s.vx*=-.3;}
  const p=PADS[s.level-1];const floor=Math.min(terrainY(s.x-10,s.level),terrainY(s.x+10,s.level));
  if(s.y+12>=floor){s.y=floor-12;s.thrust=false;
   if(Math.abs(s.x-p.x)+10<=p.w/2&&s.vy>=0&&s.vy<=28&&Math.abs(s.vx)<=20&&Math.abs(s.angle)<=.16){s.score+=500+Math.floor(s.fuel)*5;s.message='Soft touchdown! Fuel saved: '+Math.floor(s.fuel)+'%.';api.sound('win');if(s.level===3){s.status='won';s.message='Three pads reached. Precision pilot!';}else s.phase='landed';}
   else crash();
  }
 }
 function draw(c){frame(c,'SOFT LANDING',s.score,'← → TILT  ·  ↑ / ACTION THRUST  ·  ↓ LEVEL FEET');
  for(let n=0;n<34;n++){c.fillStyle=n%3?PAL.dim:PAL.paper;c.fillRect(20+(n*79)%440,45+(n*31)%145,2,2);}
  c.fillStyle='#344457';c.beginPath();c.moveTo(0,296);for(let x=0;x<=480;x+=4)c.lineTo(x,terrainY(x,s.level));c.lineTo(480,296);c.fill();
  const p=PADS[s.level-1];c.fillStyle=PAL.teal;c.fillRect(p.x-p.w/2,260,p.w,5);text(c,'PAD '+s.level,p.x,284,11,PAL.teal,'center');
  c.save();c.translate(Math.round(s.x),Math.round(s.y));c.rotate(s.angle);c.fillStyle=PAL.gold;c.fillRect(-9,-8,18,14);c.fillStyle=PAL.paper;c.fillRect(-5,-6,10,5);c.fillStyle=PAL.teal;c.fillRect(-12,6,4,7);c.fillRect(8,6,4,7);c.fillRect(-14,11,8,3);c.fillRect(6,11,8,3);if(s.thrust){c.fillStyle=PAL.coral;c.fillRect(-4,8,8,10+Math.floor(s.time*20)%5);}c.restore();
  text(c,'PAD '+s.level+'/3  ·  HULL '+s.lives,12,49,10);text(c,'FUEL '+Math.floor(s.fuel)+'%',468,49,10,s.fuel<20?PAL.coral:PAL.gold,'right');
  text(c,'DOWN '+s.vy.toFixed(0)+' / 28',12,69,10,s.vy>28?PAL.coral:PAL.teal);text(c,'SIDE '+Math.abs(s.vx).toFixed(0)+' / 20',12,85,10,Math.abs(s.vx)>20?PAL.coral:PAL.teal);text(c,Math.abs(s.angle)<=.16?'FEET LEVEL':'LEVEL THE FEET',12,101,10,Math.abs(s.angle)<=.16?PAL.teal:PAL.coral);
  if(s.phase==='landed'&&s.status==='playing')banner(c,'SOFT TOUCHDOWN','ACTION / TAP → NEXT PAD',PAL.teal);
  if(s.phase==='crashed')banner(c,'A LITTLE TOO FAST','ACTION / TAP → RETRY THIS PAD',PAL.coral);
 }
 return {state:s,update,draw};
}
