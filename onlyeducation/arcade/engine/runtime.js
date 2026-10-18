import {Input} from './input.js';import {random} from './math.js';
export class Runtime{
 constructor({canvas,controls,module,assets,sound,onState,onError,seed=1972}){
  this.canvas=canvas;this.ctx=canvas.getContext('2d');this.ctx.imageSmoothingEnabled=false;this.input=new Input(canvas,controls);this.sound=sound;this.module=module;this.assets=assets;this.onState=onState;this.onError=onError;this.seed=seed;this.ticks=0;this.frames=0;this.mode='ready';this.raf=0;this.last=0;this.acc=0;this.faulted=false;
  try{this.create();}catch(e){this.input.destroy();throw e;}this.bound=t=>this.frame(t);this.raf=requestAnimationFrame(this.bound);
 }
 create(){this.game=this.module.createGame({rng:random(this.seed),sound:n=>this.sound.play(n),sprite:(ctx,id,x,y,options)=>this.assets.draw(ctx,id,x,y,options)});if(!this.game?.state||!this.game.update||!this.game.draw)throw Error('Invalid game module');this.gameDisposed=false;}
 start(){if(this.mode==='ready'){this.mode='playing';this.input.clear();this.last=0;this.acc=0;this.onState?.(this);if(!this.raf)this.raf=requestAnimationFrame(this.bound);}}
 pause(){if(this.mode==='playing'){this.mode='paused';this.input.clear();this.sound.silence();this.onState?.(this);}}
 resume(){if(this.mode==='paused'){this.mode='playing';this.input.clear();this.last=0;this.acc=0;this.onState?.(this);if(!this.raf)this.raf=requestAnimationFrame(this.bound);}}
 restart(){if(this.faulted||this.mode==='disposed')return;try{this.disposeGame();this.input.clear();this.sound.silence();this.ticks=0;this.acc=0;this.last=0;this.create();this.mode='ready';this.onState?.(this);if(!this.raf)this.raf=requestAnimationFrame(this.bound);}catch(e){this.fail(e);}}
 retry(){if(this.faulted||this.mode!=='ended'||this.game.state.status!=='lost'||typeof this.game.retry!=='function')return false;try{if(!this.game.retry())return false;this.input.clear();this.sound.silence();this.acc=0;this.last=0;this.mode='playing';this.onState?.(this);if(!this.raf)this.raf=requestAnimationFrame(this.bound);return true;}catch(e){this.fail(e);return false;}}
 frame(time){
  this.raf=0;if(this.mode==='disposed')return;
  try{
   const elapsed=this.last?Math.min((time-this.last)/1000,.1):0;this.last=time;
   if(this.mode==='playing'){
    this.acc+=elapsed;while(this.acc>=1/60&&this.mode==='playing'){this.game.update(1/60,this.input);this.input.consume();this.acc-=1/60;this.ticks++;
     if(this.game.state.status!=='playing'){this.mode='ended';this.input.clear();this.sound.play(this.game.state.status==='won'?'win':'lose');this.onState?.(this);}
    }
   }else this.acc=0;
   this.ctx.save();this.ctx.imageSmoothingEnabled=false;this.game.draw(this.ctx);this.ctx.restore();this.frames++;
   if(this.mode==='playing')this.raf=requestAnimationFrame(this.bound);
  }catch(e){this.fail(e);}
 }
 disposeGame(){if(!this.gameDisposed){this.gameDisposed=true;this.game?.dispose?.();}}
 fail(e){this.faulted=true;this.mode='error';cancelAnimationFrame(this.raf);this.raf=0;this.input.destroy();this.sound.silence();this.onError?.(e);}
 snapshot(){return {mode:this.mode,ticks:this.ticks,frames:this.frames,inputListeners:this.input.listeners,state:JSON.parse(JSON.stringify(this.game.state))};}
 destroy(){if(this.mode==='disposed')return;this.mode='disposed';cancelAnimationFrame(this.raf);this.raf=0;this.input.destroy();this.sound.silence();this.disposeGame();}
}
