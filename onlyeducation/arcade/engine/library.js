const KEY='onlyeducation.library.v1';
export class Library{
 constructor(ids,storage){
  this.allowed=new Set(ids);this.available=true;this.favorites=[];this.recent=[];
  try{this.storage=storage??globalThis.localStorage;const d=JSON.parse(this.storage.getItem(KEY)||'null');if(d?.version===1){this.favorites=this.clean(d.favorites);this.recent=this.clean(d.recent).slice(0,10);}}
  catch{this.available=false;}
 }
 clean(value){return Array.isArray(value)?[...new Set(value.filter(id=>typeof id==='string'&&this.allowed.has(id)))]:[];}
 save(){try{this.storage.setItem(KEY,JSON.stringify({version:1,favorites:this.favorites,recent:this.recent}));}catch{this.available=false;}}
 has(id){return this.favorites.includes(id);}
 toggle(id){if(!this.allowed.has(id))return false;this.favorites=this.has(id)?this.favorites.filter(x=>x!==id):[...this.favorites,id];this.save();return this.has(id);}
 play(id){if(!this.allowed.has(id))return;this.recent=[id,...this.recent.filter(x=>x!==id)].slice(0,10);this.save();}
}
