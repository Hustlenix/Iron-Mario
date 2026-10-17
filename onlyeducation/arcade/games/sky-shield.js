import { clamp } from '../engine/math.js';

export const WAVES = 3;
export const GROUND = 276;
export function blastRadius(age) {
  if (age < 0 || age >= 1.15) return 0;
  if (age < 0.25) return age / 0.25 * 36;
  if (age < 0.72) return 36;
  return (1.15 - age) / 0.43 * 36;
}
export function segmentHitsCircle(ax, ay, bx, by, cx, cy, radius) {
  const dx = bx - ax, dy = by - ay;
  const t = clamp(((cx - ax) * dx + (cy - ay) * dy) / (dx * dx + dy * dy || 1), 0, 1);
  return (ax + t * dx - cx) ** 2 + (ay + t * dy - cy) ** 2 <= radius ** 2;
}

export function createGame(api) {
  const sound = name => api.sound?.(name);
  const s = {
    status: 'playing', score: 0, message: 'Aim ahead of falling missiles. One burst can catch a group.',
    level: 1, phase: 'defend', waveTime: 0, time: 0, nextId: 1,
    cities: [72, 168, 312, 408].map(x => ({ x, hp: 2 })), lives: 4,
    aim: { x: 240, y: 150 }, lastPointer: null, ammo: 14, maxAmmo: 14,
    remaining: 10, spawned: 0, spawnTimer: 1.8, cooldown: 0,
    missiles: [], interceptors: [], blasts: [], impacts: [], intercepted: 0, shots: 0,
  };
  const clouds = Array.from({ length: 8 }, () => ({ x: Math.floor(api.rng() * 480), y: 50 + Math.floor(api.rng() * 150), w: 30 + Math.floor(api.rng() * 40) }));
  function spawnMissile() {
    const targets = s.cities.map((c, index) => ({ ...c, index })).filter(c => c.hp > 0);
    if (!targets.length) return;
    const city = targets[Math.floor(api.rng() * targets.length)];
    const x = 16 + api.rng() * 448, y = 30;
    const speed = 25 + s.level * 8 + api.rng() * 9;
    const distance = Math.hypot(city.x - x, GROUND - y);
    s.missiles.push({ id: s.nextId++, x, y, ox: x, oy: y, vx: (city.x - x) / distance * speed, vy: (GROUND - y) / distance * speed, target: city.index });
    s.spawned += 1; s.remaining -= 1;
  }
  function launch() {
    if (s.cooldown > 0) return;
    if (!s.ammo) { s.message = 'Battery empty. Existing bursts still protect the skyline.'; return; }
    const x = 240, y = 278, tx = s.aim.x, ty = s.aim.y;
    const distance = Math.hypot(tx - x, ty - y);
    s.interceptors.push({ x, y, ox: x, oy: y, tx, ty, vx: (tx - x) / distance * 245, vy: (ty - y) / distance * 245 });
    s.ammo -= 1; s.shots += 1; s.cooldown = 0.24; sound('move');
  }
  function nextWave() {
    s.level += 1; s.phase = 'defend'; s.maxAmmo = 11 + s.level * 3; s.ammo = s.maxAmmo;
    s.remaining = 6 + s.level * 4; s.spawned = 0; s.spawnTimer = 1.2; s.cooldown = 0;
    s.message = `WAVE ${s.level}/${WAVES}: battery refilled. Faster missiles incoming.`;
  }
  function update(dt, input) {
    if (s.status !== 'playing') return;
    dt = clamp(dt, 0, 0.05); s.time += dt;
    s.cooldown = Math.max(0, s.cooldown - dt);
    for (const b of s.blasts) b.age += dt;
    s.blasts = s.blasts.filter(b => b.age < 1.15);
    for (const p of s.impacts) p.age += dt;
    s.impacts = s.impacts.filter(p => p.age < 0.65);
    if (s.phase === 'intermission') { s.waveTime -= dt; if (s.waveTime <= 0) nextWave(); return; }
    const dx = Number(input.down('right')) - Number(input.down('left'));
    const dy = Number(input.down('down')) - Number(input.down('up'));
    const pointer = input.pointer;
    if (dx || dy) { s.aim.x += dx * 185 * dt; s.aim.y += dy * 185 * dt; }
    else if (pointer.active && (!s.lastPointer || pointer.pressed || pointer.x !== s.lastPointer.x || pointer.y !== s.lastPointer.y)) {
      s.aim.x = pointer.x; s.aim.y = pointer.y;
    }
    s.lastPointer = pointer.active ? { x: pointer.x, y: pointer.y } : null;
    s.aim.x = clamp(s.aim.x, 16, 464); s.aim.y = clamp(s.aim.y, 42, 250);
    if (input.pressed('action') || input.down('action') || (pointer.active && (pointer.down || pointer.pressed))) launch();
    if (s.remaining > 0) {
      s.spawnTimer -= dt;
      if (s.spawnTimer <= 0) { spawnMissile(); s.spawnTimer = Math.max(0.58, 1.45 - s.level * 0.18) + api.rng() * 0.35; }
    }
    const flying = [];
    for (const rocket of s.interceptors) {
      const left = Math.hypot(rocket.tx - rocket.x, rocket.ty - rocket.y);
      if (left <= 245 * dt) { s.blasts.push({ x: rocket.tx, y: rocket.ty, age: 0.06, chain: false }); sound('hit'); }
      else { rocket.x += rocket.vx * dt; rocket.y += rocket.vy * dt; flying.push(rocket); }
    }
    s.interceptors = flying;
    const incoming = [], chains = [];
    for (const m of s.missiles) {
      const nx = m.x + m.vx * dt, ny = m.y + m.vy * dt;
      if (s.blasts.some(b => segmentHitsCircle(m.x, m.y, nx, ny, b.x, b.y, blastRadius(b.age) + 3))) {
        s.intercepted += 1; s.score += 50 * s.level; sound('score');
        chains.push({ x: nx, y: ny, age: 0.06, chain: true });
        s.message = 'INTERCEPT! Keep bursts ahead of the next flight path.';
      } else if (ny >= GROUND) {
        const city = s.cities[m.target];
        if (city.hp > 0) { city.hp -= 1; sound('hit'); }
        s.impacts.push({ x: city.x, y: GROUND, age: 0 });
        s.message = city.hp ? 'City hit. One shield left here.' : 'City lost. Protect the remaining lights.';
      } else { m.x = nx; m.y = ny; incoming.push(m); }
    }
    s.missiles = incoming; s.blasts.push(...chains);
    s.lives = s.cities.filter(c => c.hp > 0).length;
    if (!s.lives) { s.status = 'lost'; s.message = 'The skyline fell. Lead the missiles and group your bursts.'; sound('lose'); return; }
    if (s.remaining === 0 && !s.missiles.length && !s.interceptors.length) {
      s.score += s.lives * 100 + s.ammo * 5;
      if (s.level === WAVES) { s.status = 'won'; s.message = `SKYLINE SAFE! ${s.lives} cities survived all three waves.`; sound('win'); }
      else { s.phase = 'intermission'; s.waveTime = 1.8; s.message = 'WAVE CLEAR. Battery refill arriving...'; sound('score'); }
    }
  }

  function text(ctx, value, x, y, size = 10, color = '#fff0cf', align = 'left') {
    ctx.fillStyle = color; ctx.font = `bold ${size}px monospace`; ctx.textBaseline = 'top'; ctx.textAlign = align; ctx.fillText(value, x, y);
  }
  function line(ctx, ax, ay, bx, by, color, width = 1) {
    ctx.strokeStyle = color; ctx.lineWidth = width; ctx.beginPath(); ctx.moveTo(Math.round(ax), Math.round(ay)); ctx.lineTo(Math.round(bx), Math.round(by)); ctx.stroke();
  }
  function draw(ctx) {
    ctx.save(); ctx.imageSmoothingEnabled = false;
    ctx.fillStyle = '#12253a'; ctx.fillRect(0, 0, 480, 320);
    ctx.fillStyle = '#1c3448';
    for (const c of clouds) { ctx.fillRect(c.x, c.y, c.w, 2); ctx.fillRect(c.x + 8, c.y - 3, c.w - 16, 2); }
    for (const m of s.missiles) { line(ctx, m.ox, m.oy, m.x, m.y, '#743f4a'); ctx.fillStyle = '#fa8068'; ctx.fillRect(Math.round(m.x) - 2, Math.round(m.y) - 2, 5, 5); }
    for (const r of s.interceptors) { line(ctx, r.ox, r.oy, r.x, r.y, '#3b6874'); ctx.fillStyle = '#61d5c8'; ctx.fillRect(Math.round(r.x) - 2, Math.round(r.y) - 2, 4, 4); }
    for (const b of s.blasts) {
      const radius = Math.floor(blastRadius(b.age));
      ctx.fillStyle = b.chain ? '#326b73' : '#377a79';
      // Horizontal bands create an intentionally pixel-stepped circular field.
      for (let y = -radius; y <= radius; y += 4) { const half = Math.floor(Math.sqrt(Math.max(0, radius * radius - y * y)) / 4) * 4; ctx.fillRect(Math.round(b.x) - half, Math.round(b.y) + y, half * 2, 4); }
      ctx.strokeStyle = '#b7f5dc'; ctx.lineWidth = 1; ctx.strokeRect(Math.round(b.x) - 4, Math.round(b.y) - 4, 8, 8);
    }
    ctx.fillStyle = '#263c4e'; ctx.fillRect(0, 276, 480, 23);
    ctx.fillStyle = '#597177'; ctx.fillRect(0, 276, 480, 3);
    for (const [i, city] of s.cities.entries()) {
      const x = city.x;
      if (city.hp > 0) {
        ctx.fillStyle = city.hp === 2 ? '#779b9e' : '#8d7277'; ctx.fillRect(x - 17, 252, 34, 24); ctx.fillRect(x - 10, 242, 20, 10);
        ctx.fillStyle = '#fff0cf'; for (let py = 252; py <= 264; py += 8) for (let px = -11; px <= 11; px += 11) ctx.fillRect(x + px, py, 4, 4);
        ctx.fillStyle = '#61d5c8'; for (let hp = 0; hp < city.hp; hp += 1) ctx.fillRect(x - 7 + hp * 9, 283, 6, 4);
      } else { ctx.fillStyle = '#775561'; ctx.fillRect(x - 17, 270, 34, 6); line(ctx, x - 6, 255, x + 6, 267, '#fa8068', 2); line(ctx, x + 6, 255, x - 6, 267, '#fa8068', 2); }
      text(ctx, String(i + 1), x - 23, 263, 8, '#90b7d8');
    }
    for (const p of s.impacts) { const radius = Math.floor(p.age * 35); ctx.strokeStyle = '#fa8068'; ctx.lineWidth = 2; ctx.strokeRect(p.x - radius, p.y - radius, radius * 2, radius); }
    if (api.sprite) api.sprite(ctx, 'pieces_turret', 224, 254);
    else { ctx.fillStyle = '#61d5c8'; ctx.fillRect(227, 274, 26, 12); ctx.fillRect(237, 262, 6, 14); }
    const ax = Math.round(s.aim.x), ay = Math.round(s.aim.y);
    ctx.strokeStyle = '#ffc56a'; ctx.lineWidth = 1; ctx.strokeRect(ax - 7, ay - 7, 14, 14); line(ctx, ax - 12, ay, ax - 4, ay, '#ffc56a'); line(ctx, ax + 4, ay, ax + 12, ay, '#ffc56a'); line(ctx, ax, ay - 12, ax, ay - 4, '#ffc56a'); line(ctx, ax, ay + 4, ax, ay + 12, '#ffc56a');
    ctx.fillStyle = '#20364a'; ctx.fillRect(0, 0, 480, 28); ctx.fillRect(0, 298, 480, 22);
    text(ctx, 'SKY SHIELD', 12, 8, 12, '#ffc56a'); text(ctx, `WAVE ${s.level}/${WAVES}`, 153, 9); text(ctx, `AMMO ${s.ammo}`, 260, 9, 10, s.ammo < 4 ? '#fa8068' : '#61d5c8'); text(ctx, `${s.lives} CITIES`, 379, 9);
    text(ctx, 'AIM: POINTER / ARROWS   FIRE: TAP / ACTION   LEAD THE TARGET', 240, 305, 8, '#90b7d8', 'center');
    if (s.phase === 'intermission') { ctx.fillStyle = '#152536'; ctx.fillRect(102, 125, 276, 55); text(ctx, 'SKYLINE HOLDING', 240, 135, 16, '#61d5c8', 'center'); text(ctx, 'FRESH BATTERY ON THE WAY', 240, 160, 10, '#fff0cf', 'center'); }
    ctx.restore();
  }
  return { state: s, update, draw };
}
