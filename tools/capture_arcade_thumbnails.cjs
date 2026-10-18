const {chromium}=require('./arcade_playwright.cjs');
const fs=require('node:fs'),path=require('node:path');
const BASE='http://127.0.0.1:8785/arcade/?qa=1';
const OUT=path.resolve('onlyeducation/arcade/art/previews');
const IDS=["dino-dash","grid-x","sidecourt","orbit-duel","paddle-panic","dark-cavern","armored-arena","brick-burst","byte-munch","invader-patrol","rock-drift","soft-landing","flag-run","dot-gobbler","sky-shield","bug-blaster","hopway","color-steps","crate-shift","stackfall"];
(async()=>{const browser=await chromium.launch({headless:true});try{const page=await browser.newPage({viewport:{width:1440,height:1000}});const errors=[];page.on('pageerror',e=>errors.push(e.message));fs.mkdirSync(OUT,{recursive:true});
 for(const id of IDS.filter(id=>!process.env.ARCADE_CAPTURE_IDS||process.env.ARCADE_CAPTURE_IDS.split(',').includes(id))){await page.goto(BASE+'#game/'+id);await page.waitForFunction(id=>window.__arcade?.snapshot()?.mode==='ready'&&document.querySelector('#game-title').textContent.toLowerCase()===id.replaceAll('-',' '),id);await page.locator('#start').click();await page.waitForFunction(()=>window.__arcade.snapshot().ticks>1);
  if(id==='grid-x'){const b=await page.locator('#game-canvas').boundingBox();await page.mouse.click(b.x+70/480*b.width,b.y+86/320*b.height);await page.waitForTimeout(600);}
  else if(id==='brick-burst'){await page.keyboard.press('Space');await page.waitForTimeout(400);}
  else if(id==='dino-dash'){await page.waitForTimeout(2800);await page.keyboard.press('Space');await page.waitForTimeout(180);}
  else if(id==='sidecourt'){await page.keyboard.down('Space');await page.waitForTimeout(650);await page.keyboard.up('Space');}
  else if(id==='rock-drift'){await page.keyboard.down('ArrowUp');await page.keyboard.down('Space');await page.waitForTimeout(500);await page.keyboard.up('ArrowUp');await page.keyboard.up('Space');}
  else if(id==='color-steps'||id==='hopway'){await page.keyboard.press(id==='color-steps'?'ArrowLeft':'ArrowUp');await page.waitForTimeout(160);}
  else if(id==='crate-shift'){await page.keyboard.press('ArrowRight');await page.waitForTimeout(30);}
  else if(id==='stackfall'){await page.keyboard.press('ArrowLeft');await page.keyboard.press('ArrowUp');await page.keyboard.press('Space');await page.waitForTimeout(50);}
  else if(id==='flag-run'){await page.keyboard.down('ArrowRight');await page.waitForTimeout(300);await page.keyboard.up('ArrowRight');}
  else if(['orbit-duel','armored-arena','invader-patrol','bug-blaster'].includes(id)){await page.keyboard.down('Space');await page.waitForTimeout(700);await page.keyboard.up('Space');}
  else if(id==='soft-landing'){await page.waitForTimeout(1400);await page.keyboard.down('Space');await page.waitForTimeout(650);await page.keyboard.up('Space');}
  else if(id==='dot-gobbler'){await page.keyboard.down('ArrowRight');await page.waitForTimeout(500);await page.keyboard.up('ArrowRight');}
  else if(id==='sky-shield'){await page.keyboard.press('Space');await page.waitForTimeout(450);}
  else await page.waitForTimeout(250);
  const png=await page.locator('#game-canvas').evaluate(c=>c.toDataURL('image/png').split(',')[1]);fs.writeFileSync(path.join(OUT,id+'.png'),Buffer.from(png,'base64'));console.log('CAPTURE '+id);
 }
 if(errors.length)throw Error(errors.join('; '));
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
