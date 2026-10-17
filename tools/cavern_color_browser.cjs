// Wave B UI proof: observed snapshots guide real keyboard/pointer/touch input only.
const {chromium}=require('./arcade_playwright.cjs');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const URL=process.env.ARCADE_URL||'http://127.0.0.1:8785/arcade/?qa=1';
const OUT=path.resolve('build/arcade/browser');fs.mkdirSync(OUT,{recursive:true});
const report={stateInjection:false,url:URL,desktop:{},mobile:{},errors:[],failedRequests:[]};
const snap=p=>p.evaluate(()=>window.__arcade.snapshot());
const press=async(p,key)=>{await p.keyboard.press(key,{delay:25});await p.waitForTimeout(30);};
async function tapCanvas(p,x,y){const b=await p.locator('#game-canvas').boundingBox();await p.mouse.click(b.x+x*b.width/480,b.y+y*b.height/320,{delay:30});await p.waitForTimeout(30);}
async function launch(p,id,touch=false){if(await p.locator('#game-view').isVisible())await p.locator('.back-link').click();const card=p.locator(`[data-game="${id}"]`);if(touch)await card.tap();else await card.click();await p.waitForFunction(()=>window.__arcade.snapshot()?.mode==='ready');assert.equal((await snap(p)).ticks,0);if(touch)await p.locator('#start').tap();else await p.locator('#start').click();await p.waitForFunction(()=>window.__arcade.snapshot()?.ticks>1);}
async function restart(p){await p.locator('#restart').click();const s=await snap(p);assert.equal(s.mode,'ready');assert.equal(s.ticks,0);assert.equal(s.state.score,0);await p.waitForTimeout(100);assert.equal((await snap(p)).ticks,0);await p.locator('#start').click();await p.waitForFunction(()=>window.__arcade.snapshot().ticks>1);}
async function lifecycle(p){await p.locator('#pause').click();const s=await snap(p);assert.equal(s.mode,'paused');await p.waitForTimeout(180);const after=await snap(p);assert.equal(after.ticks,s.ticks);assert.deepEqual(after.state,s.state);await p.locator('#pause').click();await p.waitForFunction(t=>window.__arcade.snapshot().ticks>t,s.ticks);await restart(p);return{pauseFreezes:true,resume:true,restartReadyTicksZero:true};}
async function exit(p){await p.locator('.back-link').click();await p.waitForFunction(()=>window.__arcade.snapshot()===null);await p.waitForTimeout(90);const r=await p.evaluate(()=>window.__arcade.resources());assert.deepEqual(r,{active:0,inputListeners:0,raf:0,hudTimer:0,voices:0});return r;}
function monitor(p){p.on('pageerror',e=>report.errors.push(e.message));p.on('response',r=>{if(r.status()>=400)report.failedRequests.push(r.status()+' '+r.url());});}
const neighbors=i=>[(i+11)%12,(i+1)%12,(i+6)%12];
function route(from,to,blocked){const q=[[from]],seen=new Set([from]);for(let i=0;i<q.length;i++){const r=q[i],at=r.at(-1);if(at===to)return r;for(const n of neighbors(at))if(!seen.has(n)&&!blocked.includes(n)){seen.add(n);q.push([...r,n]);}}return null;}
async function selectCave(p,target){const s=(await snap(p)).state,index=neighbors(s.room).indexOf(target);assert(index>=0);for(let n=0;n<(index-s.selected+3)%3;n++)await press(p,'ArrowRight');}
async function walkCave(p,steps){for(const target of steps.slice(1)){await selectCave(p,target);await press(p,'Space');assert.equal((await snap(p)).state.room,target);}}
async function cave(p){
 await press(p,'KeyZ');for(let i=0;i<3;i++)await press(p,'Space');assert.equal((await snap(p)).state.status,'lost');await p.screenshot({path:path.join(OUT,'dark-cavern-loss.png')});await restart(p);
 await tapCanvas(p,220,280);assert.equal((await snap(p)).state.room,1);await selectCave(p,0);await press(p,'Space');
 let s=(await snap(p)).state;const approach=neighbors(s.monster).map(i=>route(s.room,i,[s.monster,...s.pits])).filter(Boolean).sort((a,b)=>a.length-b.length)[0];await walkCave(p,approach);await selectCave(p,s.monster);await press(p,'KeyZ');await press(p,'Space');assert.equal((await snap(p)).state.monsterDefeated,true);
 for(const cache of s.treasures.slice()){s=(await snap(p)).state;await walkCave(p,route(s.room,cache,s.pits));}
 s=(await snap(p)).state;await walkCave(p,route(s.room,0,s.pits));const end=await snap(p);assert.equal(end.state.status,'won');assert.equal(end.mode,'ended');assert.equal(end.state.caches,2);
 return{win:true,loss:true,score:end.state.score,moves:end.state.moves,shotsUsed:3-end.state.ammo,keyboard:true,pointerDoor:true,solverGuidance:'Read-only seeded hazard layout; all moves and shots through UI'};
}
const HOPS={left:[1,0],down:[1,1],up:[-1,-1],right:[-1,0]},KEYS={left:'ArrowLeft',right:'ArrowRight',up:'ArrowUp',down:'ArrowDown'};
const index=p=>p.row*(p.row+1)/2+p.col;
const adjacent=(p,rows)=>Object.entries(HOPS).map(([action,[r,c]])=>({action,row:p.row+r,col:p.col+c})).filter(p=>p.row>=0&&p.row<rows&&p.col>=0&&p.col<=p.row);
function distance(a,b,rows){if(!a||!b)return 99;const q=[{...a,d:0}],seen=new Set([index(a)]);for(let i=0;i<q.length;i++){const p=q[i];if(index(p)===index(b))return p.d;for(const n of adjacent(p,rows))if(!seen.has(index(n))){seen.add(index(n));q.push({...n,d:p.d+1});}}return99;}
function paintRoute(s,target){const q=[{...s.player,path:[]}],seen=new Set([index(s.player)]);for(let i=0;i<q.length;i++){const p=q[i];if(index(p)===index(target)&&p.path.length)return p.path;for(const n of adjacent(p,s.rows)){if(s.enemy&&index(n)===index(s.enemy))continue;if(seen.has(index(n))&&index(n)!==index(target))continue;seen.add(index(n));q.push({...n,path:[...p.path,n.action]});}}return null;}
function paintChoice(s){const paths=[];for(let r=0;r<s.rows;r++)for(let c=0;c<=r;c++)if(s.tiles[index({row:r,col:c})]<s.coats){const route=paintRoute(s,{row:r,col:c});if(route?.length)paths.push(route);}paths.sort((a,b)=>a.length-b.length);if(paths.length)return paths[0][0];return adjacent(s.player,s.rows).filter(p=>!s.enemy||index(p)!==index(s.enemy)).sort((a,b)=>distance(b,s.enemy,s.rows)-distance(a,s.enemy,s.rows))[0]?.action;}
async function color(p){
 for(let i=0;i<3;i++){await press(p,'ArrowUp');if(i<2)await p.waitForTimeout(1200);}assert.equal((await snap(p)).state.status,'lost');await p.screenshot({path:path.join(OUT,'color-steps-loss.png')});await restart(p);
 let moves=0,enemySeen=false,recalls=0;const levels=[];
 for(let n=0;n<250;n++) {
  await p.waitForFunction(()=>{const s=window.__arcade.snapshot().state;return s.cooldown<=0||s.status!=='playing';});const s=(await snap(p)).state;if(s.status!=='playing')break;
  if(s.levelComplete){levels.push({level:s.level,score:s.score,lives:s.lives});await press(p,'Space');continue;}
  if(s.enemy)enemySeen=true;
  if(s.recalls>0&&s.enemy&&distance(s.enemy,s.player,s.rows)<=1&&s.enemyClock<.3){await press(p,'Space');recalls++;continue;}
  const move=paintChoice(s);assert(move,'paintable route or escape hop exists');await p.keyboard.press(KEYS[move],{delay:20});moves++;await p.waitForTimeout(25);
 }
 const end=await snap(p);assert.equal(end.state.status,'won',JSON.stringify({mode:end.mode,state:end.state,moves,recalls}));assert.equal(end.mode,'ended');assert.equal(end.state.completed,3);assert(enemySeen);levels.push({level:3,score:end.state.score,lives:end.state.lives});
 return{win:true,edgeLoss:true,score:end.state.score,hops:end.state.hops,keyboardMoves:moves,recalls,enemySeen,levels};
}
async function touch(p,cdp,action){const b=p.locator(`[data-input="${action}"]`);await b.scrollIntoViewIfNeeded();const r=await b.boundingBox();await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:r.x+r.width/2,y:r.y+r.height/2}]});await p.waitForTimeout(75);await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await p.waitForTimeout(45);}
(async()=>{const browser=await chromium.launch({headless:true});try{
 const ctx=await browser.newContext({viewport:{width:1440,height:1000}}),page=await ctx.newPage();monitor(page);page.setDefaultTimeout(15000);await page.goto(URL,{waitUntil:'networkidle'});
 for(const[id,play]of[['dark-cavern',cave],['color-steps',color]]){console.log('Desktop '+id);await launch(page,id);const life=await lifecycle(page);await page.locator('#game-canvas').screenshot({path:path.join(OUT,id+'-playing.png')});const result=await play(page);await page.screenshot({path:path.join(OUT,id+'-result.png')});report.desktop[id]={...life,...result,resources:await exit(page)};fs.writeFileSync(path.join(OUT,'cavern-color-report.json'),JSON.stringify(report,null,2));}
 const mobileCtx=await browser.newContext({viewport:{width:375,height:844},isMobile:true,hasTouch:true,deviceScaleFactor:1}),mobile=await mobileCtx.newPage();monitor(mobile);mobile.setDefaultTimeout(15000);const cdp=await mobileCtx.newCDPSession(mobile);await mobile.goto(URL,{waitUntil:'networkidle'});
 for(const id of ['dark-cavern','color-steps']){console.log('Mobile '+id);await launch(mobile,id,true);await touch(mobile,cdp,'left');
  if(id==='dark-cavern'){assert.equal((await snap(mobile)).state.selected,2);await touch(mobile,cdp,'action');assert.equal((await snap(mobile)).state.room,6);await touch(mobile,cdp,'secondary');assert.equal((await snap(mobile)).state.mode,'shoot');}
  else {assert((await snap(mobile)).state.score>0);assert.deepEqual((await snap(mobile)).state.player,{row:1,col:0});await touch(mobile,cdp,'action');assert.equal((await snap(mobile)).state.recalls,0);assert.deepEqual((await snap(mobile)).state.player,{row:0,col:0});}
  const width=await mobile.evaluate(()=>({viewport:innerWidth,scroll:document.documentElement.scrollWidth}));assert(width.scroll<=width.viewport+1);await mobile.locator('#game-shell').scrollIntoViewIfNeeded();await mobile.screenshot({path:path.join(OUT,'mobile-'+id+'.png')});report.mobile[id]={dpad:true,action:true,score:(await snap(mobile)).state.score,width,resources:await exit(mobile)};
 }
 assert.deepEqual(report.errors,[]);assert.deepEqual(report.failedRequests,[]);report.passed=true;fs.writeFileSync(path.join(OUT,'cavern-color-report.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
 }catch(e){report.passed=false;report.failure=e.stack;fs.writeFileSync(path.join(OUT,'cavern-color-report.json'),JSON.stringify(report,null,2));throw e;}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
