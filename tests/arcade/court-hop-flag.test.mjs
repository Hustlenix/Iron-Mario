import test from 'node:test';
import assert from 'node:assert/strict';
import {createGame as court} from '../../onlyeducation/arcade/games/sidecourt.js';
import {createGame as hop} from '../../onlyeducation/arcade/games/hopway.js';
import {createGame as flag} from '../../onlyeducation/arcade/games/flag-run.js';
const input=(held=[],pressed=[],pointer={})=>({down:a=>held.includes(a),pressed:a=>pressed.includes(a),pointer:{active:false,down:false,pressed:false,...pointer}});
const idle=input();
function make(factory,seed=73){const sounds=[];return {...factory({rng:()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296},sound:s=>sounds.push(s)}),sounds};}
function tick(g,n=1,i=idle){for(let k=0;k<n;k++)g.update(1/60,i);}
function courtLive(g,b={}){Object.assign(g.state,{serveReady:false,serveDelay:0,lastHit:'cpu',bounces:0,bounceSide:null});Object.assign(g.state.ball,{x:110,y:210,vx:-90,vy:30,...b});}
function step(g,dir){g.state.moveClock=0;g.update(1/60,input([dir],[dir]));}

test('all three Wave B modules reproduce seeded input sequences',()=>{
 for(const factory of [court,hop,flag]){
  const a=make(factory),b=make(factory);
  for(let n=0;n<300;n++){const i=input(n%90<45?['right']:['left'],n%43===0?['action']:[]);a.update(1/60,i);b.update(1/60,i);}
  assert.deepEqual(a.state,b.state);
 }
});

test('Sidecourt player serve requires action and starts a real gravity trajectory',()=>{
 const g=make(court);tick(g,60);assert.equal(g.state.serveReady,true);
 tick(g,1,input(['action'],['action']));assert.equal(g.state.serveReady,false);
 const y=g.state.ball.y,vy=g.state.ball.vy;tick(g,6);
 assert(g.state.ball.y<y);assert(g.state.ball.vy>vy);
});
test('Sidecourt movement clamps to the player half; hovering cannot move it',()=>{
 const g=make(court);g.update(2,input(['right']));assert.equal(g.state.playerX,213);
 g.update(2,input(['left']));assert.equal(g.state.playerX,32);
 g.update(.1,input([],[],{active:true,x:200}));assert.equal(g.state.playerX,32);
 g.update(.1,input([],[],{active:true,down:true,x:200}));assert(g.state.playerX>32);
});
test('Sidecourt reachable swing changes velocity and scores a return',()=>{
 const g=make(court);courtLive(g);g.update(1/60,input(['action'],['action']));
 assert.equal(g.state.lastHit,'player');assert(g.state.ball.vx>0);assert(g.state.ball.vy<0);assert.equal(g.state.score,10);
 const hits=g.state.hits;tick(g,25,input(['action']));assert.equal(g.state.hits,hits,'same player cannot hit twice in succession');
});
test('Sidecourt lob and drive produce different trajectories',()=>{
 const a=make(court),b=make(court);courtLive(a);courtLive(b);
 a.update(1/60,input(['action'],['up']));b.update(1/60,input(['action'],['down']));
 assert(a.state.ball.vx<b.state.ball.vx);assert(a.state.ball.vy<b.state.ball.vy);
});
test('Sidecourt unreachable swing misses rather than teleporting the ball',()=>{
 const g=make(court);courtLive(g,{x:205,y:100});g.update(1/60,input(['action'],['action']));
 assert.equal(g.state.lastHit,'cpu');assert.equal(g.state.score,0);assert.equal(g.state.hits,0);
});
test('Sidecourt net collision reflects a low shot',()=>{
 const g=make(court);courtLive(g,{x:230,y:240,vx:200,vy:0});g.state.lastHit='player';
 g.update(.05,idle);assert(g.state.ball.vx<0);assert(g.state.ball.x<240);
});
test('Sidecourt first ground bounce is legal but second awards opponent point',()=>{
 const g=make(court);courtLive(g,{x:100,y:273,vx:0,vy:100});g.update(.03,idle);
 assert.equal(g.state.bounces,1);assert.equal(g.state.cpuPoints,0);assert(g.state.ball.vy<0);
 Object.assign(g.state.ball,{y:273,vy:100});g.update(.03,idle);
 assert.equal(g.state.cpuPoints,1);assert.equal(g.state.serveReady,true);
});
test('Sidecourt AI returns reachable balls and increasingly pursues the projected landing',()=>{
 const g=make(court);courtLive(g,{x:350,y:190,vx:160,vy:70});g.state.lastHit='player';g.state.cpuX=365;g.state.cpuCooldown=0;
 tick(g,1);assert.equal(g.state.lastHit,'cpu');assert(g.state.ball.vx<0);
});
test('Sidecourt five-point win and loss freeze final state',()=>{
 for(const winning of [true,false]){
  const g=make(court);g.state[winning?'playerPoints':'cpuPoints']=4;
  courtLive(g,{x:winning?400:100,y:273,vx:0,vy:100});g.state.bounceSide=winning?'cpu':'player';g.state.bounces=1;g.state.lastHit=winning?'cpu':'player';g.state.cpuCooldown=1;
  g.update(.03,idle);assert.equal(g.state.status,winning?'won':'lost');
  const saved=structuredClone(g.state);tick(g,20,input(['action','right']));assert.deepEqual(g.state,saved);
 }
});

test('Hopway each forward row scores once and holding controls obeys hop cooldown',()=>{
 const g=make(hop);g.state.lanes=[];tick(g,1,input(['up'],['up']));
 assert.equal(g.state.player.row,8);assert.equal(g.state.score,10);
 tick(g,1,input(['up']));assert.equal(g.state.player.row,8);
 g.state.hopCooldown=0;tick(g,1,input(['down']));g.state.hopCooldown=0;tick(g,1,input(['up']));
 assert.equal(g.state.score,10);
});
test('Hopway standing on a log carries the player with its current',()=>{
 const g=make(hop);g.state.player={x:100,row:2};g.state.lanes=[{row:2,type:'log',speed:30,width:400,spacing:600,phase:0}];
 g.update(.1,idle);assert.equal(g.state.lives,4);assert.equal(g.state.player.x,103);
});
test('Hopway water gaps and traffic cause damage with a protected respawn',()=>{
 for(const lane of [{row:3,type:'log',speed:0,width:20,spacing:500,phase:0},{row:3,type:'car',speed:0,width:300,spacing:500,phase:0}]){
  const g=make(hop);g.state.player={x:100,row:3};g.state.lanes=[lane];tick(g);
  assert.equal(g.state.lives,3);assert.equal(g.state.player.row,9);assert(g.state.respawn>0);tick(g,10);assert.equal(g.state.lives,3);
 }
});
test('Hopway current carrying the player out of bounds costs a life',()=>{
 const g=make(hop);g.state.player={x:449,row:2};g.state.lanes=[{row:2,type:'log',speed:60,width:600,spacing:700,phase:0}];
 g.update(.1,idle);assert.equal(g.state.lives,3);
});
test('Hopway a goal accepts only an empty home bay',()=>{
 const g=make(hop);g.state.lanes=[];g.state.player={x:72,row:1};tick(g,1,input(['up']));
 assert.equal(g.state.homes[0],true);assert.equal(g.state.delivered,1);assert(g.state.score>=150);
 g.state.respawn=0;g.state.hopCooldown=0;g.state.player={x:72,row:1};tick(g,1,input(['up']));
 assert.equal(g.state.lives,3);assert.equal(g.state.delivered,1);
});
test('Hopway four homes progress to faster lanes, twelve homes complete the run',()=>{
 const g=make(hop),initialSpeed=Math.abs(g.state.lanes[0].speed);
 for(let round=1;round<=3;round++){
  for(const x of [72,192,312,432]){g.state.player={x,row:1};g.state.respawn=0;g.state.hopCooldown=0;tick(g,1,input(['up']));}
  if(round<3){assert.equal(g.state.level,round+1);assert(Math.abs(g.state.lanes[0].speed)>initialSpeed);}
 }
 assert.equal(g.state.delivered,12);assert.equal(g.state.status,'won');
});
test('Hopway timer expiration with the final life causes a frozen loss',()=>{
 const g=make(hop);g.state.lives=1;g.state.timer=.001;tick(g);assert.equal(g.state.status,'lost');
 const save=structuredClone(g.state);tick(g,20,input(['up']));assert.deepEqual(g.state,save);
});
test('Hopway a canvas tap selects the direction toward the tap',()=>{
 const g=make(hop);g.state.lanes=[];tick(g,1,input([],[],{active:true,pressed:true,x:240,y:100}));
 assert.equal(g.state.player.row,8);
});

test('Flag Run map keeps every flag, fuel can, enemy and exit reachable',()=>{
 const g=make(flag);
 for(let level=1;level<=3;level++){
  const s=g.state,seen=new Set(['1,11']),queue=[{x:1,y:11}];
  for(let at=0;at<queue.length;at++)for(const[dx,dy]of [[1,0],[-1,0],[0,1],[0,-1]]){
   const x=queue[at].x+dx,y=queue[at].y+dy,k=x+','+y;
   if(s.grid[y]?.[x]===0&&!seen.has(k)){seen.add(k);queue.push({x,y});}
  }
  for(const p of [...s.flags,...s.fuelCans,...s.enemies,s.exit])assert(seen.has(p.x+','+p.y));
  if(level<3){s.flags.forEach(f=>f.taken=true);s.collected=6;s.car={x:2,y:11,dir:'left'};step(g,'left');assert.equal(s.level,level+1);}
 }
});
test('Flag Run walls block the car while road movement consumes real fuel',()=>{
 const g=make(flag),fuel=g.state.fuel;step(g,'left');assert.equal(g.state.car.x,1);
 step(g,'up');assert.equal(g.state.car.y,10);assert(g.state.fuel<fuel);
});
test('Flag Run flags are collected once and fuel cans refill within cap',()=>{
 const g=make(flag);g.state.enemies=[];g.state.car={x:1,y:2,dir:'up'};step(g,'up');
 assert.equal(g.state.collected,1);assert.equal(g.state.score,100);
 step(g,'down');step(g,'up');assert.equal(g.state.score,100);
 g.state.fuel=50;g.state.car={x:1,y:7,dir:'up'};step(g,'up');assert(g.state.fuel>79&&g.state.fuel<=80);assert.equal(g.state.score,125);
});
test('Flag Run smoke has a fuel cost, cooldown, and actually stuns pursuing cars',()=>{
 const g=make(flag);g.state.invulnerable=0;g.state.enemies=[{x:1,y:11,dir:'up',stunned:0,id:0,clock:0}];
 tick(g,1,input([],['action']));assert.equal(g.state.lives,3);assert(g.state.fuel<89);assert.equal(g.state.smoke.length,1);assert(g.state.enemies[0].stunned>0);
 tick(g,1,input([],['action']));assert.equal(g.state.smoke.length,1);
 const p={x:g.state.enemies[0].x,y:g.state.enemies[0].y};tick(g,40);assert.deepEqual({x:g.state.enemies[0].x,y:g.state.enemies[0].y},p);
});
test('Flag Run BFS pursuit approaches the car without crossing buildings',()=>{
 const g=make(flag);g.state.car={x:1,y:1,dir:'up'};g.state.enemies=[{x:7,y:1,dir:'left',stunned:0,id:0,clock:0}];
 tick(g);assert.equal(g.state.enemies[0].x,6);assert.equal(g.state.grid[g.state.enemies[0].y][g.state.enemies[0].x],0);
});
test('Flag Run collision costs one life and respawn preserves collected flags',()=>{
 const g=make(flag);g.state.invulnerable=0;g.state.flags[0].taken=true;g.state.collected=1;g.state.enemies=[{x:1,y:10,dir:'down',stunned:0,id:0,clock:1}];
 step(g,'up');assert.equal(g.state.lives,2);assert.equal(g.state.car.y,11);assert(g.state.invulnerable>0);assert.equal(g.state.collected,1);assert(g.state.flags[0].taken);
});
test('Flag Run empty fuel ends final life and terminal state stays frozen',()=>{
 const g=make(flag);g.state.lives=1;g.state.fuel=.001;tick(g);assert.equal(g.state.status,'lost');
 const saved=structuredClone(g.state);tick(g,50,input(['right'],['action']));assert.deepEqual(g.state,saved);
});
test('Flag Run must return to exit after six flags and wins only after third district',()=>{
 const g=make(flag);
 for(let round=1;round<=3;round++){
  g.state.enemies=[];g.state.flags.forEach(f=>f.taken=true);g.state.collected=6;g.state.totalFlags=round*6;g.state.car={x:2,y:11,dir:'left'};
  assert.equal(g.state.status,'playing');step(g,'left');
  assert.equal(g.state.status,round===3?'won':'playing');
 }
 assert(g.state.score>0);assert.equal(g.state.totalFlags,18);
});
