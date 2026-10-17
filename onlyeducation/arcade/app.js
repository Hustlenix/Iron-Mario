import {GAMES} from './catalog.js';import {Runtime} from './engine/runtime.js';import {Sound} from './engine/audio.js';import {SaveStore} from './engine/store.js';import {PixelAssets} from '../history-assets/shared/pixel-assets.js';
const $=s=>document.querySelector(s),store=new SaveStore(),sound=new Sound(store.data.muted);
let runtime=null,current=null,loadToken=0,category='All',lastScore=-1,lastMessage='',lastSave='',hudTimer=0;
const playable=()=>GAMES.filter(g=>['PLAYABLE','TESTED','RELEASE READY'].includes(g.status));
function el(tag,cls,text){const n=document.createElement(tag);if(cls)n.className=cls;if(text!==undefined)n.textContent=text;return n;}
const art=g=>'../history-assets/assets/concepts/'+g.art+'.png';
function home(){
 const term=$('#search').value.trim().toLowerCase(),era=$('#era-filter').value;
 const list=playable().filter(g=>(category==='All'||g.category===category)&&(!era||g.era===era)&&(!term||(g.title+' '+g.tagline+' '+g.category).toLowerCase().includes(term)));
 $('#games').replaceChildren(...list.map(g=>{const a=el('a','game-card');a.href='#game/'+g.id;a.dataset.game=g.id;const im=el('div','game-art');const img=el('img');img.src=art(g);img.alt=g.title+' pixel artwork';img.loading='lazy';im.append(img,el('span','card-label',g.era),el('span','play-arrow','↗'));const copy=el('div','card-copy'),meta=el('div','meta');meta.append(el('span','',g.category.toUpperCase()),el('span','','FREE PLAY'));copy.append(meta,el('h3','',g.title),el('p','',g.tagline),el('div','record',store.data.games[g.id]?.plays?'YOUR BEST '+(store.data.games[g.id]?.best||0).toLocaleString():'A FRESH START AWAITS'));a.append(im,copy);return a;}));
 $('#results').textContent=list.length+' of '+playable().length+' playable cabinets';$('#empty').hidden=!!list.length;
 $('#planned').replaceChildren(...GAMES.filter(g=>!playable().includes(g)).map(g=>{const d=el('div','planned-item'),im=el('img');im.src='../history-assets/assets/medallions/'+g.art+'.png';im.alt='';im.loading='lazy';d.append(im,el('span','',g.title),el('small','','PLANNED'));return d;}));
 const total=Object.values(store.data.games).reduce((n,g)=>n+(g.plays||0),0);$('#progress-copy').textContent=store.available?(total?total+' sessions started. Your scores stay in this browser.':'Your scores stay in this browser. No account needed.'):'Browser storage is unavailable. This session still works; scores will not persist.';
 $('#badges').replaceChildren(...[['first-score','✦','FIRST POINT'],['first-win','★','FIRST VICTORY'],['six-cabinets','▦','SIX CABINETS']].map(([id,icon,label])=>{const d=el('div','badge'+(store.data.achievements.includes(id)?' earned':''));d.append(el('b','',icon),el('span','',label));d.title=store.data.achievements.includes(id)?'Earned':'Not yet earned';return d;}));
}
function filters(){const cats=['All',...new Set(playable().map(g=>g.category))];$('#categories').replaceChildren(...cats.map(c=>{const b=el('button','',c);b.setAttribute('aria-pressed',c===category);b.onclick=()=>{category=c;filters();home();};return b;}));}
for(const era of ['1950s','1960s','1970s','1980s']){const d=el('div','era'),im=el('img');im.src='../history-assets/assets/scenes/'+era+'.png';im.alt='';const b=el('button','','EXPLORE →');b.onclick=()=>{$('#era-filter').value=era;category='All';filters();home();location.hash='collection';};d.append(el('b','',era),im,el('span','',{'1950s':'LAB EXPERIMENTS','1960s':'SPACE & VECTORS','1970s':'THE ARCADE ARRIVES','1980s':'A WORLD IN COLOR'}[era]),b);$('#timeline').append(d);}
$('#search').oninput=home;$('#era-filter').onchange=home;$('#reset-filters').onclick=()=>{$('#search').value='';$('#era-filter').value='';category='All';filters();home();};
function saveRun(){if(!runtime||!current)return;const s=runtime.game.state;const sig=[s.score,s.status,s.level].join(':');if(sig!==lastSave){store.record(current.id,s);lastSave=sig;}}
function stop(){loadToken++;if(runtime){saveRun();runtime.destroy();runtime=null;}clearInterval(hudTimer);hudTimer=0;lastSave='';current=null;sound.silence();}
function overlay(kicker,title,copy,button,hidden=false){$('#game-overlay').hidden=hidden;$('#overlay-kicker').textContent=kicker;$('#overlay-title').textContent=title;$('#overlay-copy').textContent=copy;$('#start').hidden=!button;$('#start').textContent=button||'';}
function stateChanged(){
 if(!runtime)return;const mode=runtime.mode,s=runtime.game.state;
 $('#pause').disabled=!['playing','paused'].includes(mode);$('#pause').textContent=mode==='paused'?'Resume':'Pause';$('#restart').disabled=mode==='error';
 if(mode==='ready')overlay(current.era+' · '+current.category.toUpperCase(),'Your turn.',current.description,"LET'S PLAY ▸");
 if(mode==='playing')overlay('','','','',true);
 if(mode==='paused')overlay('TAKE A BREATHER','Paused.','Your game will be right here.','RESUME ▸');
 if(mode==='ended'){saveRun();overlay(s.status==='won'?'NICE WORK':'ONE MORE GO?',s.status==='won'?'You did it.':'Good run.',s.message+' · Score '+s.score,'PLAY AGAIN ↻');}
 updateHUD();
}
function updateHUD(){if(!runtime)return;const s=runtime.game.state;$('#score').textContent='SCORE '+s.score;$('#best').textContent='BEST '+Math.max(store.data.games[current.id]?.best||0,s.score);if(s.message!==lastMessage){$('#game-message').textContent=s.message||'';lastMessage=s.message;}if(s.score!==lastScore){saveRun();lastScore=s.score;}$('#save-note').textContent=store.available?'Scores and progress are saved on this device.':'Storage unavailable: scores last for this session only.';}
function failure(error){console.error('Arcade load/runtime error:',error);if(runtime){runtime.destroy();runtime=null;}clearInterval(hudTimer);hudTimer=0;$('#pause').disabled=true;$('#restart').disabled=true;overlay('CABINET NEEDS A MOMENT','Could not start.','This cabinet could not load. Check your connection and try again.','TRY AGAIN ↻');}
async function loadGame(id){
 stop();const token=loadToken;current=GAMES.find(g=>g.id===id);
 $('#home-view').hidden=true;$('#game-view').hidden=false;window.scrollTo(0,0);
 if(!current||!playable().includes(current)){$('#pause').disabled=true;$('#restart').disabled=true;$('#score').textContent='SCORE —';$('#best').textContent='BEST —';$('#game-message').textContent='';$('#game-description').textContent='This game is still in development.';$('#game-controls').textContent='Choose a playable game from the collection.';$('#history-copy').textContent='';$('#history-source').hidden=true;$('#game-era').textContent='PLANNED';$('#game-title').textContent='This cabinet is on the workbench.';$('#game-tagline').textContent='Choose a tested cabinet from the collection.';overlay('COMING LATER','Not playable yet.','Return to the arcade to choose an available game.',null);return;}
 document.title=current.title+' — OnlyEducation';$('#game-title').textContent=current.title;$('#game-era').textContent=current.era+' · '+current.category.toUpperCase();$('#game-tagline').textContent=current.tagline;$('#game-description').textContent=current.description;$('#game-controls').textContent=current.controls;$('#history-copy').textContent='Inspired by a '+current.year+' gameplay idea. This is an independent interpretation with original code, visuals and levels.';$('#history-source').hidden=!current.source;$('#history-source').href=current.source||'#';$('#pause').disabled=true;$('#restart').disabled=true;lastScore=-1;lastMessage='';$('#game-message').textContent='';$('#score').textContent='SCORE 0';$('#best').textContent='BEST '+(store.data.games[id]?.best||0);overlay('WARMING UP','Loading cabinet…','Preparing its game module and shared pixel artwork.',null);
 try{
  const [module,assets]=await Promise.all([import('./games/'+id+'.js'),PixelAssets.load('../history-assets/assets/manifest.json',{ids:current.assets||[]})]);
  if(token!==loadToken)return;
  runtime=new Runtime({canvas:$('#game-canvas'),controls:$('#touch-controls'),module,assets,sound,onState:stateChanged,onError:failure,seed:1972});stateChanged();hudTimer=setInterval(updateHUD,120);
 }catch(e){if(token===loadToken)failure(e);}
}
async function start(){await sound.unlock();if(!runtime){if(current)location.reload();return;}if(runtime.mode==='ready'){store.record(current.id,runtime.game.state,{started:true});runtime.start();}else if(runtime.mode==='paused')runtime.resume();else if(runtime.mode==='ended'){lastSave='';runtime.restart();if(!runtime)return;store.record(current.id,runtime.game.state,{started:true});runtime.start();}$('#game-canvas').focus();}
$('#start').onclick=start;
$('#pause').onclick=()=>{if(!runtime)return;if(runtime.mode==='playing')runtime.pause();else{runtime.resume();sound.unlock();}};
$('#restart').onclick=()=>{if(!runtime)return;saveRun();lastSave='';runtime.restart();};
function mute(){sound.muted=!sound.muted;store.mute(sound.muted);if(sound.muted)sound.silence();else sound.unlock();updateMute();}
function updateMute(){$('#mute').textContent=sound.muted?'Sound off':'Sound on';$('#mute').setAttribute('aria-pressed',sound.muted);}
$('#mute').onclick=mute;updateMute();
$('#fullscreen').onclick=async()=>{try{if(document.fullscreenElement)await document.exitFullscreen();else await $('#play-column').requestFullscreen();}catch{$('#game-message').textContent='Fullscreen is unavailable in this browser. The game still works here.';}};
document.addEventListener('fullscreenchange',()=>{$('#fullscreen').textContent=document.fullscreenElement?'Exit fullscreen':'Fullscreen';});
document.addEventListener('visibilitychange',()=>{if(document.hidden)runtime?.pause();});
window.addEventListener('blur',()=>runtime?.pause());
window.addEventListener('keydown',e=>{if(!runtime||/INPUT|SELECT|TEXTAREA/.test(e.target.tagName)||e.ctrlKey||e.altKey||e.metaKey)return;if(['KeyP','Escape'].includes(e.code)){e.preventDefault();$('#pause').click();}else if(e.code==='KeyR'){e.preventDefault();$('#restart').click();}else if(['Enter','Space'].includes(e.code)&&runtime.mode!=='playing'&&e.target.tagName!=='BUTTON'){e.preventDefault();start();}});
function route(){if(location.hash.startsWith('#game/'))loadGame(location.hash.slice(6));else{stop();$('#home-view').hidden=false;$('#game-view').hidden=true;document.title='OnlyEducation — Play the Past. Build the Future.';home();requestAnimationFrame(()=>{if(location.hash==='#collection'||location.hash==='#history')$(location.hash).scrollIntoView();else window.scrollTo(0,0);});}}
window.addEventListener('hashchange',route);window.addEventListener('pagehide',()=>{stop();sound.destroy();});filters();home();route();
if(new URLSearchParams(location.search).has('qa'))Object.defineProperty(window,'__arcade',{value:Object.freeze({snapshot:()=>runtime?.snapshot()||null,resources:()=>({active:runtime?1:0,inputListeners:runtime?.input.listeners||0,raf:runtime?.raf?1:0,hudTimer:hudTimer?1:0,voices:sound.voices.size}),saves:()=>JSON.parse(JSON.stringify(store.data)),catalog:()=>GAMES.map(g=>({id:g.id,status:g.status}))})});
