const {chromium}=require('playwright');
(async()=>{
  const browser=await chromium.launch({headless:true});
  for(const viewport of [{width:960,height:700},{width:390,height:844}]){
    const page=await browser.newPage({viewport});
    const failed=[];
    page.on('response',r=>{if(r.status()>=400) failed.push(`${r.status()} ${r.url()}`)});
    await page.goto('http://127.0.0.1:8771/build/shared-foundation/index.html',{waitUntil:'networkidle'});
    const images=await page.locator('img').count();
    const broken=await page.locator('img').evaluateAll(nodes=>nodes.filter(n=>!n.complete||n.naturalWidth===0).map(n=>n.alt));
    const bodyWidth=await page.locator('body').evaluate(n=>n.scrollWidth);
    if(images<15||broken.length||bodyWidth>viewport.width+2) throw new Error(JSON.stringify({viewport,images,broken,bodyWidth}));
    await page.screenshot({path:`build/shared-foundation/gallery-${viewport.width}x${viewport.height}.png`,fullPage:false});
    await page.close();
  }
  await browser.close(); console.log('SHARED_ASSET_GALLERY_SMOKE=2 viewports, images loaded, no horizontal overflow');
})().catch(e=>{console.error(e);process.exit(1)});
