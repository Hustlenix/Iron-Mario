const {chromium}=require('playwright');
const fs=require('node:fs');
const assert=require('node:assert/strict');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const errors=[];const states=new Map();
 const observe=page=>{
  const state={};states.set(page,state);
  page.on('pageerror',e=>errors.push(e.message));
  page.on('console',m=>{
   const line=m.text().trim();
   if(/SCRIPT ERROR|ERROR:|Parse Error/.test(line))errors.push(line);
   for(const key of ['HOME_READY','SCENE_READY','ARCADE_READY','ARCADE_STARTED','ARCADE_PAUSE','LIBRARY_PAGE','FLAPPY_STATE']){
    if(line.startsWith(key+' '))state[key]=line.slice(key.length+1);
   }
  });
 };
 const wait=async(page,key,value)=>{
  const until=Date.now()+120000;
  while(states.get(page)[key]!==value){
   if(Date.now()>until)throw Error(`${key}: expected ${value}, actual ${states.get(page)[key]}`);
   await page.waitForTimeout(150);
  }
 };
 const boot=async(page)=>{
  await page.goto('http://127.0.0.1:8765/');
  await page.locator('#start').click();
  await page.locator('#gate').waitFor({state:'hidden',timeout:90000});
  await wait(page,'HOME_READY','IRON MARIO');
 };
 fs.mkdirSync('docs/screenshots',{recursive:true});
 const context=await browser.newContext({viewport:{width:1280,height:720}});
 const page=await context.newPage();observe(page);await boot(page);
 await page.screenshot({path:'docs/screenshots/iron-mario-home.png'});
 await page.mouse.click(780,360);await wait(page,'ARCADE_READY','adventure');
 await page.waitForTimeout(450);
 await page.keyboard.down('ArrowRight');await page.keyboard.down('Space');
 await page.waitForTimeout(220);await page.keyboard.up('Space');await page.keyboard.up('ArrowRight');
 await page.keyboard.down('e');await page.waitForTimeout(200);await page.keyboard.up('e');
 await page.screenshot({path:'docs/screenshots/iron-mario-adventure.png'});
 await page.keyboard.press('Escape');await wait(page,'ARCADE_PAUSE','adventure true');
 await page.screenshot({path:'docs/screenshots/iron-mario-paused.png'});
 await page.mouse.click(800,465);await wait(page,'SCENE_READY','res://scenes/title_screen.tscn');
 await page.mouse.click(620,480);await wait(page,'SCENE_READY','res://scenes/arcade_library.tscn');
 await page.screenshot({path:'docs/screenshots/arcade-library.png'});
 const ids=['dino_dash','grid_x','sidecourt','orbit_duel','paddle_panic','dark_cavern','armored_arena','brick_burst','byte_munch','invader_patrol','rock_drift','soft_landing','flag_run','dot_gobbler','sky_shield','bug_blaster','hopway','color_steps','crate_shift','stackfall'];
 for(let index=0;index<ids.length;index++){
  const targetPage=Math.floor(index/6);
  for(let p=0;p<targetPage;p++){
   await page.mouse.click(840,660);await wait(page,'LIBRARY_PAGE',String(p+1));
  }
  const slot=index%6;
  await page.mouse.click(225+(slot%3)*415,270+Math.floor(slot/3)*195);
  await wait(page,'ARCADE_READY',ids[index]);
  await page.screenshot({path:`docs/screenshots/briefing-${ids[index]}.png`});
  await page.keyboard.press('Enter');await wait(page,'ARCADE_STARTED',ids[index]);
  const playKeys={
   dino_dash:['Space'],grid_x:['ArrowRight','Space'],sidecourt:['ArrowLeft','Space'],
   orbit_duel:['ArrowRight','ArrowUp','Space'],paddle_panic:['ArrowUp','Space'],
   dark_cavern:['ArrowRight','z','Space'],armored_arena:['ArrowRight','Space'],
   brick_burst:['ArrowRight','Space'],byte_munch:['ArrowUp'],invader_patrol:['ArrowLeft','Space'],
   rock_drift:['ArrowRight','ArrowUp','Space'],soft_landing:['ArrowRight','Space'],
   flag_run:['ArrowRight','Space'],dot_gobbler:['ArrowRight'],sky_shield:[],
   bug_blaster:['ArrowLeft','Space'],hopway:['Space'],color_steps:['ArrowLeft'],
   crate_shift:['ArrowLeft'],stackfall:['ArrowRight','ArrowUp','Space']
  }[ids[index]];
  for(const key of playKeys)await page.keyboard.down(key);
  if(ids[index]==='sky_shield')await page.mouse.click(650,300);
  await page.waitForTimeout(160);
  for(const key of playKeys)await page.keyboard.up(key);
  await page.screenshot({path:`docs/screenshots/cabinet-${ids[index]}.png`});
  await page.keyboard.press('Escape');await wait(page,'ARCADE_PAUSE',ids[index]+' true');
  await page.mouse.click(800,465);await wait(page,'SCENE_READY','res://scenes/arcade_library.tscn');
  await wait(page,'LIBRARY_PAGE','0');
 }
 console.log('PASS all 20 cabinet briefings, start, gameplay input, pause and return to Arcade');
 await page.mouse.click(160,50);await wait(page,'SCENE_READY','res://scenes/title_screen.tscn');
 await page.mouse.click(1000,480);await wait(page,'SCENE_READY','res://scenes/quick_games.tscn');
 await page.mouse.click(1000,535);await wait(page,'SCENE_READY','res://scenes/flappy_bird.tscn');
 await page.waitForTimeout(450);await page.keyboard.press('Space');await wait(page,'FLAPPY_STATE','playing');
 await wait(page,'FLAPPY_STATE','game_over');await page.keyboard.press('r');await wait(page,'FLAPPY_STATE','playing');
 await page.keyboard.press('Escape');await wait(page,'SCENE_READY','res://scenes/title_screen.tscn');
 console.log('PASS preserved quick-game home and Flappy start, crash, retry and exit');
 await context.close();
 const mobile=await browser.newContext({viewport:{width:844,height:390},hasTouch:true,isMobile:true,deviceScaleFactor:1});
 const phone=await mobile.newPage();observe(phone);await boot(phone);
 const tap=(x,y)=>phone.touchscreen.tap((844-390*1280/720)/2+x*390/720,y*390/720);
 await tap(780,360);await wait(phone,'ARCADE_READY','adventure');await phone.waitForTimeout(450);
 const cdp=await mobile.newCDPSession(phone);
 const pt=(x,y,id)=>({x:(844-390*1280/720)/2+x*390/720,y:y*390/720,id});
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[pt(280,660,0),pt(1140,650,1)]});
 await phone.waitForTimeout(180);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
 await phone.screenshot({path:'docs/screenshots/mobile-iron-mario.png'});
 await tap(1190,65);await wait(phone,'ARCADE_PAUSE','adventure true');
 await tap(800,465);await wait(phone,'SCENE_READY','res://scenes/title_screen.tscn');
 await tap(620,480);await wait(phone,'SCENE_READY','res://scenes/arcade_library.tscn');
 await tap(640,270);await wait(phone,'ARCADE_READY','grid_x');
 await tap(480,465);await wait(phone,'ARCADE_STARTED','grid_x');
 await tap(450,220);await phone.screenshot({path:'docs/screenshots/mobile-grid-x.png'});
 await phone.setViewportSize({width:390,height:844});assert.equal(await phone.locator('#rotate').isVisible(),true);
 await phone.screenshot({path:'docs/screenshots/mobile-rotate.png'});
 await phone.setViewportSize({width:844,height:390});assert.equal(await phone.locator('#rotate').isVisible(),false);
 await mobile.close();
 console.log('PASS two-finger adventure controls, tap board, pause and orientation');
 const vault=await browser.newContext({viewport:{width:1280,height:720}});
 const archive=await vault.newPage();observe(archive);
 await archive.goto('http://127.0.0.1:8765/extended-arcade/');
 await archive.locator('#status').waitFor({state:'hidden',timeout:90000});
 await archive.locator('#iron-mario-return').waitFor({state:'visible'});
 await archive.screenshot({path:'docs/screenshots/preserved-arcade-vault.png'});
 await archive.locator('#iron-mario-return').click();
 await archive.locator('#gate').waitFor({state:'visible',timeout:30000});
 await vault.close();
 console.log('PASS preserved larger arcade loads and returns to Iron Mario');
 await browser.close();assert.deepEqual(errors,[]);console.log('BROWSER TESTS: 0 errors');
})().catch(e=>{console.error(e);process.exit(1)});
