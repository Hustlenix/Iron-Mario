import test from 'node:test';
import assert from 'node:assert/strict';
import { createGame, COLS, ROWS, SHAPES, rotated, occupied, canPlace, ghostY, clearRows, LINE_GOAL } from '../../onlyeducation/arcade/games/stackfall.js';

const empty = () => Array.from({ length: ROWS }, () => Array(COLS).fill(0));
const rng = seed => () => {
  seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
  return seed / 4294967296;
};
const inputs = (pressed = [], down = pressed) => ({
  down: key => down.includes(key), pressed: key => pressed.includes(key),
  pointer: { x: 0, y: 0, down: false, pressed: false, active: false },
});
const game = (seed = 42) => createGame({ rng: rng(seed), sound() {} });
const piece = (type, x, y, matrix = SHAPES[type].map(row => [...row])) => ({ type, matrix, x, y });
const tick = (g, actions = [], held = actions, dt = 1 / 60) => g.update(dt, inputs(actions, held));

test('same seed and input history produce identical full state', () => {
  const a = game(), b = game();
  for (let i = 0; i < 240; i += 1) {
    const actions = i % 60 === 0 ? ['up'] : i % 53 === 0 ? ['action'] : [];
    const held = i % 100 < 35 ? ['left'] : i % 100 > 65 ? ['right'] : [];
    tick(a, actions, held);
    tick(b, actions, held);
  }
  assert.deepEqual(a.state, b.state);
});

test('each seven-piece bag contains all shapes and seed affects order', () => {
  function sequence(seed) {
    const g = game(seed), types = [];
    for (let i = 0; i < 21; i += 1) {
      types.push(g.state.active.type);
      g.state.board = empty();
      tick(g, ['action']);
    }
    for (let i = 0; i < 21; i += 7) assert.equal(new Set(types.slice(i, i + 7)).size, 7);
    return types;
  }
  assert.notDeepEqual(sequence(4), sequence(21));
});

test('collision checks walls, floor, settled blocks and permits spawning above ceiling', () => {
  const board = empty();
  assert.equal(canPlace(board, piece(1, 4, -1)), true);
  assert.equal(canPlace(board, piece(1, -1, 0)), false);
  assert.equal(canPlace(board, piece(1, COLS - 1, 0)), false);
  assert.equal(canPlace(board, piece(1, 0, ROWS - 1)), false);
  board[10][4] = 2;
  assert.equal(canPlace(board, piece(1, 4, 9)), false);
  assert.equal(canPlace(board, piece(1, 2, 9)), true);
});

test('four clockwise turns and inverse turn preserve every shape', () => {
  for (const original of SHAPES) {
    let matrix = original;
    for (let i = 0; i < 4; i += 1) matrix = rotated(matrix);
    assert.deepEqual(matrix, original);
    assert.deepEqual(rotated(rotated(original), -1), original);
  }
});

test('a wall kick rotates a vertical beam away from the left edge', () => {
  const g = game();
  g.state.active = piece(0, -2, 5, rotated(SHAPES[0]));
  assert.equal(canPlace(g.state.board, g.state.active), true);
  tick(g, ['up']);
  assert.equal(g.state.active.x, 0);
  assert.deepEqual(g.state.active.matrix, rotated(rotated(SHAPES[0])));
  assert.equal(canPlace(g.state.board, g.state.active), true);
});

test('floor kick permits rotation and a completely blocked rotation does nothing', () => {
  const g = game();
  g.state.active = piece(0, 3, ROWS - 2);
  tick(g, ['up']);
  assert.equal(g.state.active.y, ROWS - 4);
  assert.equal(canPlace(g.state.board, g.state.active), true);
  const blocked = game();
  blocked.state.board = Array.from({ length: ROWS }, () => Array(COLS).fill(4));
  blocked.state.active = piece(2, 3, 6);
  occupied(blocked.state.active).forEach(({ x, y }) => { blocked.state.board[y][x] = 0; });
  const before = structuredClone(blocked.state.active);
  tick(blocked, ['up']);
  assert.deepEqual(blocked.state.active, before);
});

test('ghost lands on occupied geometry; hard drop locks at that exact height', () => {
  const g = game();
  g.state.active = piece(1, 4, 0);
  g.state.board[14][4] = 6;
  assert.equal(ghostY(g.state.board, g.state.active), 12);
  tick(g, ['action']);
  assert.equal(g.state.board[12][4], 2);
  assert.equal(g.state.board[13][5], 2);
  assert.equal(g.state.score, 24);
  assert.equal(g.state.pieces, 1);
  assert.equal(g.state.board[14][4], 6);
});

test('row collapse preserves survivor order and creates independent empty rows', () => {
  const board = empty();
  board[15][3] = 5;
  board[16].fill(1);
  board[17].fill(2);
  const result = clearRows(board);
  assert.equal(result.count, 2);
  assert.equal(result.board.length, ROWS);
  assert.equal(result.board[17][3], 5);
  assert.equal(result.board[0].every(v => v === 0), true);
  assert.notEqual(result.board[0], result.board[1]);
});

test('a four-row clear earns score, advances level and removes every filled cell', () => {
  const g = game();
  for (let y = ROWS - 4; y < ROWS; y += 1) {
    g.state.board[y].fill(3);
    g.state.board[y][5] = 0;
  }
  g.state.active = piece(0, 3, ROWS - 4, rotated(SHAPES[0]));
  tick(g, ['action']);
  assert.equal(g.state.lines, 4);
  assert.equal(g.state.level, 2);
  assert.equal(g.state.lastClear, 4);
  assert.equal(g.state.score, 900);
  assert.equal(g.state.board.flat().every(value => value === 0), true);
});

test('soft drop responds on first press, scores distance and never crosses the floor', () => {
  const g = game();
  g.state.active = piece(1, 4, 0);
  g.state.gravity = 0.74; // Switching speeds must not turn old gravity time into a burst.
  tick(g, ['down']);
  assert.equal(g.state.active.y, 1);
  assert.equal(g.state.score, 1);
  for (let i = 0; i < 42; i += 1) tick(g, [], ['down']);
  assert.equal(g.state.active.y, ROWS - 2);
  assert.equal(g.state.board.flat().some(Boolean), false);
  for (let i = 0; i < 25; i += 1) tick(g);
  assert.equal(g.state.pieces, 1);
});

test('gravity accelerates at later levels without requiring held input', () => {
  const slow = game(), fast = game();
  slow.state.active = piece(1, 4, 0);
  fast.state.active = piece(1, 4, 0);
  fast.state.level = 6;
  for (let i = 0; i < 60; i += 1) { tick(slow); tick(fast); }
  assert.equal(slow.state.active.y, 1);
  assert.ok(fast.state.active.y >= 4);
});

test('lock delay permits adjustment but only eight grounded reset requests', () => {
  const g = game();
  g.state.active = piece(1, 4, ROWS - 2);
  for (let i = 0; i < 18; i += 1) tick(g);
  assert.equal(g.state.pieces, 0);
  tick(g, ['left']);
  assert.equal(g.state.lockResets, 1);
  assert.ok(g.state.lockTime < 0.1);
  for (let i = 0; i < 12; i += 1) {
    tick(g);
    tick(g, [i % 2 ? 'left' : 'right']);
  }
  assert.equal(g.state.lockResets, 8);
  for (let i = 0; i < 30; i += 1) tick(g);
  assert.equal(g.state.pieces, 1);
});

test('held movement repeats after a delay and cannot escape the board', () => {
  const g = game();
  g.state.active = piece(1, 4, 1);
  tick(g, ['left']);
  assert.equal(g.state.active.x, 3);
  for (let i = 0; i < 5; i += 1) tick(g, [], ['left']);
  assert.equal(g.state.active.x, 3);
  for (let i = 0; i < 90; i += 1) tick(g, [], ['left']);
  assert.equal(g.state.active.x, 0);
});

test('blocked spawn and locking above the ceiling both produce topout', () => {
  const spawnBlocked = game();
  spawnBlocked.state.active = piece(1, 0, ROWS - 2);
  spawnBlocked.state.board[0][4] = 3;
  spawnBlocked.state.next = [1, 0, 2];
  tick(spawnBlocked, ['action']);
  assert.equal(spawnBlocked.state.status, 'lost');
  const above = game();
  above.state.active = piece(1, 4, -1);
  above.state.board[1][4] = 3;
  tick(above, ['action']);
  assert.equal(above.state.status, 'lost');
  assert.equal(above.state.pieces, 0);
});

test('clear goal wins, and both terminal states ignore later inputs', () => {
  const g = game();
  g.state.lines = LINE_GOAL - 1;
  g.state.board[ROWS - 1].fill(5);
  g.state.board[ROWS - 1][4] = 0;
  g.state.board[ROWS - 1][5] = 0;
  g.state.active = piece(1, 4, ROWS - 2);
  tick(g, ['action']);
  assert.equal(g.state.status, 'won');
  assert.equal(g.state.lines, LINE_GOAL);
  assert.equal(g.state.active, null);
  for (const status of ['won', 'lost']) {
    g.state.status = status;
    const before = structuredClone(g.state);
    tick(g, ['action', 'up', 'left']);
    assert.deepEqual(g.state, before);
  }
});
