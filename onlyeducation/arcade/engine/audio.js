export class Sound{
 constructor(muted=false){this.muted=muted;this.ctx=null;this.voices=new Set();}
 async unlock(){try{this.ctx??=new (window.AudioContext||window.webkitAudioContext)();if(this.ctx.state==='suspended')await this.ctx.resume();}catch{/* Visual feedback remains available. */}}
 play(name){if(this.muted||!this.ctx||this.ctx.state!=='running')return;const notes={hit:[300,.05],score:[660,.12],lose:[100,.22],win:[880,.25],move:[220,.025]};const [f,t]=notes[name]||notes.hit;const o=this.ctx.createOscillator(),g=this.ctx.createGain();o.type='square';o.frequency.setValueAtTime(f,this.ctx.currentTime);o.frequency.exponentialRampToValueAtTime(name==='lose'?45:f*1.35,this.ctx.currentTime+t);g.gain.setValueAtTime(.035,this.ctx.currentTime);g.gain.exponentialRampToValueAtTime(.0001,this.ctx.currentTime+t);o.connect(g);g.connect(this.ctx.destination);o.start();o.stop(this.ctx.currentTime+t);this.voices.add(o);o.onended=()=>{o.disconnect();g.disconnect();this.voices.delete(o);};}
 silence(){for(const o of this.voices){try{o.stop();}catch{}}this.voices.clear();}
 async destroy(){this.silence();if(this.ctx)await this.ctx.close();this.ctx=null;}
}
