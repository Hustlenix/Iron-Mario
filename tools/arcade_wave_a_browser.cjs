/* Actual browser input QA. The read-only hook observes state; it never changes it. */
const { chromium } = require('./arcade_playwright.cjs');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const BASE = process.env.ARCADE_URL || 'http://127.0.0.1:8785/arcade/?qa=1';
const OUT = path.resolve('build/arcade/browser');
const IDS = ['grid-x','crate-shift','byte-munch','stackfall','brick-burst','paddle-panic'];
const report = { url:BASE, stateInjection:false, desktop:{}, mobile:{}, errors:[], failedRequests:[], externalRequests:[] };
fs.mkdirSync(OUT,{recursive:true});
const snap = page => page.evaluate(()=>window.__arcade.snapshot());
const resources = page => page.evaluate(()=>window.__arcade.resources());
const sleep = (page,ms) => page.waitForTimeout(ms);
async function press(page,key) { await page.keyboard.press(key,{delay:45}); await sleep(page,35); }
async function canvasPoint(page,x,y) { const b=await page.locator('#game-canvas').boundingBox(); return {x:b.x+x/480*b.width,y:b.y+y/320*b.height}; }
async function canvasClick(page,x,y) { const p=await canvasPoint(page,x,y); await page.mouse.click(p.x,p.y,{delay:35}); await sleep(page,40); }
function monitor(page) {
  page.on('pageerror',e=>report.errors.push(e.message));
  page.on('response',r=>{if(r.status()>=400)report.failedRequests.push(`${r.status()} ${r.url()}`);});
  page.on('request',r=>{if(!r.url().startsWith(new URL(BASE).origin))report.externalRequests.push(r.url());});
}
async function home(page) {
  if(await page.locator('#game-view').isVisible()) await page.locator('.back-link').click();
  await page.locator('#home-view').waitFor({state:'visible'});
  const available=await page.evaluate(()=>window.__arcade.catalog().filter(g=>['PLAYABLE','TESTED','RELEASE READY'].includes(g.status)).length);assert.equal(await page.locator('[data-game]').count(),available);
}
async function launch(page,id,touch=false) {
  await home(page);
  const card=page.locator(`[data-game="${id}"]`);
  if(touch)await card.tap();else await card.click();
  await page.waitForFunction(()=>window.__arcade?.snapshot()?.mode==='ready');
  const ready=await snap(page);assert.equal(ready.ticks,0);assert.equal(ready.state.score,0);
  const expected=await page.locator('#game-title').textContent();assert(expected.length>0);
  if(touch)await page.locator('#start').tap();else await page.locator('#start').click();
  await page.waitForFunction(()=>window.__arcade?.snapshot()?.ticks>2);
  return ready;
}
async function lifecycle(page,id) {
  await page.locator('#pause').click();
  await page.waitForFunction(()=>window.__arcade.snapshot().mode==='paused');
  const frozen=await snap(page);await sleep(page,250);const after=await snap(page);
  assert.equal(after.ticks,frozen.ticks,`${id}: pause freezes simulation ticks`);
  assert.deepEqual(after.state,frozen.state,`${id}: pause freezes game state`);
  await page.locator('#pause').click();
  await page.waitForFunction(t=>window.__arcade.snapshot().ticks>t,frozen.ticks);
  await page.locator('#restart').click();
  const reset=await snap(page);assert.equal(reset.mode,'ready');assert.equal(reset.ticks,0);assert.equal(reset.state.score,0);
  await sleep(page,150);assert.equal((await snap(page)).ticks,0,'ready screen must not run the game');
  await page.locator('#start').click();await page.waitForFunction(()=>window.__arcade.snapshot().ticks>1);
  return {pauseFreezes:true,resume:true,restartReady:true,restartTicks:0};
}
async function exit(page,id) {
  await page.locator('.back-link').click();
  await page.waitForFunction(()=>window.__arcade.snapshot()===null);
  await sleep(page,100);
  const r=await resources(page);assert.deepEqual(r,{active:0,inputListeners:0,raf:0,hudTimer:0,voices:0},`${id}: exit releases runtime resources`);
  return r;
}
const lines=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
function result(b){for(const l of lines)if(b[l[0]]&&l.every(i=>b[i]===b[l[0]]))return b[l[0]];return b.every(Boolean)?0:null;}
function value(b,turn){const end=result(b);if(end!==null)return end===1?1:end===2?-1:0;let best=turn===1?-2:2;for(let i=0;i<9;i++)if(!b[i]){b[i]=turn;const score=value(b,3-turn);b[i]=0;best=turn===1?Math.max(best,score):Math.min(best,score);}return best;}
function bestMove(board){let best=-2,choice=-1;for(let i=0;i<9;i++)if(!board[i]){board[i]=1;const score=value(board,2);board[i]=0;if(score>best){best=score;choice=i;}}return choice;}
async function grid(page) {
  await press(page,'ArrowLeft');assert.equal((await snap(page)).state.cursor,3,'Grid keyboard selection '+JSON.stringify(await snap(page)));
  const moves=[];
  for(let n=0;n<40;n++) {
    const s=(await snap(page)).state;if(s.status!=='playing')break;
    if(s.roundComplete){await canvasClick(page,360,240);continue;}
    if(s.turn==='ai'){await page.waitForFunction(()=>{const s=window.__arcade.snapshot().state;return s.turn!=='ai'||s.roundComplete||s.status!=='playing';});continue;}
    const choice=bestMove(s.board.slice());assert(choice>=0);moves.push({round:s.round,square:choice});
    await canvasClick(page,70+choice%3*68,86+Math.floor(choice/3)*68);
  }
  const end=await snap(page);assert.equal(end.state.status,'won');assert.equal(end.mode,'ended');assert.equal(end.state.round,3);
  return {status:end.state.status,score:end.state.score,wins:end.state.wins,draws:end.state.draws,keyboardSelection:true,pointerMoves:moves};
}
const solutions=['RR','LURDRU','LURRDRU','LUUDRRDRULULLULUR','LUUULURRRDRDLLDDLUUUDRRUULL'];
const keys={L:'ArrowLeft',R:'ArrowRight',U:'ArrowUp',D:'ArrowDown'};
async function crate(page) {
  await canvasClick(page,136,122);assert.equal((await snap(page)).state.pushes,1,'adjacent-tile pointer push');
  await press(page,'KeyZ');assert.equal((await snap(page)).state.pushes,0,'keyboard undo');
  const rooms=[];
  for(let room=0;room<5;room++) {
    for(const move of solutions[room])await press(page,keys[move]);
    const s=(await snap(page)).state;assert.equal(s.completed,room+1,`Crate room ${room+1}`);assert.equal(s.levelComplete,true);
    rooms.push({room:room+1,steps:s.steps,pushes:s.pushes,score:s.score});
    if(room<4)await press(page,'Space');
  }
  const end=await snap(page);assert.equal(end.state.status,'won');assert.equal(end.mode,'ended');
  return {status:end.state.status,score:end.state.score,adjacentTap:true,undo:true,rooms};
}
function snakeRoute(s) {
  const h=s.snake[0],goal=s.food,blocked=new Set([...s.snake.slice(0,-1),...s.obstacles].map(p=>p.x+','+p.y));
  const queue=[{x:h.x,y:h.y,path:[],dx:s.direction.x,dy:s.direction.y}],seen=new Set([h.x+','+h.y]);
  for(let i=0;i<queue.length;i++) {
    const p=queue[i];if(p.x===goal.x&&p.y===goal.y)return p.path;
    for(const [key,dx,dy]of[['ArrowUp',0,-1],['ArrowDown',0,1],['ArrowLeft',-1,0],['ArrowRight',1,0]]) {
      if(!p.path.length&&dx===-p.dx&&dy===-p.dy)continue;
      const x=p.x+dx,y=p.y+dy,k=x+','+y;if(x<0||y<0||x>=s.cols||y>=s.rows||blocked.has(k)||seen.has(k))continue;
      seen.add(k);queue.push({x,y,path:[...p.path,key],dx,dy});
    }
  }
  return null;
}
async function snake(page) {
  let keyCount=0;
  for(let n=0;n<80;n++) {
    const s=(await snap(page)).state;if(s.eaten>0||s.status!=='playing')break;
    const route=snakeRoute(s);assert(route?.length,'legal route to first food');
    await page.keyboard.press(route[0],{delay:15});keyCount++;
    await page.waitForFunction(p=>{const s=window.__arcade.snapshot().state;return s.status!=='playing'||s.snake[0].x!==p.x||s.snake[0].y!==p.y;},s.snake[0]);
  }
  const scored=(await snap(page)).state;assert.ok(scored.eaten>0,'Snake eats actual food');assert.ok(scored.score>0);
  // Stop turning. The current direction inevitably reaches an edge in this first circuit.
  await page.waitForFunction(()=>window.__arcade.snapshot().state.status==='lost',null,{timeout:12000});
  const end=await snap(page);assert.equal(end.mode,'ended');
  return {status:end.state.status,score:end.state.score,eaten:end.state.eaten,guidedKeyboardTurns:keyCount,message:end.state.message};
}
async function stack(page) {
  const initial=(await snap(page)).state.active.x;await press(page,'ArrowLeft');assert((await snap(page)).state.active.x<initial,'Stackfall keyboard movement');
  await press(page,'ArrowRight');await press(page,'ArrowUp');
  let drops=0;for(;drops<30;drops++){if((await snap(page)).mode==='ended')break;await press(page,'Space');}
  const end=await snap(page);assert.equal(end.state.status,'lost');assert.ok(end.state.pieces>0);assert.ok(end.state.score>0);
  return {status:end.state.status,score:end.state.score,lockedPieces:end.state.pieces,hardDrops:drops,keyboardMove:true,keyboardRotate:true};
}
async function brick(page) {
  const initial=(await snap(page)).state.paddle.x;await page.keyboard.down('ArrowRight');await sleep(page,140);await page.keyboard.up('ArrowRight');assert((await snap(page)).state.paddle.x>initial);
  await press(page,'Space');assert.equal((await snap(page)).state.ball.docked,false);
  await page.waitForFunction(()=>window.__arcade.snapshot().state.score>0,null,{timeout:8000});
  let snapNow=await snap(page);
  for(let n=0;n<200&&snapNow.state.status==='playing';n++) {
    const s=snapNow.state;
    if(s.ball.docked)await press(page,'Space');
    const target=s.ball.x<240?'ArrowRight':'ArrowLeft';
    await page.keyboard.down(target);await sleep(page,90);await page.keyboard.up(target);snapNow=await snap(page);
  }
  assert.equal(snapNow.state.status,'lost','Brick Burst exhausts real lives after deliberately missing');
  return {status:snapNow.state.status,score:snapNow.state.score,hits:snapNow.state.hits,destroyed:snapNow.state.destroyed,lives:snapNow.state.lives,keyboardLaunch:true,keyboardPaddle:true};
}
async function paddle(page) {
  const initial=(await snap(page)).state.py;await page.keyboard.down('ArrowUp');await sleep(page,120);await page.keyboard.up('ArrowUp');assert((await snap(page)).state.py<initial);
  // Return at least one ball using the visible pointer controller, then miss honestly.
  let now=await snap(page),returns=0;
  for(let n=0;n<240&&now.state.score===0&&now.mode==='playing';n++) {
    const p=await canvasPoint(page,70,Math.max(28,Math.min(292,now.state.ball.y)));
    await page.mouse.move(p.x,p.y);await sleep(page,70);now=await snap(page);returns++;
  }
  assert.ok(now.state.score>0,'Paddle earns actual paddle-return score');
  await page.mouse.move(2,2);
  for(let n=0;n<600&&now.mode==='playing';n++) {
    const key=now.state.ball.y<160?'ArrowDown':'ArrowUp';
    await page.keyboard.down(key);await sleep(page,90);await page.keyboard.up(key);now=await snap(page);
  }
  assert.equal(now.state.status,'lost','Paddle reaches first-to-five opponent match result');
  assert.equal(now.state.cpu,5);
  return {status:now.state.status,score:now.state.score,playerPoints:now.state.player,cpuPoints:now.state.cpu,pointerTrackingSamples:returns,keyboardMove:true};
}
async function touchHold(page,cdp,action,ms=90) {
  const button=page.locator(`[data-input="${action}"]`);await button.scrollIntoViewIfNeeded();const b=await button.boundingBox();
  const point={x:b.x+b.width/2,y:b.y+b.height/2};
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[point]});await sleep(page,ms);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await sleep(page,35);
}
async function mobileCheck(page,cdp,id) {
  await launch(page,id,true);
  const before=await snap(page);
  const direction={ 'grid-x':'left','crate-shift':'right','byte-munch':'up','stackfall':'left','brick-burst':'right','paddle-panic':'down' }[id];
  await touchHold(page,cdp,direction,id==='byte-munch'?210:100);
  const after=await snap(page);
  if(id==='grid-x'){assert.notEqual(after.state.cursor,before.state.cursor);await touchHold(page,cdp,'action');assert.equal((await snap(page)).state.board.filter(x=>x===1).length,1);}
  if(id==='crate-shift'){assert(after.state.steps>before.state.steps);await touchHold(page,cdp,'secondary');assert.equal((await snap(page)).state.steps,0);}
  if(id==='byte-munch')assert.equal(after.state.direction.y,-1);
  if(id==='stackfall'){assert(after.state.active.x<before.state.active.x);await touchHold(page,cdp,'action');assert((await snap(page)).state.pieces>0);}
  if(id==='brick-burst'){assert(after.state.paddle.x>before.state.paddle.x);await touchHold(page,cdp,'action');assert.equal((await snap(page)).state.ball.docked,false);}
  if(id==='paddle-panic')assert(after.state.py>before.state.py);
  const width=await page.evaluate(()=>({viewport:innerWidth,document:document.documentElement.scrollWidth}));assert(width.document<=width.viewport+1,`${id}: no horizontal overflow`);
  await page.locator('#game-shell').scrollIntoViewIfNeeded();await page.screenshot({path:path.join(OUT,`mobile-${id}.png`)});
  const r=await exit(page,id);return {touchDpad:true,touchAction:['grid-x','stackfall','brick-burst'].includes(id),touchUndo:id==='crate-shift',width,exitResources:r};
}

(async()=>{
 const browser=await chromium.launch({headless:true});
 try {
  const context=await browser.newContext({viewport:{width:1440,height:1000}}),page=await context.newPage();monitor(page);page.setDefaultTimeout(15000);
  await page.goto(BASE,{waitUntil:'networkidle'});await page.waitForFunction(()=>window.__arcade);await home(page);await page.screenshot({path:path.join(OUT,'desktop-home.png'),fullPage:true});
  const runners={'grid-x':grid,'crate-shift':crate,'byte-munch':snake,'stackfall':stack,'brick-burst':brick,'paddle-panic':paddle};
  for(const id of IDS){
    console.log('Desktop '+id);await launch(page,id);const life=await lifecycle(page,id);
    await page.locator('#game-canvas').screenshot({path:path.join(OUT,`${id}-playing.png`)});
    const evidence=await runners[id](page);await page.screenshot({path:path.join(OUT,`${id}-result.png`)});
    report.desktop[id]={...life,...evidence,exitResources:await exit(page,id)};fs.writeFileSync(path.join(OUT,'wave-a-report.json'),JSON.stringify(report,null,2));
  }
  const saves=await page.evaluate(()=>window.__arcade.saves());assert.equal(saves.games['grid-x'].wins,1);assert.equal(saves.games['crate-shift'].wins,1);assert(saves.achievements.includes('six-cabinets'));assert(saves.achievements.includes('first-win'));
  await page.reload({waitUntil:'networkidle'});assert.deepEqual(await page.evaluate(()=>window.__arcade.saves()),saves,'scores and earned badges persist on reload');report.persistence={wins:saves.games['grid-x'].wins+saves.games['crate-shift'].wins,achievements:saves.achievements,reload:true};
  const mobileContext=await browser.newContext({viewport:{width:375,height:844},isMobile:true,hasTouch:true,deviceScaleFactor:1});
  const mobile=await mobileContext.newPage();monitor(mobile);mobile.setDefaultTimeout(15000);await mobile.goto(BASE,{waitUntil:'networkidle'});await mobile.waitForFunction(()=>window.__arcade);const cdp=await mobileContext.newCDPSession(mobile);
  for(const id of IDS){console.log('Mobile '+id);report.mobile[id]=await mobileCheck(mobile,cdp,id);fs.writeFileSync(path.join(OUT,'wave-a-report.json'),JSON.stringify(report,null,2));}
  assert.deepEqual(report.errors,[]);assert.deepEqual(report.failedRequests,[]);assert.deepEqual(report.externalRequests,[]);
  report.passed=true;fs.writeFileSync(path.join(OUT,'wave-a-report.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
 }catch(error){report.passed=false;report.failure=error.stack;fs.writeFileSync(path.join(OUT,'wave-a-report.json'),JSON.stringify(report,null,2));throw error;}finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
