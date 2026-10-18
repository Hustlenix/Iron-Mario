// Original three-round noughts-and-crosses laboratory. No external assets or code.
const LINES = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
const ORDER = [4,0,2,6,8,1,3,5,7];
const MODE = ['CURIOUS', 'TACTICAL', 'EXPERT'];
const C = { navy:'#152536', paper:'#fff0cf', teal:'#61d5c8', gold:'#ffc56a', coral:'#fa8068', dim:'#8ca5b0' };
const GRID = { x:36, y:52, cell:68 };

export function gridOutcome(board) {
  for (const line of LINES) if (board[line[0]] && line.every(i => board[i] === board[line[0]])) return board[line[0]];
  return board.every(Boolean) ? 'draw' : null;
}

function minimax(board, turn, depth = 0) {
  const result = gridOutcome(board);
  if (result === 2) return 10 - depth;
  if (result === 1) return depth - 10;
  if (result === 'draw') return 0;
  let best = turn === 2 ? -Infinity : Infinity;
  for (const move of ORDER) {
    if (board[move]) continue;
    board[move] = turn;
    const value = minimax(board, 3 - turn, depth + 1);
    board[move] = 0;
    best = turn === 2 ? Math.max(best, value) : Math.min(best, value);
  }
  return best;
}

/** Round 1 explores; round 2 wins/blocks; round 3 searches every legal future. */
export function chooseGridMove(board, difficulty, rng = () => 0) {
  if (gridOutcome(board) !== null) return -1;
  const empty = ORDER.filter(i => !board[i]);
  if (difficulty === 0) return empty[Math.floor(rng() * empty.length)];
  const copy = board.slice();
  if (difficulty === 1) {
    for (const mark of [2, 1]) for (const i of empty) {
      copy[i] = mark;
      const win = gridOutcome(copy) === mark;
      copy[i] = 0;
      if (win) return i;
    }
    return empty[Math.floor(rng() * empty.length)];
  }
  let best = -Infinity, chosen = empty[0];
  for (const i of empty) {
    copy[i] = 2;
    const value = minimax(copy, 1);
    copy[i] = 0;
    if (value > best) { best = value; chosen = i; }
  }
  return chosen;
}

export function createGame(api) {
  const state = { status:'playing', score:0, message:'Your turn. Make a line of three.', board:Array(9).fill(0), round:1, cursor:4, turn:'player', roundComplete:false, roundResult:null, wins:0, draws:0, aiTime:0 };
  const sound = name => api.sound?.(name);
  function finishTurn() {
    const outcome = gridOutcome(state.board);
    if (outcome === null) return false;
    state.roundResult = outcome;
    if (outcome === 2) {
      state.status = 'lost'; state.message = 'Terminal wins. Retry here; earlier clears are safe.'; sound('lose');
    } else {
      state.score += outcome === 1 ? 200 * state.round : 80 * state.round;
      if (outcome === 1) state.wins++; else state.draws++;
      state.roundComplete = true;
      state.message = outcome === 1 ? 'Three in a row! Laboratory cleared.' : 'Good defence! A draw advances.';
      if (state.round === 3) { state.status = 'won'; state.message = 'All three terminals cleared!'; sound('win'); }
      else sound('score');
    }
    return true;
  }
  function play(index) {
    if (state.turn !== 'player' || state.board[index]) return;
    state.cursor = index; state.board[index] = 1; sound('move');
    if (!finishTurn()) { state.turn = 'ai'; state.aiTime = 0.5; state.message = 'Terminal is thinking...'; }
  }
  function update(dt, input) {
    if (state.status !== 'playing') return;
    const p = input.pointer;
    if (state.roundComplete) {
      if (input.pressed('action') || (p.active && p.pressed && p.x >= 274 && p.x < 458 && p.y >= 220 && p.y < 258)) {
        state.round++; state.board = Array(9).fill(0); state.turn = 'player'; state.roundComplete = false; state.roundResult = null; state.cursor = 4;
        state.message = state.round === 3 ? 'Expert defence: a draw clears this terminal.' : 'Your turn. Make a line of three.'; sound('move');
      }
      return;
    }
    if (state.turn === 'ai') {
      state.aiTime -= dt;
      if (state.aiTime <= 0) {
        const move = chooseGridMove(state.board, state.round - 1, api.rng);
        if (move >= 0) state.board[move] = 2;
        sound('hit');
        if (!finishTurn()) { state.turn = 'player'; state.message = 'Your turn. Make a line of three.'; }
      }
      return;
    }
    let x = state.cursor % 3, y = Math.floor(state.cursor / 3);
    if (input.pressed('left')) x = (x + 2) % 3;
    if (input.pressed('right')) x = (x + 1) % 3;
    if (input.pressed('up')) y = (y + 2) % 3;
    if (input.pressed('down')) y = (y + 1) % 3;
    state.cursor = y * 3 + x;
    if (p.active && p.pressed && p.x >= GRID.x && p.y >= GRID.y && p.x < GRID.x + 204 && p.y < GRID.y + 204) {
      play(Math.floor((p.y - GRID.y) / GRID.cell) * 3 + Math.floor((p.x - GRID.x) / GRID.cell));
    } else if (input.pressed('action')) play(state.cursor);
  }
  function draw(ctx) {
    ctx.fillStyle = C.navy; ctx.fillRect(0,0,480,320);
    ctx.font = 'bold 17px monospace'; ctx.fillStyle = C.paper; ctx.fillText('GRID X',24,27);
    ctx.font = '11px monospace'; ctx.fillStyle = C.dim; ctx.fillText('3 TERMINALS / DRAW TO ADVANCE',228,25);
    for (let i = 0; i < 9; i++) {
      const x = GRID.x + (i % 3) * GRID.cell, y = GRID.y + Math.floor(i / 3) * GRID.cell;
      ctx.fillStyle = '#253d4d'; ctx.fillRect(x + 2,y + 2,64,64);
      if (state.cursor === i && state.turn === 'player' && !state.roundComplete) { ctx.strokeStyle = C.gold; ctx.lineWidth = 2; ctx.strokeRect(x + 5,y + 5,58,58); }
      if (state.board[i] === 1) {
        ctx.fillStyle = C.teal;
        for (let j = 0; j < 6; j++) { ctx.fillRect(x + 16 + j * 5,y + 16 + j * 5,7,7); ctx.fillRect(x + 41 - j * 5,y + 16 + j * 5,7,7); }
      } else if (state.board[i] === 2) {
        ctx.strokeStyle = C.coral; ctx.lineWidth = 7; ctx.strokeRect(x + 19,y + 19,28,28);
      }
    }
    if (state.roundResult === 1 || state.roundResult === 2) {
      const line = LINES.find(line => line.every(i => state.board[i] === state.roundResult));
      if (line) { ctx.strokeStyle = C.gold; ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(GRID.x + line[0] % 3 * 68 + 34,GRID.y + Math.floor(line[0] / 3) * 68 + 34); ctx.lineTo(GRID.x + line[2] % 3 * 68 + 34,GRID.y + Math.floor(line[2] / 3) * 68 + 34); ctx.stroke(); }
    }
    ctx.fillStyle = C.gold; ctx.font = 'bold 15px monospace'; ctx.fillText(`ROUND ${state.round} / 3`,278,65);
    ctx.fillStyle = C.teal; ctx.font = '12px monospace'; ctx.fillText(MODE[state.round - 1],278,86);
    api.sprite?.(ctx,'pieces_terminal',330,101,{scale:2});
    ctx.fillStyle = C.paper; ctx.font = '12px monospace'; ctx.fillText(`SCORE ${state.score}`,278,181);
    ctx.fillStyle = C.dim; ctx.fillText(`${state.wins} WINS  ${state.draws} DRAWS`,278,201);
    if (state.roundComplete && state.status === 'playing') {
      ctx.fillStyle = C.gold; ctx.fillRect(274,220,184,38); ctx.fillStyle = C.navy; ctx.font = 'bold 13px monospace'; ctx.fillText('NEXT TERMINAL >',286,244);
    } else { ctx.fillStyle = C.paper; ctx.font = '11px monospace'; ctx.fillText('YOU: X   TERMINAL: O',278,229); ctx.fillText('Arrows + SPACE',278,250); }
    ctx.fillStyle = C.paper; ctx.font = '12px monospace'; ctx.fillText(state.message,24,281);
    ctx.fillStyle = C.dim; ctx.font = '10px monospace'; ctx.fillText('TAP A SQUARE  /  DPAD + ACTION  /  NO TIME LIMIT',24,303);
  }
  function retry() {
    if (state.status !== 'lost') return false;
    Object.assign(state, { status:'playing', board:Array(9).fill(0), turn:'player', roundComplete:false, roundResult:null, cursor:4, aiTime:0,
      message:state.round === 3 ? 'Expert defence: a draw clears this terminal.' : 'Try this terminal again. Earlier clears are safe.' });
    sound('move');
    return true;
  }
  return { state, update, draw, retry };
}
