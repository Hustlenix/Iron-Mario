/** Byte Munch: original endless grid survival. No DOM or clock ownership. */
const COLS = 28, ROWS = 16, CELL = 16, OX = 16, OY = 48;
const DIRS = { up: { x: 0, y: -1 }, down: { x: 0, y: 1 }, left: { x: -1, y: 0 }, right: { x: 1, y: 0 } };
const key = p => p.x + ',' + p.y;
const same = (a, b) => a.x === b.x && a.y === b.y;
const distance = (a, b) => Math.abs(a.x - b.x) + Math.abs(a.y - b.y);

export function createGame(api) {
  const rng = api.rng;
  const sound = name => api.sound?.(name);
  const state = {
    status: 'playing', score: 0, message: 'Collect gold bytes. Avoid walls and your tail.',
    snake: [{ x: 8, y: 8 }, { x: 7, y: 8 }, { x: 6, y: 8 }, { x: 5, y: 8 }],
    direction: { ...DIRS.right }, turns: [], food: null, obstacles: [], warnings: [],
    eaten: 0, level: 1, interval: 0.16, accumulator: 0, time: 0, flash: 0,
    cols: COLS, rows: ROWS, maxLength: 4, started: false
  };

  function reachableCells(blocked) {
    const start = state.snake[0];
    const seen = new Set([key(start)]);
    const queue = [start], free = [];
    for (let i = 0; i < queue.length; i++) {
      const p = queue[i];
      for (const d of Object.values(DIRS)) {
        const n = { x: p.x + d.x, y: p.y + d.y }, k = key(n);
        if (n.x < 0 || n.y < 0 || n.x >= COLS || n.y >= ROWS || seen.has(k) || blocked.has(k)) continue;
        seen.add(k); queue.push(n); free.push(n);
      }
    }
    return free;
  }

  function placeFood() {
    const blocked = new Set([...state.obstacles, ...state.snake, ...state.warnings].map(key));
    let free = reachableCells(blocked);
    if (!free.length) {
      // A coiled body may temporarily enclose the head. Its tail will move:
      // never incorrectly declare a win merely because the current flood fill is small.
      const occupied = new Set([...state.obstacles, ...state.snake].map(key));
      free = [];
      for (let y = 0; y < ROWS; y++) for (let x = 0; x < COLS; x++)
        if (!occupied.has(x + ',' + y)) free.push({ x, y });
    }
    if (!free.length) {
      state.food = null; state.status = 'won';
      state.message = 'Circuit complete! Every free cell belongs to your byte train.';
      sound('win'); return;
    }
    const point = free[Math.min(free.length - 1, Math.floor(rng() * free.length))];
    state.food = { ...point, bonus: (state.eaten + 1) % 5 === 0 };
  }

  function warnObstacles() {
    if (state.obstacles.length >= 24) return;
    const occupied = new Set([...state.snake, ...state.obstacles, ...state.warnings, state.food].filter(Boolean).map(key));
    const candidates = [];
    // Sparse interior posts leave a two-cell outer circuit and never create a solid wall.
    for (let y = 3; y < ROWS - 3; y += 3) for (let x = 4; x < COLS - 4; x += 4) {
      const p = { x, y };
      if (!occupied.has(key(p)) && distance(p, state.snake[0]) >= 6) candidates.push(p);
    }
    for (let i = 0; i < 2 && candidates.length; i++) {
      const at = Math.min(candidates.length - 1, Math.floor(rng() * candidates.length));
      state.warnings.push({ ...candidates.splice(at, 1)[0], remaining: 1.2 });
    }
  }

  function queueTurn(next) {
    const previous = state.turns.at(-1) || state.direction;
    if (same(previous, next) || next.x === -previous.x && next.y === -previous.y || state.turns.length >= 2) return;
    state.turns.push({ ...next });
  }

  function lose(message) {
    state.status = 'lost'; state.message = message; sound('lose');
  }

  function step() {
    if (state.turns.length) state.direction = state.turns.shift();
    const h = state.snake[0], n = { x: h.x + state.direction.x, y: h.y + state.direction.y };
    if (n.x < 0 || n.y < 0 || n.x >= COLS || n.y >= ROWS) return lose('Circuit edge! Your byte train reached ' + state.snake.length + ' cells.');
    const eating = state.food && same(n, state.food);
    // The tail vacates its cell on a non-eating move, so entering that cell is legal.
    const body = eating ? state.snake : state.snake.slice(0, -1);
    if (body.some(p => same(p, n))) return lose('Tail tangled! Try planning an open route.');
    if (state.obstacles.some(p => same(p, n))) return lose('Circuit post! Watch the amber warning cells.');
    state.snake.unshift(n);
    if (eating) {
      state.score += (state.food.bonus ? 50 : 20) * state.level;
      state.eaten++; state.flash = 0.28;
      state.maxLength = Math.max(state.maxLength, state.snake.length);
      sound('score');
      const level = 1 + Math.floor(state.eaten / 5);
      if (level > state.level) {
        state.level = level;
        state.interval = Math.max(0.075, 0.16 - (level - 1) * 0.012);
        state.message = 'Circuit ' + level + ': faster bytes. Amber posts appear safely.';
        warnObstacles();
      }
      placeFood();
    } else state.snake.pop();
  }

  placeFood();

  function update(dt, input) {
    if (state.status !== 'playing') return;
    const pressed = name => input.pressed(name);
    for (const [name, d] of Object.entries(DIRS)) if (pressed(name)) queueTurn(d);
    if (input.pointer?.active && input.pointer.pressed) {
      const h = state.snake[0];
      const dx = input.pointer.x - (OX + h.x * CELL + CELL / 2);
      const dy = input.pointer.y - (OY + h.y * CELL + CELL / 2);
      if (Math.abs(dx) + Math.abs(dy) > 10)
        queueTurn(Math.abs(dx) > Math.abs(dy) ? dx > 0 ? DIRS.right : DIRS.left : dy > 0 ? DIRS.down : DIRS.up);
    }
    state.started = true;
    state.time += dt; state.flash = Math.max(0, state.flash - dt);
    for (const warning of state.warnings) warning.remaining -= dt;
    const expired = state.warnings.filter(p => p.remaining <= 0);
    state.warnings = state.warnings.filter(p => p.remaining > 0);
    for (const p of expired) {
      // If the player arrives during the warning, cancel the post rather than materializing
      // inside them or their next two cells. Fruit is never overwritten.
      if (distance(p, state.snake[0]) > 3 && !state.snake.some(s => same(s, p)) &&
          !same(p, state.food || { x: -1, y: -1 }) && !state.obstacles.some(s => same(s, p))) {
        state.obstacles.push({ x: p.x, y: p.y });
      }
    }
    state.accumulator += dt;
    while (state.accumulator + 1e-9 >= state.interval && state.status === 'playing') {
      state.accumulator -= state.interval; step();
    }
  }

  function draw(ctx) {
    ctx.imageSmoothingEnabled = false;
    ctx.fillStyle = '#152536'; ctx.fillRect(0, 0, 480, 320);
    ctx.fillStyle = '#fff0cf'; ctx.font = 'bold 13px monospace'; ctx.textAlign = 'left';
    ctx.fillText('BYTE MUNCH', 16, 21);
    ctx.fillStyle = '#61d5c8'; ctx.font = '11px monospace';
    ctx.fillText('CIRCUIT ' + String(state.level).padStart(2, '0'), 16, 37);
    ctx.textAlign = 'right'; ctx.fillStyle = '#ffc56a'; ctx.font = 'bold 17px monospace';
    ctx.fillText(String(state.score).padStart(5, '0'), 464, 23);
    ctx.fillStyle = '#afc4cc'; ctx.font = '10px monospace'; ctx.fillText('LENGTH ' + state.snake.length + '  /  ' + (5 - state.eaten % 5) + ' TO NEXT', 464, 37);
    ctx.fillStyle = '#315164'; ctx.fillRect(OX - 2, OY - 2, COLS * CELL + 4, ROWS * CELL + 4);
    for (let y = 0; y < ROWS; y++) for (let x = 0; x < COLS; x++) {
      ctx.fillStyle = (x + y) % 2 ? '#1c3243' : '#1b3040';
      ctx.fillRect(OX + x * CELL, OY + y * CELL, CELL, CELL);
    }
    for (const p of state.obstacles) {
      const x = OX + p.x * CELL, y = OY + p.y * CELL;
      ctx.fillStyle = '#536477'; ctx.fillRect(x + 1, y + 1, 14, 14);
      ctx.fillStyle = '#8c9aa7'; ctx.fillRect(x + 2, y + 2, 12, 3);
      ctx.fillStyle = '#152536'; ctx.fillRect(x + 6, y + 6, 4, 4);
    }
    for (const p of state.warnings) {
      const x = OX + p.x * CELL, y = OY + p.y * CELL;
      ctx.fillStyle = Math.floor(state.time * 8) % 2 ? '#ffc56a' : '#735a36';
      ctx.fillRect(x + 3, y + 3, 10, 2); ctx.fillRect(x + 3, y + 11, 10, 2);
      ctx.fillRect(x + 3, y + 3, 2, 10); ctx.fillRect(x + 11, y + 3, 2, 10);
    }
    if (state.food) {
      const x = OX + state.food.x * CELL, y = OY + state.food.y * CELL;
      ctx.fillStyle = state.food.bonus ? '#fa8068' : '#ffc56a';
      ctx.fillRect(x + 4, y + 2, 8, 12); ctx.fillRect(x + 2, y + 4, 12, 8);
      ctx.fillStyle = '#fff0cf'; ctx.fillRect(x + 4, y + 4, 3, 3);
      ctx.fillStyle = '#b57542'; ctx.fillRect(x + 9, y + 9, 3, 3);
    }
    for (let i = state.snake.length - 1; i >= 0; i--) {
      const p = state.snake[i], x = OX + p.x * CELL, y = OY + p.y * CELL;
      ctx.fillStyle = i === 0 ? state.flash > 0 ? '#fff0cf' : '#a2eee0' : i % 3 ? '#61d5c8' : '#46b4ae';
      ctx.fillRect(x + 1, y + 1, 14, 14);
      ctx.fillStyle = '#297c83'; ctx.fillRect(x + 2, y + 12, 12, 2);
      if (i) { ctx.fillStyle = '#8ae8d7'; ctx.fillRect(x + 3, y + 3, 3, 3); }
      else {
        ctx.fillStyle = '#152536';
        const d = state.direction;
        if (d.x) {
          const ex = x + (d.x > 0 ? 10 : 3);
          ctx.fillRect(ex, y + 3, 3, 3); ctx.fillRect(ex, y + 10, 3, 3);
        } else {
          const ey = y + (d.y > 0 ? 10 : 3);
          ctx.fillRect(x + 3, ey, 3, 3); ctx.fillRect(x + 10, ey, 3, 3);
        }
      }
    }
    ctx.textAlign = 'left'; ctx.font = '9px monospace'; ctx.fillStyle = '#afc4cc';
    ctx.fillText('TURN: ARROWS / WASD / D-PAD  •  GOLD +20  CORAL +50', 16, 317);
  }
  return { state, update, draw };
}
