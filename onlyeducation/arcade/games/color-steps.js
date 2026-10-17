// Original color workshop: a pixel robot paints a pyramid while a scrap bug pursues.
export const HOPS={left:[1,0],down:[1,1],up:[-1,-1],right:[-1,0]};
export const tileIndex=(row,col)=>row*(row+1)/2+col;
export const insidePyramid=(row,col,rows)=>row>=0&&row<rows&&col>=0&&col<=row;
export const tilePoint=(row,col)=>({x:178+(col-row/2)*58,y:62+row*41});
export function pyramidNeighbors(row,col,rows) {return Object.entries(HOPS).map(([action,[dr,dc]])=>({action,row:row+dr,col:col+dc})).filter(p=>insidePyramid(p.row,p.col,rows));}
export function pyramidDistance(a,b,rows) {
  const queue=[{...a,d:0}],seen=new Set([tileIndex(a.row,a.col)]);
  for(let i=0;i<queue.length;i++){const p=queue[i];if(p.row===b.row&&p.col===b.col)return p.d;for(const next of pyramidNeighbors(p.row,p.col,rows)){const key=tileIndex(next.row,next.col);if(!seen.has(key)){seen.add(key);queue.push({...next,d:p.d+1});}}}
  return Infinity;
}
const C={ink:'#152536',paper:'#fff0cf',teal:'#61d5c8',gold:'#ffc56a',coral:'#fa8068',dim:'#9bb4bb'};
export function createGame(api) {
  const state={status:'playing',score:0,message:'Paint every tile gold. Stay ahead of the scrap bug.',level:1,rows:4,coats:1,tiles:Array(10).fill(0),player:{row:0,col:0},enemy:null,enemyWait:3.2,enemyClock:0,lives:3,hops:0,recalls:1,levelComplete:false,cooldown:0,invulnerable:0,hopTime:0,from:{row:0,col:0},time:0,completed:0};
  state.tiles[0]=1;
  const sound=name=>api.sound?.(name);
  function enemyInterval(){return [1.35,1.08,.86][state.level-1];}
  function hurt(reason) {
    if(state.invulnerable>0)return;
    state.lives--;sound('lose');
    if(state.lives<=0){state.status='lost';state.message=reason+' Workshop closed. Try again!';return;}
    state.player={row:0,col:0};state.from={...state.player};state.hopTime=0;state.cooldown=.28;state.enemy=null;state.enemyWait=2.8;state.enemyClock=0;state.invulnerable=1.1;state.message=reason+' '+state.lives+' lives left. Tiles stay painted.';
  }
  function collision(){if(state.enemy&&state.enemy.row===state.player.row&&state.enemy.col===state.player.col)hurt('Scrap bug caught you!');}
  function checkComplete() {
    if(!state.tiles.every(n=>n>=state.coats))return;
    state.completed=state.level;state.levelComplete=true;state.score+=250*state.level;state.message='Pyramid '+state.level+' complete! Action opens the next.';sound('score');
    if(state.level===3){state.status='won';state.message='COLOR WORKSHOP COMPLETE! Three golden pyramids.';sound('win');}
  }
  function hop(action) {
    if(state.cooldown>0)return;
    const [dr,dc]=HOPS[action],row=state.player.row+dr,col=state.player.col+dc;
    if(!insidePyramid(row,col,state.rows)){hurt('Edge tumble!');return;}
    state.from={...state.player};state.player={row,col};state.hopTime=.18;state.cooldown=.2;state.hops++;sound('move');
    collision();if(state.status!=='playing'||state.invulnerable>1)return;
    const i=tileIndex(row,col);
    if(state.tiles[i]<state.coats){state.tiles[i]++;state.score+=20*state.level;sound('score');}
    checkComplete();
  }
  function nextLevel() {
    state.level++;state.rows=5;state.coats=state.level===3?2:1;state.tiles=Array(15).fill(0);state.tiles[0]=1;state.player={row:0,col:0};state.from={...state.player};state.enemy=null;state.enemyWait=3.2;state.enemyClock=0;state.cooldown=.2;state.hopTime=0;state.recalls=1;state.invulnerable=.6;state.levelComplete=false;state.message=state.coats===2?'Two coats this time. Teal first, then gold.':'A wider pyramid. Keep an escape route.';
  }
  function action() {
    if(state.levelComplete){nextLevel();return;}
    if(state.recalls<=0){state.message='Recall spent. Keep hopping!';return;}
    state.recalls--;state.player={row:0,col:0};state.from={...state.player};state.enemy=null;state.enemyWait=2.6;state.enemyClock=0;state.invulnerable=1;state.hopTime=0;state.cooldown=.2;state.message='Recalled to the peak. One rescue per pyramid.';sound('hit');
  }
  function update(dt,input) {
    if(state.status!=='playing')return;dt=Math.max(0,Math.min(dt,.1));state.time+=dt;state.cooldown=Math.max(0,state.cooldown-dt);state.hopTime=Math.max(0,state.hopTime-dt);state.invulnerable=Math.max(0,state.invulnerable-dt);
    const p=input.pointer;
    if(input.pressed('action')||(p?.active&&p.pressed&&p.x>=338&&p.x<462&&p.y>=189&&p.y<221)){action();return;}
    if(state.levelComplete)return;
    let direction=Object.keys(HOPS).find(key=>input.pressed(key));
    if(!direction&&p?.active&&p.pressed){for(const next of pyramidNeighbors(state.player.row,state.player.col,state.rows)){const target=tilePoint(next.row,next.col);if(Math.abs(p.x-target.x)/28+Math.abs(p.y-target.y)/14<=1){direction=next.action;break;}}}
    if(!direction)direction=Object.keys(HOPS).find(key=>input.down(key));
    if(direction)hop(direction);
    if(state.status!=='playing'||state.levelComplete)return;
    if(!state.enemy){state.enemyWait-=dt;if(state.enemyWait<=0){const col=state.player.col<state.rows/2?state.rows-1:0;state.enemy={row:state.rows-1,col};state.enemyClock=enemyInterval();state.message='Scrap bug awake. Keep moving!';}return;}
    state.enemyClock-=dt;
    if(state.enemyClock<=0){
      const options=pyramidNeighbors(state.enemy.row,state.enemy.col,state.rows);const distances=options.map(p=>pyramidDistance(p,state.player,state.rows));const best=Math.min(...distances);const chosen=options.filter((_,i)=>distances[i]===best);const next=chosen[Math.floor(api.rng()*chosen.length)];state.enemy={row:next.row,col:next.col};state.enemyClock+=enemyInterval();collision();
    }
  }
  function polygon(ctx,points,color){ctx.fillStyle=color;ctx.beginPath();points.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));ctx.closePath();ctx.fill();}
  function draw(ctx) {
    ctx.fillStyle=C.ink;ctx.fillRect(0,0,480,320);ctx.textAlign='left';ctx.font='bold 16px monospace';ctx.fillStyle=C.paper;ctx.fillText('COLOR STEPS',20,25);ctx.font='11px monospace';ctx.fillStyle=C.gold;ctx.fillText('SCORE '+state.score,325,24);
    for(let row=0;row<state.rows;row++)for(let col=0;col<=row;col++){
      const {x,y}=tilePoint(row,col),coat=state.tiles[tileIndex(row,col)],color=coat>=state.coats?C.gold:coat?C.teal:'#536a82';
      polygon(ctx,[[x-27,y],[x,y+14],[x,y+29],[x-27,y+15]],'#283f52');polygon(ctx,[[x,y+14],[x+27,y],[x+27,y+15],[x,y+29]],'#385666');polygon(ctx,[[x,y-14],[x+27,y],[x,y+14],[x-27,y]],color);
      ctx.fillStyle=coat>=state.coats?'#fff0cf':'#93acc0';ctx.fillRect(Math.round(x)-3,Math.round(y)-2,6,3);
    }
    function character(position,id,color,offset=0){const p=tilePoint(position.row,position.col);ctx.fillStyle='#0d1c28';ctx.fillRect(Math.round(p.x)-10,p.y+2,20,4);ctx.fillStyle=color;ctx.fillRect(Math.round(p.x)-7,p.y-18-offset,14,18);api.sprite?.(ctx,id,Math.round(p.x)-16,p.y-28-offset,{scale:1});}
    if(state.enemy)character(state.enemy,'pieces_bug',C.coral);
    const t=state.hopTime/.18;const p=tilePoint(state.player.row,state.player.col),a=tilePoint(state.from.row,state.from.col),x=Math.round(p.x+(a.x-p.x)*t),y=Math.round(p.y+(a.y-p.y)*t-Math.sin(t*Math.PI)*12);
    if(state.invulnerable<=0||Math.floor(state.time*12)%2){ctx.fillStyle=C.teal;ctx.fillRect(x-7,y-19,14,19);api.sprite?.(ctx,'pieces_robot',x-16,y-29,{scale:1});}
    ctx.fillStyle=C.gold;ctx.font='bold 13px monospace';ctx.fillText('PYRAMID '+state.level+'/3',338,58);ctx.fillStyle=C.paper;ctx.font='12px monospace';ctx.fillText('LIVES '+state.lives,338,82);
    const painted=state.tiles.filter(n=>n>=state.coats).length;ctx.fillText('GOLD '+painted+'/'+state.tiles.length,338,103);ctx.fillStyle=C.dim;ctx.font='10px monospace';ctx.fillText(state.coats===2?'2 COATS PER TILE':'1 COAT PER TILE',338,122);
    ctx.fillStyle=state.enemy?C.coral:C.dim;ctx.fillText(state.enemy?'BUG IS HUNTING':'BUG IN '+Math.max(0,Math.ceil(state.enemyWait))+'s',338,148);ctx.fillStyle=C.dim;ctx.fillText('HOPS '+state.hops,338,168);
    ctx.fillStyle=state.levelComplete?C.gold:state.recalls?C.teal:'#304b59';ctx.fillRect(338,189,124,32);ctx.fillStyle=state.levelComplete||state.recalls?C.ink:C.dim;ctx.font='bold 10px monospace';ctx.fillText(state.levelComplete?'NEXT PYRAMID >':'RECALL '+state.recalls+' [SPACE]',347,210);
    ctx.fillStyle=C.dim;ctx.font='10px monospace';ctx.fillText('LEFT  = DOWN-LEFT',338,245);ctx.fillText('DOWN  = DOWN-RIGHT',338,260);ctx.fillText('UP    = UP-LEFT',338,275);ctx.fillText('RIGHT = UP-RIGHT',338,290);
    ctx.fillStyle=C.paper;ctx.font='9px monospace';ctx.fillText(state.message,16,315);
  }
  return {state,update,draw};
}
