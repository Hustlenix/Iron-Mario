/** Brick Burst: original endless paddle arena with swept, bounded substeps. */
const LEFT = 12, RIGHT = 468, TOP = 44;
const COLORS = ['#fa8068', '#ffc56a', '#b7a3e8', '#61d5c8', '#8dbae0', '#c7d78c'];
const clamp = (n, a, b) => Math.max(a, Math.min(b, n));
const overlaps = (b, r) => b.x + b.r > r.x && b.x - b.r < r.x + r.w && b.y + b.r > r.y && b.y - b.r < r.y + r.h;

export function createGame(api) {
  const rng = api.rng, sound = name => api.sound?.(name);
  const state = {
    status: 'playing', score: 0, message: 'Move the paddle. Press action or tap to launch.',
    level: 1, lives: 3, bricks: [], destroyed: 0, hits: 0, combo: 0, speed: 205,
    paddle: { x: 198, y: 284, w: 84, h: 10 },
    ball: { x: 240, y: 277, r: 4, vx: 0, vy: 0, docked: true },
    drops: [], sparks: [], trail: [], wideTime: 0, slowTime: 0, waveDelay: 0, time: 0
  };

  function buildWave() {
    const rows = Math.min(6, 4 + Math.floor((state.level + 1) / 2));
    const pattern = (state.level - 1) % 4;
    state.bricks = [];
    for (let row = 0; row < rows; row++) for (let col = 0; col < 10; col++) {
      // Four changing silhouettes; no unbreakable bricks can strand the last target.
      if (pattern === 1 && (row + col) % 5 === 0) continue;
      if (pattern === 2 && row < 2 && (col < 2 - row || col > 7 + row)) continue;
      if (pattern === 3 && row % 2 === 1 && (col === 4 || col === 5)) continue;
      const hp = state.level >= 5 && row === 0 ? 3 : state.level >= 2 && row < 2 ? 2 : 1;
      state.bricks.push({
        x: 22 + col * 44, y: 63 + row * 17, w: 40, h: 13,
        hp, maxHp: hp, row, color: COLORS[row],
        drop: row === rows - 1 && col === 2 ? 'wide' : row === 1 && col === 7 ? 'slow' : null
      });
    }
    state.speed = Math.min(340, 205 + (state.level - 1) * 19);
    state.drops = []; state.trail = []; state.combo = 0;
  }

  function dock() {
    state.ball.docked = true; state.ball.vx = 0; state.ball.vy = 0;
    state.ball.x = state.paddle.x + state.paddle.w / 2; state.ball.y = state.paddle.y - 7;
    state.trail = [];
  }

  function launch() {
    const vx = (rng() < 0.5 ? -1 : 1) * state.speed * 0.32;
    Object.assign(state.ball, { docked: false, vx, vy: -Math.sqrt(state.speed ** 2 - vx ** 2) });
    state.message = 'Aim with the paddle edges. Catch WIDE and SLOW chips.';
    sound('move');
  }

  function setSpeed(speed) {
    state.speed = Math.min(380, speed);
    const m = Math.hypot(state.ball.vx, state.ball.vy);
    if (m) {
      state.ball.vx = state.ball.vx / m * state.speed;
      state.ball.vy = state.ball.vy / m * state.speed;
    }
  }

  function loseBall() {
    state.lives--; state.combo = 0; state.wideTime = 0; state.slowTime = 0; state.drops = [];
    const center = state.paddle.x + state.paddle.w / 2;
    state.paddle.w = 84; state.paddle.x = clamp(center - 42, LEFT, RIGHT - 84);
    dock(); sound('lose');
    if (state.lives <= 0) {
      state.status = 'lost'; state.message = 'Out of paddles! Reached wave ' + state.level + ' with ' + state.score + ' points.';
    } else state.message = state.lives + ' lives left. Press action or tap to serve again.';
  }

  function hitBrick(brick) {
    brick.hp--; state.hits++;
    setSpeed(state.speed + 0.8);
    state.score += 5 * state.level;
    sound('hit');
    if (brick.hp <= 0) {
      state.destroyed++; state.combo++;
      state.score += (20 + Math.min(8, state.combo) * 2) * state.level;
      if (brick.drop) state.drops.push({ x: brick.x + 13, y: brick.y + 3, w: 14, h: 10, type: brick.drop });
      for (let i = 0; i < 5; i++)
        state.sparks.push({ x: brick.x + brick.w / 2, y: brick.y + 6, vx: (i - 2) * 24, vy: -42 - i % 2 * 16, life: 0.38, color: brick.color });
      sound('score');
    }
  }

  function bounceBrick(brick, px, py) {
    const b = state.ball;
    if (py + b.r <= brick.y + 0.001 && b.vy > 0) { b.y = brick.y - b.r; b.vy = -Math.abs(b.vy); }
    else if (py - b.r >= brick.y + brick.h - 0.001 && b.vy < 0) { b.y = brick.y + brick.h + b.r; b.vy = Math.abs(b.vy); }
    else if (px + b.r <= brick.x + 0.001 && b.vx > 0) { b.x = brick.x - b.r; b.vx = -Math.abs(b.vx); }
    else if (px - b.r >= brick.x + brick.w - 0.001 && b.vx < 0) { b.x = brick.x + brick.w + b.r; b.vx = Math.abs(b.vx); }
    else {
      // Resolve a simultaneous corner/fixture overlap along the least penetrating side.
      const sides = [
        { d: b.x + b.r - brick.x, x: brick.x - b.r, vx: -Math.abs(b.vx) },
        { d: brick.x + brick.w - b.x + b.r, x: brick.x + brick.w + b.r, vx: Math.abs(b.vx) },
        { d: b.y + b.r - brick.y, y: brick.y - b.r, vy: -Math.abs(b.vy) },
        { d: brick.y + brick.h - b.y + b.r, y: brick.y + brick.h + b.r, vy: Math.abs(b.vy) }
      ].sort((a, c) => a.d - c.d);
      const side = sides[0];
      if (side.x !== undefined) { b.x = side.x; b.vx = side.vx; }
      else { b.y = side.y; b.vy = side.vy; }
    }
    hitBrick(brick);
  }

  function moveBall(dt) {
    const b = state.ball, p = state.paddle;
    const factor = state.slowTime > 0 ? 0.72 : 1;
    // Three-pixel displacement cap is below the smallest collider thickness.
    const steps = Math.max(1, Math.ceil(Math.max(Math.abs(b.vx), Math.abs(b.vy)) * dt * factor / 3));
    const step = dt * factor / steps;
    for (let i = 0; i < steps && !b.docked && state.status === 'playing'; i++) {
      const px = b.x, py = b.y;
      b.x += b.vx * step; b.y += b.vy * step;
      if (b.x - b.r < LEFT) { b.x = LEFT + b.r; b.vx = Math.abs(b.vx); sound('hit'); }
      if (b.x + b.r > RIGHT) { b.x = RIGHT - b.r; b.vx = -Math.abs(b.vx); sound('hit'); }
      if (b.y - b.r < TOP) { b.y = TOP + b.r; b.vy = Math.abs(b.vy); sound('hit'); }
      if (b.vy > 0 && py + b.r <= p.y + 0.01 && overlaps(b, p)) {
        b.y = p.y - b.r;
        const offset = clamp((b.x - (p.x + p.w / 2)) / (p.w / 2), -1, 1);
        const angle = offset * Math.PI * 0.36;
        b.vx = Math.sin(angle) * state.speed;
        if (Math.abs(b.vx) < 18) b.vx = (b.vx < 0 ? -1 : 1) * 18;
        b.vy = -Math.sqrt(state.speed ** 2 - b.vx ** 2);
        state.combo = 0; sound('hit');
      }
      for (const brick of state.bricks) {
        if (brick.hp > 0 && overlaps(b, brick)) { bounceBrick(brick, px, py); break; }
      }
      if (b.y - b.r > 320) { loseBall(); break; }
      if (!state.bricks.some(brick => brick.hp > 0)) {
        state.score += 200 * state.level;
        state.waveDelay = 1; dock(); sound('win');
        state.message = 'Wave ' + state.level + ' clear! +' + 200 * state.level;
        break;
      }
    }
  }

  function updateDrops(dt) {
    for (const d of state.drops) {
      const oldY = d.y;
      d.y += 74 * dt;
      const p = state.paddle;
      if (d.x + d.w > p.x && d.x < p.x + p.w && oldY <= p.y + p.h && d.y + d.h >= p.y) {
        if (d.type === 'wide') {
          const center = p.x + p.w / 2; state.wideTime = 12; p.w = 116; p.x = clamp(center - 58, LEFT, RIGHT - p.w);
        } else state.slowTime = 10;
        state.score += 25; d.y = 1000; sound('score');
      }
    }
    state.drops = state.drops.filter(d => d.y < 320);
  }

  function update(dt, input) {
    if (state.status !== 'playing') return;
    state.time += dt;
    state.wideTime = Math.max(0, state.wideTime - dt); state.slowTime = Math.max(0, state.slowTime - dt);
    const p = state.paddle;
    if (state.wideTime === 0 && p.w !== 84) {
      const center = p.x + p.w / 2; p.w = 84; p.x = clamp(center - 42, LEFT, RIGHT - p.w);
    }
    const direction = Number(input.down('right')) - Number(input.down('left'));
    if (direction) p.x += direction * 390 * dt;
    else if (input.pointer?.active && input.pointer.down) {
      const target = input.pointer.x - p.w / 2;
      p.x += clamp(target - p.x, -650 * dt, 650 * dt);
    }
    p.x = clamp(p.x, LEFT, RIGHT - p.w);
    for (const s of state.sparks) { s.x += s.vx * dt; s.y += s.vy * dt; s.vy += 180 * dt; s.life -= dt; }
    state.sparks = state.sparks.filter(s => s.life > 0);
    if (state.waveDelay > 0) {
      state.waveDelay = Math.max(0, state.waveDelay - dt);
      if (state.waveDelay === 0) {
        state.level++;
        if (state.level % 3 === 0) state.lives = Math.min(5, state.lives + 1);
        state.wideTime = 0; state.slowTime = 0;
        const center = p.x + p.w / 2; p.w = 84; p.x = clamp(center - 42, LEFT, RIGHT - 84);
        buildWave(); dock();
        state.message = 'Wave ' + state.level + (state.level % 3 === 0 ? ' • extra life!' : '') + ' Press action to serve.';
      }
      return;
    }
    updateDrops(dt);
    if (state.ball.docked) {
      state.ball.x = p.x + p.w / 2; state.ball.y = p.y - 7;
      if (input.pressed('action') || input.pointer?.active && input.pointer.pressed) launch();
    } else {
      state.trail.unshift({ x: state.ball.x, y: state.ball.y }); state.trail.length = Math.min(state.trail.length, 5);
      moveBall(dt);
    }
  }

  function draw(ctx) {
    ctx.imageSmoothingEnabled = false;
    ctx.fillStyle = '#152536'; ctx.fillRect(0, 0, 480, 320);
    ctx.fillStyle = '#fff0cf'; ctx.font = 'bold 13px monospace'; ctx.textAlign = 'left';
    ctx.fillText('BRICK BURST', 16, 20);
    ctx.fillStyle = '#afc4cc'; ctx.font = '10px monospace'; ctx.fillText('WAVE ' + String(state.level).padStart(2, '0'), 16, 35);
    for (let i = 0; i < state.lives; i++) {
      ctx.fillStyle = '#fa8068'; ctx.fillRect(89 + i * 12, 27, 8, 5); ctx.fillRect(91 + i * 12, 25, 4, 9);
    }
    ctx.textAlign = 'right'; ctx.fillStyle = '#ffc56a'; ctx.font = 'bold 17px monospace';
    ctx.fillText(String(state.score).padStart(5, '0'), 464, 23);
    ctx.fillStyle = '#afc4cc'; ctx.font = '10px monospace';
    ctx.fillText(state.bricks.filter(b => b.hp > 0).length + ' BRICKS', 464, 36);
    ctx.fillStyle = '#1b3040'; ctx.fillRect(LEFT, TOP, RIGHT - LEFT, 276);
    ctx.fillStyle = '#2c4558';
    for (let y = 48; y < 284; y += 16) for (let x = 20; x < 464; x += 16) ctx.fillRect(x, y, 1, 1);
    ctx.fillStyle = '#4a687d'; ctx.fillRect(8, TOP, 4, 276); ctx.fillRect(RIGHT, TOP, 4, 276); ctx.fillRect(8, TOP - 3, 464, 3);
    for (const b of state.bricks) {
      if (b.hp <= 0) continue;
      ctx.fillStyle = '#0d1d2b'; ctx.fillRect(b.x + 1, b.y + 2, b.w, b.h);
      ctx.fillStyle = b.color; ctx.fillRect(b.x, b.y, b.w, b.h - 1);
      ctx.fillStyle = '#fff0cf'; ctx.fillRect(b.x + 2, b.y + 1, b.w - 4, 1);
      ctx.fillStyle = '#152536';
      if (b.hp > 1) for (let n = 0; n < b.hp; n++) ctx.fillRect(b.x + 13 + n * 5, b.y + 5, 3, 3);
      if (b.maxHp > b.hp) {
        ctx.fillRect(b.x + 20, b.y + 2, 2, 4); ctx.fillRect(b.x + 18, b.y + 6, 2, 4);
      }
      if (b.drop) { ctx.fillStyle = '#152536'; ctx.fillRect(b.x + 3, b.y + 5, 3, 3); }
    }
    for (const d of state.drops) {
      const x = Math.round(d.x), y = Math.round(d.y);
      ctx.fillStyle = d.type === 'wide' ? '#61d5c8' : '#b7a3e8'; ctx.fillRect(x, y, d.w, d.h);
      ctx.fillStyle = '#152536'; ctx.font = 'bold 9px monospace'; ctx.textAlign = 'center'; ctx.fillText(d.type === 'wide' ? 'W' : 'S', x + 7, y + 8);
    }
    for (let i = state.trail.length - 1; i >= 0; i--) {
      ctx.fillStyle = i > 2 ? '#315164' : '#618b91';
      ctx.fillRect(Math.round(state.trail[i].x) - 2, Math.round(state.trail[i].y) - 2, 4, 4);
    }
    const p = state.paddle, b = state.ball;
    ctx.fillStyle = '#0d1d2b'; ctx.fillRect(Math.round(p.x), p.y + 4, p.w, p.h);
    ctx.fillStyle = state.wideTime ? '#ffc56a' : '#61d5c8'; ctx.fillRect(Math.round(p.x), p.y, p.w, p.h);
    ctx.fillStyle = '#fff0cf'; ctx.fillRect(Math.round(p.x) + 5, p.y + 1, p.w - 10, 2);
    ctx.fillStyle = '#297c83'; ctx.fillRect(Math.round(p.x) + 5, p.y + 7, p.w - 10, 2);
    ctx.fillStyle = '#fff0cf'; ctx.fillRect(Math.round(b.x) - 4, Math.round(b.y) - 4, 8, 8);
    ctx.fillStyle = '#ffc56a'; ctx.fillRect(Math.round(b.x) + 1, Math.round(b.y) + 1, 3, 3);
    for (const s of state.sparks) { ctx.fillStyle = s.color; ctx.fillRect(Math.round(s.x), Math.round(s.y), 3, 3); }
    ctx.textAlign = 'center'; ctx.font = 'bold 11px monospace'; ctx.fillStyle = '#fff0cf';
    if (state.waveDelay > 0) ctx.fillText('WAVE CLEAR! +' + 200 * state.level, 240, 220);
    else if (b.docked && state.status === 'playing') {
      ctx.fillText('ACTION / TAP TO LAUNCH', 240, 225);
      ctx.font = '10px monospace'; ctx.fillStyle = '#afc4cc'; ctx.fillText('MOVE: LEFT / RIGHT OR DRAG', 240, 242);
    }
    ctx.textAlign = 'left'; ctx.font = '9px monospace'; ctx.fillStyle = '#afc4cc';
    ctx.fillText(state.wideTime ? 'WIDE ' + Math.ceil(state.wideTime) + 's' : 'EDGE HIT = STEEPER ANGLE', 16, 313);
    ctx.textAlign = 'right';
    ctx.fillText(state.slowTime ? 'SLOW ' + Math.ceil(state.slowTime) + 's' : 'EVERY 3RD WAVE: +1 LIFE', 464, 313);
  }

  buildWave(); dock();
  return { state, update, draw };
}
