import test from 'node:test';
import assert from 'node:assert/strict';
import { CAVERN_GRAPH, makeCavern, cavernWarnings, createGame as createCave } from '../../onlyeducation/arcade/games/dark-cavern.js';
import { HOPS, tileIndex, insidePyramid, pyramidNeighbors, pyramidDistance, createGame as createColor } from '../../onlyeducation/arcade/games/color-steps.js';
const idle={down:()=>false,pressed:()=>false,pointer:{active:false,pressed:false,x:0,y:0}};
const press=action=>({...idle,pressed:key=>key===action,down:key=>key===action});
const tap=(x,y,active=true)=>({...idle,pointer:{active,pressed:true,x,y}});
const random=seed=>()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};
const api=seed=>({rng:random(seed),sound:()=>{}});
function graphPath(from,to,blocked=[]) {
  const queue=[[from]],seen=new Set([from]);
  for(let i=0;i<queue.length;i++){const route=queue[i],at=route.at(-1);if(at===to)return route;for(const next of CAVERN_GRAPH[at])if(!seen.has(next)&&!blocked.includes(next)){seen.add(next);queue.push([...route,next]);}}
  return null;
}
function caveSelect(game,target) {const index=CAVERN_GRAPH[game.state.room].indexOf(target);assert(index>=0);for(let guard=0;game.state.selected!==index&&guard<3;guard++)game.update(1/60,press('right'));}
function caveWalk(game,route) {for(const target of route.slice(1)){caveSelect(game,target);game.update(1/60,press('action'));assert.equal(game.state.room,target);}}
function solveCave(game) {
  const transcript=[],s=game.state,approach=CAVERN_GRAPH[s.monster].map(i=>graphPath(s.room,i,[s.monster,...s.pits])).filter(Boolean).sort((a,b)=>a.length-b.length)[0];
  caveWalk(game,approach);transcript.push(...approach);caveSelect(game,s.monster);game.update(1/60,press('secondary'));game.update(1/60,press('action'));
  for(const treasure of s.treasures.slice()){const path=graphPath(s.room,treasure,s.pits);caveWalk(game,path);transcript.push(...path.slice(1));}
  const home=graphPath(s.room,0,s.pits);caveWalk(game,home);transcript.push(...home.slice(1));return transcript;
}
test('Dark Cavern graph is original connected symmetric twelve-room degree-three map',()=>{
  assert.equal(CAVERN_GRAPH.length,12);
  CAVERN_GRAPH.forEach((edges,i)=>{assert.equal(new Set(edges).size,3);assert(!edges.includes(i));edges.forEach(j=>assert(CAVERN_GRAPH[j].includes(i)));});
  for(let i=0;i<12;i++)assert(graphPath(0,i));
});
test('Dark Cavern seeded generation preserves learning rooms and solvability across 250 seeds',()=>{
  for(let seed=0;seed<250;seed++) {
    const layout=makeCavern(random(seed));assert.deepEqual(layout,makeCavern(random(seed)));
    assert.equal(new Set([layout.monster,...layout.pits,...layout.treasures]).size,5);
    for(const safe of [0,...CAVERN_GRAPH[0]])assert(![layout.monster,...layout.pits].includes(safe));
    for(const treasure of layout.treasures)assert(graphPath(0,treasure,[layout.monster,...layout.pits]));
    assert(CAVERN_GRAPH[layout.monster].some(room=>graphPath(0,room,[layout.monster,...layout.pits])));
  }
});
test('Dark Cavern warnings report only immediate neighbours and update after hunt/cache',()=>{
  const game=createCave(api(1972)),s=game.state;
  for(let room=0;room<12;room++){
    const warnings=cavernWarnings(s,room).join(' ');
    assert.equal(warnings.includes('SCRAPING'),CAVERN_GRAPH[room].includes(s.monster));
    assert.equal(warnings.includes('COLD AIR'),CAVERN_GRAPH[room].some(i=>s.pits.includes(i)));
    assert.equal(warnings.includes('GLIMMER'),CAVERN_GRAPH[room].some(i=>s.treasures.includes(i)));
  }
  s.monsterDefeated=true;assert(!cavernWarnings(s,CAVERN_GRAPH[s.monster][0]).join(' ').includes('SCRAPING'));
});
test('Dark Cavern complete expedition succeeds only after hunt, both caches and return',t=>{
  for(const seed of [1,1972,2026]){const game=createCave(api(seed));const route=solveCave(game);assert.equal(game.state.status,'won');assert.equal(game.state.room,0);assert.equal(game.state.caches,2);assert(game.state.monsterDefeated);assert(game.state.score>600);t.diagnostic(`seed ${seed}, room path ${route.map(i=>i+1).join('>')}, monster ${game.state.monster+1}, score ${game.state.score}`);const final=structuredClone(game.state);game.update(1,press('action'));assert.deepEqual(game.state,final);}
});
test('Dark Cavern three missed shots cause an earned loss and never add hunt score',()=>{
  const game=createCave(api(3));game.update(1/60,press('secondary'));for(let i=0;i<3;i++)game.update(1/60,press('action'));
  assert.equal(game.state.status,'lost');assert.equal(game.state.ammo,0);assert.equal(game.state.score,0);assert.equal(game.state.monsterDefeated,false);
});
test('Dark Cavern entering the actual creature or pit causes appropriate loss',()=>{
  for(const hazard of ['monster','pit']){const game=createCave(api(1972)),s=game.state,target=hazard==='monster'?s.monster:s.pits[0];const blocked=hazard==='monster'?s.pits:[s.monster,...s.pits.filter(i=>i!==target)];const route=graphPath(0,target,blocked);assert(route);caveWalk(game,route);assert.equal(s.status,'lost');assert.match(s.message,hazard==='monster'?/creature found/:/hidden pit/);}
});
test('Dark Cavern taps select and use a door, mode toggle works, inactive pointer ignored',()=>{
  const game=createCave(api(1972));game.update(1/60,tap(320,182,false));assert.equal(game.state.mode,'move');game.update(1/60,tap(320,182));assert.equal(game.state.mode,'shoot');game.update(1/60,tap(320,182));assert.equal(game.state.mode,'move');game.update(1/60,tap(220,280));assert.equal(game.state.room,1);assert.equal(game.state.moves,1);
});
test('Dark Cavern runs with identical seeds and input sequences stay deterministic',()=>{
  const a=createCave(api(987)),b=createCave(api(987));for(const action of ['right','action','left','secondary','action','secondary','down','action']){a.update(1/60,press(action));b.update(1/60,press(action));assert.deepEqual(a.state,b.state);}
});

function waitColor(game,seconds=.22){for(let n=0;n<Math.ceil(seconds*60);n++)game.update(1/60,idle);}
function colorRoute(state,target) {
  const start=state.player,queue=[{...start,path:[]}],seen=new Set([tileIndex(start.row,start.col)]);
  for(let i=0;i<queue.length;i++){
    const p=queue[i];if(p.row===target.row&&p.col===target.col&&p.path.length)return p.path;
    for(const next of pyramidNeighbors(p.row,p.col,state.rows)){
      if(state.enemy&&next.row===state.enemy.row&&next.col===state.enemy.col)continue;
      const key=tileIndex(next.row,next.col);if(seen.has(key)&&key!==tileIndex(target.row,target.col))continue;seen.add(key);queue.push({...next,path:[...p.path,next.action]});
    }
  }
  return null;
}
function nextPaintMove(state) {
  const targets=[];for(let r=0;r<state.rows;r++)for(let c=0;c<=r;c++)if(state.tiles[tileIndex(r,c)]<state.coats){const path=colorRoute(state,{row:r,col:c});if(path?.length)targets.push(path);}
  targets.sort((a,b)=>a.length-b.length);if(targets.length)return targets[0][0];
  // A bug on the last target is temporary: lure it away instead of teleporting or deleting it.
  return pyramidNeighbors(state.player.row,state.player.col,state.rows).filter(p=>!state.enemy||p.row!==state.enemy.row||p.col!==state.enemy.col).sort((a,b)=>pyramidDistance(b,state.enemy,state.rows)-pyramidDistance(a,state.enemy,state.rows))[0]?.action;
}
test('Color Steps diagonal directions and triangular graph are consistent',()=>{
  assert.deepEqual(HOPS,{left:[1,0],down:[1,1],up:[-1,-1],right:[-1,0]});
  for(const rows of [4,5])for(let r=0;r<rows;r++)for(let c=0;c<=r;c++){assert(insidePyramid(r,c,rows));for(const n of pyramidNeighbors(r,c,rows))assert.equal(pyramidDistance({row:r,col:c},n,rows),1);}
  assert.equal(insidePyramid(0,-1,4),false);assert.equal(insidePyramid(4,1,4),false);assert.equal(pyramidDistance({row:4,col:0},{row:4,col:4},5),8);
});
test('Color Steps normal hop paints a tile, repeated painted visits do not farm score',()=>{
  const game=createColor(api(3));game.update(1/60,press('left'));assert.deepEqual(game.state.player,{row:1,col:0});assert.equal(game.state.tiles[1],1);assert.equal(game.state.score,20);
  waitColor(game);game.update(1/60,press('right'));waitColor(game);game.update(1/60,press('left'));assert.equal(game.state.score,20);
});
test('Color Steps edge falls consume lives, safe respawn preserves paint, three falls lose',()=>{
  const game=createColor(api(7));for(let i=0;i<3;i++){game.update(1/60,press('up'));if(i<2){assert.equal(game.state.lives,2-i);assert.deepEqual(game.state.player,{row:0,col:0});waitColor(game,1.2);}}
  assert.equal(game.state.status,'lost');assert.equal(game.state.lives,0);assert.equal(game.state.tiles[0],1);
});
test('Color Steps recall works once per pyramid and pursuer spawns then approaches',()=>{
  const game=createColor(api(11));game.update(1/60,press('left'));waitColor(game);game.update(1/60,press('action'));assert.equal(game.state.recalls,0);assert.deepEqual(game.state.player,{row:0,col:0});
  game.update(1/60,press('action'));assert.equal(game.state.recalls,0);waitColor(game,2.7);assert(game.state.enemy);
  const before=pyramidDistance(game.state.enemy,game.state.player,game.state.rows);waitColor(game,1.4);assert.equal(pyramidDistance(game.state.enemy,game.state.player,game.state.rows),before-1);
});
test('Color Steps pursuer eventually catches an idle player and cannot instantly hit respawn',()=>{
  const game=createColor(api(7));waitColor(game,9);assert.equal(game.state.lives,2);assert.equal(game.state.enemy,null);assert(game.state.enemyWait>0);assert.equal(game.state.status,'playing');
});
test('Color Steps pointer only hops to adjacent diamonds and ignores inactive pointer',()=>{
  const game=createColor(api(8));game.update(1/60,tap(149,103,false));assert.deepEqual(game.state.player,{row:0,col:0});game.update(1/60,tap(236,226));assert.deepEqual(game.state.player,{row:0,col:0});game.update(1/60,tap(149,103));assert.deepEqual(game.state.player,{row:1,col:0});
});
test('Color Steps all three pyramids are genuinely winnable with active pursuer and deterministic inputs',t=>{
  const a=createColor(api(1972)),b=createColor(api(1972));let moves=0,enemySeen=false;
  for(let n=0;n<250&&a.state.status==='playing';n++){
    if(a.state.levelComplete){a.update(1/60,press('action'));b.update(1/60,press('action'));waitColor(a);waitColor(b);}
    else {const move=nextPaintMove(a.state);assert(move,'unpainted tile must be reachable');a.update(1/60,press(move));b.update(1/60,press(move));waitColor(a);waitColor(b);moves++;}
    if(a.state.enemy)enemySeen=true;assert.deepEqual(a.state,b.state);
  }
  t.diagnostic(`three pyramids: ${moves} inputs, ${a.state.hops} legal hops, score ${a.state.score}, lives ${a.state.lives}, enemy seen ${enemySeen}`);
  assert.equal(a.state.status,'won');assert.equal(a.state.completed,3);assert.equal(a.state.rows,5);assert.equal(a.state.coats,2);assert(a.state.tiles.every(n=>n===2));assert(enemySeen);assert(a.state.score>3000);
  const final=structuredClone(a.state);a.update(.1,press('left'));assert.deepEqual(a.state,final);
});
