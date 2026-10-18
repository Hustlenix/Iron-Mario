const {chromium}=require('./arcade_playwright.cjs');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const BASE=process.env.ARCADE_URL||'http://127.0.0.1:8785/arcade/?qa=1';
const OUT=path.resolve('build/arcade/dino-retry');fs.mkdirSync(OUT,{recursive:true});
const report={stateInjection:false,errors:[],failedRequests:[],checks:[]};
const snap=p=>p.evaluate(()=>window.__arcade.snapshot());
function monitor(p){p.on('pageerror',e=>report.errors.push(e.message));p.on('response',r=>{if(r.status()>=400)report.failedRequests.push(r.status()+' '+r.url());});}
async function check(name,fn){const detail=await fn();report.checks.push({name,pass:true,detail});console.log('PASS '+name);}
async function point(p,x,y){const b=await p.locator('#game-canvas').boundingBox();return {x:b.x+x*b.width/480,y:b.y+y*b.height/320};}
async function clickCanvas(p,x,y){const q=await point(p,x,y);await p.mouse.click(q.x,q.y,{delay:20});}
async function start(p,id,touch=false){await p.goto(BASE+'#game/'+id);await p.waitForFunction(()=>window.__arcade?.snapshot()?.mode==='ready');if(touch)await p.locator('#start').tap();else await p.locator('#start').click();await p.waitForFunction(()=>window.__arcade.snapshot().ticks>1);}
async function holdTouch(p,cdp,on){if(!on){await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});return;}const b=await p.locator('[data-input="secondary"]').boundingBox();await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:b.x+b.width/2,y:b.y+b.height/2}]});}
async function runDino(p,touch=false,cdp=null){
 let duck=false,jumps=0,sawDuck=false,canvasTap=false;const deadline=Date.now()+35000;
 while(Date.now()<deadline){const s=(await snap(p)).state;if(s.status!=='playing')throw Error('Runner collided: '+JSON.stringify(s));if(s.cleared>=7)break;
  const o=s.obstacles.find(o=>!o.passed),needDuck=o?.kind==='flyer'&&o.x<250;
  if(needDuck!==duck){if(touch)await holdTouch(p,cdp,needDuck);else if(needDuck)await p.keyboard.down('ArrowDown');else await p.keyboard.up('ArrowDown');duck=needDuck;}
  sawDuck ||= s.ducking;
  if(o?.kind==='thorn'&&o.x<110+s.speed*(touch ? 0.28 : 0.24)&&s.grounded){
   if(touch){const b=await p.locator('[data-input="action"]').boundingBox();await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:b.x+b.width/2,y:b.y+b.height/2}]});await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});}
   else if(!canvasTap){await clickCanvas(p,220,160);canvasTap=true;}
   else await p.keyboard.press('Space',{delay:20});
   jumps++;
  }
  await p.waitForTimeout(40);
 }
 if(duck){if(touch)await holdTouch(p,cdp,false);else await p.keyboard.up('ArrowDown');}
 const s=(await snap(p)).state;assert.ok(s.cleared>=7);assert.ok(s.score>0);assert.ok(sawDuck);assert.ok(jumps>=5);
 await p.locator('#game-canvas').screenshot({path:path.join(OUT,touch?'dino-live-mobile.png':'dino-live.png')});await p.locator('#pause').click();const frozen=await snap(p);await p.waitForTimeout(180);assert.deepEqual((await snap(p)).state,frozen.state);
 await p.locator('#play-column').screenshot({path:path.join(OUT,touch?'dino-mobile.png':'dino-desktop.png')});
 return {score:s.score,cleared:s.cleared,jumps,duckedLowFlyer:sawDuck,pauseFreezes:true,canvasTap:!touch&&canvasTap};
}
const lines=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
function result(b){for(const l of lines)if(b[l[0]]&&l.every(i=>b[i]===b[l[0]]))return b[l[0]];return b.every(Boolean)?0:null;}
function value(b,turn){const end=result(b);if(end!==null)return end===1?1:end===2?-1:0;let best=turn===1?-2:2;for(let i=0;i<9;i++)if(!b[i]){b[i]=turn;const s=value(b,3-turn);b[i]=0;best=turn===1?Math.max(best,s):Math.min(best,s);}return best;}
function move(b,worst=false){let best=worst?2:-2,choice=-1;for(let i=0;i<9;i++)if(!b[i]){b[i]=1;const s=value(b,2);b[i]=0;if(worst?s<best:s>best){best=s;choice=i;}}return choice;}
async function gridMove(p,i){await clickCanvas(p,70+i%3*68,86+Math.floor(i/3)*68);await p.waitForTimeout(550);}
async function cleanup(p){await p.locator('.back-link').click();await p.waitForFunction(()=>window.__arcade.snapshot()===null);const r=await p.evaluate(()=>window.__arcade.resources());assert.deepEqual(r,{active:0,inputListeners:0,raf:0,hudTimer:0,voices:0});return r;}
(async()=>{const browser=await chromium.launch({headless:true});try{
 const c=await browser.newContext({viewport:{width:1440,height:1000}}),p=await c.newPage();monitor(p);p.setDefaultTimeout(15000);
 await check('Prehistoric filter and age label open Dino Dash',async()=>{
  await p.goto(BASE+'#collection');await p.waitForFunction(()=>window.__arcade);await p.locator('#era-filter').selectOption('Prehistoric');assert.equal(await p.locator('[data-game]').count(),1);assert.match(await p.locator('.card-label').textContent(),/67 million years ago/i);
  await p.locator('[data-game="dino-dash"]').click();await p.waitForFunction(()=>window.__arcade.snapshot()?.mode==='ready');assert.match(await p.locator('#game-era').textContent(),/67 million years ago/i);assert.match(await p.locator('#history-copy').textContent(),/playful prehistoric detour/);
  await p.locator('#start').click();await p.waitForFunction(()=>window.__arcade.snapshot().ticks>1);return {ageLabel:true,playfulHistoryNote:true};
 });
 await check('Desktop runner jumps, ducks and clears seven actual hazards',async()=>runDino(p));
 await check('Runner restart, real collision, replay and score persistence work',async()=>{
  await p.locator('#restart').click();assert.equal((await snap(p)).mode,'ready');assert.equal((await snap(p)).state.score,0);await p.locator('#start').click();
  await p.waitForFunction(()=>window.__arcade.snapshot().mode==='ended',null,{timeout:12000});assert.equal((await snap(p)).state.status,'lost');
  await p.locator('#start').click();assert.equal((await snap(p)).mode,'playing');assert.ok((await snap(p)).state.elapsed<.2);
  const best=await p.evaluate(()=>window.__arcade.saves().games['dino-dash'].best);assert.ok(best>100);return {realCollision:true,replay:true,best,exit:await cleanup(p)};
 });
 await check('Grid X later-round loss retries the current terminal with progress intact',async()=>{
  await start(p,'grid-x');
  for(let n=0;n<8;n++){const s=(await snap(p)).state;if(s.roundComplete)break;await gridMove(p,move(s.board.slice()));}
  assert.equal((await snap(p)).state.roundComplete,true);await p.keyboard.press('Space');await p.waitForTimeout(50);
  for(let n=0;n<18;n++){const s=(await snap(p)).state;if(s.status==='lost')break;if(s.roundComplete){await p.keyboard.press('Space');await p.waitForTimeout(30);continue;}await gridMove(p,move(s.board.slice(),true));}
  const lost=(await snap(p)).state;assert.equal(lost.status,'lost');assert.ok(lost.round>=2);assert.ok(lost.score>0);assert.match(await p.locator('#start').textContent(),/RETRY TERMINAL/);
  const plays=await p.evaluate(()=>window.__arcade.saves().games['grid-x'].plays);
  await p.locator('#start').click();const retry=await snap(p);assert.equal(retry.mode,'playing');assert.equal(retry.state.round,lost.round);assert.equal(retry.state.score,lost.score);assert.equal(retry.state.wins,lost.wins);assert.equal(retry.state.draws,lost.draws);assert.deepEqual(retry.state.board,Array(9).fill(0));
  assert.equal(await p.evaluate(()=>window.__arcade.saves().games['grid-x'].plays),plays);
  await p.locator('#play-column').screenshot({path:path.join(OUT,'grid-retry.png')});
  await p.locator('#restart').click();assert.equal((await snap(p)).state.round,1);assert.equal((await snap(p)).state.score,0);
  return {lostRound:lost.round,retainedScore:retry.state.score,retainedClears:lost.wins+lost.draws,retryCountsAsSameSession:true,fullRestart:true,exit:await cleanup(p)};
 });
 const mc=await browser.newContext({viewport:{width:375,height:844},isMobile:true,hasTouch:true,deviceScaleFactor:1}),m=await mc.newPage();monitor(m);m.setDefaultTimeout(15000);const cdp=await mc.newCDPSession(m);
 await check('Phone touch runner clears seven hazards with JUMP and held DUCK',async()=>{
  await start(m,'dino-dash',true);const evidence=await runDino(m,true,cdp);const widths=await m.evaluate(()=>({viewport:innerWidth,scroll:document.documentElement.scrollWidth}));assert(widths.scroll<=widths.viewport);assert.equal(await m.locator('[data-input="left"]').isVisible(),false);return {...evidence,widths,exit:await cleanup(m)};
 });
 assert.deepEqual(report.errors,[]);assert.deepEqual(report.failedRequests,[]);report.passed=true;
 }catch(e){report.passed=false;report.failure=e.stack;throw e;}finally{fs.writeFileSync(path.join(OUT,'report.json'),JSON.stringify(report,null,2));await browser.close();console.log(JSON.stringify(report,null,2));}})().catch(e=>{console.error(e);process.exitCode=1;});
