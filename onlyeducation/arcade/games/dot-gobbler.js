import {PAL,text,frame,banner,bot} from '../engine/presentation.js';
export const DIRS={left:[-1,0],right:[1,0],up:[0,-1],down:[0,1]};
export function dotMaze(){return Array.from({length:11},(_,y)=>Array.from({length:19},(_,x)=>x===0||y===0||x===18||y===10||([4,8,12,16].includes(x)&&![1,5,9].includes(y))?1:0));}
export function mazePath(grid,start,target){const q=[{...start,path:[]}],seen=new Set([start.x+','+start.y]);for(let n=0;n<q.length;n++){const p=q[n];if(p.x===target.x&&p.y===target.y)return p.path;for(const [dir,[dx,dy]] of Object.entries(DIRS)){const x=p.x+dx,y=p.y+dy,k=x+','+y;if(grid[y]?.[x]===0&&!seen.has(k)){seen.add(k);q.push({x,y,path:[...p.path,dir]});}}}return [];}
export function createGame(api){
 const s={status:'playing',score:0,level:1,lives:3,grid:dotMaze(),player:{x:1,y:1},dir:null,wanted:null,dots:[],powers:[],foes:[],clock:0,enemyClock:0,power:0,shield:2.5,time:0,phase:'maze',message:'Collect every dot. Crystals turn the tables for seven seconds.'};
 function resetActors(){s.player={x:1,y:1};s.dir=null;s.wanted=null;s.shield=2.5;s.enemyClock=0;s.foes=[{x:17,y:9,stun:0},{x:17,y:1,stun:0},...(s.level>1?[{x:9,y:9,stun:0}]:[])];}
 function begin(){s.dots=[];s.powers=[{x:1,y:9},{x:17,y:1}];for(let y=1;y<10;y++)for(let x=1;x<18;x++)if(!s.grid[y][x]&&!(x===1&&y===1)&&!s.powers.some(p=>p.x===x&&p.y===y))s.dots.push({x,y});s.power=0;s.phase='maze';s.clock=0;resetActors();}begin();
 const can=d=>d&&s.grid[s.player.y+DIRS[d][1]]?.[s.player.x+DIRS[d][0]]===0;
 function contact(){for(const f of s.foes){if(f.x!==s.player.x||f.y!==s.player.y||f.stun>0)continue;if(s.power>0){s.score+=100;Object.assign(f,{x:17,y:9,stun:3});api.sound('score');}else if(s.shield<=0){s.lives--;api.sound('hit');if(!s.lives){s.status='lost';s.message='The robots caught up. Try a different route.';}else{resetActors();s.message='Dots kept. A fresh start from the entrance.';}break;}}}
 function update(dt,i){if(s.status!=='playing'||!Number.isFinite(dt)||dt<=0)return;dt=Math.min(dt,.05);
  if(s.phase==='clear'){if(i.pressed('action')||i.pointer.pressed){s.level++;begin();}return;}
  s.time+=dt;s.power=Math.max(0,s.power-dt);s.shield=Math.max(0,s.shield-dt);for(const f of s.foes)f.stun=Math.max(0,f.stun-dt);
  for(const d of Object.keys(DIRS))if(i.pressed(d)||i.down(d))s.wanted=d;
  if(i.pointer.down){const dx=i.pointer.x-(12+s.player.x*24+12),dy=i.pointer.y-(32+s.player.y*24+12);if(Math.max(Math.abs(dx),Math.abs(dy))>10)s.wanted=Math.abs(dx)>Math.abs(dy)?(dx>0?'right':'left'):(dy>0?'down':'up');}
  s.clock+=dt;if(s.clock>=.13){s.clock%=.13;if(can(s.wanted))s.dir=s.wanted;if(can(s.dir)){s.player.x+=DIRS[s.dir][0];s.player.y+=DIRS[s.dir][1];}
   const n=s.dots.findIndex(p=>p.x===s.player.x&&p.y===s.player.y);if(n>=0){s.dots.splice(n,1);s.score+=10;api.sound('tick');}
   const power=s.powers.findIndex(p=>p.x===s.player.x&&p.y===s.player.y);if(power>=0){s.powers.splice(power,1);s.power=7;s.score+=50;api.sound('power');s.message='CRYSTAL CHARGED · robots are vulnerable for seven seconds.';}
   contact();
  }
  if(s.status!=='playing')return;
  s.enemyClock+=dt;if(s.enemyClock>=.3){s.enemyClock%=.3;for(const f of s.foes){if(f.stun>0||s.shield>0)continue;const choices=Object.entries(DIRS).filter(([,d])=>s.grid[f.y+d[1]]?.[f.x+d[0]]===0);let d;
    if(s.power>0)d=choices.sort((a,b)=>Math.abs(f.x+b[1][0]-s.player.x)+Math.abs(f.y+b[1][1]-s.player.y)-Math.abs(f.x+a[1][0]-s.player.x)-Math.abs(f.y+a[1][1]-s.player.y))[0]?.[0];
    else d=api.rng()<.22?choices[Math.floor(api.rng()*choices.length)]?.[0]:mazePath(s.grid,f,s.player)[0];if(d){f.x+=DIRS[d][0];f.y+=DIRS[d][1];}}
   contact();}
  if(s.status==='playing'&&!s.dots.length&&!s.powers.length){s.score+=500;api.sound('win');if(s.level===2){s.status='won';s.message='Both mazes swept clean!';}else{s.phase='clear';s.message='Maze one clear. Action opens the second maze.';}}
 }
 function draw(c){frame(c,'DOT GOBBLER',s.score,'');
  for(let y=0;y<11;y++)for(let x=0;x<19;x++)if(s.grid[y][x]){c.fillStyle='#29485c';c.fillRect(12+x*24,32+y*24,23,23);c.fillStyle='#41667a';c.fillRect(14+x*24,34+y*24,19,3);}
  for(const p of s.dots){c.fillStyle=PAL.paper;c.fillRect(22+p.x*24,42+p.y*24,3,3);}for(const p of s.powers){c.fillStyle=PAL.violet;c.fillRect(19+p.x*24,39+p.y*24,9,9);}
  for(const f of s.foes)if(f.stun<=0)bot(c,24+f.x*24,44+f.y*24,s.power>0?PAL.violet:PAL.coral,16);
  bot(c,24+s.player.x*24,44+s.player.y*24,s.shield>0&&Math.floor(s.time*8)%2?PAL.paper:PAL.gold,16);
  text(c,'MAZE '+s.level+'/2  HULL '+s.lives+'  LEFT '+(s.dots.length+s.powers.length),240,312,10,PAL.paper,'center');if(s.power>0)text(c,'POWER '+Math.ceil(s.power)+'s',240,22,10,PAL.violet,'center');
  if(s.phase==='clear')banner(c,'EVERY DOT COUNTS','ACTION / TAP → NEXT MAZE',PAL.teal);
 }
 return {state:s,update,draw};
}
