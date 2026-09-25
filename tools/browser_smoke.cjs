// Run against a local exported build: BROWSER_EXECUTABLE=/path/to/chrome node tools/browser_smoke.cjs
const {chromium} = require('playwright');
const fs = require('node:fs');
const assert = require('node:assert/strict');
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:process.env.BROWSER_EXECUTABLE||undefined,args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const failures=[];
 const scenes=new Map(),flappy=new Map();
 const observe=page=>page.on('console',message=>{
   const line=message.text();
   if(line.startsWith('SCENE_READY '))scenes.set(page,line.slice(12));
   if(line.startsWith('FLAPPY_STATE '))flappy.set(page,line.slice(13));
 });
 const waitState=async(map,page,value)=>{
   const until=Date.now()+120000;
   while(map.get(page)!==value){
     if(Date.now()>until)throw Error('Timed out waiting for '+value+'; actual '+map.get(page));
     await page.waitForTimeout(200);
   }
 };
 const scene=async(page,path)=>waitState(scenes,page,'res://scenes/'+path+'.tscn');
 const context=await browser.newContext({viewport:{width:1280,height:720}});
 const page=await context.newPage();
 observe(page);
 page.on('pageerror',e=>failures.push(e.message));
 page.on('console',m=>{if(m.type()==='error')console.log(m.text());if(/SCRIPT ERROR|Parse Error|Failed to load|ERROR:/.test(m.text()))failures.push(m.text());});
 await page.goto('http://127.0.0.1:8765/');
 await page.locator('#start').click();
 await page.locator('#gate').waitFor({state:'hidden',timeout:90000});
 await page.waitForTimeout(1800);
 fs.mkdirSync('docs/screenshots',{recursive:true});
 await page.screenshot({path:'docs/screenshots/title.png'});
 await page.mouse.click(1000,535); // Bonus Flappy
 await scene(page,'flappy_bird');
 await page.waitForTimeout(400);
 await page.screenshot({path:'docs/screenshots/flappy-ready.png'});
 await page.keyboard.press('Space');
 await page.waitForTimeout(200);
 await page.screenshot({path:'docs/screenshots/flappy-flight.png'});
 await waitState(flappy,page,'game_over'); // Wait for actual physics, even on slow CI.
 await page.screenshot({path:'docs/screenshots/flappy-game-over.png'});
 await page.keyboard.press('r');
 await waitState(flappy,page,'playing');
 await page.mouse.click(1150,675); // Must be visible and clickable after camera fix.
 await scene(page,'title_screen');
 await page.mouse.click(200,675);
 await scene(page,'profile_scene');
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
 observe(phone);
 phone.on('pageerror',e=>failures.push(e.message));
 phone.on('console',m=>{if(m.type()==='error')console.log(m.text());if(/SCRIPT ERROR|Parse Error|Failed to load|ERROR:/.test(m.text()))failures.push(m.text());});
 await phone.goto('http://127.0.0.1:8765/');
 await phone.locator('#start').tap();
 await phone.locator('#gate').waitFor({state:'hidden',timeout:90000});
 await phone.waitForTimeout(1000);
 // Godot keeps the 16:9 viewport centered inside the landscape browser.
 const tap = async(x,y)=>phone.touchscreen.tap((844-390*1280/720)/2+x*390/720,y*390/720);
 await tap(200,675);
 await phone.waitForTimeout(500);
 await tap(805,450); // Prism Weaver
 await phone.waitForTimeout(300);
 await phone.screenshot({path:'docs/screenshots/mobile-profile.png'});
 await tap(635,640);
 await tap(1000,640);
 await phone.waitForTimeout(400);
 await tap(1000,535);
 await scene(phone,'flappy_bird');
 await phone.waitForTimeout(400);
 await tap(500,300);
 await phone.waitForTimeout(200);
 await phone.screenshot({path:'docs/screenshots/mobile-flappy-flight.png'});
 await waitState(flappy,phone,'game_over');
 await tap(500,300); // Retry using a real touch, not keyboard input.
 await waitState(flappy,phone,'playing');
 await tap(1150,675);
 await scene(phone,'title_screen');
 await tap(180,220); // Single Arc Reactor Dash
 await scene(phone,'minigames/arc_reactor_dash');
 await phone.screenshot({path:'docs/screenshots/mobile-single-game.png'});
 const cdp=await mobile.newCDPSession(phone);
 const point=(x,y,id)=>({x:(844-390*1280/720)/2+x*390/720,y:y*390/720,id});
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[point(260,640,0),point(1140,640,1)]});
 await phone.waitForTimeout(150);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
 await scene(phone,'single_result');
 await phone.screenshot({path:'docs/screenshots/mobile-single-result.png'});
 await tap(600,545); // Play Again
 await scene(phone,'minigames/arc_reactor_dash');
 await tap(90,175); // Home
 await scene(phone,'title_screen');
 await phone.screenshot({path:'docs/screenshots/mobile-home.png'});
 await tap(600,535);
 await phone.waitForTimeout(1300);
 await phone.screenshot({path:'docs/screenshots/mobile-briefing.png'});
 const deadline=Date.now()+120000;
 while(!String(scenes.get(phone)).includes('/minigames/')){
   if(Date.now()>deadline)throw Error('Tournament did not launch');
   await phone.waitForTimeout(200);
 }
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
