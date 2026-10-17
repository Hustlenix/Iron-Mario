import test from 'node:test';
import assert from 'node:assert/strict';
import { createGame as createSnake } from '../../onlyeducation/arcade/games/byte-munch.js';
import { createGame as createBricks } from '../../onlyeducation/arcade/games/brick-burst.js';

function rng(seed = 42) {
  return () => { seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0; return seed / 4294967296; };
}
const idle = { down: () => false, pressed: () => false, pointer: { active: false, down: false, pressed: false, x: 0, y: 0 } };
function input(pressed = [], held = [], pointer = {}) {
  return { down: action => held.includes(action), pressed: action => pressed.includes(action), pointer: { ...idle.pointer, ...pointer } };
}
function game(factory, seed = 42) {
  const sounds = [], g = factory({ rng: rng(seed), sound: name => sounds.push(name) });
  return { ...g, sounds };
}
function snakeStep(g, pressed = []) { g.update(g.state.interval + 0.00001, input(pressed)); }
function fixtureBall(g, extra) { Object.assign(g.state.ball, { docked: false, vx: 0, vy: -205, ...extra }); }

test('Byte Munch seeded initial food and input sequence are reproducible', () => {
  const a = game(createSnake), b = game(createSnake);
  for (const control of [[], ['up'], [], ['left'], [], ['down'], [], ['right']]) {
    snakeStep(a, control); snakeStep(b, control);
  }
  assert.deepEqual(a.state, b.state);
  assert.deepEqual(a.sounds, b.sounds);
});

test('Byte Munch food awards score, grows exactly one cell, and spawns on free cells', () => {
  const g = game(createSnake);
  g.state.food = { x: 9, y: 8, bonus: false };
  snakeStep(g);
  assert.equal(g.state.score, 20);
  assert.equal(g.state.snake.length, 5);
  assert.equal(g.state.eaten, 1);
  assert(!g.state.snake.some(s => s.x === g.state.food.x && s.y === g.state.food.y));
  assert(g.sounds.includes('score'));
});

test('Byte Munch fifth food raises difficulty and warns before creating distant posts', () => {
  const g = game(createSnake);
  g.state.eaten = 4; g.state.food = { x: 9, y: 8, bonus: true };
  snakeStep(g);
  assert.equal(g.state.level, 2);
  assert.equal(g.state.score, 50);
  assert(g.state.interval < 0.16);
  assert.equal(g.state.obstacles.length, 0);
  assert.equal(g.state.warnings.length, 2);
  assert(g.state.warnings.every(p => p.remaining > 1));
});

test('Byte Munch a warning under the player is cancelled rather than becoming a fatal tile', () => {
  const g = game(createSnake);
  g.state.warnings = [{ x: 8, y: 8, remaining: 0.005 }];
  g.update(0.01, idle);
  assert.equal(g.state.obstacles.length, 0);
  assert.equal(g.state.warnings.length, 0);
  assert.equal(g.state.status, 'playing');
});

test('Byte Munch rejects reversal and safely buffers two perpendicular turns', () => {
  const g = game(createSnake);
  g.update(0.01, input(['left']));
  assert.equal(g.state.turns.length, 0);
  g.update(0.01, input(['up']));
  g.update(0.01, input(['left']));
  assert.deepEqual(g.state.turns, [{ x: 0, y: -1 }, { x: -1, y: 0 }]);
  g.update(0.13, idle);
  assert.deepEqual(g.state.snake[0], { x: 8, y: 7 });
  snakeStep(g);
  assert.deepEqual(g.state.snake[0], { x: 7, y: 7 });
});

test('Byte Munch permits entry into the cell the tail vacates', () => {
  const g = game(createSnake);
  g.state.snake = [{ x: 2, y: 2 }, { x: 2, y: 3 }, { x: 1, y: 3 }, { x: 1, y: 2 }];
  g.state.direction = { x: -1, y: 0 }; g.state.food = { x: 10, y: 10, bonus: false };
  snakeStep(g);
  assert.equal(g.state.status, 'playing');
  assert.deepEqual(g.state.snake[0], { x: 1, y: 2 });
});

test('Byte Munch self collision, obstacle collision, and walls cause real frozen loss', () => {
  const cases = [
    g => { g.state.snake = [{ x: 2, y: 2 }, { x: 2, y: 3 }, { x: 1, y: 3 }, { x: 1, y: 2 }, { x: 1, y: 1 }]; g.state.direction = { x: -1, y: 0 }; },
    g => { g.state.obstacles = [{ x: 9, y: 8 }]; },
    g => { g.state.snake = [{ x: 27, y: 8 }, { x: 26, y: 8 }]; }
  ];
  for (const setup of cases) {
    const g = game(createSnake); setup(g); snakeStep(g);
    assert.equal(g.state.status, 'lost');
    const saved = structuredClone(g.state);
    g.update(1, input(['up']));
    assert.deepEqual(g.state, saved);
  }
});

test('Byte Munch filling all available cells is a genuine win', () => {
  const g = game(createSnake);
  g.state.snake = [{ x: 0, y: 0 }];
  for (let y = 0; y < 16; y++) for (let x = 0; x < 28; x++)
    if (!(y === 0 && (x === 0 || x === 1))) g.state.snake.push({ x, y });
  g.state.food = { x: 1, y: 0, bonus: false };
  snakeStep(g);
  assert.equal(g.state.status, 'won');
  assert.equal(g.state.snake.length, 448);
  assert.equal(g.state.food, null);
});

test('Byte Munch canvas tap turns toward the tap, idle pointer does not steer', () => {
  const g = game(createSnake);
  g.update(0.01, input([], [], { active: true, pressed: true, x: 152, y: 60 }));
  assert.deepEqual(g.state.turns, [{ x: 0, y: -1 }]);
  const h = game(createSnake);
  h.update(0.01, input([], [], { active: true, x: 152, y: 60 }));
  assert.equal(h.state.turns.length, 0);
});

test('Brick Burst starts docked, action launches once, and seeded play is reproducible', () => {
  const a = game(createBricks), b = game(createBricks);
  assert.equal(a.state.ball.docked, true);
  for (const g of [a, b]) {
    g.update(1 / 60, input(['action']));
    assert.equal(g.state.ball.docked, false);
    assert(g.state.ball.vy < 0);
    for (let i = 0; i < 240; i++) g.update(1 / 60, input([], i % 120 < 60 ? ['right'] : ['left']));
  }
  assert.deepEqual(a.state, b.state);
});

test('Brick Burst keyboard and pointer drag respect both arena bounds', () => {
  const g = game(createBricks);
  g.update(2, input([], ['left']));
  assert.equal(g.state.paddle.x, 12);
  g.update(2, input([], ['right']));
  assert.equal(g.state.paddle.x + g.state.paddle.w, 468);
  g.update(1, input([], [], { active: true, down: true, x: 20, y: 290 }));
  assert.equal(g.state.paddle.x, 12);
  g.update(0.1, input([], [], { active: true, x: 450, y: 290 }));
  assert.equal(g.state.paddle.x, 12, 'idle pointer must not hijack keyboard position');
});

test('Brick Burst downward paddle contact aims according to impact point', () => {
  for (const offset of [-36, 36]) {
    const g = game(createBricks);
    fixtureBall(g, { x: 240 + offset, y: 278, vx: 0, vy: 205 });
    g.update(0.03, idle);
    assert(g.state.ball.vy < 0);
    assert(Math.sign(g.state.ball.vx) === Math.sign(offset));
    assert(g.state.ball.y < g.state.paddle.y);
    assert.equal(g.state.lives, 3);
  }
});

test('Brick Burst never rescues a ball from the underside of the paddle', () => {
  const g = game(createBricks);
  fixtureBall(g, { x: 240, y: 298, vx: 0, vy: 205 });
  g.update(0.15, idle);
  assert.equal(g.state.lives, 2);
  assert.equal(g.state.ball.docked, true);
});

test('Brick Burst substeps prevent tunnelling through a reinforced brick', () => {
  const g = game(createBricks);
  g.state.bricks = [{ x: 200, y: 100, w: 40, h: 13, hp: 2, maxHp: 2, color: '#ffc56a', drop: null }];
  fixtureBall(g, { x: 220, y: 150, vx: 0, vy: -600 });
  g.update(0.1, idle);
  assert.equal(g.state.bricks[0].hp, 1);
  assert(g.state.ball.vy > 0);
  assert.equal(g.state.score, 5);
  assert.equal(g.state.waveDelay, 0);
});

test('Brick Burst side impacts reflect horizontally without duplicating damage', () => {
  const g = game(createBricks);
  g.state.bricks = [{ x: 200, y: 100, w: 40, h: 13, hp: 3, maxHp: 3, color: '#ffc56a', drop: null }];
  fixtureBall(g, { x: 190, y: 106, vx: 205, vy: 0 });
  g.update(0.06, idle);
  assert.equal(g.state.bricks[0].hp, 2);
  assert(g.state.ball.vx < 0);
  assert.equal(g.state.hits, 1);
});

test('Brick Burst clearing the final brick awards the wave bonus then builds a distinct harder wave', () => {
  const g = game(createBricks);
  const first = g.state.bricks.map(b => [b.x, b.y, b.hp]);
  g.state.bricks = [{ x: 200, y: 100, w: 40, h: 13, hp: 1, maxHp: 1, color: '#ffc56a', drop: null }];
  fixtureBall(g, { x: 220, y: 119, vx: 0, vy: -205 });
  g.update(0.02, idle);
  assert.equal(g.state.score, 227);
  assert.equal(g.state.waveDelay, 1);
  assert.equal(g.state.status, 'playing');
  g.update(1, idle);
  assert.equal(g.state.level, 2);
  assert(g.state.bricks.some(b => b.hp > 1));
  assert.notDeepEqual(g.state.bricks.map(b => [b.x, b.y, b.hp]), first);
  assert.equal(g.state.ball.docked, true);
});

test('Brick Burst every third wave grants one life with a cap of five', () => {
  const g = game(createBricks);
  g.state.level = 2; g.state.waveDelay = 0.01;
  g.update(0.02, idle);
  assert.equal(g.state.level, 3); assert.equal(g.state.lives, 4);
  g.state.level = 5; g.state.lives = 5; g.state.waveDelay = 0.01;
  g.update(0.02, idle);
  assert.equal(g.state.lives, 5);
});

test('Brick Burst upgrade catches change actual paddle width and expire', () => {
  const g = game(createBricks);
  g.state.drops = [{ x: 210, y: 270, w: 14, h: 10, type: 'wide' }];
  g.update(0.1, idle);
  assert.equal(g.state.paddle.w, 116);
  assert.equal(g.state.wideTime, 12);
  assert.equal(g.state.score, 25);
  g.update(12, idle);
  assert.equal(g.state.paddle.w, 84);
  g.state.drops = [{ x: 210, y: 270, w: 14, h: 10, type: 'slow' }];
  g.update(0.1, idle);
  assert.equal(g.state.slowTime, 10);
});

test('Brick Burst a slow chip reduces actual travel distance, not only HUD text', () => {
  const normal = game(createBricks), slow = game(createBricks);
  for (const g of [normal, slow]) fixtureBall(g, { x: 240, y: 240, vx: 100, vy: -100 });
  slow.state.slowTime = 5;
  normal.update(0.1, idle); slow.update(0.1, idle);
  assert(Math.abs(slow.state.ball.x - 240) < Math.abs(normal.state.ball.x - 240));
  assert.equal(slow.state.slowTime, 4.9);
});

test('Brick Burst three missed balls end the run and freeze further score/state changes', () => {
  const g = game(createBricks);
  for (let n = 0; n < 3; n++) {
    fixtureBall(g, { x: 450, y: 325, vx: 0, vy: 205 });
    g.update(0.03, idle);
    assert.equal(g.state.lives, 2 - n);
  }
  assert.equal(g.state.status, 'lost');
  const saved = structuredClone(g.state);
  g.update(1, input(['action'], ['left']));
  assert.deepEqual(g.state, saved);
});
