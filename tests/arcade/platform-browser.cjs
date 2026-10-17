const { chromium } = require('../../tools/arcade_playwright.cjs');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const BASE = process.env.ARCADE_URL || 'http://127.0.0.1:8785/arcade/?qa=1';
const OUT = path.resolve('build/arcade/platform');
fs.mkdirSync(OUT, { recursive: true });
const results = [], findings = [], normalErrors = [], normalFailures = [];
let browser;
const check = async (name, fn) => {
  try { const detail = await fn(); results.push({ name, pass: true, detail }); console.log('PASS', name); }
  catch (error) { const text = error.message; results.push({ name, pass: false, error: text }); findings.push({ name, error: text }); console.error('FAIL', name, text); }
};
const ready = page => page.waitForFunction(() => window.__arcade?.snapshot()?.mode === 'ready');
const mode = (page, value) => page.waitForFunction(value => window.__arcade?.snapshot()?.mode === value, value);
const snap = page => page.evaluate(() => window.__arcade.snapshot());
const resources = page => page.evaluate(() => window.__arcade.resources());
async function newPage(options = {}, init) {
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, ...options });
  const page = await context.newPage();
  page.setDefaultTimeout(7000);
  if (init) await page.addInitScript(init);
  return { context, page };
}
async function loadHome(page) {
  await page.goto(BASE, { waitUntil: 'networkidle' });
  await page.waitForFunction(() => window.__arcade?.catalog().length > 0);
}
async function choose(page, id) { await page.locator('a[data-game="' + id + '"]').click(); await ready(page); }
async function home(page) { await page.locator('.back-link').click(); await page.locator('#home-view').waitFor({ state: 'visible' }); }
(async () => {
  browser = await chromium.launch({ headless: true });
  const { page, context } = await newPage();
  page.on('pageerror', e => normalErrors.push(e.message));
  page.on('response', r => { if (r.status() >= 400) normalFailures.push(r.status() + ' ' + r.url()); });

  await check('Home shows only playable cabinets and clear planned items', async () => {
    await loadHome(page);
    const count = await page.locator('.game-card').count();
    const expected = await page.evaluate(() => window.__arcade.catalog().filter(g => ['PLAYABLE', 'TESTED', 'RELEASE READY'].includes(g.status)).length);
    assert.equal(count, expected);
    assert(count >= 6);
    assert.equal(await page.locator('.planned-item a').count(), 0);
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth), 1440);
    await page.screenshot({ path: path.join(OUT, 'desktop-home.png'), fullPage: true });
    return { count, planned: await page.locator('.planned-item').count() };
  });
  await check('Empty search and combined filters recover through clear filters', async () => {
    await page.locator('#search').fill('no-cabinet-should-match-this');
    assert.equal(await page.locator('.game-card').count(), 0);
    assert(await page.locator('#empty').isVisible());
    await page.locator('#reset-filters').click();
    assert((await page.locator('.game-card').count()) >= 6);
    await page.locator('#categories button').filter({ hasText: /^Puzzle$/ }).click();
    await page.locator('#era-filter').selectOption('1950s');
    assert.equal(await page.locator('.game-card').count(), 1);
    assert.equal(await page.locator('.game-card h3').innerText(), 'Grid X');
    await page.locator('#era-filter').selectOption('');
    await page.locator('#categories button').filter({ hasText: /^All$/ }).click();
  });
  await check('Ready cabinet has no continuously running RAF', async () => {
    await choose(page, 'brick-burst');
    await page.waitForTimeout(150);
    const a = await snap(page);
    await page.waitForTimeout(150);
    const b = await snap(page);
    assert.equal(a.ticks, 0); assert.equal(a.frames, b.frames);
    assert.equal((await resources(page)).raf, 0);
    await page.screenshot({ path: path.join(OUT, 'desktop-ready.png') });
  });
  await check('Focused ready button starts with Enter', async () => {
    await page.locator('#start').focus();
    await page.keyboard.press('Enter');
    await page.waitForTimeout(200);
    assert.equal((await snap(page)).mode, 'playing', 'Enter on the focused start button was swallowed');
  });
  if ((await snap(page))?.mode !== 'playing') await page.locator('#start').click();
  await check('Canvas focus accepts held gameplay keys', async () => {
    await page.locator('#game-canvas').focus();
    const before = (await snap(page)).state.paddle.x;
    await page.keyboard.down('ArrowLeft'); await page.waitForTimeout(120); await page.keyboard.up('ArrowLeft');
    assert((await snap(page)).state.paddle.x < before, 'Canvas keydown was ignored');
  });
  await check('Focused toolbar button activates with Space', async () => {
    await page.locator('#pause').focus(); await page.keyboard.press('Space'); await page.waitForTimeout(150);
    assert.equal((await snap(page)).mode, 'paused', 'Space activation on button was swallowed');
    await page.locator('#pause').click();
  });
  await check('Mute works, immediately silences voices, and persists after reload', async () => {
    const before = await page.locator('#mute').getAttribute('aria-pressed');
    await page.locator('#mute').click();
    const expected = before === 'true' ? 'false' : 'true';
    assert.equal(await page.locator('#mute').getAttribute('aria-pressed'), expected);
    if (expected === 'true') assert.equal((await resources(page)).voices, 0);
    await page.reload({ waitUntil: 'networkidle' }); await ready(page);
    assert.equal(await page.locator('#mute').getAttribute('aria-pressed'), expected);
  });
  await check('Played sessions persist after reload', async () => {
    const saved = await page.evaluate(() => window.__arcade.saves());
    assert(saved.games['brick-burst'].plays >= 1);
    await page.locator('#start').click();
    await page.locator('#pause').click();
    const paused = await snap(page);
    await page.waitForTimeout(150);
    assert.deepEqual((await snap(page)).state, paused.state);
    assert.equal((await resources(page)).raf, 0);
    await home(page);
    await page.reload({ waitUntil: 'networkidle' });
    const now = await page.evaluate(() => window.__arcade.saves());
    assert(now.games['brick-burst'].plays > saved.games['brick-burst'].plays);
  });
  await check('Returning home releases all per-game resources', async () => {
    const r = await resources(page);
    assert.deepEqual(r, { active: 0, inputListeners: 0, raf: 0, hudTimer: 0, voices: 0 });
  });
  await check('Fullscreen enters and exits through the real browser API', async () => {
    await choose(page, 'brick-burst');
    await page.locator('#fullscreen').click();
    await page.waitForTimeout(200);
    const entered = await page.evaluate(() => !!document.fullscreenElement);
    assert(entered, 'Fullscreen click did not enter fullscreen');
    assert.equal(await page.locator('#fullscreen').innerText(), 'Exit fullscreen');
    // Toolbar and touch controls remain available inside fullscreen.
    assert(await page.locator('#fullscreen').isVisible());
    assert(await page.locator('[data-input="action"]').isVisible());
    await page.locator('#fullscreen').click();
    await page.waitForTimeout(100);
    if (await page.evaluate(() => !!document.fullscreenElement)) await page.evaluate(() => document.exitFullscreen());
    assert.equal(await page.evaluate(() => !!document.fullscreenElement), false);
    await home(page);
  });
  await check('Repeated cabinet switches do not accumulate active runtimes or listeners', async () => {
    let baseline;
    for (const id of ['byte-munch', 'grid-x', 'brick-burst', 'crate-shift', 'paddle-panic', 'stackfall', 'brick-burst']) {
      await choose(page, id);
      const r = await resources(page);
      baseline ??= r.inputListeners;
      assert.equal(r.active, 1); assert.equal(r.inputListeners, baseline); assert.equal(r.hudTimer, 1);
      await home(page);
      assert.deepEqual(await resources(page), { active: 0, inputListeners: 0, raf: 0, hudTimer: 0, voices: 0 });
    }
    return { inputListenersPerGame: baseline };
  });
  await check('Invalid cabinet route shows unavailable state with no stale active controls', async () => {
    await choose(page, 'brick-burst'); await page.locator('#start').click();
    await page.goto(BASE + '#game/not-a-real-cabinet', { waitUntil: 'networkidle' });
    assert.equal(await page.locator('#overlay-title').innerText(), 'Not playable yet.');
    assert.equal((await resources(page)).active, 0);
    assert(await page.locator('#pause').isDisabled());
    assert(await page.locator('#restart').isDisabled());
    await page.screenshot({ path: path.join(OUT, 'invalid-route.png') });
  });
  await check('Normal browsing has no page errors or HTTP failures', async () => {
    assert.deepEqual(normalErrors, []); assert.deepEqual(normalFailures, []);
  });
  await context.close();

  await check('Delayed module shows a loading state then opens correctly', async () => {
    const { page, context } = await newPage();
    let release; const gate = new Promise(resolve => release = resolve);
    await page.route('**/arcade/games/brick-burst.js', async route => { await gate; await route.continue(); });
    await loadHome(page);
    await page.locator('[data-game="brick-burst"]').click();
    await page.locator('#overlay-title').filter({ hasText: 'Loading cabinet' }).waitFor();
    assert(await page.locator('#start').isHidden());
    await page.screenshot({ path: path.join(OUT, 'loading.png') });
    release(); await ready(page);
    await context.close();
  });
  await check('Leaving during an in-flight load never resurrects the closed cabinet', async () => {
    const { page, context } = await newPage();
    let release; const gate = new Promise(resolve => release = resolve);
    await page.route('**/arcade/games/byte-munch.js', async route => { await gate; await route.continue(); });
    await loadHome(page);
    await page.locator('[data-game="byte-munch"]').click();
    await page.locator('#overlay-title').filter({ hasText: 'Loading cabinet' }).waitFor();
    await home(page);
    await choose(page, 'brick-burst');
    release(); await page.waitForTimeout(250);
    assert.equal(await page.locator('#game-title').innerText(), 'Brick Burst');
    assert.equal((await snap(page)).state.ball.docked, true);
    assert.equal((await resources(page)).active, 1);
    await home(page);
    assert.equal((await resources(page)).inputListeners, 0);
    await context.close();
  });
  await check('Failed module load has clear recovery UI and retry succeeds after network returns', async () => {
    const { page, context } = await newPage();
    const errors = []; page.on('pageerror', e => errors.push(e.message));
    await page.route('**/arcade/games/brick-burst.js', route => route.fulfill({ status: 503, contentType: 'text/plain', body: 'Temporary test failure' }));
    await loadHome(page);
    await page.locator('[data-game="brick-burst"]').click();
    await page.locator('#overlay-title').filter({ hasText: 'Could not start.' }).waitFor();
    assert(await page.locator('#start').isVisible());
    assert.equal((await resources(page)).active, 0);
    await page.screenshot({ path: path.join(OUT, 'network-error.png') });
    await page.unroute('**/arcade/games/brick-burst.js');
    await page.locator('#start').click();
    await page.waitForTimeout(800);
    assert.equal((await snap(page))?.mode, 'ready', 'Retry remains stuck on the cached failed dynamic import');
    assert.deepEqual(errors, []);
    await context.close();
  });
  await check('Blocked localStorage still permits play and says scores are session-only', async () => {
    const { page, context } = await newPage({}, () => Object.defineProperty(window, 'localStorage', { get() { throw new DOMException('Storage blocked', 'SecurityError'); } }));
    await loadHome(page);
    assert.match(await page.locator('#progress-copy').innerText(), /unavailable/i);
    await choose(page, 'brick-burst'); await page.locator('#start').click();
    await page.locator('#mute').click();
    assert.equal((await snap(page)).mode, 'playing');
    assert.match(await page.locator('#save-note').innerText(), /unavailable|session/i);
    await context.close();
  });
  await check('Corrupt save is ignored safely without losing playability', async () => {
    const { page, context } = await newPage({}, () => localStorage.setItem('onlyeducation.arcade.v1', '{broken JSON'));
    await loadHome(page);
    const save = await page.evaluate(() => window.__arcade.saves());
    assert.equal(save.version, 1); assert.deepEqual(save.games, {});
    await choose(page, 'brick-burst'); await page.locator('#start').click();
    assert.equal((await snap(page)).mode, 'playing');
    await context.close();
  });
  await check('Reduced motion disables animated hover and smooth scroll', async () => {
    const { page, context } = await newPage({ reducedMotion: 'reduce' });
    await loadHome(page);
    const card = page.locator('.game-card').first();
    await card.hover();
    const style = await card.evaluate(el => ({ transform: getComputedStyle(el).transform, transition: getComputedStyle(el).transitionDuration, scroll: getComputedStyle(document.documentElement).scrollBehavior }));
    assert.equal(style.transform, 'none'); assert.equal(style.transition, '0s'); assert.equal(style.scroll, 'auto');
    await context.close();
  });
  for (const width of [320, 375, 430, 768]) await check('Mobile layout ' + width + 'px fits and touch controls stay tappable', async () => {
    const { page, context } = await newPage({ viewport: { width, height: 900 }, isMobile: width < 500, hasTouch: true });
    await loadHome(page);
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth), width);
    await page.screenshot({ path: path.join(OUT, 'home-' + width + '.png'), fullPage: true });
    await choose(page, 'brick-burst');
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth), width);
    await page.locator('#start').tap();
    const buttons = await page.locator('#touch-controls button').evaluateAll(buttons => buttons.map(b => { const r = b.getBoundingClientRect(); return { w: r.width, h: r.height, left: r.left, right: r.right }; }));
    assert(buttons.every(b => b.w >= 39 && b.h >= 39 && b.left >= 0 && b.right <= width));
    await page.locator('#pause').tap();
    await page.screenshot({ path: path.join(OUT, 'play-' + width + '.png'), fullPage: true });
    await context.close();
    return { buttons: buttons.length };
  });
})().catch(error => { findings.push({ name: 'Harness setup', error: error.stack }); console.error(error); }).finally(async () => {
  await browser?.close();
  const report = { timestamp: new Date().toISOString(), base: BASE, checks: results.length, passed: results.filter(r => r.pass).length, failed: findings.length, results, findings };
  fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify({ checks: report.checks, passed: report.passed, failed: report.failed, report: path.join(OUT, 'report.json') }));
  process.exitCode = findings.length ? 1 : 0;
});
