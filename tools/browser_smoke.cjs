const {chromium} = require('playwright');
const fs = require('node:fs');
(async () => {
  const browser = await chromium.launch({headless:true});
  const context = await browser.newContext({viewport:{width:1280,height:720}});
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => {if (m.type()==='error') errors.push(m.text());});
  page.on('response', r => {if (r.status()>=400) errors.push(`${r.status()} ${r.url()}`);});
  fs.mkdirSync('build/browser-qa',{recursive:true});
  await page.goto('http://127.0.0.1:8765/',{waitUntil:'domcontentloaded'});
  await page.locator('#status').waitFor({state:'hidden',timeout:90000});
  for (const name of ['SOLSTICE','VECTOR','UMBRA','PRISM']) {
    await page.locator('#hero-a11y').filter({hasText:`Selected ${name}.`}).waitFor({state:'attached',timeout:5000});
    await page.screenshot({path:`build/browser-qa/hero-${name.toLowerCase()}.png`});
    await page.locator('#canvas').press('Space');
    await page.locator('#hero-a11y').filter({hasText:'Power demonstration active.'}).waitFor({state:'attached',timeout:5000});
    await page.locator('#canvas').press('ArrowRight');
  }
  await page.locator('#canvas').press('ArrowRight');
  await page.locator('#canvas').press('Enter');
  await page.locator('#hero-a11y').filter({hasText:'Selected VECTOR. KINETIC ACROBAT. Equipped.'}).waitFor({state:'attached',timeout:5000});
  // Roster preferences are synchronous: verify an immediate reload after equipment.
  await page.reload();
  await page.locator('#status').waitFor({state:'hidden',timeout:90000});
  console.log('Reloaded hero:',await page.locator('#hero-a11y').textContent());
  await page.locator('#hero-a11y').filter({hasText:'Selected VECTOR. KINETIC ACROBAT. Equipped.'}).waitFor({state:'attached',timeout:5000});
  for (const width of [375,390,430]) {
    await page.setViewportSize({width,height:844});
    await page.waitForTimeout(300);
    await page.screenshot({path:`build/browser-qa/hero-phone-${width}.png`});
    const logical = Number(await page.locator('#canvas').getAttribute('data-selector-width'));
    if (Math.abs(logical-width)>2) throw new Error(`Hero width ${logical} does not match CSS viewport ${width}`);
  }
  const phoneContext = await browser.newContext({viewport:{width:390,height:844},deviceScaleFactor:3,isMobile:true,hasTouch:true});
  const phone = await phoneContext.newPage();
  phone.on('pageerror', e => errors.push(e.message));
  phone.on('console', m => {if(m.type()==='error') errors.push(m.text());});
  await phone.goto('http://127.0.0.1:8765/',{waitUntil:'domcontentloaded'});
  await phone.locator('#status').waitFor({state:'hidden',timeout:90000});
  await phone.screenshot({path:'build/browser-qa/hero-phone-dpr3.png'});
  const phoneWidth = Number(await phone.locator('#canvas').getAttribute('data-selector-width'));
  if (Math.abs(phoneWidth-390)>2) throw new Error(`DPR3 hero width ${phoneWidth} does not match 390 CSS pixels`);
  await phone.touchscreen.tap(265,170);
  await phone.locator('#hero-a11y').filter({hasText:'Selected VECTOR.'}).waitFor({state:'attached',timeout:5000});
  await phone.touchscreen.tap(260,605);
  await phone.locator('#hero-a11y').filter({hasText:'Power demonstration active.'}).waitFor({state:'attached',timeout:5000});
  await phone.screenshot({path:'build/browser-qa/hero-phone-dpr3-power.png'});
  await phoneContext.close();
  await page.setViewportSize({width:1280,height:720});
  // Retain the existing onboarding / game / pause regression path.
  await page.goto('http://127.0.0.1:8765/?screen=arcade',{waitUntil:'domcontentloaded'});
  await page.locator('#status').waitFor({state:'hidden',timeout:90000});
  await page.screenshot({path:'build/browser-qa/onboarding.png'});
  // Click the visible onboarding action, then exercise the in-game pause flow.
  await page.mouse.click(600,380);
  await page.waitForTimeout(1000);
  await page.screenshot({path:'build/browser-qa/first-game.png'});
  await page.mouse.click(1170,60);
  await page.screenshot({path:'build/browser-qa/paused.png'});
  await page.keyboard.press('Escape');
  await page.waitForTimeout(9500);
  await page.screenshot({path:'build/browser-qa/result.png'});
  await page.setViewportSize({width:390,height:844});
  await page.waitForTimeout(300);
  await page.screenshot({path:'build/browser-qa/portrait.png'});
  await page.setViewportSize({width:844,height:390});
  await page.waitForTimeout(300);
  await page.screenshot({path:'build/browser-qa/mobile-landscape.png'});
  await context.close();
  await browser.close();
  if (errors.length) throw new Error(errors.join('\n'));
  console.log('Browser load, game, pause, result, resize: no console errors or missing assets.');
})().catch(e => {console.error(e);process.exit(1);});
