export const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
export const rects=(a,b)=>a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y;
export const distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
export function random(seed=1){let s=seed>>>0;return()=>{s=(Math.imul(1664525,s)+1013904223)>>>0;return s/4294967296;};}
export function level(rows){if(!Array.isArray(rows)||!rows.length||rows.some(r=>!(typeof r==='string'||Array.isArray(r))||!r.length))throw Error('Invalid level');const w=rows[0].length;if(rows.some(r=>r.length!==w))throw Error('Invalid level');return rows.map(r=>[...r]);}
