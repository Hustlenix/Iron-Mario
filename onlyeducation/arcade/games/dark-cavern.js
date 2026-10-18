// Original graph expedition. No copied room graph, maps, art, or historical code.
export const CAVERN_GRAPH = Array.from({length:12},(_,i)=>[(i+11)%12,(i+1)%12,(i+6)%12]);
export function cavernReachable(start,blocked=[]) {
  const forbidden=new Set(blocked),seen=new Set([start]),queue=[start];
  for(let i=0;i<queue.length;i++)for(const next of CAVERN_GRAPH[queue[i]])if(!seen.has(next)&&!forbidden.has(next)){seen.add(next);queue.push(next);}
  return queue;
}
export function makeCavern(rng) {
  const candidates=[2,3,4,5,7,8,9,10];
  for(let attempt=0;attempt<40;attempt++) {
    const shuffled=candidates.slice();
    for(let i=shuffled.length-1;i>0;i--){const j=Math.floor(rng()*(i+1));[shuffled[i],shuffled[j]]=[shuffled[j],shuffled[i]];}
    const monster=shuffled[0],pits=shuffled.slice(1,3),safe=cavernReachable(0,[monster,...pits]);
    const targets=safe.filter(i=>i!==0&&!CAVERN_GRAPH[0].includes(i));
    if(targets.length<2||!CAVERN_GRAPH[monster].some(i=>safe.includes(i)))continue;
    return {monster,pits,treasures:targets.slice(-2)};
  }
  return {monster:8,pits:[3,10],treasures:[4,7]};
}
export function cavernWarnings(state,room=state.room) {
  const nearby=CAVERN_GRAPH[room],warnings=[];
  if(!state.monsterDefeated&&nearby.includes(state.monster))warnings.push('SCRAPING: creature nearby');
  if(nearby.some(i=>state.pits.includes(i)))warnings.push('COLD AIR: a pit nearby');
  if(nearby.some(i=>state.treasures.includes(i)))warnings.push('GLIMMER: cache nearby');
  return warnings.length?warnings:['Quiet tunnels. Take notes.'];
}
const C={ink:'#152536',paper:'#fff0cf',teal:'#61d5c8',gold:'#ffc56a',coral:'#fa8068',dim:'#9bb4bb'};
const point=i=>({x:146+Math.round(Math.sin(i*Math.PI/6)*103),y:147-Math.round(Math.cos(i*Math.PI/6)*88)});
export function createGame(api) {
  const layout=makeCavern(api.rng),state={status:'playing',score:0,message:'Entrance is safe. Listen before moving.',level:1,room:0,selected:0,mode:'move',ammo:3,monsterDefeated:false,caches:0,moves:0,visited:[0],notes:{},lastShot:null,flash:0,...layout};
  const sound=name=>api.sound?.(name);
  const note=()=>{state.notes[state.room]=cavernWarnings(state);};note();
  function toggle(){if(state.monsterDefeated){state.message='Creature cleared. Recover caches and return.';return;}state.mode=state.mode==='move'?'shoot':'move';state.message=state.mode==='shoot'?'Aim at a tunnel. Action fires one bolt.':'Choose a tunnel. Action enters.';sound('move');}
  function use() {
    const target=CAVERN_GRAPH[state.room][state.selected];
    if(state.mode==='shoot') {
      if(state.ammo<=0)return;
      state.ammo--;state.lastShot=target;state.flash=.35;
      if(target===state.monster){state.monsterDefeated=true;state.score+=250;state.mode='move';state.message='Creature dispersed! Find both caches.';sound('score');note();}
      else {state.message='Empty tunnel. Your bolt is gone.';sound('hit');if(state.ammo===0){state.status='lost';state.message='No bolts remain. The creature blocks escape.';sound('lose');}}
      return;
    }
    state.room=target;state.moves++;state.selected=0;
    if(!state.visited.includes(target)){state.visited.push(target);state.score+=10;}
    if(state.pits.includes(target)){state.status='lost';state.message='A hidden pit! Cold air was the warning.';sound('lose');return;}
    if(target===state.monster&&!state.monsterDefeated){state.status='lost';state.message='The creature found you. Listen, then aim.';sound('lose');return;}
    if(state.treasures.includes(target)){state.treasures=state.treasures.filter(i=>i!==target);state.caches++;state.level=1+state.caches;state.score+=150;state.message='Crystal cache secured. '+state.caches+' / 2.';sound('score');}
    else {state.message=target===0?'Entrance: clear creature + collect 2 caches.':'Room '+String(target+1).padStart(2,'0')+'. Listen to the tunnels.';sound('move');}
    note();
    if(target===0&&state.caches===2&&state.monsterDefeated){state.status='won';state.score+=Math.max(100,400-state.moves*5);state.message='Expedition complete. Both caches brought home!';sound('win');}
  }
  function update(dt,input) {
    if(state.status!=='playing')return;state.flash=Math.max(0,state.flash-dt);
    const p=input.pointer;
    if(input.pressed('secondary')){toggle();return;}
    if(p?.active&&p.pressed) {
      if(p.x>=288&&p.x<456&&p.y>=168&&p.y<198){toggle();return;}
      if(p.y>=262&&p.y<302){const index=Math.floor((p.x-20)/152);if(index>=0&&index<3&&p.x<20+index*152+136){state.selected=index;use();return;}}
    }
    if(input.pressed('left')||input.pressed('up'))state.selected=(state.selected+2)%3;
    if(input.pressed('right')||input.pressed('down'))state.selected=(state.selected+1)%3;
    if(input.pressed('action'))use();
  }
  function draw(ctx) {
    ctx.fillStyle=C.ink;ctx.fillRect(0,0,480,320);ctx.textAlign='left';ctx.font='bold 16px monospace';ctx.fillStyle=C.paper;ctx.fillText('DARK CAVERN',20,25);
    ctx.font='11px monospace';ctx.fillStyle=C.gold;ctx.fillText('CACHE '+state.caches+'/2   BOLTS '+state.ammo,267,24);
    ctx.strokeStyle='#2f4854';ctx.lineWidth=2;
    CAVERN_GRAPH.forEach((neighbors,i)=>neighbors.forEach(j=>{if(j<i)return;const a=point(i),b=point(j);ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();}));
    const near=CAVERN_GRAPH[state.room];
    for(let i=0;i<12;i++) {
      const p=point(i),seen=state.visited.includes(i),active=i===state.room;
      ctx.fillStyle=active?C.teal:seen?'#4f6d75':'#213c4b';ctx.fillRect(p.x-15,p.y-12,30,24);
      ctx.strokeStyle=near[state.selected]===i?C.gold:'#45616f';ctx.lineWidth=near[state.selected]===i?3:1;ctx.strokeRect(p.x-15,p.y-12,30,24);
      ctx.font='bold 11px monospace';ctx.textAlign='center';ctx.fillStyle=active?C.ink:C.paper;ctx.fillText(String(i+1).padStart(2,'0'),p.x,p.y+4);
      if(i===0){ctx.fillStyle=C.gold;ctx.fillRect(p.x-7,p.y-18,14,3);}
    }
    if(state.flash&&state.lastShot!==null){const a=point(state.room),b=point(state.lastShot);ctx.strokeStyle=C.gold;ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(b.x,b.y);ctx.stroke();}
    ctx.textAlign='left';ctx.fillStyle=C.gold;ctx.font='bold 13px monospace';ctx.fillText('ROOM '+String(state.room+1).padStart(2,'0'),288,58);
    ctx.font='10px monospace';ctx.fillStyle=C.paper;cavernWarnings(state).forEach((line,i)=>ctx.fillText(line,282,81+i*16));
    ctx.fillStyle=C.dim;ctx.fillText(state.monsterDefeated?'CREATURE: CLEARED':'CREATURE: LURKING',288,135);ctx.fillText('SCORE '+state.score,288,151);
    ctx.fillStyle=state.mode==='shoot'?C.coral:C.teal;ctx.fillRect(288,168,168,30);ctx.fillStyle=C.ink;ctx.font='bold 11px monospace';ctx.fillText(state.mode==='shoot'?'AIM MODE [Z]':'WALK MODE [Z]',300,188);
    ctx.font='10px monospace';ctx.fillStyle=C.dim;ctx.fillText('Arrows: choose tunnel',288,216);ctx.fillStyle=state.mode==='shoot'?C.coral:C.teal;ctx.fillText(state.mode==='shoot'?'ACTION: FIRE 1 BOLT':'ACTION: ENTER TUNNEL',282,232);
    ctx.fillStyle=C.paper;ctx.font='10px monospace';ctx.fillText(state.message,20,251);
    near.forEach((room,i)=>{const x=20+i*152;ctx.fillStyle=i===state.selected?C.gold:'#304b59';ctx.fillRect(x,262,136,40);ctx.fillStyle=i===state.selected?C.ink:C.paper;ctx.font='bold 12px monospace';ctx.fillText((state.mode==='shoot'?'FIRE > ':'TUNNEL ')+String(room+1).padStart(2,'0'),x+13,286);});
    ctx.font='9px monospace';ctx.fillStyle=C.dim;ctx.fillText('LISTEN > DEDUCE > HUNT > RECOVER > RETURN TO ROOM 01',20,315);
  }
  return {state,update,draw};
}
