const KEYS={ArrowLeft:'left',KeyA:'left',ArrowRight:'right',KeyD:'right',ArrowUp:'up',KeyW:'up',ArrowDown:'down',KeyS:'down',Space:'action',Enter:'action',KeyZ:'secondary',Backspace:'secondary'};
export class Input{
 constructor(canvas,controls){
  this.pointerInside=false;this.controls=controls;this.keys=new Set();this.edges=new Set();this.sources=new Map();this.pointer={x:240,y:160,down:false,pressed:false,active:false};this.abort=new AbortController();this.listeners=0;
  const on=(el,type,fn)=>{el.addEventListener(type,fn,{signal:this.abort.signal});this.listeners++;};
  const set=(source,a,held)=>{if(held){if(!this.keys.has(a))this.edges.add(a);this.sources.set(source,a);}else this.sources.delete(source);this.keys=new Set(this.sources.values());};
  on(window,'keydown',e=>{if(/^(INPUT|SELECT|TEXTAREA|BUTTON|A)$/.test(e.target.tagName)||e.ctrlKey||e.altKey||e.metaKey)return;const a=KEYS[e.code];if(a){e.preventDefault();set(e.code,a,true);}});
  on(window,'keyup',e=>{const a=KEYS[e.code];if(a){set(e.code,a,false);if(!/^(INPUT|SELECT|TEXTAREA|BUTTON|A)$/.test(e.target.tagName))e.preventDefault();}});
  on(window,'blur',()=>this.clear());
  const point=e=>{this.pointerInside=true;const r=canvas.getBoundingClientRect();this.pointer.x=(e.clientX-r.left)*480/r.width;this.pointer.y=(e.clientY-r.top)*320/r.height;this.pointer.active=true;};
  on(canvas,'pointerdown',e=>{e.preventDefault();canvas.focus();canvas.setPointerCapture(e.pointerId);point(e);this.pointer.down=true;this.pointer.pressed=true;});
  on(canvas,'pointermove',e=>{point(e);});
  on(canvas,'pointerup',e=>{point(e);this.pointer.down=false;});
  on(canvas,'pointercancel',()=>this.clear());
  on(canvas,'lostpointercapture',()=>{this.pointer.down=false;});
  on(canvas,'pointerleave',()=>{this.pointerInside=false;if(!this.pointer.down&&!this.pointer.pressed)this.pointer.active=false;});
  for(const b of controls.querySelectorAll('[data-input]')){
   on(b,'pointerdown',e=>{e.preventDefault();b.setPointerCapture(e.pointerId);set('touch'+e.pointerId,b.dataset.input,true);b.classList.add('held');});
   for(const type of ['pointerup','pointercancel','lostpointercapture'])on(b,type,e=>{set('touch'+e.pointerId,b.dataset.input,false);b.classList.remove('held');});
  }
 }
 down(a){return this.keys.has(a);}pressed(a){return this.edges.has(a);}
 consume(){this.edges.clear();this.pointer.pressed=false;if(!this.pointerInside&&!this.pointer.down)this.pointer.active=false;}
 clear(){this.pointerInside=false;this.controls.querySelectorAll('.held').forEach(b=>b.classList.remove('held'));this.keys.clear();this.edges.clear();this.sources.clear();Object.assign(this.pointer,{down:false,pressed:false,active:false});}
 destroy(){this.clear();this.abort.abort();this.listeners=0;}
}
