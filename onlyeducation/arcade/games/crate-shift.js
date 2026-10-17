// Five original warehouse layouts. Solutions and independent solver checks in tests.
export const LEVELS = [
  { name:'First delivery', hint:['Push the crate','onto the gold pad.'], rows:['#######','#     #','# @$ .#','#     #','#######'] },
  { name:'Twin bays', hint:['Walk behind each','crate to push it.'], rows:['#######','# . . #','# $ $ #','#  @  #','#     #','#######'] },
  { name:'Side passage', hint:['The wall changes','your approach.'], rows:['########','#      #','# .# . #','# $$   #','#  @   #','#      #','########'] },
  { name:'Around the bend', hint:['One pad needs a','sideways arrival.'], rows:['#########','#   .   #','#   #   #','# . $ . #','#  $ $  #','#   @   #','#########'] },
  { name:'Last dispatch', hint:['Plan the top bays','and lower dock.'], rows:['#########','# .   . #','#   #   #','#  $ $  #','# # $ # #','#   @   #','#   .   #','#########'] },
];
const C = { navy:'#152536', paper:'#fff0cf', teal:'#61d5c8', gold:'#ffc56a', coral:'#fa8068', dim:'#8ca5b0' };
const DIRS = { left:[-1,0], right:[1,0], up:[0,-1], down:[0,1] };
const TILE = 32, X = 24, Y = 42;

export function parseLevel(rows) {
  const width = rows[0].length, board = { width, height:rows.length, walls:[], goals:[], crates:[], player:-1 };
  let players = 0;
  rows.forEach((row,y) => {
    if (row.length !== width) throw new Error('Warehouse must be rectangular');
    [...row].forEach((cell,x) => {
      const i = y * width + x;
      if (!'# .$@*+'.includes(cell)) throw new Error('Unknown warehouse cell');
      if (cell === '#') board.walls.push(i);
      if ('.*+'.includes(cell)) board.goals.push(i);
      if (cell === '$' || cell === '*') board.crates.push(i);
      if (cell === '@' || cell === '+') { board.player = i; players++; }
      if ((x === 0 || y === 0 || x === width - 1 || y === rows.length - 1) && cell !== '#') throw new Error('Warehouse boundary must be closed');
    });
  });
  if (players !== 1 || !board.crates.length || board.crates.length !== board.goals.length) throw new Error('Warehouse needs one player and matched crates/goals');
  return board;
}

export function crateSolved(board) { return board.crates.every(i => board.goals.includes(i)); }

/** Pure legal movement; never pulls crates, chains pushes, wraps rows, or mutates. */
export function moveCrate(board, direction) {
  const [dx,dy] = DIRS[direction] || [0,0];
  if (!dx && !dy) return null;
  const nextX = board.player % board.width + dx, nextY = Math.floor(board.player / board.width) + dy;
  if (nextX < 0 || nextX >= board.width || nextY < 0 || nextY >= board.height) return null;
  const next = nextY * board.width + nextX;
  if (board.walls.includes(next)) return null;
  const index = board.crates.indexOf(next), crates = board.crates.slice();
  if (index >= 0) {
    const pushX = nextX + dx, pushY = nextY + dy, destination = pushY * board.width + pushX;
    if (pushX < 0 || pushX >= board.width || pushY < 0 || pushY >= board.height || board.walls.includes(destination) || crates.includes(destination)) return null;
    crates[index] = destination;
  }
  return { board:{ ...board, player:next, crates }, pushed:index >= 0 };
}

export function cornerDeadlock(board) {
  const wall = i => board.walls.includes(i);
  return board.crates.some(i => !board.goals.includes(i) && (wall(i - 1) || wall(i + 1)) && (wall(i - board.width) || wall(i + board.width)));
}

export function createGame(api) {
  const state = { status:'playing', score:0, message:'Fill every gold pad.', level:0, board:parseLevel(LEVELS[0].rows), steps:0, pushes:0, completed:0, levelComplete:false, deadlocked:false, historyCount:0 };
  let history = [], held = '', repeat = 0;
  const sound = name => api.sound?.(name);
  function move(direction) {
    const result = moveCrate(state.board,direction);
    if (!result) return;
    history.push({ board:state.board, steps:state.steps, pushes:state.pushes, score:state.score });
    state.board = result.board; state.steps++; state.pushes += Number(result.pushed); state.historyCount = history.length;
    state.deadlocked = cornerDeadlock(state.board);
    state.message = state.deadlocked ? 'Corner jam! Undo to recover.' : 'Fill every gold pad.';
    sound(result.pushed ? 'hit' : 'move');
    if (crateSolved(state.board)) {
      state.levelComplete = true; state.completed = state.level + 1;
      state.score += Math.max(100,500 + state.level * 100 - state.steps * 3 - state.pushes * 2);
      state.message = 'Delivery complete!'; sound('score');
      if (state.level === LEVELS.length - 1) { state.status = 'won'; state.message = 'All five rooms dispatched!'; sound('win'); }
    }
  }
  function undo() {
    const previous = history.pop();
    if (!previous) return;
    Object.assign(state,previous);
    state.historyCount = history.length; state.levelComplete = false; state.completed = state.level; state.deadlocked = cornerDeadlock(state.board);
    state.message = 'Move undone. Try another approach.'; held = ''; repeat = 0; sound('move');
  }
  function update(dt,input) {
    if (state.status !== 'playing') return;
    const p = input.pointer, tap = p.active && p.pressed;
    if (input.pressed('secondary') || (tap && p.x >= 328 && p.x < 456 && p.y >= 204 && p.y < 236)) { undo(); return; }
    if (state.levelComplete) {
      if (input.pressed('action') || (tap && p.x >= 328 && p.x < 456 && p.y >= 246 && p.y < 282)) {
        state.level++; state.board = parseLevel(LEVELS[state.level].rows); state.steps = 0; state.pushes = 0; state.levelComplete = false; state.deadlocked = false; state.historyCount = 0; state.message = 'Fill every gold pad.'; history = []; held = ''; repeat = 0; sound('move');
      }
      return;
    }
    if (tap) {
      const cx = Math.floor((p.x - X) / TILE), cy = Math.floor((p.y - Y) / TILE);
      const dx = cx - state.board.player % state.board.width, dy = cy - Math.floor(state.board.player / state.board.width);
      if (Math.abs(dx) + Math.abs(dy) === 1 && cx >= 0 && cy >= 0 && cx < state.board.width && cy < state.board.height) move(dx < 0 ? 'left' : dx > 0 ? 'right' : dy < 0 ? 'up' : 'down');
      return;
    }
    const pressed = Object.keys(DIRS).find(key => input.pressed(key));
    if (pressed) { move(pressed); held = pressed; repeat = 0.24; return; }
    if (!held || !input.down(held)) { held = ''; return; }
    repeat -= dt;
    if (repeat <= 0) { move(held); repeat += 0.13; }
  }
  function draw(ctx) {
    ctx.fillStyle = C.navy; ctx.fillRect(0,0,480,320);
    ctx.font = 'bold 17px monospace'; ctx.fillStyle = C.paper; ctx.fillText('CRATE SHIFT',24,27);
    ctx.font = '11px monospace'; ctx.fillStyle = C.gold; ctx.fillText(`SCORE ${state.score}`,328,25);
    const board = state.board;
    for (let i = 0; i < board.width * board.height; i++) {
      const x = X + i % board.width * TILE, y = Y + Math.floor(i / board.width) * TILE;
      const wall = board.walls.includes(i);
      ctx.fillStyle = wall ? '#365464' : '#c7b6a0'; ctx.fillRect(x,y,TILE,TILE);
      if (wall) { api.sprite?.(ctx,'tiles_steel',x,y,{scale:2}); ctx.fillStyle = '#15253655'; ctx.fillRect(x,y + 28,32,4); }
      else {
        ctx.strokeStyle = '#ae9e8b'; ctx.lineWidth = 1; ctx.strokeRect(x + 1,y + 1,30,30);
        if (board.goals.includes(i)) { ctx.fillStyle = C.gold; ctx.fillRect(x + 5,y + 5,22,22); ctx.fillStyle = C.navy; ctx.fillRect(x + 10,y + 10,12,12); }
      }
      if (board.crates.includes(i)) {
        ctx.fillStyle = board.goals.includes(i) ? C.teal : C.coral; ctx.fillRect(x + 2,y + 2,28,28);
        api.sprite?.(ctx,'pieces_crate',x,y,{scale:1});
        if (board.goals.includes(i)) { ctx.fillStyle = C.teal; ctx.fillRect(x + 4,y + 24,24,5); }
      }
      if (board.player === i) { ctx.fillStyle = C.teal; ctx.fillRect(x + 9,y + 5,14,22); api.sprite?.(ctx,'pieces_scout',x,y,{scale:1}); }
    }
    ctx.fillStyle = C.gold; ctx.font = 'bold 14px monospace'; ctx.fillText(`ROOM ${state.level + 1} / 5`,328,61);
    ctx.fillStyle = C.paper; ctx.font = '12px monospace'; ctx.fillText(LEVELS[state.level].name,328,82);
    ctx.fillStyle = C.dim; ctx.font = '11px monospace'; LEVELS[state.level].hint.forEach((line,i) => ctx.fillText(line,328,107 + i * 15));
    ctx.fillStyle = C.paper; ctx.fillText(`STEPS  ${state.steps}`,328,150); ctx.fillText(`PUSHES ${state.pushes}`,328,168);
    ctx.fillStyle = C.gold; ctx.fillText(`PADS ${board.crates.filter(i => board.goals.includes(i)).length}/${board.goals.length}`,328,186);
    ctx.fillStyle = history.length ? '#365464' : '#203344'; ctx.fillRect(328,204,128,32); ctx.fillStyle = history.length ? C.paper : C.dim; ctx.fillText('UNDO [Z]',350,225);
    if (state.levelComplete) { ctx.fillStyle = C.gold; ctx.fillRect(328,246,128,36); ctx.fillStyle = C.navy; ctx.font = 'bold 12px monospace'; ctx.fillText('NEXT ROOM >',337,269); }
    else { ctx.fillStyle = state.deadlocked ? C.coral : C.dim; ctx.font = '10px monospace'; ctx.fillText(state.deadlocked ? 'Corner jam.' : 'Arrows / WASD',328,254); ctx.fillText(state.deadlocked ? 'Press Z to undo.' : 'Tap a neighbour',328,270); }
    ctx.fillStyle = C.dim; ctx.font = '10px monospace'; ctx.fillText('PUSH, NEVER PULL',328,302);
  }
  return { state, update, draw };
}
