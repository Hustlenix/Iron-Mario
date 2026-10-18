import test from 'node:test';
import assert from 'node:assert/strict';
import {createGame,RUNNER} from '../../onlyeducation/arcade/games/dino-dash.js';
import {random} from '../../onlyeducation/arcade/engine/math.js';
const controls=(pressed=[],held=[],pointer={})=>({pressed:a=>pressed.includes(a),down:a=>held.includes(a),pointer:{active:false,pressed:false,down:false,x:0,y:0,...pointer}});
const idle=controls();
const game=(seed=67)=>createGame({rng:random(seed),sound(){},sprite(){}});
test('Dino Dash keyboard and quick pointer tap start the same jump; no midair jump',()=>{
 const a=game(),b=game();a.update(1/60,controls(['action']));b.update(1/60,controls([],[],{active:true,pressed:true}));
 assert.equal(a.state.grounded,false);assert.ok(a.state.bottom<RUNNER.floor);assert.equal(a.state.bottom,b.state.bottom);
 a.update(1/60,controls(['action']));b.update(1/60,idle);assert.equal(a.state.vy,b.state.vy);
});
test('Dino Dash jump returns to the floor and a near-landing tap is buffered',()=>{
 const g=game();g.update(1/60,controls(['up']));
 let high=g.state.bottom;for(let i=0;i<60;i++){g.update(1/60,idle);high=Math.min(high,g.state.bottom);}
 assert.ok(high<185);assert.equal(g.state.bottom,RUNNER.floor);assert.equal(g.state.grounded,true);
 Object.assign(g.state,{bottom:259,vy:120,grounded:false});g.update(1/60,controls(['action']));
 assert.equal(g.state.grounded,false);assert.ok(g.state.vy<0);
});
test('Dino Dash low flyers hit a standing dinosaur and clear a held duck',()=>{
 for(const duck of [false,true]){
  const g=game();g.state.obstacles=[{kind:'flyer',x:100,y:214,w:36,h:18,passed:false}];
  g.update(1/60,controls([],duck?['secondary']:[]));assert.equal(g.state.status,duck?'playing':'lost');
 }
 const g=game();g.update(1/60,controls(['action'],['down']));assert.equal(g.state.ducking,false);assert.equal(g.state.grounded,false);
});
test('Dino Dash collision ends once, freezes the run, and never awards a passed-hazard bonus',()=>{
 const g=game();g.state.obstacles=[{kind:'thorn',x:90,y:232,w:22,h:28,passed:false}];g.update(1/60,idle);
 assert.equal(g.state.status,'lost');assert.equal(g.state.cleared,0);const s=structuredClone(g.state);
 for(let i=0;i<60;i++)g.update(1/60,controls(['action'],['secondary']));assert.deepEqual(g.state,s);
});
test('Dino Dash invalid delta is ignored and speed has a finite upper bound',()=>{
 const g=game(),before=structuredClone(g.state);for(const dt of [NaN,Infinity,-1,0])g.update(dt,idle);assert.deepEqual(g.state,before);
 g.state.elapsed=10000;g.state.spawnIn=100;g.update(.1,idle);assert.equal(g.state.speed,RUNNER.maxSpeed);assert.ok(Number.isFinite(g.state.score));
});
test('Dino Dash seed and input stream reproduce positions, hazards and score',()=>{
 const a=game(6),b=game(6);
 for(let n=0;n<1500;n++){const i=controls(n%47===0?['action']:[],n%170>130?['secondary']:[]);a.update(1/60,i);b.update(1/60,i);}
 assert.deepEqual(a.state,b.state);
});
test('Dino Dash authored jump arc and spawn gaps permit 30 hazards across 24 seeds',()=>{
 let flyers=0;
 for(let seed=1;seed<=24;seed++){
  const g=game(seed);
  for(let tick=0;tick<6500&&g.state.cleared<30&&g.state.status==='playing';tick++){
   const o=g.state.obstacles.find(o=>!o.passed),near=o&&o.x<110+g.state.speed*.22;
   const duck=o?.kind==='flyer'&&o.x<260;
   g.update(1/60,controls(o?.kind==='thorn'&&near&&g.state.grounded?['action']:[],duck?['secondary']:[]));
   if(duck)flyers++;assert.ok(g.state.obstacles.length<=4,'offscreen hazards must be culled');
  }
  assert.equal(g.state.status,'playing','seed '+seed+' must have a fair path');assert.equal(g.state.cleared,30,'seed '+seed);assert.ok(g.state.score>750);
 }
 assert.ok(flyers>0);
});

test('Dino Dash opens with three small separated ground hazards before flyers',()=>{const g=game();g.update(.1,idle);assert.equal(g.state.obstacles.length,0);assert.ok(g.state.spawnIn>2);const sizes=[];let last=0;for(let n=0;n<700&&sizes.length<3;n++){g.state.spawnIn=0;g.update(1/60,idle);if(g.state.spawned>last){const o=g.state.obstacles.at(-1);sizes.push([o.w,o.h,o.kind]);assert.ok(g.state.spawnIn>=1.78);last=g.state.spawned;}g.state.obstacles=[];}assert.deepEqual(sizes,[[18,20,'thorn'],[22,24,'thorn'],[26,28,'thorn']]);});
