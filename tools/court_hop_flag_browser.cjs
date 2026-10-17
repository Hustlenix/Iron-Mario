const {chromium}=require('./arcade_playwright.cjs');
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const ROOT='http://127.0.0.1:8785/arcade/?qa=1';
const OUT=path.resolve('build/arcade/wave-b/court-hop-flag');
fs.mkdirSync(OUT,{recursive:true});
const results=[],errors=[],failed=[];
let browser;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function snapshot(p){return p.evaluate(()=>window.__arcade.snapshot());}
async function phase(p,mode){await p.waitForFunction(m=>window.__arcade?.snapshot()?.mode===m,mode,{timeout:8000});}
async function cabinet(p,id){
 await p.goto(ROOT+'#game/'+id,{waitUntil:'networkidle'});await phase(p,'ready');await p.locator('#start').click();await phase(p,'playing');
}
async function key(p,k,duration){await p.keyboard.down(k);await p.waitForTimeout(duration);await p.keyboard.up(k);}
async function common(p,id){
 await p.locator('#pause').click();await phase(p,'paused');
 const before=await snapshot(p);await p.waitForTimeout(120);assert.deepEqual((await snapshot(p)).state,before.state);
 assert.equal(await p.evaluate(()=>window.__arcade.resources().raf),0);
 await p.locator('#restart').click();await phase(p,'ready');assert.equal((await snapshot(p)).state.score,0);
 await p.locator('.back-link').click();await p.locator('#home-view').waitFor({state:'visible'});
 assert.deepEqual(await p.evaluate(()=>window.__arcade.resources()),{active:0,inputListeners:0,raf:0,hudTimer:0,voices:0});
}
async function check(name,fn){try{const detail=await fn();results.push({name,pass:true,detail});console.log('PASS '+name);}catch(e){results.push({name,pass:false,error:e.stack});console.error('FAIL '+name+' '+e.message);}}
(async()=>{
 browser=await chromium.launch({headless:true});
 const context=await browser.newContext({viewport:{width:1440,height:1050}});
 const p=await context.newPage();p.setDefaultTimeout(8000);
 p.on('pageerror',e=>errors.push(e.message));p.on('response',r=>{if(r.status()>=400)failed.push(r.status()+' '+r.url());});
 await check('Sidecourt real keyboard movement, aim, swing and scored return',async()=>{
  await cabinet(p,'sidecourt');
  const initial=(await snapshot(p)).state.playerX;
  await key(p,'ArrowRight',160);assert((await snapshot(p)).state.playerX>initial);
  await key(p,'ArrowDown',30);assert.equal((await snapshot(p)).state.aim,'drive');
  await key(p,'ArrowUp',30);assert.equal((await snapshot(p)).state.aim,'lob');
  // Follow the incoming ball using actual held keyboard input. QA hooks only read.
  await p.keyboard.down('Space');let held=null,seenReturn=false;
  for(let n=0;n<180;n++){
   const s=(await snapshot(p)).state;
   if(s.score>0){seenReturn=true;break;}
   if(s.status!=='playing')break;
   const target=s.lastHit==='cpu'?Math.max(40,Math.min(205,s.ball.x+s.ball.vx*.15)):115;
   const next=s.playerX<target-10?'ArrowRight':s.playerX>target+10?'ArrowLeft':null;
   if(next!==held){if(held)await p.keyboard.up(held);if(next)await p.keyboard.down(next);held=next;}
   await p.waitForTimeout(60);
  }
  if(held)await p.keyboard.up(held);await p.keyboard.up('Space');
  const s=(await snapshot(p)).state;assert(seenReturn,'No score from an actual serve/return sequence');
  assert(s.hits>0);await p.screenshot({path:path.join(OUT,'sidecourt-desktop.png')});
  await common(p,'sidecourt');return{score:s.score,hits:s.hits,playerPoints:s.playerPoints,cpuPoints:s.cpuPoints};
 });
 await check('Hopway real forward hops score, traffic causes a life loss',async()=>{
  await cabinet(p,'hopway');const start=(await snapshot(p)).state;
  await p.keyboard.down('ArrowUp');
  await p.waitForFunction(()=>window.__arcade.snapshot().state.lives<4,null,{timeout:7000});
  await p.keyboard.up('ArrowUp');const s=(await snapshot(p)).state;
  assert(s.score>start.score);assert(s.lives<4);assert(s.delivered<12);assert.equal(s.status,'playing');
  await p.screenshot({path:path.join(OUT,'hopway-desktop.png')});
  await common(p,'hopway');return{score:s.score,lives:s.lives,reason:s.message};
 });
 await check('Flag Run actual movement collects a flag, fuel and deploys smoke',async()=>{
  await cabinet(p,'flag-run');
  await p.keyboard.down('ArrowUp');
  await p.waitForFunction(()=>window.__arcade.snapshot().state.collected>=1,null,{timeout:5000});
  await p.keyboard.up('ArrowUp');const picked=(await snapshot(p)).state;
  assert(picked.score>=125);assert.equal(picked.car.y,1);assert(picked.fuelCans.some(c=>c.taken));
  await p.keyboard.press('Space');await p.waitForTimeout(50);const smoke=(await snapshot(p)).state;
  assert(smoke.smoke.length>0);assert(smoke.fuel<picked.fuel-10);
  await p.screenshot({path:path.join(OUT,'flag-run-desktop.png')});
  await common(p,'flag-run');return{score:smoke.score,flags:smoke.collected,fuel:smoke.fuel};
 });
 await check('No normal-play page errors or HTTP failures',async()=>{assert.deepEqual(errors,[]);assert.deepEqual(failed,[]);});
 await context.close();
 const mobile=await browser.newContext({viewport:{width:375,height:900},isMobile:true,hasTouch:true});
 const q=await mobile.newPage();q.setDefaultTimeout(8000);
 q.on('pageerror',e=>errors.push(e.message));
 async function holdTouch(action,duration){
  const b=q.locator('[data-input="'+action+'"]'),box=await b.boundingBox();
  const session=await q.context().newCDPSession(q);
  await session.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:box.x+box.width/2,y:box.y+box.height/2}]});
  await q.waitForTimeout(duration);await session.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await session.detach();
 }
 for(const id of ['sidecourt','hopway','flag-run'])await check(id+' mobile touch, pause, restart and cleanup',async()=>{
  await cabinet(q,id);const s=(await snapshot(q)).state;
  assert.equal(await q.evaluate(()=>document.documentElement.scrollWidth),375);
  await q.locator('#touch-controls').scrollIntoViewIfNeeded();
  if(id==='sidecourt'){
   await holdTouch('right',140);assert((await snapshot(q)).state.playerX>s.playerX);
   await q.waitForTimeout(750);await holdTouch('action',180);assert((await snapshot(q)).state.hits>0);
  }else if(id==='hopway'){
   await holdTouch('up',80);assert((await snapshot(q)).state.score>s.score);
  }else{
   await holdTouch('up',180);assert((await snapshot(q)).state.car.y<s.car.y);
   await holdTouch('action',80);assert((await snapshot(q)).state.smoke.length>0);
  }
  await q.screenshot({path:path.join(OUT,id+'-mobile.png'),fullPage:true});
  await common(q,id);
  return{width:375};
 });
 await mobile.close();
})().catch(e=>{results.push({name:'harness',pass:false,error:e.stack});console.error(e);}).finally(async()=>{
 await browser?.close();
 const report={checks:results.length,passed:results.filter(r=>r.pass).length,failed:results.filter(r=>!r.pass).length,errors,failedRequests:failed,results};
 fs.writeFileSync(path.join(OUT,'report.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
 process.exitCode=report.failed?1:0;
});
