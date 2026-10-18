// Shared drawing vocabulary only; every cabinet owns its own rules and state.
export const PAL={ink:'#152536',paper:'#fff0cf',teal:'#61d5c8',gold:'#ffc56a',coral:'#fa8068',dim:'#9bb4bb',violet:'#b7a3e8'};
export const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
export const hit=(a,b,r)=>Math.hypot(a.x-b.x,a.y-b.y)<r;
export function text(c,s,x,y,size=11,color=PAL.paper,align='left'){c.fillStyle=color;c.font='bold '+size+'px monospace';c.textAlign=align;c.textBaseline='alphabetic';c.fillText(s,x,y);c.textAlign='left';}
export function frame(c,title,score,hint){c.fillStyle=PAL.ink;c.fillRect(0,0,480,320);c.imageSmoothingEnabled=false;c.fillStyle='#20364a';c.fillRect(0,0,480,33);c.fillRect(0,296,480,24);text(c,title,12,22,14,PAL.gold);text(c,String(score).padStart(5,'0'),468,22,13,PAL.paper,'right');text(c,hint,240,312,9,PAL.dim,'center');}
export function banner(c,title,subtitle,color=PAL.gold){c.fillStyle='#10202fee';c.fillRect(45,124,390,78);c.strokeStyle=color;c.strokeRect(45,124,390,78);text(c,title,240,150,17,color,'center');text(c,subtitle,240,180,10,PAL.paper,'center');}
export function ship(c,p,color=PAL.teal,scale=1){c.save();c.translate(Math.round(p.x),Math.round(p.y));c.rotate(p.angle||0);c.fillStyle=color;c.beginPath();c.moveTo(12*scale,0);c.lineTo(-9*scale,-8*scale);c.lineTo(-5*scale,0);c.lineTo(-9*scale,8*scale);c.closePath();c.fill();c.fillStyle=PAL.paper;c.fillRect(0,-2,5,4);c.restore();}
export function bot(c,x,y,color=PAL.coral,size=16){c.fillStyle=color;c.fillRect(Math.round(x-size/2),Math.round(y-size/2),size,size);c.fillStyle=PAL.ink;c.fillRect(Math.round(x-5),Math.round(y-3),10,5);c.fillStyle=PAL.paper;c.fillRect(Math.round(x-4),Math.round(y-2),3,2);}
