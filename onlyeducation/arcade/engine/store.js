const KEY='onlyeducation.arcade.v1';
const number=v=>typeof v==='number'&&Number.isFinite(v)?Math.max(0,Math.floor(v)):0;
export class SaveStore{
 constructor(storage){this.available=true;this.data={version:1,muted:false,games:{},achievements:[]};try{this.storage=storage??globalThis.localStorage;const d=JSON.parse(this.storage.getItem(KEY)||'null');if(d?.version===1&&d.games&&typeof d.games==='object'&&!Array.isArray(d.games)){this.data.muted=d.muted===true;this.data.achievements=Array.isArray(d.achievements)?d.achievements.filter(x=>['first-score','first-win','six-cabinets'].includes(x)):[];for(const[id,g]of Object.entries(d.games)){if(!/^[a-z]+(?:-[a-z]+)*$/.test(id)||!g||typeof g!=='object')continue;this.data.games[id]={best:number(g.best),plays:number(g.plays),wins:number(g.wins),level:Math.max(1,number(g.level))};}}}catch{this.available=false;}}
 write(){try{this.storage.setItem(KEY,JSON.stringify(this.data));return true;}catch{this.available=false;return false;}}
 record(id,state,{started=false}={}){const old=this.data.games[id]||{best:0,plays:0,wins:0,level:1};const best=Math.max(old.best,number(state.score));this.data.games[id]={best,plays:old.plays+(started?1:0),wins:old.wins+(state.status==='won'?1:0),level:Math.max(old.level,number(state.level))};if(best>0)this.unlock('first-score');if(state.status==='won')this.unlock('first-win');if(Object.values(this.data.games).filter(g=>g.plays>0).length>=6)this.unlock('six-cabinets');this.write();}
 unlock(id){if(!this.data.achievements.includes(id))this.data.achievements.push(id);}
 mute(value){this.data.muted=value;this.write();}
}
