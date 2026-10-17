// OnlyEducation: an independently authored falling-block workshop.
export const COLS = 10;
export const ROWS = 18;
export const LINE_GOAL = 24;
export const SHAPES = [
  [[0, 0, 0, 0], [1, 1, 1, 1], [0, 0, 0, 0], [0, 0, 0, 0]],
  [[1, 1], [1, 1]],
  [[0, 1, 0], [1, 1, 1], [0, 0, 0]],
  [[1, 0, 0], [1, 1, 1], [0, 0, 0]],
  [[0, 0, 1], [1, 1, 1], [0, 0, 0]],
  [[0, 1, 1], [1, 1, 0], [0, 0, 0]],
  [[1, 1, 0], [0, 1, 1], [0, 0, 0]],
];
const COLORS = ['#61d5c8', '#ffc56a', '#b6a0e8', '#fa8068', '#90b7d8', '#b8d97d', '#f0a3b2'];
const INK = '#152536';
const PAPER = '#fff0cf';
const CELL = 14, BX = 165, BY = 36;

export function rotated(matrix, direction = 1) {
  const n = matrix.length;
  return Array.from({ length: n }, (_, y) => Array.from({ length: n }, (_, x) =>
    direction > 0 ? matrix[n - 1 - x][y] : matrix[x][n - 1 - y]));
}

export function occupied(piece) {
  const cells = [];
  piece.matrix.forEach((row, y) => row.forEach((filled, x) => {
    if (filled) cells.push({ x: piece.x + x, y: piece.y + y });
  }));
  return cells;
}

export function canPlace(board, piece) {
  return occupied(piece).every(({ x, y }) => x >= 0 && x < COLS && y < ROWS &&
    (y < 0 || board[y][x] === 0));
}

export function ghostY(board, piece) {
  let y = piece.y;
  while (canPlace(board, { ...piece, y: y + 1 })) y += 1;
  return y;
}

export function clearRows(board) {
  const remaining = board.filter(row => row.some(cell => cell === 0));
  const count = ROWS - remaining.length;
  return {
    count,
    board: [...Array.from({ length: count }, () => Array(COLS).fill(0)), ...remaining],
  };
}

export function createGame(api) {
  const state = {
    status: 'playing', score: 0, message: 'Build clean rows. Clear 24 to finish the workshop.',
    board: Array.from({ length: ROWS }, () => Array(COLS).fill(0)),
    active: null, next: [], bag: [], lines: 0, level: 1, goal: LINE_GOAL,
    pieces: 0, combo: 0, gravity: 0, lockTime: 0, lockResets: 0,
    moveDirection: 0, moveTime: 0, moveRepeat: false,
    flashTime: 0, flashRows: [], elapsed: 0, lastClear: 0,
  };
  const sound = name => api.sound?.(name);
  function takeFromBag() {
    if (!state.bag.length) {
      state.bag = SHAPES.map((_, i) => i);
      for (let i = state.bag.length - 1; i > 0; i -= 1) {
        const j = Math.floor(api.rng() * (i + 1));
        [state.bag[i], state.bag[j]] = [state.bag[j], state.bag[i]];
      }
    }
    return state.bag.pop();
  }
  function lose(message) {
    state.status = 'lost';
    state.message = message;
    sound('lose');
  }
  function spawn() {
    while (state.next.length < 4) state.next.push(takeFromBag());
    const type = state.next.shift();
    const matrix = SHAPES[type].map(row => [...row]);
    state.active = { type, matrix, x: Math.floor((COLS - matrix.length) / 2), y: -1 };
    state.gravity = 0;
    state.lockTime = 0;
    state.lockResets = 0;
    if (!canPlace(state.board, state.active)) lose('Workshop full! Try keeping a channel open.');
  }
  function grounded() {
    return !canPlace(state.board, { ...state.active, y: state.active.y + 1 });
  }
  function resetLock(wasGrounded) {
    if (wasGrounded && state.lockResets < 8) {
      state.lockTime = 0;
      state.lockResets += 1;
    }
  }
  function move(dx) {
    const next = { ...state.active, x: state.active.x + dx };
    if (!canPlace(state.board, next)) return false;
    const wasGrounded = grounded();
    state.active = next;
    resetLock(wasGrounded);
    sound('move');
    return true;
  }
  function turn(direction) {
    // Original bounded kick search, including narrow ledges and floor turns.
    // No imported rotation-system data or external game implementation.
    if (state.active.type === 1) return;
    const matrix = rotated(state.active.matrix, direction);
    const wasGrounded = grounded();
    const kicks = [[0, 0], [-1, 0], [1, 0], [-2, 0], [2, 0], [0, -1], [-1, -1], [1, -1], [0, -2]];
    for (const [dx, dy] of kicks) {
      const next = { ...state.active, matrix, x: state.active.x + dx, y: state.active.y + dy };
      if (!canPlace(state.board, next)) continue;
      state.active = next;
      resetLock(wasGrounded);
      sound('move');
      return;
    }
  }
  function lock() {
    const cells = occupied(state.active);
    if (cells.some(cell => cell.y < 0)) {
      lose('The stack reached the ceiling. Fresh workshop, fresh start!');
      return;
    }
    cells.forEach(({ x, y }) => { state.board[y][x] = state.active.type + 1; });
    state.pieces += 1;
    state.flashRows = state.board.flatMap((row, y) => row.every(Boolean) ? [y] : []);
    const result = clearRows(state.board);
    state.board = result.board;
    state.lastClear = result.count;
    if (result.count) {
      state.combo += 1;
      state.score += [0, 100, 300, 550, 900][result.count] * state.level + (state.combo - 1) * 40;
      state.lines += result.count;
      state.level = Math.min(7, 1 + Math.floor(state.lines / 4));
      state.flashTime = 0.22;
      state.message = `${result.count} ROW${result.count === 1 ? '' : 'S'}! ${Math.max(0, LINE_GOAL - state.lines)} to go.`;
      sound('score');
    } else {
      state.combo = 0;
      sound('hit');
    }
    if (state.lines >= LINE_GOAL) {
      state.status = 'won';
      state.active = null;
      state.message = 'WORKSHOP COMPLETE! 24 clean rows. Beautifully stacked.';
      sound('win');
      return;
    }
    spawn();
  }

  spawn();

  function update(dt, input) {
    if (state.status !== 'playing') return;
    dt = Math.max(0, Math.min(dt, 0.1));
    state.elapsed += dt;
    state.flashTime = Math.max(0, state.flashTime - dt);
    const left = input.down('left') || input.pressed('left');
    const right = input.down('right') || input.pressed('right');
    const direction = left === right ? 0 : (left ? -1 : 1);
    if (direction !== state.moveDirection) {
      state.moveDirection = direction;
      state.moveTime = 0;
      state.moveRepeat = false;
      if (direction) move(direction);
    } else if (direction) {
      state.moveTime += dt;
      let interval = state.moveRepeat ? 0.07 : 0.18;
      while (state.moveTime >= interval) {
        state.moveTime -= interval;
        state.moveRepeat = true;
        move(direction);
        interval = 0.07;
      }
    }
    if (input.pressed('up')) turn(1);
    if (input.pressed('secondary')) turn(-1);
    if (input.pressed('action')) {
      const landing = ghostY(state.board, state.active);
      state.score += (landing - state.active.y) * 2;
      state.active.y = landing;
      lock();
      return;
    }
    const soft = input.down('down') || input.pressed('down');
    const interval = soft ? 0.045 : Math.max(0.10, 0.78 * Math.pow(0.78, state.level - 1));
    state.gravity += dt;
    // A new soft-drop press responds immediately, even before the next gravity tick.
    if (input.pressed('down')) state.gravity = interval;
    while (state.gravity >= interval) {
      state.gravity -= interval;
      if (!canPlace(state.board, { ...state.active, y: state.active.y + 1 })) break;
      state.active.y += 1;
      state.lockTime = 0;
      if (soft) state.score += 1;
    }
    if (grounded()) {
      state.lockTime += dt;
      if (state.lockTime >= 0.34) lock();
    } else state.lockTime = 0;
  }

  function text(ctx, label, x, y, size = 10, color = PAPER, align = 'left') {
    ctx.fillStyle = color;
    ctx.font = `bold ${size}px monospace`;
    ctx.textAlign = align;
    ctx.textBaseline = 'top';
    ctx.fillText(label, x, y);
  }
  function block(ctx, x, y, size, color, ghost = false) {
    if (ghost) {
      ctx.strokeStyle = color;
      ctx.lineWidth = 1;
      ctx.strokeRect(x + 2.5, y + 2.5, size - 5, size - 5);
      return;
    }
    ctx.fillStyle = color;
    ctx.fillRect(x + 1, y + 1, size - 2, size - 2);
    ctx.fillStyle = 'rgba(255,240,207,.45)';
    ctx.fillRect(x + 2, y + 2, size - 4, 2);
    ctx.fillStyle = 'rgba(21,37,54,.3)';
    ctx.fillRect(x + 2, y + size - 4, size - 4, 2);
    ctx.fillRect(x + size - 4, y + 3, 2, size - 7);
  }
  function preview(ctx, type, x, y, scale = 10) {
    const matrix = SHAPES[type];
    matrix.forEach((row, py) => row.forEach((cell, px) => {
      if (cell) block(ctx, x + px * scale, y + py * scale, scale, COLORS[type]);
    }));
  }
  function draw(ctx) {
    ctx.save();
    ctx.imageSmoothingEnabled = false;
    ctx.fillStyle = INK;
    ctx.fillRect(0, 0, 480, 320);
    ctx.fillStyle = '#20364a';
    ctx.fillRect(0, 0, 480, 28);
    text(ctx, 'STACKFALL / THE BLOCK WORKSHOP', 14, 8, 12, '#ffc56a');
    text(ctx, '24 ROWS', 466, 9, 10, '#61d5c8', 'right');
    ctx.fillStyle = '#0d1b2a';
    ctx.fillRect(BX - 3, BY - 3, COLS * CELL + 6, ROWS * CELL + 6);
    for (let y = 0; y < ROWS; y += 1) {
      for (let x = 0; x < COLS; x += 1) {
        ctx.fillStyle = (x + y) % 2 ? '#192d3e' : '#1c3143';
        ctx.fillRect(BX + x * CELL, BY + y * CELL, CELL - 1, CELL - 1);
        if (state.board[y][x]) block(ctx, BX + x * CELL, BY + y * CELL, CELL, COLORS[state.board[y][x] - 1]);
      }
    }
    if (state.active) {
      const landing = ghostY(state.board, state.active);
      for (const ghost of [true, false]) {
        const piece = ghost ? { ...state.active, y: landing } : state.active;
        occupied(piece).forEach(({ x, y }) => {
          if (y >= 0) block(ctx, BX + x * CELL, BY + y * CELL, CELL, COLORS[piece.type], ghost);
        });
      }
    }
    if (state.flashTime > 0) {
      ctx.globalAlpha = state.flashTime / 0.22 * 0.4;
      ctx.fillStyle = '#fff0cf';
      state.flashRows.forEach(y => ctx.fillRect(BX, BY + y * CELL, COLS * CELL, CELL - 1));
      ctx.globalAlpha = 1;
    }
    text(ctx, 'SCORE', 18, 42, 10, '#90b7d8');
    text(ctx, String(state.score).padStart(6, '0'), 18, 58, 20);
    text(ctx, 'ROWS', 18, 94, 10, '#90b7d8');
    text(ctx, `${state.lines} / ${LINE_GOAL}`, 18, 110, 20, '#61d5c8');
    text(ctx, 'GEAR', 18, 146, 10, '#90b7d8');
    text(ctx, `0${state.level}`, 18, 162, 20, '#ffc56a');
    ctx.fillStyle = '#31495a';
    ctx.fillRect(18, 194, 126, 8);
    ctx.fillStyle = '#61d5c8';
    ctx.fillRect(18, 194, Math.min(126, Math.floor(state.lines / LINE_GOAL * 126)), 8);
    text(ctx, 'FILL A ROW.', 18, 218, 11);
    text(ctx, 'MAKE SOME ROOM.', 18, 234, 11);
    text(ctx, state.combo > 1 ? `CHAIN x${state.combo}` : 'ONE PIECE AT A TIME', 18, 264, 9, '#ffc56a');
    text(ctx, 'COMING UP', 328, 42, 11, '#90b7d8');
    state.next.slice(0, 3).forEach((type, i) => {
      ctx.fillStyle = '#20364a';
      ctx.fillRect(328, 62 + i * 48, 128, 40);
      text(ctx, String(i + 1), 338, 74 + i * 48, 11, '#90b7d8');
      preview(ctx, type, 376, 66 + i * 48);
    });
    text(ctx, 'ARROWS  MOVE', 328, 218, 10);
    text(ctx, 'UP / Z  ROTATE', 328, 234, 10);
    text(ctx, 'SPACE   DROP', 328, 250, 10, '#ffc56a');
    text(ctx, 'DOWN    SOFT DROP', 328, 266, 10, '#90b7d8');
    ctx.fillStyle = '#20364a';
    ctx.fillRect(0, 298, 480, 22);
    const message = state.status === 'playing' ? state.message : (state.status === 'won' ? 'WORKSHOP COMPLETE! Start again to beat your score.' : 'WORKSHOP FULL. Restart for a fresh stack.');
    text(ctx, message, 240, 305, 9, state.status === 'lost' ? '#fa8068' : PAPER, 'center');
    ctx.restore();
  }

  return { state, update, draw };
}
