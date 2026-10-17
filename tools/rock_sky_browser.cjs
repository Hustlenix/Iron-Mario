/* Real keyboard/mouse/touch QA; read-only snapshots never mutate game state. */
const { chromium } = require('./arcade_playwright.cjs');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const BASE = process.env.ARCADE_URL || 'http://127.0.0.1:8785/arcade/?qa=1';
const OUT = path.resolve('build/arcade/wave-b-rock-sky');
const report = { url: BASE, stateInjection: false, desktop: {}, mobile: {}, errors: [], failedRequests: [], externalRequests: [] };
fs.mkdirSync(OUT, { recursive: true });
const snap = page => page.evaluate(() => window.__arcade.snapshot());
const wait = (page, ms) => page.waitForTimeout(ms);
function monitor(page) {
  page.on('pageerror', e => report.errors.push(e.message));
  page.on('response', r => { if (r.status() >= 400) report.failedRequests.push(`${r.status()} ${r.url()}`); });
  page.on('request', r => { if (!r.url().startsWith(new URL(BASE).origin)) report.externalRequests.push(r.url()); });
}
async function launch(page, id, touch) {
  await page.goto(BASE + '#game/' + id);
  await page.waitForFunction(() => window.__arcade?.snapshot()?.mode === 'ready');
  assert.equal((await snap(page)).ticks, 0);
  if (touch) await page.locator('#start').tap(); else await page.locator('#start').click();
  await page.waitForFunction(() => window.__arcade.snapshot().ticks > 2);
}
async function holdTouch(page, selectors, ms) {
  const session = await page.context().newCDPSession(page);
  await page.locator('#touch-controls').scrollIntoViewIfNeeded();
  const points = [];
  for (const [id, selector] of selectors.entries()) {
    const rect = await page.locator(selector).boundingBox();
    points.push({ x: rect.x + rect.width / 2, y: rect.y + rect.height / 2, id: id + 1 });
  }
  try { await session.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: points }); await wait(page, ms); }
  finally { await session.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] }); await session.detach(); }
}
async function holdKeys(page, keys, ms) {
  await page.locator('#game-canvas').focus();
  try { for (const key of keys) await page.keyboard.down(key); await wait(page, ms); }
  finally { for (const key of keys) await page.keyboard.up(key); }
}
async function shootAt(page, x, y, touch) {
  await page.locator('#game-canvas').scrollIntoViewIfNeeded();
  const rect = await page.locator('#game-canvas').boundingBox();
  const cx = rect.x + x / 480 * rect.width, cy = rect.y + y / 320 * rect.height;
  if (touch) await page.touchscreen.tap(cx, cy); else await page.mouse.click(cx, cy, { delay: 35 });
}
async function lifecycle(page, id, touch) {
  const click = async selector => touch ? page.locator(selector).tap() : page.locator(selector).click();
  await click('#pause');
  await page.waitForFunction(() => window.__arcade.snapshot().mode === 'paused');
  const frozen = await snap(page); await wait(page, 180);
  assert.deepEqual((await snap(page)).state, frozen.state, `${id}: pause freezes state`);
  assert.equal((await snap(page)).ticks, frozen.ticks);
  await click('#pause');
  await page.waitForFunction(t => window.__arcade.snapshot().ticks > t, frozen.ticks);
  await click('#restart');
  assert.equal((await snap(page)).mode, 'ready');
  assert.equal((await snap(page)).state.score, 0);
  assert.equal((await snap(page)).ticks, 0);
  await wait(page, 100); assert.equal((await snap(page)).ticks, 0);
  await click('#start');
  await page.waitForFunction(() => window.__arcade.snapshot().ticks > 1);
  await click('.back-link');
  await page.waitForFunction(() => window.__arcade.snapshot() === null);
  await wait(page, 150);
  const resources = await page.evaluate(() => window.__arcade.resources());
  assert.deepEqual(resources, { active: 0, inputListeners: 0, raf: 0, hudTimer: 0, voices: 0 });
  return { pauseFreezes: true, resume: true, restart: true, exit: resources };
}
async function rock(page, touch) {
  await launch(page, 'rock-drift', touch);
  const initial = (await snap(page)).state.ship;
  if (touch) { await holdTouch(page, ['[data-input="right"]'], 180); await holdTouch(page, ['[data-input="up"]'], 280); }
  else { await holdKeys(page, ['ArrowRight'], 180); await holdKeys(page, ['ArrowUp'], 280); }
  const moved = (await snap(page)).state.ship;
  assert.notEqual(moved.angle, initial.angle, 'rotation is driven by real controls');
  assert.ok(Math.hypot(moved.vx, moved.vy) > 15, 'thrust creates momentum');
  for (let attempt = 0; attempt < 3; attempt += 1) {
    if (touch) await holdTouch(page, ['[data-input="right"]', '[data-input="action"]'], 2600);
    else await holdKeys(page, ['ArrowRight', 'Space'], 2600);
    if ((await snap(page)).state.score > 0) break;
  }
  const played = await snap(page);
  assert.ok(played.state.shots > 3);
  assert.ok(played.state.score > 0, 'real fire must destroy actual rock geometry');
  await page.locator('#game-shell').screenshot({ path: path.join(OUT, `rock-drift-${touch ? 'mobile' : 'desktop'}.png`) });
  const evidence = { score: played.state.score, status: played.state.status, shots: played.state.shots, destroyed: played.state.destroyed, lives: played.state.lives, ticks: played.ticks, input: touch ? 'CDP real multitouch D-pad and action' : 'keyboard rotation, thrust and fire' };
  assert.equal(played.state.status, 'playing', 'lifecycle is checked during an active run');
  evidence.lifecycle = await lifecycle(page, 'rock-drift', touch);
  return evidence;
}
async function sky(page, touch) {
  await launch(page, 'sky-shield', touch);
  const initial = (await snap(page)).state.aim.x;
  if (touch) await holdTouch(page, ['[data-input="left"]'], 180); else await holdKeys(page, ['ArrowLeft'], 180);
  assert.ok((await snap(page)).state.aim.x < initial, 'D-pad or keyboard moves reticle');
  const targets = [];
  for (let attempt = 0; attempt < 18; attempt += 1) {
    const state = (await snap(page)).state;
    if (state.intercepted > 0) break;
    const target = state.missiles.filter(m => !targets.includes(m.id)).sort((a, b) => b.y - a.y)[0];
    if (target) {
      const lead = Math.hypot(target.x - 240, target.y - 278) / 245 + 0.16;
      const x = Math.max(16, Math.min(464, target.x + target.vx * lead));
      const y = Math.max(42, Math.min(250, target.y + target.vy * lead));
      await shootAt(page, x, y, touch); targets.push(target.id);
    }
    await wait(page, 350);
  }
  const played = await snap(page);
  assert.ok(played.state.intercepted > 0, 'real pointer or touchscreen shot must intercept a live missile');
  assert.ok(played.state.score > 0);
  assert.ok(played.state.ammo < played.state.maxAmmo);
  await page.locator('#game-shell').screenshot({ path: path.join(OUT, `sky-shield-${touch ? 'mobile' : 'desktop'}.png`) });
  const evidence = { score: played.state.score, status: played.state.status, intercepted: played.state.intercepted, shots: played.state.shots, ammo: played.state.ammo, lives: played.state.lives, ticks: played.ticks, targets, input: touch ? 'touch D-pad and real canvas tap' : 'keyboard reticle and real pointer aim/click' };
  evidence.lifecycle = await lifecycle(page, 'sky-shield', touch);
  return evidence;
}
(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    for (const touch of [false, true]) {
      const context = await browser.newContext(touch ? { viewport: { width: 375, height: 844 }, isMobile: true, hasTouch: true, deviceScaleFactor: 1 } : { viewport: { width: 1365, height: 1000 }, deviceScaleFactor: 1 });
      const page = await context.newPage(); monitor(page);
      const target = touch ? report.mobile : report.desktop;
      target.rock = await rock(page, touch);
      target.sky = await sky(page, touch);
      const viewport = await page.evaluate(() => ({ width: innerWidth, scrollWidth: document.documentElement.scrollWidth }));
      assert.equal(viewport.scrollWidth, viewport.width, 'no horizontal page overflow');
      target.viewport = viewport;
      await context.close();
    }
    assert.deepEqual(report.errors, []); assert.deepEqual(report.failedRequests, []); assert.deepEqual(report.externalRequests, []);
    report.passed = true;
  } catch (error) { report.passed = false; report.failure = error.stack; throw error; }
  finally { fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2)); await browser.close(); console.log(JSON.stringify(report, null, 2)); }
})().catch(error => { console.error(error); process.exitCode = 1; });
