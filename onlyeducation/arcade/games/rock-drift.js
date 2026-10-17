import { clamp } from '../engine/math.js';

export const FIELD = Object.freeze({ width: 480, top: 28, height: 268 });
export const WAVES = 3;
const TAU = Math.PI * 2;
const RADII = [0, 9, 16, 25];
export const wrap = (value, size) => ((value % size) + size) % size;
export const torusDelta = (a, b, size) => wrap(a - b + size / 2, size) - size / 2;
export function segmentCircle(ax, ay, bx, by, cx, cy, radius) {
  const dx = bx - ax, dy = by - ay;
  const t = clamp(((cx - ax) * dx + (cy - ay) * dy) / (dx * dx + dy * dy || 1), 0, 1);
  return (ax + t * dx - cx) ** 2 + (ay + t * dy - cy) ** 2 <= radius ** 2;
}
function torusDistance(a, b) {
  return Math.hypot(torusDelta(a.x, b.x, FIELD.width), torusDelta(a.y, b.y, FIELD.height));
}

export function createGame(api) {
  const sound = name => api.sound?.(name);
  const s = {
    status: 'playing', score: 0, message: 'Turn, thrust, coast. Clear three debris fields.',
    level: 1, lives: 3, phase: 'flight', waveTime: 0, time: 0, nextId: 1,
    ship: { x: 240, y: 162, vx: 0, vy: 0, angle: -Math.PI / 2, shield: 2, thrust: false },
    rocks: [], bullets: [], sparks: [], cooldown: 0, shots: 0, destroyed: 0,
  };
  const stars = Array.from({ length: 38 }, () => ({ x: Math.floor(api.rng() * 480), y: 30 + Math.floor(api.rng() * 264), bright: api.rng() > 0.75 }));
  function rock(x, y, size, angle = api.rng() * TAU) {
    const speed = 20 + s.level * 9 + (3 - size) * 18 + api.rng() * 12;
    return { id: s.nextId++, x: wrap(x, 480), y: 28 + wrap(y - 28, 268), size, radius: RADII[size], vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed, spin: api.rng() * TAU, turn: (api.rng() - 0.5) * 1.4 };
  }
  function beginWave() {
    s.rocks = [];
    for (let i = 0; i < s.level + 1; i += 1) {
      const angle = TAU * i / (s.level + 1) + api.rng() * 0.5;
      s.rocks.push(rock(240 + Math.cos(angle) * 190, 162 + Math.sin(angle) * 104, 3));
    }
    s.phase = 'flight';
    s.ship.shield = Math.max(1.5, s.ship.shield);
    s.message = `FIELD ${s.level} / ${WAVES}: large rocks split into faster fragments.`;
  }
  function burst(x, y, color, count = 10) {
    for (let i = 0; i < count; i += 1) {
      const angle = TAU * i / count;
      s.sparks.push({ x, y, vx: Math.cos(angle) * (20 + i * 3), vy: Math.sin(angle) * (20 + i * 3), life: 0.35, color });
    }
  }
  function safeRespawn() {
    let safe = { x: 240, y: 162 }, clearance = -Infinity;
    for (const y of [78, 162, 246]) for (const x of [80, 160, 240, 320, 400]) {
      const point = { x, y };
      const distance = Math.min(...s.rocks.map(r => torusDistance(point, r) - r.radius), 1000);
      if (distance > clearance) { safe = point; clearance = distance; }
    }
    Object.assign(s.ship, safe, { vx: 0, vy: 0, angle: -Math.PI / 2, shield: 2.2 });
  }
  function destroyRock(index) {
    const r = s.rocks.splice(index, 1)[0];
    s.destroyed += 1;
    s.score += [0, 100, 50, 25][r.size];
    burst(r.x, r.y, '#ffc56a');
    sound('score');
    if (r.size > 1) {
      const heading = Math.atan2(r.vy, r.vx);
      s.rocks.push(rock(r.x - 4, r.y, r.size - 1, heading - 0.9), rock(r.x + 4, r.y, r.size - 1, heading + 0.9));
    }
  }
  beginWave();

  function update(dt, input) {
    if (s.status !== 'playing') return;
    dt = clamp(dt, 0, 0.05);
    s.time += dt;
    s.cooldown = Math.max(0, s.cooldown - dt);
    s.ship.shield = Math.max(0, s.ship.shield - dt);
    for (const p of s.sparks) { p.x += p.vx * dt; p.y += p.vy * dt; p.life -= dt; }
    s.sparks = s.sparks.filter(p => p.life > 0);
    if (s.phase === 'intermission') {
      s.waveTime -= dt;
      if (s.waveTime <= 0) { s.level += 1; beginWave(); }
      return;
    }
    const ship = s.ship;
    const turn = Number(input.down('right')) - Number(input.down('left'));
    ship.angle = wrap(ship.angle + turn * 3.35 * dt + Math.PI, TAU) - Math.PI;
    ship.thrust = input.down('up');
    if (ship.thrust) { ship.vx += Math.cos(ship.angle) * 155 * dt; ship.vy += Math.sin(ship.angle) * 155 * dt; }
    const drag = Math.exp(-(input.down('down') || input.down('secondary') ? 3.8 : 0.12) * dt);
    ship.vx *= drag; ship.vy *= drag;
    const speed = Math.hypot(ship.vx, ship.vy);
    if (speed > 200) { ship.vx *= 200 / speed; ship.vy *= 200 / speed; }
    ship.x = wrap(ship.x + ship.vx * dt, 480);
    ship.y = 28 + wrap(ship.y - 28 + ship.vy * dt, 268);
    if ((input.down('action') || input.pressed('action')) && s.cooldown <= 0) {
      s.bullets.push({ x: ship.x + Math.cos(ship.angle) * 13, y: ship.y + Math.sin(ship.angle) * 13, vx: Math.cos(ship.angle) * 330 + ship.vx, vy: Math.sin(ship.angle) * 330 + ship.vy, life: 0.95 });
      s.cooldown = 0.18; s.shots += 1; sound('move');
    }
    for (const r of s.rocks) {
      r.x = wrap(r.x + r.vx * dt, 480); r.y = 28 + wrap(r.y - 28 + r.vy * dt, 268); r.spin += r.turn * dt;
    }
    for (const b of s.bullets) {
      const endX = b.x + b.vx * dt, endY = b.y + b.vy * dt;
      b.life -= dt;
      if (b.life > 0) {
        const index = s.rocks.findIndex(r => {
          const cx = b.x + torusDelta(r.x, b.x, 480), cy = b.y + torusDelta(r.y, b.y, 268);
          return segmentCircle(b.x, b.y, endX, endY, cx, cy, r.radius + 2);
        });
        if (index >= 0) { destroyRock(index); b.life = 0; }
      }
      b.x = wrap(endX, 480); b.y = 28 + wrap(endY - 28, 268);
    }
    s.bullets = s.bullets.filter(b => b.life > 0);
    if (ship.shield <= 0 && s.rocks.some(r => torusDistance(ship, r) < r.radius + 7)) {
      s.lives -= 1; burst(ship.x, ship.y, '#fa8068', 16); sound('hit');
      if (!s.lives) { s.status = 'lost'; s.message = 'Ship lost. Short thrusts and braking make space to aim.'; sound('lose'); return; }
      safeRespawn(); s.message = 'New ship. The ring protects you briefly; make some room.';
    }
    if (!s.rocks.length) {
      s.bullets = [];
      if (s.level === WAVES) { s.status = 'won'; s.score += s.lives * 250; s.message = 'ALL FIELDS CLEAR. The orbital workshop is safe!'; sound('win'); }
      else { s.phase = 'intermission'; s.waveTime = 1.6; s.score += 100; s.message = 'FIELD CLEAR. Next debris field approaching...'; sound('score'); }
    }
  }

  function text(ctx, value, x, y, size = 10, color = '#fff0cf', align = 'left') {
    ctx.fillStyle = color; ctx.font = `bold ${size}px monospace`; ctx.textBaseline = 'top'; ctx.textAlign = align; ctx.fillText(value, x, y);
  }
  function draw(ctx) {
    ctx.save(); ctx.imageSmoothingEnabled = false;
    ctx.fillStyle = '#101f30'; ctx.fillRect(0, 0, 480, 320);
    for (const star of stars) { ctx.fillStyle = star.bright ? '#70848d' : '#2b4257'; ctx.fillRect(star.x, star.y, star.bright ? 2 : 1, 1); }
    ctx.save(); ctx.beginPath(); ctx.rect(0, 28, 480, 268); ctx.clip();
    for (const r of s.rocks) {
      // Draw adjacent images too: a wrapping rock never vanishes at the boundary.
      for (const dx of [-480, 0, 480]) for (const dy of [-268, 0, 268]) {
        const x = Math.round(r.x + dx), y = Math.round(r.y + dy);
        if (x < -32 || x > 512 || y < 0 || y > 324) continue;
        if (api.sprite && r.size > 1) { const scale = r.size === 3 ? 2 : 1; api.sprite(ctx, 'pieces_rock', x - 16 * scale, y - 16 * scale, { scale }); }
        else { ctx.fillStyle = '#536879'; ctx.fillRect(x - r.radius + 3, y - r.radius, r.radius * 2 - 6, r.radius * 2); ctx.fillRect(x - r.radius, y - r.radius + 3, r.radius * 2, r.radius * 2 - 6); ctx.fillStyle = '#8a9ca0'; ctx.fillRect(x - 4, y - r.radius + 2, 7, 3); }
      }
    }
    ctx.fillStyle = '#ffc56a'; for (const b of s.bullets) ctx.fillRect(Math.round(b.x) - 2, Math.round(b.y) - 2, 4, 4);
    const ship = s.ship;
    if (s.status !== 'lost') {
      ctx.save(); ctx.translate(Math.round(ship.x), Math.round(ship.y)); ctx.rotate(ship.angle + Math.PI / 2);
      if (ship.thrust && s.phase === 'flight') { ctx.fillStyle = '#fa8068'; ctx.fillRect(-3, 11, 6, 5 + Math.floor(s.time * 20) % 5); ctx.fillStyle = '#ffc56a'; ctx.fillRect(-1, 10, 2, 5); }
      if (api.sprite) api.sprite(ctx, 'pieces_ship', -16, -16);
      else { ctx.fillStyle = '#61d5c8'; ctx.beginPath(); ctx.moveTo(0, -12); ctx.lineTo(9, 10); ctx.lineTo(0, 6); ctx.lineTo(-9, 10); ctx.closePath(); ctx.fill(); }
      ctx.restore();
      if (ship.shield > 0) { ctx.strokeStyle = '#61d5c8'; ctx.lineWidth = 1; ctx.strokeRect(Math.round(ship.x) - 19, Math.round(ship.y) - 19, 38, 38); }
    }
    for (const p of s.sparks) { ctx.fillStyle = p.color; ctx.fillRect(Math.round(p.x), Math.round(p.y), 2, 2); }
    ctx.restore();
    ctx.fillStyle = '#20364a'; ctx.fillRect(0, 0, 480, 28); ctx.fillRect(0, 296, 480, 24);
    text(ctx, 'ROCK DRIFT', 12, 8, 12, '#ffc56a'); text(ctx, `FIELD ${s.level}/${WAVES}`, 164, 9); text(ctx, `SHIPS ${s.lives}`, 280, 9, 10, '#61d5c8'); text(ctx, String(s.score).padStart(5, '0'), 468, 8, 12, '#fff0cf', 'right');
    text(ctx, 'LEFT/RIGHT TURN   UP THRUST   DOWN BRAKE   ACTION FIRE', 240, 305, 9, '#90b7d8', 'center');
    if (s.phase === 'intermission') { ctx.fillStyle = '#152536'; ctx.fillRect(104, 132, 272, 52); text(ctx, 'DEBRIS FIELD CLEAR', 240, 142, 16, '#61d5c8', 'center'); text(ctx, 'CATCH YOUR BREATH. MORE ON THE WAY.', 240, 166, 9, '#fff0cf', 'center'); }
    ctx.restore();
  }
  return { state: s, update, draw };
}
