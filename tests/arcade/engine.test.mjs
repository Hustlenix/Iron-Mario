import test from 'node:test';
import assert from 'node:assert/strict';
import { clamp, rects, distance, random, level } from '../../onlyeducation/arcade/engine/math.js';
import { SaveStore } from '../../onlyeducation/arcade/engine/store.js';
import { Runtime } from '../../onlyeducation/arcade/engine/runtime.js';
import { Input } from '../../onlyeducation/arcade/engine/input.js';
import { createGame } from '../../onlyeducation/arcade/games/paddle-panic.js';

const SAVE_KEY = 'onlyeducation.arcade.v1';
class MemoryStorage {
  constructor(initial = null) { this.entries = new Map(initial === null ? [] : [[SAVE_KEY, initial]]); }
  getItem(key) { return this.entries.get(key) ?? null; }
  setItem(key, value) { this.entries.set(key, String(value)); }
}
const input = (held = [], pointer = {}) => ({
  down: action => held.includes(action), pressed: () => false,
  pointer: { active: false, down: false, pressed: false, x: 240, y: 160, ...pointer },
});
const paddle = (seed = 47) => createGame({ rng: random(seed), sound() {} });

test('math clamps and measures Euclidean distance without conflating touching rectangles', () => {
  assert.equal(clamp(-1, 0, 10), 0);
  assert.equal(clamp(7, 0, 10), 7);
  assert.equal(clamp(12, 0, 10), 10);
  assert.equal(distance({ x: -1, y: 2 }, { x: 2, y: 6 }), 5);
  assert.equal(rects({ x: 0, y: 0, w: 10, h: 10 }, { x: 9, y: 9, w: 3, h: 3 }), true);
  assert.equal(rects({ x: 0, y: 0, w: 10, h: 10 }, { x: 10, y: 0, w: 3, h: 3 }), false);
});

test('seeded generator reproduces its stream in [0,1) and differentiates seeds', () => {
  const a = random(9), b = random(9), c = random(10);
  const aa = Array.from({ length: 1000 }, a), bb = Array.from({ length: 1000 }, b);
  assert.deepEqual(aa, bb);
  assert.notEqual(aa[0], c());
  assert.ok(aa.every(v => v >= 0 && v < 1));
});

test('level parser rejects ragged/empty input and gives mutable independent rows', () => {
  const source = ['abc', 'def'];
  const parsed = level(source);
  parsed[0][0] = 'X';
  assert.equal(source[0], 'abc');
  assert.equal(parsed[1][0], 'd');
  for (const bad of [[], null, [''], ['aa', 'bbb'], [null], [3]]) {
    assert.throws(() => level(bad), { message: 'Invalid level' });
  }
});

test('save record persists best scores, plays, wins, level, mute and unique achievements', () => {
  const storage = new MemoryStorage(), store = new SaveStore(storage);
  store.record('paddle-panic', { score: 0, status: 'playing', level: 1 }, { started: true });
  store.record('paddle-panic', { score: 400, status: 'won', level: 5 });
  store.record('paddle-panic', { score: 20, status: 'lost', level: 2 }, { started: true });
  store.unlock('first-score');
  store.mute(true);
  const restored = new SaveStore(storage);
  assert.deepEqual(restored.data.games['paddle-panic'], { best: 400, plays: 2, wins: 1, level: 5 });
  assert.equal(restored.data.muted, true);
  assert.equal(restored.data.achievements.filter(id => id === 'first-score').length, 1);
  assert.ok(restored.data.achievements.includes('first-win'));
});

test('six distinct played games unlock the collection achievement once', () => {
  const store = new SaveStore(new MemoryStorage());
  for (let i = 0; i < 6; i += 1) store.record(`game-${i}`, { score: 0, status: 'playing' }, { started: true });
  store.record('game-0', { score: 1, status: 'lost' });
  assert.equal(store.data.achievements.filter(id => id === 'six-cabinets').length, 1);
});

test('invalid JSON, unknown versions and storage denial leave a usable in-memory store', () => {
  for (const raw of ['{bad json', '{"version":900,"games":{"x":{"best":10000}}}']) {
    const store = new SaveStore(new MemoryStorage(raw));
    assert.deepEqual(store.data.games, {});
    assert.doesNotThrow(() => store.record('x', { score: 12, status: 'lost' }));
    assert.equal(store.data.games.x.best, 12);
  }
  const denied = { getItem() { throw new Error('blocked'); }, setItem() { throw new Error('quota'); } };
  const store = new SaveStore(denied);
  assert.equal(store.available, false);
  assert.doesNotThrow(() => store.record('x', { score: 35, status: 'lost' }));
  assert.equal(store.data.games.x.best, 35);
  assert.equal(store.write(), false);
});

test('a restricted localStorage property itself is handled by the fallback', () => {
  const previous = Object.getOwnPropertyDescriptor(globalThis, 'localStorage');
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, get() { throw new Error('SecurityError'); } });
  try {
    let store;
    assert.doesNotThrow(() => { store = new SaveStore(); });
    assert.equal(store.available, false);
    assert.doesNotThrow(() => store.record('paddle-panic', { score: 20, status: 'lost' }));
    assert.equal(store.data.games['paddle-panic'].best, 20);
  } finally {
    if (previous) Object.defineProperty(globalThis, 'localStorage', previous);
    else delete globalThis.localStorage;
  }
});

test('array-shaped game data is rejected instead of silently losing keyed saves', () => {
  const store = new SaveStore(new MemoryStorage(JSON.stringify({ version: 1, games: [] })));
  assert.equal(Array.isArray(store.data.games), false);
  store.record('paddle-panic', { score: 99, status: 'lost' });
  assert.equal(new SaveStore(store.storage).data.games['paddle-panic'].best, 99);
});

test('persisted counters and scores are finite nonnegative numbers before incrementing', () => {
  const storage = new MemoryStorage(JSON.stringify({ version: 1, games: {
    'paddle-panic': { best: 'garbage', plays: '6', wins: -3, level: 'bad' },
  } }));
  const store = new SaveStore(storage);
  store.record('paddle-panic', { score: 15, status: 'won', level: 2 }, { started: true });
  for (const key of ['best', 'plays', 'wins', 'level']) {
    assert.equal(typeof store.data.games['paddle-panic'][key], 'number', key);
    assert.ok(Number.isFinite(store.data.games['paddle-panic'][key]), key);
    assert.ok(store.data.games['paddle-panic'][key] >= 0, key);
  }
  assert.equal(store.data.games['paddle-panic'].best, 15);
});

test('paddle serves and opponent follow deterministic input history', () => {
  const a = paddle(), b = paddle();
  for (let i = 0; i < 1200; i += 1) {
    const controls = input(i % 180 < 90 ? ['up'] : ['down']);
    a.update(1 / 60, controls);
    b.update(1 / 60, controls);
  }
  assert.deepEqual(a.state, b.state);
});

test('paddles stay inside the court under keyboard and pointer control', () => {
  const g = paddle();
  for (let i = 0; i < 100; i += 1) g.update(1 / 60, input(['up']));
  assert.equal(g.state.py, 24);
  for (let i = 0; i < 100; i += 1) g.update(1 / 60, input([], { active: true, y: 1000 }));
  assert.equal(g.state.py, 244);
  assert.ok(g.state.ay >= 24 && g.state.ay <= 244);
});

test('ball rebounds from both horizontal court limits', () => {
  const g = paddle();
  g.state.serve = 0;
  g.state.ball = { x: 240, y: 28, vx: 170, vy: -90 };
  g.update(1 / 60, input());
  assert.equal(g.state.ball.y, 28);
  assert.equal(g.state.ball.vy, 90);
  g.state.ball = { x: 240, y: 292, vx: -170, vy: 90 };
  g.update(1 / 60, input());
  assert.equal(g.state.ball.y, 292);
  assert.equal(g.state.ball.vy, -90);
});

test('left paddle reflects toward opponent and edge contact gives directional aim', () => {
  const g = paddle();
  g.state.serve = 0;
  g.state.py = 120;
  g.state.ball = { x: 41, y: 124, vx: -200, vy: 0 };
  g.update(1 / 60, input());
  assert.ok(g.state.ball.vx > 0);
  assert.ok(g.state.ball.vy < 0);
  assert.equal(g.state.ball.x, 40);
  assert.equal(g.state.score, 5);
  assert.equal(g.state.rally, 1);
  assert.ok(Math.abs(Math.hypot(g.state.ball.vx, g.state.ball.vy) - 197) < 1e-8);
});

test('right paddle reflects toward player and missed paddle does not bounce', () => {
  const g = paddle();
  g.state.serve = 0;
  g.state.ay = 134;
  g.state.ball = { x: 439, y: 160, vx: 200, vy: 0 };
  g.update(1 / 60, input());
  assert.ok(g.state.ball.vx < 0);
  assert.equal(g.state.ball.x, 440);
  g.state.ball = { x: 41, y: 280, vx: -200, vy: 0 };
  g.state.py = 24;
  g.update(1 / 60, input());
  assert.ok(g.state.ball.vx < 0);
  assert.equal(g.state.rally, 1);
});

test('a point updates the correct player, score, level and delayed next serve', () => {
  const g = paddle();
  g.state.serve = 0;
  g.state.ball = { x: 489, y: 80, vx: 180, vy: 0 };
  g.update(1 / 60, input());
  assert.equal(g.state.player, 1);
  assert.equal(g.state.cpu, 0);
  assert.equal(g.state.score, 100);
  assert.equal(g.state.level, 2);
  assert.equal(g.state.ball.x, 240);
  assert.equal(g.state.serve, 0.8);
  const before = { ...g.state.ball };
  g.update(1 / 60, input());
  assert.deepEqual(g.state.ball, before);
});

test('five points wins or loses and terminal input freezes gameplay', () => {
  for (const winner of ['player', 'cpu']) {
    const g = paddle();
    g.state[winner] = 4;
    g.state.serve = 0;
    g.state.ball = { x: winner === 'player' ? 489 : -9, y: 80, vx: winner === 'player' ? 180 : -180, vy: 0 };
    g.update(1 / 60, input());
    assert.equal(g.state.status, winner === 'player' ? 'won' : 'lost');
    assert.equal(g.state[winner], 5);
    if (winner === 'player') assert.equal(g.state.score, 600);
    const before = structuredClone(g.state);
    g.update(1 / 60, input(['up']));
    assert.deepEqual(g.state, before);
  }
});

function runtimeFixture(run, options = {}) {
  const originals = Object.fromEntries(['window', 'requestAnimationFrame', 'cancelAnimationFrame'].map(key => [key, Object.getOwnPropertyDescriptor(globalThis, key)]));
  const frames = new Map();
  let frameId = 0, updates = [], disposed = 0, created = 0;
  const signals = [], errors = [];
  class TrackedTarget extends EventTarget {
    addEventListener(type, fn, config) { if (config?.signal) signals.push(config.signal); super.addEventListener(type, fn, config); }
  }
  const target = new TrackedTarget();
  const ctx = { save() {}, restore() {}, imageSmoothingEnabled: true };
  const canvas = new TrackedTarget();
  canvas.getContext = () => ctx;
  canvas.getBoundingClientRect = () => ({ left: 0, top: 0, width: 480, height: 320 });
  canvas.focus = () => {};
  canvas.setPointerCapture = () => {};
  globalThis.window = target;
  globalThis.requestAnimationFrame = fn => { frames.set(++frameId, fn); return frameId; };
  globalThis.cancelAnimationFrame = id => frames.delete(id);
  let runtime;
  try {
    const construct = () => new Runtime({ canvas, controls: { querySelectorAll() { return []; } },
      module: { createGame() { created += 1; if (options.throwOnCreate === created) throw new Error('fixture module failed'); return { state: { status: 'playing', score: 0 }, update(dt, controls) { updates.push({ dt, pressed: controls.pressed('action'), held: controls.down('action') }); }, draw() {}, dispose() { disposed += 1; } }; } },
      assets: { draw() {} }, sound: { play() {}, silence() {} }, onError(error) { errors.push(error); },
    });
    if (options.throwOnCreate === 1) {
      run({ construct, frames, signals });
      return;
    }
    runtime = construct();
    const frame = time => {
      const [id, fn] = frames.entries().next().value;
      frames.delete(id);
      fn(time);
    };
    run({ runtime, frame, frames, updates, signals, errors, get disposed() { return disposed; } });
  } finally {
    runtime?.destroy();
    for (const [key, descriptor] of Object.entries(originals)) {
      if (descriptor) Object.defineProperty(globalThis, key, descriptor);
      else delete globalThis[key];
    }
  }
}

test('runtime caps catch-up, consumes press once, and pause/resume never replay stale input', () => {
  runtimeFixture(({ runtime, frame, updates }) => {
    runtime.start();
    frame(100);
    runtime.input.edges.add('action');
    runtime.input.keys.add('action');
    frame(1100);
    assert.equal(updates.length, 6);
    assert.ok(updates.every(step => step.dt === 1 / 60));
    assert.equal(updates.filter(step => step.pressed).length, 1);
    runtime.pause();
    assert.equal(runtime.input.down('action'), false);
    frame(2100);
    assert.equal(updates.length, 6);
    runtime.input.edges.add('action');
    runtime.resume();
    frame(3000);
    frame(3020);
    assert.equal(updates.length, 7);
    assert.equal(updates.at(-1).pressed, false);
  });
});

test('runtime restart recreates clean state and destroy cancels its loop and listeners', () => {
  runtimeFixture(fixture => {
    const { runtime, frame, frames } = fixture;
    runtime.start();
    frame(100);
    frame(120);
    runtime.game.state.score = 88;
    runtime.restart();
    assert.equal(runtime.mode, 'ready');
    assert.equal(runtime.ticks, 0);
    assert.equal(runtime.game.state.score, 0);
    assert.equal(fixture.disposed, 1);
    runtime.destroy();
    assert.equal(runtime.mode, 'disposed');
    assert.equal(runtime.input.listeners, 0);
    assert.equal(frames.size, 0);
  });
});

test('constructor module failure aborts installed listeners and schedules no frame', () => {
  runtimeFixture(({ construct, frames, signals }) => {
    assert.throws(construct, /fixture module failed/);
    assert.ok(signals.length > 0);
    assert.ok(signals.every(signal => signal.aborted));
    assert.equal(frames.size, 0);
  }, { throwOnCreate: 1 });
});

test('destroy is idempotent and does not dispose the same game twice', () => {
  runtimeFixture(fixture => {
    fixture.runtime.destroy();
    fixture.runtime.destroy();
    assert.equal(fixture.disposed, 1);
    assert.equal(fixture.frames.size, 0);
    assert.ok(fixture.signals.every(signal => signal.aborted));
  });
});

test('restart module failure releases listeners and RAF and reports one error', () => {
  runtimeFixture(fixture => {
    const { runtime, frames, errors, signals } = fixture;
    runtime.start();
    runtime.input.edges.add('action');
    assert.doesNotThrow(() => runtime.restart());
    assert.equal(runtime.mode, 'error');
    assert.equal(runtime.faulted, true);
    assert.equal(runtime.input.listeners, 0);
    assert.ok(signals.every(signal => signal.aborted));
    assert.equal(frames.size, 0);
    assert.equal(errors.length, 1);
    assert.match(errors[0].message, /fixture module failed/);
    assert.equal(fixture.disposed, 1);
    runtime.destroy();
    assert.equal(fixture.disposed, 1);
  }, { throwOnCreate: 2 });
});

test('paused and ready runtimes stop scheduling RAF; resume schedules one fresh loop', () => {
  runtimeFixture(({ runtime, frames, frame, updates }) => {
    assert.equal(frames.size, 1);
    frame(100);
    assert.equal(frames.size, 0);
    assert.equal(updates.length, 0);
    runtime.start();
    assert.equal(frames.size, 1);
    frame(1000);
    frame(1020);
    runtime.pause();
    // One already queued callback may finish drawing, but cannot schedule another.
    if (frames.size) frame(1040);
    assert.equal(frames.size, 0);
    const before = updates.length;
    runtime.resume();
    runtime.resume();
    assert.equal(frames.size, 1);
    frame(5000);
    assert.equal(updates.length, before);
    frame(5020);
    assert.equal(updates.length, before + 1);
    assert.equal(frames.size, 1);
  });
});

test('touch capture loss releases pointer and clear removes held button feedback', () => {
  const previous = Object.getOwnPropertyDescriptor(globalThis, 'window');
  globalThis.window = new EventTarget();
  const canvas = new EventTarget(), button = new EventTarget(), classes = new Set();
  canvas.getBoundingClientRect = () => ({ left: 0, top: 0, width: 240, height: 160 });
  canvas.focus = () => {};
  canvas.setPointerCapture = button.setPointerCapture = () => {};
  button.dataset = { input: 'left' };
  button.classList = { add: value => classes.add(value), remove: value => classes.delete(value) };
  const controls = { querySelectorAll(selector) { return selector === '[data-input]' ? [button] : classes.has('held') ? [button] : []; } };
  const event = (target, type) => { const e = new Event(type, { cancelable: true }); Object.assign(e, { pointerId: 7, clientX: 60, clientY: 40 }); target.dispatchEvent(e); };
  let controlsInput;
  try {
    controlsInput = new Input(canvas, controls);
    event(canvas, 'pointerdown');
    assert.equal(controlsInput.pointer.down, true);
    assert.equal(controlsInput.pointer.x, 120);
    assert.equal(controlsInput.pointer.y, 80);
    event(canvas, 'lostpointercapture');
    assert.equal(controlsInput.pointer.down, false);
    event(button, 'pointerdown');
    assert.equal(controlsInput.down('left'), true);
    assert.equal(classes.has('held'), true);
    controlsInput.clear();
    assert.equal(controlsInput.down('left'), false);
    assert.equal(controlsInput.pressed('left'), false);
    assert.equal(classes.has('held'), false);
    assert.equal(controlsInput.pointer.active, false);
    controlsInput.destroy();
    event(button, 'pointerdown');
    assert.equal(controlsInput.down('left'), false);
    assert.equal(controlsInput.listeners, 0);
  } finally {
    controlsInput?.destroy();
    if (previous) Object.defineProperty(globalThis, 'window', previous); else delete globalThis.window;
  }
});
