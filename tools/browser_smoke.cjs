// Run against a local exported build: BROWSER_EXECUTABLE=/path/to/chrome node tools/browser_smoke.cjs
const {chromium} = require('playwright');
const fs = require('node:fs');
const assert = require('node:assert/strict');
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:process.env.BROWSER_EXECUTABLE||undefined,args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const failures=[];
 const context=await browser.newContext({viewport:{width:1280,height:720}});
 const page=await context.newPage();
 page.on('pageerror',e=>failures.push(e.message));
 page.on('console',m=>{if(m.type()==='error')console.log(m.text());if(/SCRIPT ERROR|Parse Error|Failed to load|ERROR:/.test(m.text()))failures.push(m.text());});
 await page.goto('http://127.0.0.1:8765/');
 await page.locator('#start').click();
 await page.locator('#gate').waitFor({state:'hidden',timeout:90000});
 await page.waitForTimeout(1800);
 fs.mkdirSync('docs/screenshots',{recursive:true});
 await page.screenshot({path:'docs/screenshots/title.png'});
 await page.mouse.click(1000,535); // Bonus Flappy
 await page.waitForTimeout(900);
 await page.screenshot({path:'docs/screenshots/flappy-ready.png'});
 await page.keyboard.press('Space');
 await page.waitForTimeout(200);
 await page.screenshot({path:'docs/screenshots/flappy-flight.png'});
 await page.waitForTimeout(2200); // Let the hero reach the floor.
 await page.screenshot({path:'docs/screenshots/flappy-game-over.png'});
 await page.keyboard.press('r');
 await page.waitForTimeout(150);
 await page.mouse.click(1150,675); // Must be visible and clickable after camera fix.
 await page.waitForTimeout(1000);
 await page.mouse.click(1000,367);
 await page.waitForTimeout(800);
 for(let i=0;i<9;i++){
   await page.mouse.click(565+(i%3)*248,260+Math.floor(i/3)*94);
   await page.waitForTimeout(100);
 }
 await page.screenshot({path:'docs/screenshots/heroes.png'});
 await page.mouse.click(635,640); // save Copper Guard
 await page.mouse.click(1000,640);
 await page.waitForTimeout(500);
 await page.reload();
 await page.locator('#start').click();
 await page.locator('#gate').waitFor({state:'hidden',timeout:90000});
 await page.waitForTimeout(800);
 await page.screenshot({path:'docs/screenshots/saved-hero.png'});
 console.log('PASS desktop browser: boots, all nine selectors respond, save and reload');
 const mobile=await browser.newContext({viewport:{width:844,height:390},hasTouch:true,isMobile:true,deviceScaleFactor:1});
 const phone=await mobile.newPage();
 phone.on('pageerror',e=>failures.push(e.message));
 phone.on('console',m=>{if(m.type()==='error')console.log(m.text());if(/SCRIPT ERROR|Parse Error|Failed to load|ERROR:/.test(m.text()))failures.push(m.text());});
 await phone.goto('http://127.0.0.1:8765/');
 await phone.locator('#start').tap();
 await phone.locator('#gate').waitFor({state:'hidden',timeout:90000});
 await phone.waitForTimeout(1000);
 // Godot keeps the 16:9 viewport centered inside the landscape browser.
 const tap = async(x,y)=>phone.touchscreen.tap((844-390*1280/720)/2+x*390/720,y*390/720);
 await tap(1000,367);
 await phone.waitForTimeout(500);
 await tap(805,450); // Prism Weaver
 await phone.waitForTimeout(300);
 await phone.screenshot({path:'docs/screenshots/mobile-profile.png'});
 await tap(635,640);
 await tap(1000,640);
 await phone.waitForTimeout(400);
 await tap(1000,535);
 await phone.waitForTimeout(900);
 await tap(500,300);
 await phone.waitForTimeout(200);
 await phone.screenshot({path:'docs/screenshots/mobile-flappy-flight.png'});
 await phone.waitForTimeout(2200);
 await tap(500,300); // Retry using a real touch, not keyboard input.
 await phone.waitForTimeout(150);
 await tap(1150,675);
 await phone.waitForTimeout(1000);
 await tap(600,365);
 await phone.waitForTimeout(1300);
 await phone.screenshot({path:'docs/screenshots/mobile-briefing.png'});
 await phone.waitForTimeout(2200);
 await phone.screenshot({path:'docs/screenshots/mobile-game.png'});
 await phone.setViewportSize({width:390,height:844});
 assert.equal(await phone.locator('#rotate').isVisible(),true);
 await phone.screenshot({path:'docs/screenshots/mobile-portrait.png'});
 await phone.setViewportSize({width:844,height:390});
 assert.equal(await phone.locator('#rotate').isVisible(),false);
 console.log('PASS mobile browser: touch menus, profile, mission, rotation overlay');
 await browser.close();
 assert.deepEqual(failures,[]);
 console.log('BROWSER TESTS: 0 errors');
})().catch(error=>{console.error(error);process.exit(1)});
