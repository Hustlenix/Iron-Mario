import test from 'node:test';
import assert from 'node:assert/strict';
import { random } from '../../onlyeducation/arcade/engine/math.js';
import { createGame as createRock, wrap, torusDelta, segmentCircle } from '../../onlyeducation/arcade/games/rock-drift.js';
import { createGame as createSky, blastRadius, segmentHitsCircle } from '../../onlyeducation/arcade/games/sky-shield.js';

const controls = (down = [], pressed = [], pointer = {}) => ({ down: key => down.includes(key), pressed: key => pressed.includes(key), pointer: { x: 240, y: 160, active: false, down: false, pressed: false, ...pointer } });
const rockGame = (seed = 1972) => createRock({ rng: random(seed), sound() {} });
const skyGame = (seed = 1980) => createSky({ rng: random(seed), sound() {} });
const tick = (g, down = [], pressed = [], pointer = {}, dt = 1 / 60) => g.update(dt, controls(down, pressed, pointer));
const stationaryRock = (size = 3, x = 100, y = 100) => ({ id: 900, size, radius: [0, 9, 16, 25][size], x, y, vx: 0, vy: 0, spin: 0, turn: 0 });
const bullet = (x, y, vx = 0, vy = 0) => ({ x, y, vx, vy, life: 1 });
const missile = (x, y, target = 0, vx = 0, vy = 0) => ({ id: 900, x, y, ox: x, oy: y, vx, vy, target });

test('toroidal geometry wraps negatives and returns the shortest signed offset', () => {
  assert.equal(wrap(-1, 480), 479);
  assert.equal(wrap(481, 480), 1);
  assert.equal(torusDelta(2, 478, 480), 4);
  assert.equal(torusDelta(478, 2, 480), -4);
  assert.equal(segmentCircle(0, 0, 30, 0, 14, 1, 2), true);
  assert.equal(segmentCircle(0, 0, 30, 0, 14, 3, 2), false);
});

test('Rock Drift seed and identical control history reproduce the full run', () => {
  const a = rockGame(), b = rockGame();
  assert.notDeepEqual(a.state.rocks, rockGame(44).state.rocks);
  for (let i = 0; i < 1200; i += 1) {
    const down = ['action', ...(i % 170 < 110 ? ['right'] : []), ...(i % 130 < 50 ? ['up'] : [])];
    tick(a, down); tick(b, down);
  }
  assert.deepEqual(a.state, b.state);
  assert.ok(a.state.shots > 0);
});

test('thrust adds inertia, coasting keeps momentum, braking removes it, rotation changes heading', () => {
  const g = rockGame();
  g.state.ship.shield = 100;
  for (let i = 0; i < 30; i += 1) tick(g, ['up']);
  const moving = Math.hypot(g.state.ship.vx, g.state.ship.vy);
  assert.ok(moving > 60);
  tick(g);
  const coasting = Math.hypot(g.state.ship.vx, g.state.ship.vy);
  assert.ok(coasting > moving * 0.99);
  for (let i = 0; i < 30; i += 1) tick(g, ['down']);
  assert.ok(Math.hypot(g.state.ship.vx, g.state.ship.vy) < moving * 0.2);
  const angle = g.state.ship.angle;
  tick(g, ['right']);
  assert.ok(g.state.ship.angle > angle);
});

test('ship wraps across both playfield edges rather than hitting an invisible wall', () => {
  const g = rockGame();
  Object.assign(g.state.ship, { x: 479, y: 29, vx: 180, vy: -90, shield: 10 });
  tick(g);
  assert.ok(g.state.ship.x < 4);
  assert.ok(g.state.ship.y > 294 && g.state.ship.y < 296);
});

test('a bullet crosses the wrap seam and strikes the opposite-edge rock', () => {
  const g = rockGame();
  g.state.rocks = [stationaryRock(1, 2, 100)];
  g.state.bullets = [bullet(474, 100, 400, 0)];
  tick(g);
  assert.equal(g.state.destroyed, 1);
  assert.equal(g.state.phase, 'intermission');
  assert.equal(g.state.bullets.length, 0);
});

test('large and medium rocks split in two; fragments are faster and small rocks disappear', () => {
  const g = rockGame();
  g.state.rocks = [stationaryRock(3)];
  g.state.bullets = [bullet(100, 100)];
  tick(g);
  assert.equal(g.state.rocks.length, 2);
  assert.ok(g.state.rocks.every(r => r.size === 2 && r.radius === 16));
  assert.equal(g.state.score, 25);
  const one = g.state.rocks[0];
  g.state.bullets = [bullet(one.x, one.y)];
  tick(g);
  assert.equal(g.state.rocks.filter(r => r.size === 1).length, 2);
  assert.equal(g.state.score, 75);
  const small = g.state.rocks.find(r => r.size === 1);
  // Separate this target from overlapping newborn siblings before testing removal.
  small.x = 220; small.y = 90;
  assert.ok(Math.hypot(small.vx, small.vy) > Math.hypot(one.vx, one.vy));
  const before = g.state.rocks.length;
  g.state.bullets = [bullet(small.x, small.y)];
  tick(g);
  assert.equal(g.state.rocks.length, before - 1);
  assert.equal(g.state.score, 175);
});

test('ship collision costs one life, chooses clear respawn space and protects the new ship', () => {
  const g = rockGame();
  g.state.rocks = [stationaryRock(3, 240, 162)];
  g.state.ship.shield = 0;
  tick(g);
  assert.equal(g.state.lives, 2);
  assert.ok(g.state.ship.shield > 2);
  assert.ok(Math.hypot(g.state.ship.x - 240, g.state.ship.y - 162) > 30);
  g.state.rocks[0].x = g.state.ship.x;
  g.state.rocks[0].y = g.state.ship.y;
  tick(g);
  assert.equal(g.state.lives, 2);
});

test('last ship collision loses and subsequent actions do not mutate terminal state', () => {
  const g = rockGame();
  g.state.lives = 1; g.state.ship.shield = 0;
  g.state.rocks = [stationaryRock(1, 240, 162)];
  tick(g);
  assert.equal(g.state.status, 'lost');
  const before = structuredClone(g.state);
  tick(g, ['action', 'up', 'right']);
  assert.deepEqual(g.state, before);
});

test('clear first field progresses once to a larger field; final field wins', () => {
  const g = rockGame();
  g.state.rocks = [];
  tick(g);
  assert.equal(g.state.phase, 'intermission');
  assert.equal(g.state.score, 100);
  for (let i = 0; i < 100; i += 1) tick(g);
  assert.equal(g.state.level, 2);
  assert.equal(g.state.rocks.length, 3);
  assert.equal(g.state.score, 100);
  g.state.level = 3; g.state.rocks = [];
  tick(g);
  assert.equal(g.state.status, 'won');
  assert.equal(g.state.score, 850);
  const before = structuredClone(g.state);
  tick(g, ['action']); assert.deepEqual(g.state, before);
});

test('held fire respects cooldown and expired bullets do not accumulate', () => {
  const g = rockGame();
  g.state.ship.shield = 100;
  for (let i = 0; i < 60; i += 1) tick(g, ['action']);
  assert.ok(g.state.shots >= 5 && g.state.shots <= 6);
  for (let i = 0; i < 65; i += 1) tick(g);
  assert.equal(g.state.bullets.length, 0);
});

test('Sky Shield seed reproduces missile targets, timings and exact state', () => {
  const a = skyGame(), b = skyGame();
  for (let i = 0; i < 650; i += 1) { tick(a, i % 40 < 10 ? ['right'] : []); tick(b, i % 40 < 10 ? ['right'] : []); }
  assert.deepEqual(a.state, b.state);
  assert.ok(a.state.spawned > 4);
  const c = skyGame(78); for (let i = 0; i < 130; i += 1) tick(c);
  assert.notDeepEqual(a.state.missiles[0], c.state.missiles[0]);
});

test('pointer aim clamps to the sky and does not override a later keyboard move with stale hover', () => {
  const g = skyGame();
  tick(g, [], [], { active: true, x: 100, y: 120 });
  assert.deepEqual(g.state.aim, { x: 100, y: 120 });
  tick(g, ['right'], [], { active: true, x: 100, y: 120 });
  const moved = g.state.aim.x;
  tick(g, [], [], { active: true, x: 100, y: 120 });
  assert.equal(g.state.aim.x, moved);
  tick(g, [], [], { active: true, x: -20, y: 300 });
  assert.deepEqual(g.state.aim, { x: 16, y: 250 });
});

test('fire spends finite ammo, cooldown blocks duplicate shots, empty battery never goes negative', () => {
  const g = skyGame();
  tick(g, ['action']);
  assert.equal(g.state.ammo, 13);
  assert.equal(g.state.interceptors.length, 1);
  tick(g, ['action']);
  assert.equal(g.state.ammo, 13);
  g.state.ammo = 0; g.state.cooldown = 0;
  tick(g, ['action']);
  assert.equal(g.state.ammo, 0);
  assert.equal(g.state.shots, 1);
  assert.match(g.state.message, /empty/);
});

test('tap launches to its aimed position; interceptor travels before producing a burst', () => {
  const g = skyGame();
  tick(g, [], [], { active: true, x: 80, y: 100, pressed: true });
  assert.equal(g.state.shots, 1);
  assert.equal(g.state.blasts.length, 0);
  assert.ok(g.state.interceptors[0].x > 80 && g.state.interceptors[0].y > 100);
  for (let i = 0; i < 65; i += 1) tick(g);
  assert.equal(g.state.interceptors.length, 0);
  assert.ok(g.state.blasts.some(b => b.x === 80 && b.y === 100));
});

test('blast grows, holds, and fades; swept collision catches fast crossing missiles', () => {
  assert.equal(blastRadius(0), 0);
  assert.equal(blastRadius(0.25), 36);
  assert.equal(blastRadius(0.6), 36);
  assert.ok(blastRadius(1) < 15);
  assert.equal(blastRadius(1.15), 0);
  assert.equal(segmentHitsCircle(0, 100, 200, 100, 100, 100, 30), true);
  const g = skyGame();
  g.state.blasts = [{ x: 100, y: 100, age: 0.3, chain: false }];
  g.state.missiles = [missile(50, 100, 0, 6000, 0)];
  tick(g);
  assert.equal(g.state.missiles.length, 0);
  assert.equal(g.state.intercepted, 1);
  assert.equal(g.state.score, 50);
});

test('an intercepted missile creates a chain burst that can catch a neighboring missile', () => {
  const g = skyGame();
  g.state.blasts = [{ x: 100, y: 100, age: 0.3, chain: false }];
  g.state.missiles = [missile(134, 100), missile(165, 100)];
  tick(g);
  assert.equal(g.state.intercepted, 1);
  assert.ok(g.state.blasts.some(b => b.chain));
  for (let i = 0; i < 20; i += 1) tick(g);
  assert.equal(g.state.intercepted, 2);
  assert.equal(g.state.score, 100);
});

test('a ground impact removes one city shield, and a second removes that city', () => {
  const g = skyGame();
  g.state.missiles = [missile(72, 275, 0, 0, 120)];
  tick(g);
  assert.equal(g.state.cities[0].hp, 1);
  assert.equal(g.state.lives, 4);
  g.state.missiles = [missile(72, 275, 0, 0, 120)];
  tick(g);
  assert.equal(g.state.cities[0].hp, 0);
  assert.equal(g.state.lives, 3);
  assert.equal(g.state.missiles.length, 0);
});

test('losing the last city ends defense; terminal updates freeze', () => {
  const g = skyGame();
  g.state.cities.forEach((c, i) => { c.hp = i === 0 ? 1 : 0; });
  g.state.missiles = [missile(72, 275, 0, 0, 120)];
  tick(g);
  assert.equal(g.state.status, 'lost');
  assert.equal(g.state.lives, 0);
  const before = structuredClone(g.state);
  tick(g, ['action']); assert.deepEqual(g.state, before);
});

test('completed wave bonuses apply once and next wave refills ammo with more missiles', () => {
  const g = skyGame();
  g.state.remaining = 0; g.state.ammo = 2;
  tick(g);
  assert.equal(g.state.phase, 'intermission');
  assert.equal(g.state.score, 410);
  for (let i = 0; i < 110; i += 1) tick(g);
  assert.equal(g.state.level, 2);
  assert.equal(g.state.ammo, 17);
  assert.equal(g.state.remaining, 14);
  assert.equal(g.state.score, 410);
});

test('protecting surviving cities through final wave wins and freezes', () => {
  const g = skyGame();
  g.state.level = 3; g.state.remaining = 0;
  g.state.cities[0].hp = 0; g.state.ammo = 4;
  tick(g);
  assert.equal(g.state.status, 'won');
  assert.equal(g.state.lives, 3);
  assert.equal(g.state.score, 320);
  const before = structuredClone(g.state);
  tick(g, ['action']); assert.deepEqual(g.state, before);
});

test('unprotected cities eventually lose through ordinary seeded simulation', () => {
  const g = skyGame();
  for (let i = 0; i < 60 * 150 && g.state.status === 'playing'; i += 1) tick(g);
  assert.equal(g.state.status, 'lost');
  assert.equal(g.state.shots, 0);
  assert.equal(g.state.lives, 0);
});
