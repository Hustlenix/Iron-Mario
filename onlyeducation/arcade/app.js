import {GAMES} from './catalog.js';
import {Runtime} from './engine/runtime.js';
import {Sound} from './engine/audio.js';
import {SaveStore} from './engine/store.js';
import {Library} from './engine/library.js';
import {PixelAssets} from '../history-assets/shared/pixel-assets.js';
const $=s=>document.querySelector(s),store=new SaveStore(),sound=new Sound(store.data.muted);
const playable=()=>GAMES.filter(g=>['PLAYABLE','TESTED','RELEASE READY'].includes(g.status));
const library=new Library(playable().map(g=>g.id));
document.body.classList.toggle('touch-device',navigator.maxTouchPoints>0||matchMedia('(any-pointer:coarse)').matches);
let runtime=null,current=null,loadToken=0,category='All',libraryView='all';
let lastScore=-1,lastMessage='',lastSave='',hudTimer=0,homeScroll=0,returnGame=null;
let pickerResume=false,pickerGame=null,pickerFocus=null,navResume=false,navGame=null;
const dialog=$('#game-switcher');
const isGame=()=>!$('#game-view').hidden;
const art=g=>'./art/previews/'+g.id+'.png';
const cover=g=>g.id==='dino-dash'?g.cover:art(g);
function el(tag,cls,text){const n=document.createElement(tag);if(cls)n.className=cls;if(text!==undefined)n.textContent=text;return n;}
function gameById(id){return playable().find(g=>g.id===id);}
function matches(g,q){return (g.title+' '+g.tagline+' '+g.category+' '+g.era+' '+(g.dateLabel||'')).toLowerCase().includes(q);}
function favoriteButton(g){
 const b=el('button','tile-favorite',library.has(g.id)?'★':'☆');
 b.dataset.favorite=g.id;b.setAttribute('aria-label',(library.has(g.id)?'Remove ':'Add ')+g.title+(library.has(g.id)?' from favorites':' to favorites'));
 b.setAttribute('aria-pressed',library.has(g.id));return b;
}
function tile(g,featured){
 const wrap=el('article','tile'+(featured?' featured':''));wrap.dataset.category=g.category;wrap.dataset.id=g.id;
 const a=el('a','game-card');a.href='#game/'+g.id;a.dataset.game=g.id;
 const media=el('div','game-art'),img=el('img');img.src=featured?cover(g):art(g);img.alt=g.title+(featured?' original pixel artwork':' gameplay preview');img.loading=featured?'eager':'lazy';media.append(img);
 if(g.id==='dino-dash')media.append(el('span','card-label','67 MILLION YEARS AGO'));
 if(!featured)media.append(el('span','card-play','↗'));
 const copy=el('div','card-copy'),meta=el('div','meta');copy.append(el('h3','',g.title));
 meta.append(el('span','',g.category),el('span','record',store.data.games[g.id]?.plays?'BEST '+store.data.games[g.id].best:'PLAY FREE'));
 copy.append(meta);if(featured){copy.append(el('p','feature-description',g.tagline),el('span','feature-cta','Let’s play  ↗'));}a.append(media,copy);wrap.append(a,favoriteButton(g));return wrap;
}
function mini(g,cls='mini-card'){
 const a=el('a',cls);a.href='#game/'+g.id;a.dataset.switchLink=g.id;
 const im=el('img');im.src=art(g);im.alt='';im.loading='lazy';
 const text=el('span');text.append(el('strong','',g.title),el('small','',g.category));a.append(im,text);return a;
}
function libraryNavigation(){
 for(const b of document.querySelectorAll('#sidebar [data-library]')){if(b.dataset.library===libraryView)b.setAttribute('aria-current','page');else b.removeAttribute('aria-current');}
 $('#game-count').textContent=playable().length;$('#favorite-count').textContent=library.favorites.length||'';
 $('#playable-total').textContent=playable().length;$('#library-note').textContent=library.available?'Saved on this device':'Saved for this session';
}
function home(){
 const term=$('#search').value.trim().toLowerCase(),era=$('#era-filter').value;
 const base=libraryView==='recent'?library.recent.map(gameById).filter(Boolean):libraryView==='favorites'?playable().filter(g=>library.has(g.id)):playable();
 const list=base.filter(g=>(category==='All'||g.category===category)&&(!era||g.era===era)&&(!term||matches(g,term)));
 const title={all:'A little escape. One more game.',recent:'Back for another go?',favorites:'The good ones, saved.'};
 $('#library-title').textContent=title[libraryView];
 $('#library-description').textContent={all:'Original pixel games. Free to play. Yours to explore.',recent:'Your last ten played games, ready when you are.',favorites:'Your own little collection. No account needed.'}[libraryView];
 const featured=libraryView==='all'&&!term&&!era&&category==='All';
 $('#games').replaceChildren(...list.map((g,i)=>tile(g,featured&&i===0)));
 $('#results').textContent=list.length+' of '+playable().length+' playable games';
 $('#empty').hidden=!!list.length;
 $('#empty-title').textContent=libraryView==='favorites'&&!base.length?'Your favorites start here.':libraryView==='recent'&&!base.length?'Your next memory is waiting.':'No games found.';
 $('#empty-copy').textContent=libraryView==='favorites'&&!base.length?'Tap a star on any game to save it here.':libraryView==='recent'&&!base.length?'Start a game and it will appear in this list.':'Try another title, category or era.';
 const recent=library.recent.slice(0,5).map(gameById).filter(Boolean);
 $('#recent-row').hidden=libraryView!=='all'||!!term||!!era||category!=='All'||!recent.length;
 $('#recent-games').replaceChildren(...recent.map(g=>mini(g)));
 const total=Object.values(store.data.games).reduce((n,g)=>n+(g.plays||0),0);
 $('#progress-copy').textContent=store.available?(total?total+' sessions started. Your scores stay in this browser.':'Your scores stay in this browser. No account needed.'):'Browser storage is unavailable. This session still works; scores will not persist.';
 $('#badges').replaceChildren(...[['first-score','✦','FIRST POINT'],['first-win','★','FIRST VICTORY'],['six-cabinets','▦','SIX GAMES']].map(([id,icon,label])=>{const n=el('div','badge'+(store.data.achievements.includes(id)?' earned':''));n.append(el('b','',icon),el('span','',label));n.title=store.data.achievements.includes(id)?'Earned':'Not yet earned';return n;}));
 libraryNavigation();
}
function filters(){
 const cats=['All',...['Action','Puzzle','Sports','Racing','Precision'].filter(c=>playable().some(g=>g.category===c))];
 $('#categories').replaceChildren(...cats.map(c=>{const b=el('button','',c);b.setAttribute('aria-pressed',c===category);b.onclick=()=>{category=c;filters();home();};return b;}));
}
function chooseLibrary(view,cat='All'){
 libraryView=view;category=cat;$('#search').value='';$('#era-filter').value='';homeScroll=0;returnGame=null;
 navResume=false;closeNav();filters();home();if(location.hash!=='#collection')location.hash='collection';else window.scrollTo(0,0);
}
const icons={Action:'✦',Puzzle:'▧',Sports:'◉',Racing:'➜',Precision:'⌁'};
$('#side-categories').replaceChildren(...Object.entries(icons).filter(([c])=>playable().some(g=>g.category===c)).map(([c,icon])=>{const b=el('button');b.setAttribute('aria-label','Browse '+c+' games');b.title=c;b.append(el('span','nav-icon',icon),el('span','nav-text',c));b.onclick=()=>chooseLibrary('all',c);return b;}));
for(const era of ['Prehistoric','1950s','1960s','1970s','1980s']){
 const prehistoric=era==='Prehistoric',d=el('div','era'+(prehistoric?' prehistoric':'')),im=el('img');
 im.src=prehistoric?'./art/dino-dash-card.png':'../history-assets/assets/scenes/'+era+'.png';im.alt='';im.loading='lazy';
 const b=el('button','','Explore →');b.onclick=()=>{libraryView='all';$('#era-filter').value=era;$('#search').value='';category='All';filters();home();location.hash='collection';$('#collection').scrollIntoView();};
 d.append(el('b','',prehistoric?'67M YEARS AGO':era),im,el('span','',{'Prehistoric':'PREHISTORIC BONUS','1950s':'LAB EXPERIMENTS','1960s':'SPACE & VECTORS','1970s':'THE ARCADE ARRIVES','1980s':'A WORLD IN COLOR'}[era]),b);$('#timeline').append(d);
}
$('#planned').replaceChildren(...GAMES.filter(g=>!playable().includes(g)).map(g=>{const d=el('div','planned-item'),im=el('img');im.src='../history-assets/assets/medallions/'+g.art+'.png';im.alt='';im.loading='lazy';d.append(im,el('span','',g.title),el('small','','PLANNED'));return d;}));
$('#search').oninput=()=>{if(isGame())openPicker($('#search').value);else home();};
$('#search').onpointerdown=e=>{if(isGame()){e.preventDefault();openPicker('');}};
$('#era-filter').onchange=home;$('#reset-filters').onclick=()=>chooseLibrary('all');
document.addEventListener('click',e=>{
 const favorite=e.target.closest('[data-favorite]');if(favorite){e.preventDefault();library.toggle(favorite.dataset.favorite);home();renderFavorite();const replacement=document.querySelector('[data-favorite="'+favorite.dataset.favorite+'"]');replacement?.focus({preventScroll:true});return;}
 const nav=e.target.closest('[data-library]');if(nav){chooseLibrary(nav.dataset.library);return;}
 const switcher=e.target.closest('[data-open-switch]');if(switcher){openPicker();return;}
 const gameLink=e.target.closest('a[href^="#game/"]');
 if(gameLink&&!isGame()){homeScroll=window.scrollY;returnGame=gameLink.getAttribute('href').slice(6);}
});
function renderFavorite(){
 const starred=current&&library.has(current.id);$('#favorite-game').textContent=starred?'★':'☆';$('#favorite-game').setAttribute('aria-pressed',!!starred);
 $('#favorite-game').setAttribute('aria-label',starred?'Remove this game from favorites':'Favorite this game');libraryNavigation();
}
$('#favorite-game').onclick=()=>{if(current){library.toggle(current.id);renderFavorite();}};
function renderPlayNext(id){
 const all=playable(),index=all.findIndex(g=>g.id===id),g=all[index];
 $('#previous-game').href='#game/'+all[(index-1+all.length)%all.length].id;
 $('#next-game').href='#game/'+all[(index+1)%all.length].id;
 const next=all.filter(x=>x.id!==id).sort((a,b)=>Number(b.category===g?.category)-Number(a.category===g?.category)).slice(0,8);
 $('#play-next').replaceChildren(...next.map(x=>mini(x,'next-card')));
}
function renderPicker(){
 const term=$('#switch-search').value.trim().toLowerCase(),games=playable().filter(g=>matches(g,term));
 $('#switch-count').textContent=games.length+' '+(games.length===1?'game':'games')+' · Choose one to open';
 $('#switch-empty').hidden=!!games.length;
 $('#switch-results').replaceChildren(...games.map(g=>{
  const b=el('button','switch-option');b.dataset.switchTarget=g.id;const img=el('img');img.src=art(g);img.alt='';
  const text=el('span');text.append(el('strong','',g.title),el('small',g.id===current?.id?'current-label':'',g.id===current?.id?'Currently open':g.category+' · '+(g.dateLabel||g.era)));
  b.append(img,text);if(g.id===current?.id)b.setAttribute('aria-current','true');return b;
 }));
}
function openPicker(query=''){
 if(dialog.open)return;
 if(!isGame())homeScroll=window.scrollY;
 const wasNavPlaying=navResume&&navGame===current?.id;navResume=false;closeNav();pickerFocus=document.activeElement;pickerGame=current?.id;pickerResume=runtime?.mode==='playing'||wasNavPlaying;
 if(pickerResume)runtime.pause();$('#switch-search').value=query;renderPicker();dialog.showModal();$('#switch-search').focus();
}
dialog.addEventListener('close',()=>{
 const resume=pickerResume&&pickerGame===current?.id&&runtime?.mode==='paused';pickerResume=false;
 if(resume)runtime.resume();if(pickerFocus?.isConnected)pickerFocus.focus({preventScroll:true});
});
$('#close-switcher').onclick=()=>dialog.close();
$('#switch-search').oninput=renderPicker;
$('#switch-search').onkeydown=e=>{if(e.key==='Enter'){e.preventDefault();$('#switch-results [data-switch-target]')?.click();}};
$('#switch-results').onclick=e=>{const b=e.target.closest('[data-switch-target]');if(!b)return;const id=b.dataset.switchTarget;if(id===current?.id){dialog.close();return;}if(!isGame())returnGame=id;pickerResume=false;pickerFocus=null;dialog.close();location.hash='game/'+id;};
dialog.addEventListener('click',e=>{const b=dialog.getBoundingClientRect();if(e.target===dialog&&(e.clientX<b.left||e.clientX>b.right||e.clientY<b.top||e.clientY>b.bottom))dialog.close();});
function desktopNav(){return matchMedia('(min-width:961px)').matches;}
function updateNavButton(){
 const expanded=desktopNav()?(isGame()?document.body.classList.contains('rail-expanded'):!document.body.classList.contains('nav-compact')):document.body.classList.contains('nav-open');
 $('#menu-toggle').setAttribute('aria-expanded',expanded);$('#menu-toggle').setAttribute('aria-label',expanded?'Collapse navigation':'Open navigation');
}
function closeNav(){
 const resume=navResume&&navGame===current?.id&&runtime?.mode==='paused';navResume=false;document.body.classList.remove('nav-open','rail-expanded');$('#nav-scrim').hidden=true;updateNavButton();if(resume)runtime.resume();
}
$('#menu-toggle').onclick=()=>{
 if(desktopNav()){document.body.classList.toggle(isGame()?'rail-expanded':'nav-compact');updateNavButton();return;}
 if(document.body.classList.contains('nav-open')){closeNav();return;}
 navResume=runtime?.mode==='playing';navGame=current?.id;if(navResume)runtime.pause();document.body.classList.add('nav-open');updateNavButton();$('#nav-scrim').hidden=false;$('#nav-all').focus();
};
$('#nav-scrim').onclick=()=>{closeNav();$('#menu-toggle').focus({preventScroll:true});};
$('#mobile-search').onclick=()=>openPicker();
const navBreakpoint=matchMedia('(min-width:961px)');navBreakpoint.addEventListener('change',()=>closeNav());
for(const b of document.querySelectorAll('#sidebar [data-library]')){b.title=b.querySelector('.nav-text').textContent;b.setAttribute('aria-label',b.title);}
$('#surprise').onclick=()=>{const choices=playable().filter(g=>g.id!==current?.id);location.hash='game/'+choices[Math.floor(Math.random()*choices.length)].id;};
$('#touch-toggle').onclick=()=>{const enabled=document.body.classList.toggle('show-touch');$('#touch-toggle').setAttribute('aria-pressed',enabled);};
function saveRun(){if(!runtime||!current)return;const s=runtime.game.state,sig=[s.score,s.status,s.level].join(':');if(sig!==lastSave){store.record(current.id,s);lastSave=sig;}}
function stop(){loadToken++;if(runtime){saveRun();runtime.destroy();runtime=null;}clearInterval(hudTimer);hudTimer=0;lastSave='';current=null;sound.silence();}
function overlay(kicker,title,copy,button,hidden=false){$('#game-overlay').hidden=hidden;$('#overlay-kicker').textContent=kicker;$('#overlay-title').textContent=title;$('#overlay-copy').textContent=copy;$('#start').hidden=!button;$('#start').textContent=button||'';}
function stateChanged(){
 if(!runtime)return;const mode=runtime.mode,s=runtime.game.state;
 $('#pause').disabled=!['playing','paused'].includes(mode);$('#pause').textContent=mode==='paused'?'Resume':'Pause';$('#restart').disabled=mode==='error';
 if(mode==='ready')overlay((current.dateLabel||current.era)+' · '+current.category.toUpperCase(),current.title,current.tagline,'PLAY NOW ▸');
 if(mode==='playing')overlay('','','','',true);
 if(mode==='paused')overlay('TAKE A BREATHER','Paused.','Your game will be right here.','RESUME ▸');
 if(mode==='ended'){saveRun();const retry=s.status==='lost'&&typeof runtime.game.retry==='function';overlay(s.status==='won'?'NICE WORK':retry?'KEEP YOUR PROGRESS':'ONE MORE GO?',s.status==='won'?'You did it.':retry?'Try this terminal.':'Good run.',s.message+' · Score '+s.score,retry?'RETRY TERMINAL ↻':'PLAY AGAIN ↻');}
 updateHUD();
}
function updateHUD(){
 if(!runtime)return;const s=runtime.game.state;$('#score').textContent='SCORE '+s.score;$('#best').textContent='BEST '+Math.max(store.data.games[current.id]?.best||0,s.score);
 if(s.message!==lastMessage){$('#game-message').textContent=s.message||'';lastMessage=s.message;}
 if(s.score!==lastScore){saveRun();lastScore=s.score;}$('#save-note').textContent=store.available?'Best scores are saved on this device.':'Storage unavailable: scores last for this session only.';
}
function failure(error){console.error('Arcade load/runtime error:',error);if(runtime){runtime.destroy();runtime=null;}clearInterval(hudTimer);hudTimer=0;$('#pause').disabled=true;$('#restart').disabled=true;overlay('CABINET NEEDS A MOMENT','Could not start.','This cabinet could not load. Check your connection and try again.','TRY AGAIN ↻');}
function controlHints(id){
 $('#touch-controls').classList.toggle('runner-controls',id==='dino-dash');
 const labels={'dino-dash':{action:'JUMP',secondary:'DUCK (HOLD)'},'grid-x':{action:'PLACE'},'crate-shift':{action:'NEXT',secondary:'UNDO'},'stackfall':{action:'DROP',secondary:'ROTATE ↶'},'brick-burst':{action:'LAUNCH'},'dark-cavern':{action:'GO / FIRE',secondary:'AIM MODE'},'color-steps':{left:'↙',down:'↘',up:'↖',right:'↗',action:'RECALL / NEXT'},'sidecourt':{action:'SWING'},'sky-shield':{action:'FIRE'},'rock-drift':{action:'FIRE'},'flag-run':{action:'SMOKE'}}[id]||{};
 const defaults={left:'←',right:'→',up:'↑',down:'↓',action:'ACTION',secondary:'Z / ALT'};
 for(const b of $('#touch-controls').querySelectorAll('[data-input]')){b.textContent=labels[b.dataset.input]||defaults[b.dataset.input];b.setAttribute('aria-label',b.dataset.input+': '+b.textContent);}
}
async function loadGame(id){
 stop();const token=loadToken;current=GAMES.find(g=>g.id===id);$('#home-view').hidden=true;$('#game-view').hidden=false;updateNavButton();window.scrollTo(0,0);renderPlayNext(id);renderFavorite();
 if(!current||!playable().includes(current)){
  $('#pause').disabled=true;$('#restart').disabled=true;$('#score').textContent='SCORE —';$('#best').textContent='BEST —';$('#game-message').textContent='';$('#game-description').textContent='This game is still in development.';$('#game-controls').textContent='Choose another game using Games or the Play next strip.';$('#history-copy').textContent='';$('#history-source').hidden=true;$('#game-era').textContent='PLANNED';$('#game-title').textContent='On the workbench';$('#game-tagline').textContent='Choose a playable game to keep going.';overlay('COMING LATER','Not playable yet.','Choose a game from Play next or open the game switcher.',null);return;
 }
 controlHints(id);document.title=current.title+' — OnlyEducation';$('#game-title').textContent=current.title;$('#game-era').textContent=(current.dateLabel||current.era)+' · '+current.category;
 $('#game-tagline').textContent=current.tagline;$('#game-description').textContent=current.description;$('#game-controls').textContent=current.controls;$('#history-copy').textContent=current.historyNote||'Inspired by a '+current.year+' gameplay idea. Original code, visuals and levels by OnlyEducation.';
 $('#history-source').hidden=!current.source;$('#history-source').href=current.source||'#';$('#pause').disabled=true;$('#restart').disabled=true;lastScore=-1;lastMessage='';$('#game-message').textContent='';$('#score').textContent='SCORE 0';$('#best').textContent='BEST '+(store.data.games[id]?.best||0);
 overlay('WARMING UP','Loading cabinet…','Preparing the game and its pixel artwork.',null);
 try{
  const [module,assets]=await Promise.all([import('./games/'+id+'.js'),PixelAssets.load(current.assetManifest||'../history-assets/assets/manifest.json',{ids:current.assets||[]})]);if(token!==loadToken)return;
  runtime=new Runtime({canvas:$('#game-canvas'),controls:$('#touch-controls'),module,assets,sound,onState:stateChanged,onError:failure,seed:1972});stateChanged();hudTimer=setInterval(updateHUD,120);$('#start').focus({preventScroll:true});
 }catch(e){if(token===loadToken)failure(e);}
}
async function start(){
 await sound.unlock();if(!runtime){if(current)location.reload();return;}
 if(runtime.mode==='ready'){library.play(current.id);store.record(current.id,runtime.game.state,{started:true});runtime.start();}
 else if(runtime.mode==='paused')runtime.resume();
 else if(runtime.mode==='ended'){lastSave='';if(runtime.game.state.status==='lost'&&typeof runtime.game.retry==='function')runtime.retry();else{runtime.restart();if(!runtime)return;library.play(current.id);store.record(current.id,runtime.game.state,{started:true});runtime.start();}}
 $('#game-canvas').focus();
}
$('#start').onclick=start;
$('#pause').onclick=()=>{if(!runtime)return;if(runtime.mode==='playing')runtime.pause();else{runtime.resume();sound.unlock();}};
$('#restart').onclick=()=>{if(!runtime)return;saveRun();lastSave='';runtime.restart();};
function updateMute(){$('#mute').textContent=sound.muted?'Sound off':'Sound on';$('#mute').setAttribute('aria-pressed',sound.muted);}
$('#mute').onclick=()=>{sound.muted=!sound.muted;store.mute(sound.muted);if(sound.muted)sound.silence();else sound.unlock();updateMute();};updateMute();
$('#fullscreen').onclick=async()=>{try{if(document.fullscreenElement)await document.exitFullscreen();else await $('#play-column').requestFullscreen();}catch{$('#game-message').textContent='Fullscreen is unavailable in this browser. The game still works here.';}};
document.addEventListener('fullscreenchange',()=>{$('#fullscreen').textContent=document.fullscreenElement?'Exit fullscreen':'Fullscreen';});
document.addEventListener('visibilitychange',()=>{if(document.hidden)runtime?.pause();});
window.addEventListener('blur',()=>runtime?.pause());
window.addEventListener('keydown',e=>{
 if(dialog.open)return;
 if(e.code==='Tab'&&document.body.classList.contains('nav-open')){
  const stops=[$('#menu-toggle'),...$('#sidebar').querySelectorAll('button,a')].filter(n=>n.getClientRects().length&&!n.disabled);
  const index=stops.indexOf(document.activeElement),next=e.shiftKey?(index<=0?stops.length-1:index-1):(index+1)%stops.length;
  e.preventDefault();stops[next]?.focus();
  return;
 }
 if(e.code==='Escape'&&(document.body.classList.contains('nav-open')||document.body.classList.contains('rail-expanded'))){e.preventDefault();closeNav();$('#menu-toggle').focus({preventScroll:true});return;}
 if(e.target.closest('input,select,textarea,[contenteditable="true"]')||e.ctrlKey||e.altKey||e.metaKey)return;
 if(e.code==='Slash'){e.preventDefault();if(isGame()||!desktopNav())openPicker();else $('#search').focus();return;}
 if(e.code==='KeyG'){e.preventDefault();openPicker();return;}
 if(!runtime)return;
 if(['KeyP','Escape'].includes(e.code)){e.preventDefault();$('#pause').click();}
 else if(e.code==='KeyR'){e.preventDefault();$('#restart').click();}
 else if(['Enter','Space'].includes(e.code)&&runtime.mode!=='playing'&&!e.target.closest('button,a,summary')){e.preventDefault();start();}
});
function route(){
 if(dialog.open){pickerResume=false;dialog.close();}navResume=false;closeNav();
 const game=location.hash.startsWith('#game/'),wasGame=isGame();document.body.classList.toggle('in-game',game);
 $('#menu-toggle').setAttribute('aria-expanded',desktopNav()?!game&&!document.body.classList.contains('nav-compact'):false);
 for(const b of document.querySelectorAll('[data-only-game]'))b.hidden=!game;
 if(game)loadGame(location.hash.slice(6));
 else{
  stop();$('#home-view').hidden=false;$('#game-view').hidden=true;updateNavButton();document.title='OnlyEducation — Your pixel playground';home();
  requestAnimationFrame(()=>{
   if(location.hash==='#history'){$('#history').open=true;$('#history').scrollIntoView();}
   else if(wasGame){window.scrollTo(0,homeScroll);if(returnGame)document.querySelector('a[data-game="'+returnGame+'"]')?.focus({preventScroll:true});}
   else window.scrollTo(0,0);
  });
 }
}
window.addEventListener('hashchange',route);window.addEventListener('pagehide',()=>{stop();sound.destroy();});
filters();home();route();
// The browser may apply the initial #collection anchor after the module's first frame.
window.addEventListener('load',()=>requestAnimationFrame(()=>{if(!isGame()&&location.hash==='#collection')window.scrollTo(0,0);}),{once:true});
if(new URLSearchParams(location.search).has('qa'))Object.defineProperty(window,'__arcade',{value:Object.freeze({
 snapshot:()=>runtime?.snapshot()||null,resources:()=>({active:runtime?1:0,inputListeners:runtime?.input.listeners||0,raf:runtime?.raf?1:0,hudTimer:hudTimer?1:0,voices:sound.voices.size}),
 saves:()=>JSON.parse(JSON.stringify(store.data)),catalog:()=>GAMES.map(g=>({id:g.id,status:g.status}))
})});
