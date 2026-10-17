const CELL=24,X0=24,Y0=54,WIDTH=432;
const GOALS=[72,192,312,432];
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
export function createGame(api){
 const sound=n=>api.sound?.(n);
 const state={status:'playing',score:0,message:'Hop through traffic, ride logs, and fill all four home bays.',level:1,lives:4,homes:[false,false,false,false],delivered:0,player:{x:240,row:9},bestRow:9,timer:45,time:0,respawn:0,hopCooldown:0,hopFlash:0,lanes:[],roundFlash:0};
 function lanes(){
  const scale=1+(state.level-1)*.22;
  state.lanes=[
   {row:1,type:'log',speed:27*scale,width:108,spacing:144,phase:api.rng()*100},
   {row:2,type:'log',speed:-34*scale,width:114,spacing:156,phase:api.rng()*100},
   {row:3,type:'log',speed:23*scale,width:120,spacing:168,phase:api.rng()*100},
   {row:5,type:'car',speed:-63*scale,width:40,spacing:132,phase:api.rng()*100},
   {row:6,type:'car',speed:47*scale,width:57,spacing:162,phase:api.rng()*100},
   {row:7,type:'car',speed:-79*scale,width:33,spacing:126,phase:api.rng()*100},
   {row:8,type:'car',speed:53*scale,width:43,spacing:150,phase:api.rng()*100}
  ];
 }
 function pieces(lane){
  const offset=((lane.phase+lane.speed*state.time)%lane.spacing+lane.spacing)%lane.spacing;
  const result=[];
  for(let x=X0+offset-lane.spacing;x<X0+WIDTH;x+=lane.spacing)result.push({x,y:Y0+lane.row*CELL,w:lane.width,h:CELL});
  return result;
 }
 function reset(delay=.55){
  state.player={x:240,row:9};state.bestRow=9;state.timer=Math.max(31,45-(state.level-1)*5);
  state.respawn=delay;state.hopCooldown=0;state.hopFlash=0;
 }
 function crash(reason){
  if(state.respawn>0||state.status!=='playing')return;
  state.lives--;sound('lose');
  state.message=reason+' '+state.lives+' lives left.';
  if(state.lives<=0){state.status='lost';state.message=reason+' Run over. '+state.delivered+' friends reached home.';}
  else reset(.7);
 }
 function delivery(){
  const index=GOALS.findIndex(x=>Math.abs(state.player.x-x)<=14);
  if(index<0){crash('Land in a lit home bay, not the hedge.');return;}
  if(state.homes[index]){crash('That bay is full. Find a glowing empty bay.');return;}
  state.homes[index]=true;state.delivered++;
  state.score+=150+Math.floor(state.timer)*2;state.message='Home safe! '+state.homes.filter(Boolean).length+' of four bays filled.';sound('score');
  if(state.homes.every(Boolean)){
   state.score+=400*state.level;state.roundFlash=1.3;
   if(state.level===3){state.status='won';state.message='All 12 friends are home! Three crossings complete.';sound('win');return;}
   state.level++;state.homes=[false,false,false,false];lanes();state.message='Crossing '+state.level+': traffic and river currents are faster.';sound('win');
  }
  reset(.65);
 }
 function hop(dx,dy){
  const p=state.player;
  p.x=clamp(p.x+dx*CELL,X0+12,X0+WIDTH-12);p.row=clamp(p.row+dy,0,9);
  state.hopCooldown=.16;state.hopFlash=.11;
  if(p.row<state.bestRow){state.score+=10;state.bestRow=p.row;}
  sound('move');if(p.row===0)delivery();
 }
 function update(dt,input){
  if(state.status!=='playing')return;
  state.time+=dt;state.hopCooldown=Math.max(0,state.hopCooldown-dt);state.hopFlash=Math.max(0,state.hopFlash-dt);state.roundFlash=Math.max(0,state.roundFlash-dt);
  if(state.respawn>0){state.respawn=Math.max(0,state.respawn-dt);return;}
  state.timer-=dt;if(state.timer<=0){state.timer=0;crash('The crossing timer ran out.');return;}
  const p=state.player,carried=state.lanes.find(l=>l.row===p.row&&l.type==='log');
  if(carried)p.x+=carried.speed*dt;
  if(state.hopCooldown===0){
   let dx=0,dy=0;
   if(input.pressed('up')||input.down('up'))dy=-1;
   else if(input.pressed('down')||input.down('down'))dy=1;
   else if(input.pressed('left')||input.down('left'))dx=-1;
   else if(input.pressed('right')||input.down('right'))dx=1;
   else if(input.pressed('action'))dy=-1;
   else if(input.pointer?.active&&input.pointer.pressed){
    const px=input.pointer.x-p.x,py=input.pointer.y-(Y0+p.row*CELL+12);
    if(Math.abs(py)>=Math.abs(px))dy=py<0?-1:1;else dx=px<0?-1:1;
   }
   if(dx||dy)hop(dx,dy);
  }
  if(state.respawn>0||state.status!=='playing')return;
  if(p.x<X0+7||p.x>X0+WIDTH-7){crash('The current carried you off the bank.');return;}
  const lane=state.lanes.find(l=>l.row===p.row);
  if(!lane)return;
  if(lane.type==='log'){
   if(!pieces(lane).some(log=>p.x-6>=log.x&&p.x+6<=log.x+log.w))crash('Splash! Aim for the wooden rafts.');
  }else{
   if(pieces(lane).some(car=>p.x+7>car.x+2&&p.x-7<car.x+car.w-2))crash('Traffic bump! Wait for a gap.');
  }
 }
 function draw(c){
  c.imageSmoothingEnabled=false;c.fillStyle='#152536';c.fillRect(0,0,480,320);
  c.fillStyle='#fff0cf';c.font='bold 13px monospace';c.textAlign='left';c.fillText('HOPWAY',24,20);
  c.fillStyle='#61d5c8';c.font='10px monospace';c.fillText('CROSSING '+state.level+' / 3  LIVES '+state.lives,24,37);
  c.textAlign='right';c.fillStyle='#ffc56a';c.font='bold 15px monospace';c.fillText(String(state.score).padStart(5,'0'),456,21);c.font='10px monospace';c.fillText('TIME '+Math.ceil(state.timer),456,38);
  for(let row=0;row<10;row++){
   c.fillStyle=row===0||row===4||row===9?'#365c4c':row<4?'#244c61':'#283848';
   c.fillRect(X0,Y0+row*CELL,WIDTH,CELL);
   if(row<4&&row>0){c.fillStyle='#3c6f7d';for(let x=X0+6;x<X0+WIDTH;x+=30)c.fillRect(x,Y0+row*CELL+18,13,2);}
   if(row>4&&row<9){c.fillStyle='#718087';for(let x=X0;x<X0+WIDTH;x+=32)c.fillRect(x,Y0+row*CELL+23,16,1);}
   if(row===4||row===9){c.fillStyle='#74a17a';for(let x=X0+8;x<X0+WIDTH;x+=24)c.fillRect(x,Y0+row*CELL+6,2,3);}
  }
  c.save();c.beginPath();c.rect(X0,Y0,WIDTH,240);c.clip();
  for(const lane of state.lanes)for(const item of pieces(lane)){
   const x=Math.round(item.x),y=item.y;
   if(lane.type==='log'){
    c.fillStyle='#6f4f3d';c.fillRect(x,y+3,item.w,18);c.fillStyle='#bb8f59';c.fillRect(x+2,y+3,item.w-4,14);
    c.fillStyle='#e3b878';c.fillRect(x+4,y+5,item.w-8,2);c.fillStyle='#6f4f3d';for(let n=10;n<item.w;n+=25)c.fillRect(x+n,y+10,13,2);
   }else{
    c.fillStyle=lane.row%2?'#fa8068':'#ffc56a';c.fillRect(x,y+5,item.w,14);
    c.fillStyle='#0d1b27';c.fillRect(x+5,y+3,8,3);c.fillRect(x+5,y+19,8,3);c.fillRect(x+item.w-13,y+3,8,3);c.fillRect(x+item.w-13,y+19,8,3);
    c.fillStyle='#a8e1d5';c.fillRect(x+(lane.speed>0?item.w-13:5),y+7,8,10);
    c.fillStyle='#fff0cf';c.fillRect(x+(lane.speed>0?item.w-3:1),y+6,2,3);c.fillRect(x+(lane.speed>0?item.w-3:1),y+16,2,3);
   }
  }
  for(let i=0;i<GOALS.length;i++){
   const x=GOALS[i];c.fillStyle=state.homes[i]?'#244c3d':'#ffc56a';c.fillRect(x-14,Y0+2,28,21);c.fillStyle='#152536';c.fillRect(x-11,Y0+4,22,17);
   if(state.homes[i]){c.fillStyle='#61d5c8';c.fillRect(x-7,Y0+8,14,11);c.fillStyle='#fff0cf';c.fillRect(x-5,Y0+6,3,4);c.fillRect(x+2,Y0+6,3,4);}
   else{c.fillStyle='#ffc56a';c.fillRect(x-3,Y0+8,6,9);c.fillRect(x-5,Y0+11,10,3);}
  }
  if(state.respawn===0||Math.floor(state.time*12)%2){
   const x=Math.round(state.player.x),y=Y0+state.player.row*CELL+(state.hopFlash>0?3:6);
   c.fillStyle='#0d1b27';c.fillRect(x-8,y+12,16,3);c.fillStyle='#61d5c8';c.fillRect(x-7,y+3,14,11);c.fillRect(x-10,y+10,4,4);c.fillRect(x+6,y+10,4,4);
   c.fillStyle='#fff0cf';c.fillRect(x-6,y,4,5);c.fillRect(x+2,y,4,5);c.fillStyle='#152536';c.fillRect(x-5,y+1,2,2);c.fillRect(x+3,y+1,2,2);
  }
  c.restore();
  c.fillStyle='#ffc56a';c.fillRect(X0,300,WIDTH*clamp(state.timer/Math.max(31,45-(state.level-1)*5),0,1),3);
  c.font='9px monospace';c.textAlign='center';c.fillStyle='#afc4cc';c.fillText('D-PAD / ARROWS HOP • WAIT FOR GAPS • RIDE THE RAFTS',240,316);c.textAlign='left';
 }
 lanes();return{state,update,draw};
}
