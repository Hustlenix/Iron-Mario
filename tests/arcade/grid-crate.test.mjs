import test from 'node:test';
import assert from 'node:assert/strict';
import { createGame as createGrid, gridOutcome, chooseGridMove } from '../../onlyeducation/arcade/games/grid-x.js';
import { createGame as createCrate, LEVELS, parseLevel, moveCrate, crateSolved, cornerDeadlock } from '../../onlyeducation/arcade/games/crate-shift.js';

const idle = { down:()=>false, pressed:()=>false, pointer:{ x:0,y:0,active:false,pressed:false,down:false } };
const press = action => ({ ...idle, down:a=>a === action, pressed:a=>a === action });
const tap = (x,y,active=true) => ({ ...idle, pointer:{ x,y,active,pressed:true,down:true } });
const rng = seed => () => { seed = (Math.imul(seed,1664525) + 1013904223) >>> 0; return seed / 4294967296; };
const api = (seed=1) => ({ rng:rng(seed), sound:()=>{} });
const lines = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
function independentOutcome(board) {
  for (const line of lines) if (board[line[0]] && line.every(i => board[i] === board[line[0]])) return board[line[0]];
  return board.every(Boolean) ? 0 : null;
}
function playerValue(board,turn) {
  const end = independentOutcome(board);
  if (end !== null) return end === 1 ? 1 : end === 2 ? -1 : 0;
  const scores = [];
  for (let i=0;i<9;i++) if (!board[i]) { board[i] = turn; scores.push(playerValue(board,3-turn)); board[i] = 0; }
  return turn === 1 ? Math.max(...scores) : Math.min(...scores);
}
function safePlayerMove(board) {
  let best=-2, chosen=-1;
  for (let i=0;i<9;i++) if (!board[i]) { board[i]=1; const value=playerValue(board,2); board[i]=0; if (value>best) { best=value; chosen=i; } }
  return chosen;
}
function gridTap(game,i) { game.update(1/60,tap(36 + i%3*68 + 34,52 + Math.floor(i/3)*68 + 34)); }
function finishAI(game) { for (let i=0;i<31;i++) game.update(1/60,idle); }

test('Grid X recognises all winning lines, draws and unfinished positions',()=>{
  for (const line of lines) for (const player of [1,2]) { const board=Array(9).fill(0); line.forEach(i=>board[i]=player); assert.equal(gridOutcome(board),player); }
  assert.equal(gridOutcome([1,2,1,1,2,2,2,1,1]),'draw');
  assert.equal(gridOutcome([1,0,0,0,2,0,0,0,0]),null);
});

test('Grid X beginner AI is legally winnable through normal pointer input',()=>{
  const game=createGrid({rng:()=>0,sound:()=>{}});
  for (const move of [0,2,1]) { gridTap(game,move); finishAI(game); }
  assert.equal(game.state.roundResult,1);
  assert.equal(game.state.roundComplete,true);
  assert.equal(game.state.score,200);
  assert.equal(game.state.wins,1);
});

test('Grid X tactical terminal takes wins and blocks immediate threats',()=>{
  assert.equal(chooseGridMove([2,2,0,1,1,0,0,0,0],1,()=>0),2);
  assert.equal(chooseGridMove([1,1,0,0,2,0,0,0,0],1,()=>0.9),2);
  assert.equal(chooseGridMove([1,1,1,2,2,0,0,0,0],2),-1);
});

test('Grid X expert cannot lose against any legal player sequence',()=>{
  const visited=new Set();
  function visit(board) {
    const key=board.join(''); if (visited.has(key)) return; visited.add(key);
    for (let i=0;i<9;i++) {
      if (board[i]) continue;
      const next=board.slice(); next[i]=1;
      assert.notEqual(independentOutcome(next),1,'expert allowed a player-winning line');
      if (independentOutcome(next)!==null) continue;
      const before=next.slice(), choice=chooseGridMove(next,2);
      assert.deepEqual(next,before,'search must not mutate board');
      assert.equal(next[choice],0,'AI must choose an empty square');
      next[choice]=2;
      if (independentOutcome(next)===null) visit(next);
    }
  }
  visit(Array(9).fill(0));
  assert.ok(visited.size>50);
});

test('Grid X keyboard navigation and inactive-pointer filtering enforce legal turns',()=>{
  const game=createGrid(api());
  game.update(1/60,tap(70,86,false)); assert.equal(game.state.board.filter(Boolean).length,0);
  game.update(1/60,press('left')); game.update(1/60,press('up')); game.update(1/60,press('action'));
  assert.equal(game.state.board[0],1);
  gridTap(game,1); assert.equal(game.state.board[1],0,'cannot play during AI turn');
  finishAI(game); const before=game.state.board.slice(); gridTap(game,0); assert.deepEqual(game.state.board,before,'occupied square cannot be replaced');
});

test('Grid X complete three-round run is reproducible and reaches earned terminal state',()=>{
  const a=createGrid(api(19)), b=createGrid(api(19));
  for (let n=0;n<50 && a.state.status==='playing';n++) {
    if (a.state.roundComplete) { a.update(1/60,press('action')); b.update(1/60,press('action')); }
    else if (a.state.turn==='ai') { finishAI(a); finishAI(b); }
    else { const move=safePlayerMove(a.state.board.slice()); gridTap(a,move); gridTap(b,move); }
    assert.deepEqual(a.state,b.state);
  }
  assert.equal(a.state.status,'won'); assert.equal(a.state.round,3); assert.equal(a.state.wins+a.state.draws,3); assert.ok(a.state.score>=480);
  const final=structuredClone(a.state); a.update(5,press('action')); assert.deepEqual(a.state,final,'terminal state is stable');
});

test('Grid X a real terminal winning move ends the run as a loss',()=>{
  const game=createGrid(api());
  Object.assign(game.state,{board:[2,2,0,1,1,0,0,0,1],round:2,turn:'ai',aiTime:0});
  game.update(1/60,idle); assert.equal(game.state.status,'lost'); assert.equal(gridOutcome(game.state.board),2); assert.equal(game.state.score,0);
});

// Independent BFS uses coordinates and sets, not production moveCrate or parseLevel.
// It validates authored layouts and yields reproducible browser-input solutions.
function solveRows(rows) {
  const width=rows[0].length,walls=new Set(),goals=new Set(),crates=[]; let player=-1;
  rows.forEach((row,y)=>[...row].forEach((cell,x)=>{const i=y*width+x;if(cell==='#')walls.add(i);if('.*+'.includes(cell))goals.add(i);if('$*'.includes(cell))crates.push(i);if('@+'.includes(cell))player=i;}));
  const key=(p,boxes)=>`${p}:${boxes.slice().sort((a,b)=>a-b).join(',')}`;
  const queue=[{player,crates,previous:-1,move:''}],seen=new Set([key(player,crates)]);
  for(let head=0;head<queue.length;head++){
    const current=queue[head];
    if(current.crates.every(i=>goals.has(i))){let solution='',i=head;while(queue[i].previous>=0){solution=queue[i].move+solution;i=queue[i].previous;}return {solution,visited:seen.size};}
    for(const [symbol,dx,dy] of [['L',-1,0],['R',1,0],['U',0,-1],['D',0,1]]){
      const x=current.player%width+dx,y=Math.floor(current.player/width)+dy;
      if(x<0||x>=width||y<0||y>=rows.length)continue;
      const destination=y*width+x;if(walls.has(destination))continue;
      const boxes=current.crates.slice(),crate=boxes.indexOf(destination);
      if(crate>=0){const bx=x+dx,by=y+dy,bi=by*width+bx;if(bx<0||bx>=width||by<0||by>=rows.length||walls.has(bi)||boxes.includes(bi))continue;boxes[crate]=bi;}
      const id=key(destination,boxes);if(seen.has(id))continue;
      seen.add(id);queue.push({player:destination,crates:boxes,previous:head,move:symbol});
    }
    assert.ok(queue.length<350000,'original warehouse solver exceeded bounded search');
  }
  return null;
}
const solutions=LEVELS.map(level=>solveRows(level.rows));
const direction={L:'left',R:'right',U:'up',D:'down'};

test('all five original Crate Shift rooms are independently solvable',t=>{
  assert.equal(LEVELS.length,5);
  assert.deepEqual(LEVELS.map(level=>parseLevel(level.rows).crates.length),[1,2,2,3,3]);
  solutions.forEach((result,i)=>{
    assert.ok(result,`room ${i+1} has no solution`);t.diagnostic(`room ${i+1}: ${result.solution} (${result.solution.length} moves, ${result.visited} search states)`);
    let board=parseLevel(LEVELS[i].rows); assert.equal(crateSolved(board),false);
    for(const symbol of result.solution){const move=moveCrate(board,direction[symbol]);assert.ok(move);board=move.board;}
    assert.equal(crateSolved(board),true);
  });
  assert.ok(solutions[4].solution.length>solutions[0].solution.length);
});

test('Crate Shift validates maps and rejects wall, edge and double-crate pushes',()=>{
  assert.throws(()=>parseLevel(['###','#@#','###']),/matched/);
  assert.throws(()=>parseLevel(['####','#@$','# .#','####']),/rectangular|boundary/);
  const board=parseLevel(['#######','#@$$..#','#     #','#######']);
  const original=structuredClone(board);
  assert.equal(moveCrate(board,'up'),null);assert.equal(moveCrate(board,'left'),null);assert.equal(moveCrate(board,'right'),null);assert.equal(moveCrate(board,'invalid'),null);assert.deepEqual(board,original);
  const next=moveCrate(board,'down');assert.ok(next);assert.equal(next.pushed,false);assert.deepEqual(board,original);
});

test('Crate Shift undo restores pushes, goals and score without score farming',()=>{
  const game=createCrate(api()),before=structuredClone(game.state.board);
  game.update(1/60,press('right'));assert.equal(game.state.pushes,1);
  game.update(1/60,press('secondary'));assert.deepEqual(game.state.board,before);assert.equal(game.state.steps,0);assert.equal(game.state.historyCount,0);
  game.update(1/60,press('right'));game.update(1/60,press('right'));assert.equal(game.state.levelComplete,true);const score=game.state.score;assert.ok(score>0);
  game.update(1/60,press('secondary'));assert.equal(game.state.levelComplete,false);assert.equal(game.state.score,0);assert.equal(game.state.completed,0);
  game.update(1/60,press('right'));assert.equal(game.state.score,score);assert.equal(game.state.completed,1);
});

test('Crate Shift identifies a reversible corner jam and ignores crates on goals',()=>{
  const jam=parseLevel(['#######','#$ @ .#','#     #','#######']);assert.equal(cornerDeadlock(jam),true);
  const solved=parseLevel(['#######','#* @  #','#     #','#######']);assert.equal(cornerDeadlock(solved),false);
  const game=createCrate(api());
  for(const action of ['down','right','up','right','up','left','left'])game.update(1/60,press(action));
  assert.equal(game.state.deadlocked,true);assert.equal(game.state.status,'playing');
  game.update(1/60,press('secondary'));assert.equal(game.state.deadlocked,false);
});

test('Crate Shift pointer movement is adjacent-only and undo button works',()=>{
  const game=createCrate(api());const initial=game.state.board.player;
  game.update(1/60,tap(24+5*32+16,42+2*32+16));assert.equal(game.state.board.player,initial);
  game.update(1/60,tap(24+3*32+16,42+2*32+16,false));assert.equal(game.state.board.player,initial);
  game.update(1/60,tap(24+3*32+16,42+2*32+16));assert.equal(game.state.pushes,1);
  game.update(1/60,tap(360,220));assert.equal(game.state.board.player,initial);assert.equal(game.state.pushes,0);
});

test('Crate Shift all five room solutions reach earned win through input and reset reproducibly',()=>{
  const a=createCrate(api(42)),b=createCrate(api(42));
  for(let level=0;level<LEVELS.length;level++){
    for(const symbol of solutions[level].solution){a.update(1/60,press(direction[symbol]));b.update(1/60,press(direction[symbol]));assert.deepEqual(a.state,b.state);}
    assert.equal(a.state.levelComplete,true);assert.equal(a.state.completed,level+1);
    if(level<LEVELS.length-1){a.update(1/60,press('action'));b.update(1/60,press('action'));assert.equal(a.state.historyCount,0);assert.equal(a.state.steps,0);}
  }
  assert.equal(a.state.status,'won');assert.equal(a.state.completed,5);assert.ok(a.state.score>2000);
  const final=structuredClone(a.state);a.update(1/60,press('secondary'));assert.deepEqual(a.state,final);
  assert.deepEqual(createCrate(api(42)).state,createCrate(api(42)).state);
});

test('Grid X retry preserves earlier clears and cannot farm score through repeated losses',()=>{
 const game=createGrid({rng:()=>0,sound(){}});
 for(const move of [0,2,1]){gridTap(game,move);finishAI(game);}
 game.update(1/60,press('action'));assert.equal(game.state.round,2);
 const saved={score:game.state.score,wins:game.state.wins,draws:game.state.draws};
 for(let n=0;n<3;n++){
  Object.assign(game.state,{board:[2,2,0,1,1,0,0,0,1],turn:'ai',aiTime:0});game.update(1/60,idle);
  assert.equal(game.state.status,'lost');assert.equal(game.retry(),true);assert.equal(game.state.round,2);
  assert.deepEqual({score:game.state.score,wins:game.state.wins,draws:game.state.draws},saved);
  assert.deepEqual(game.state.board,Array(9).fill(0));assert.equal(game.state.turn,'player');assert.equal(game.retry(),false);
 }
 game.state.status='won';assert.equal(game.retry(),false);
});
