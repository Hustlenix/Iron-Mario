extends ArcadeGame
## Eleven separate loops sharing only presentation and input helpers.
var game: String = ''
var s: Dictionary = {}
var room: Texture2D

func configure() -> void:
	game=spec.id
	s={'p':Vector2(480,250),'v':Vector2.ZERO,'n':0,'clock':0.0,'deadline':1.0,'items':[],'answer':0,'reverse':false,'cooldown':0.0}
	match game:
		'brainrot_button_panic': next_prompt()
		'meme_dodge_arena': s.dash=0.0; s.spawn=0.7; s.cooldown=0.0
		'one_pixel_survival': s.p=Vector2(480,330); s.spawn=0.5
		'impossible_parking': s.p=Vector2(190,280); s.angle=0.0; s.speed=0.0; s.throttle=0.0; s.steer=0.0; s.park_time=0.0
		'reaction_relay': s.deadline=rng.randf_range(0.8,1.8); s.reactions=[]; s.go=false
		'chaos_elevator': s.floor=0.0; s.target=0; s.onboard=-1; s.guests=[{'floor':0,'dest':3},{'floor':2,'dest':0},{'floor':1,'dest':2}]; s.done=0
		'dont_press_red': next_light()
		'fall_forever': s.p=Vector2(480,190); s.spawn=0.5; s.depth=0.0
		'physics_disaster': s.p=Vector2(270,115); s.v=Vector2.ZERO; s.cut=false; s.ball=Vector2(530,290); s.ball_v=Vector2.ZERO; s.support=0
		'paint_frontier':
			s.cell=Vector2i(3,3); s.direction=Vector2i.RIGHT; s.trail=[]; s.owned=[]; s.enemy=Vector2i(9,3); s.clock=0.0
			for x in range(2,5):
				for y in range(2,5): s.owned.append(Vector2i(x,y))
		'notebook_platformer':
			s.p=Vector2(100,330); s.v=Vector2.ZERO; s.grounded=true; s.coyote=0.12; s.core=false
	if game in ['impossible_parking','chaos_elevator'] and ResourceLoader.exists('res://assets/rooms/reactor_garage.png'):
		room=load('res://assets/rooms/reactor_garage.png')

func next_prompt() -> void:
	s.answer=rng.randi_range(0,3); s.reverse=rng.randf()<0.4; s.clock=0; s.deadline=maxf(0.55,1.65-s.n*0.08)

func next_light() -> void:
	s.green=(s.n%3!=1); s.clock=0; s.tapped=false; s.deadline=maxf(0.6,1.2-s.n*0.04)

func pad(index: int) -> Vector2:
	return Vector2(170+index*205,280)

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if action=='cancel':
		held=false; axis=Vector2.ZERO
		if game=='impossible_parking': s.throttle=0.0; s.steer=0.0
		return
	if action=='move': axis=value
	if action=='release': held=false
	match game:
		'brainrot_button_panic':
			var choice: int = -1
			if action=='press':
				for i in 4:
					if point.distance_to(pad(i))<70: choice=i
			if action=='direction': choice=[Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT].find(value)
			if action=='select': choice=int(value.x)-1
			if choice<0: return
			if choice==((s.answer+2)%4 if s.reverse else s.answer): s.n+=1; earn(15,pad(choice))
			else: damage(pad(choice))
			next_prompt()
			if s.n>=12: win(score)
		'meme_dodge_arena':
			if action in ['drag','press'] and point.y<395: s.p=point.clamp(Vector2(45,90),Vector2(915,375))
			if action=='action' and s.cooldown<=0: s.dash=0.24; s.cooldown=1.5
		'one_pixel_survival':
			if action in ['drag','press']: s.p=point.clamp(Vector2(40,85),Vector2(920,390))
		'impossible_parking':
			if action=='move': s.throttle=-value.y; s.steer=value.x
			if action=='action': s.speed*=0.1
			if action=='press':
				match pressed_button(point):
					0: s.steer=-1
					1: s.steer=1
					2: s.throttle=-1
					3: s.throttle=1
			if action=='release':
				var button: int = pressed_button(point)
				if button in [0,1]: s.steer=0
				elif button in [2,3]: s.throttle=0
				else: s.throttle=0; s.steer=0
		'reaction_relay':
			if action in ['press','action']:
				if not s.go: damage(Vector2(480,230)); s.clock=0; return
				s.reactions.append(maxf(0,s.clock-s.deadline)); s.n+=1; earn(20,Vector2(480,230)); s.clock=0; s.go=false; s.deadline=rng.randf_range(0.8,1.8)
				if s.n>=8: win(score+int(100*(1.0-s.reactions.reduce(func(a:float,b:float)->float:return a+b,0.0)/8)))
		'chaos_elevator':
			if action=='select': s.target=clampi(int(value.x)-1,0,3)
			if action=='direction': s.target=clampi(s.target-int(signf(value.y)),0,3)
			if action=='press':
				var b: int = pressed_button(point)
				if b>=0: s.target=b
		'dont_press_red':
			if action in ['press','action'] and not s.tapped:
				s.tapped=true
				if s.green: earn(20,Vector2(480,230))
				else: damage(Vector2(480,230))
		'fall_forever':
			if action in ['drag','press'] and point.y<400: s.p.x=clampf(point.x,50,910)
			if action in ['press','action']: held=true
		'physics_disaster':
			var b: int = -1
			if action=='press':
				for i in 3:
					if point.distance_to(Vector2(270+i*210,155))<65: b=i
			if action=='select': b=int(value.x)-1
			if b>=0 and not s.cut: s.cut=true; s.support=b; s.v=Vector2(280 if b==1 else (-180 if b==0 else 420),0)
		'paint_frontier':
			var d := Vector2.ZERO
			if action in ['direction','swipe']: d=value
			if action=='press':
				var b: int = pressed_button(point)
				if b>=0: d=[Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN,Vector2.UP][b]
			if d!=Vector2.ZERO: s.direction=Vector2i(signi(int(d.x)),0) if absf(d.x)>absf(d.y) else Vector2i(0,signi(int(d.y)))
		'notebook_platformer':
			if action=='action' or (action=='direction' and value.y<0): jump()
			if action=='press':
				match pressed_button(point,3):
					0: axis=Vector2.LEFT
					1: axis=Vector2.RIGHT
					2: jump()
			if action=='release': axis=Vector2.ZERO; s.v.y=maxf(s.v.y,-160)

func jump() -> void:
	if s.coyote>0: s.v.y=-330; s.coyote=0; s.grounded=false

func simulate(dt: float) -> void:
	s.clock+=dt
	match game:
		'brainrot_button_panic':
			if s.clock>s.deadline: damage(Vector2(480,150)); next_prompt()
		'meme_dodge_arena':
			s.p=(s.p+axis*280*dt).clamp(Vector2(45,85),Vector2(915,380)); s.spawn-=dt; s.dash=maxf(0,s.dash-dt); s.cooldown=maxf(0,s.cooldown-dt)
			if s.spawn<=0:
				s.spawn=0.6; s.items.append({'pos':s.p+Vector2(rng.randf_range(-70,70),rng.randf_range(-40,40)),'t':0.8,'hit':false})
			for item in s.items:
				item.t-=dt
				if item.t<=0 and not item.hit:
					item.hit=true; s.n+=1
					if item.pos.distance_to(s.p)<52 and s.dash<=0: damage(s.p)
					else: score+=10
				s.items=s.items.filter(func(o:Dictionary)->bool:return o.t>-0.18)
			if s.n>=25: win(score)
		'one_pixel_survival':
			s.p=(s.p+axis*210*dt).clamp(Vector2(40,85),Vector2(920,390)); s.spawn-=dt
			if s.spawn<=0:
				s.spawn=1.25; s.items.append({'y':85.0,'gap':rng.randf_range(180,780),'hit':false})
			for item in s.items:
				item.y+=130*dt
				if absf(item.y-s.p.y)<8 and absf(item.gap-s.p.x)>60: damage(s.p); item.hit=true; item.y=600
				if item.y>395 and not item.hit: item.hit=true; s.n+=1; score+=20
				s.items=s.items.filter(func(o:Dictionary)->bool:return o.y<500)
			if s.n>=12: win(score)
		'impossible_parking':
			s.speed=clampf(s.speed+s.throttle*95*dt-s.speed*dt*0.8,-80,130)
			s.angle+=s.steer*s.speed/90*dt
			var old: Vector2 = s.p
			s.p+=Vector2.from_angle(s.angle)*s.speed*dt
			var obstacles: Array[Rect2] = [Rect2(350,85,55,145),Rect2(510,250,160,45)]
			var collision: bool = s.p.x<55 or s.p.x>910 or s.p.y<100 or s.p.y>370
			for obstacle in obstacles:
				if obstacle.grow(25).has_point(s.p): collision=true
			if collision: s.p=old; s.speed=-s.speed*0.25; damage(s.p); s.throttle=0
			if Rect2(740,290,130,80).has_point(s.p) and absf(s.speed)<15 and absf(wrapf(s.angle,-PI,PI))<0.2: s.park_time+=dt
			else: s.park_time=0
			if s.park_time>0.8: win(200+int(duration-elapsed))
		'reaction_relay':
			s.go=s.clock>=s.deadline
			if s.clock>s.deadline+0.8: damage(Vector2(480,230)); s.clock=0; s.go=false
		'chaos_elevator':
			s.floor=move_toward(s.floor,s.target,dt*1.3)
			if absf(s.floor-s.target)<0.01:
				if s.onboard>=0 and s.guests[s.onboard].dest==s.target:
					s.guests[s.onboard].floor=-1; s.done+=1; s.onboard=-1; earn(70,Vector2(480,230))
				if s.onboard<0:
					for i in s.guests.size():
						if s.guests[i].floor==s.target: s.onboard=i; break
			if s.done==3: win(score)
		'dont_press_red':
			if s.clock>s.deadline:
				if s.green and not s.tapped: damage(Vector2(480,230))
				elif not s.green and not s.tapped: score+=20
				s.n+=1; next_light()
				if s.n>=8 and not finished: win(score)
		'fall_forever':
			s.p.x=clampf(s.p.x+axis.x*320*dt,50,910); s.spawn-=dt
			var speed: float = 100 if held else 190
			s.depth+=speed*dt
			if s.spawn<=0: s.spawn=1.25; s.items.append({'y':395.0,'gap':rng.randf_range(150,810),'passed':false})
			for item in s.items:
				item.y-=speed*dt
				if not item.passed and item.y<s.p.y+14:
					item.passed=true
					if absf(s.p.x-item.gap)>70: damage(s.p)
					else: s.n+=1; score+=20
				s.items=s.items.filter(func(o:Dictionary)->bool:return o.y>65)
			if s.n>=15: win(score)
		'physics_disaster':
			if s.cut:
				s.v.y+=400*dt; s.p+=s.v*dt
				if s.p.distance_to(s.ball)<40 and s.ball_v.length()<1: s.ball_v=Vector2(280,-180); earn(30,s.ball)
				if s.p.distance_to(Vector2(810,340))<35: lose()
				if s.p.y>380: s.p.y=380; s.v=Vector2.ZERO
				if s.ball_v.length()>0:
					s.ball_v.y+=400*dt; s.ball+=s.ball_v*dt
					if s.ball.distance_to(Vector2(710,260))<40: win(150)
					if s.ball.y>390: lose()
		'paint_frontier':
			if s.clock>=0.2:
				s.clock=0; frontier_step()
		'notebook_platformer': platform_step(dt)

func frontier_step() -> void:
	s.cell+=s.direction
	if s.cell.x<0 or s.cell.x>=12 or s.cell.y<0 or s.cell.y>=6: lose(); return
	if s.trail.has(s.cell): lose(); return
	if s.owned.has(s.cell):
		if not s.trail.is_empty():
			# Flood-fill exterior space; only a closed trail captures its interior.
			var exterior: Array[Vector2i] = []
			var queue: Array[Vector2i] = []
			for x in 12:
				queue.append(Vector2i(x,0)); queue.append(Vector2i(x,5))
			for y in 6:
				queue.append(Vector2i(0,y)); queue.append(Vector2i(11,y))
			while not queue.is_empty():
				var cell: Vector2i = queue.pop_front()
				if cell.x<0 or cell.x>=12 or cell.y<0 or cell.y>=6 or exterior.has(cell) or s.owned.has(cell) or s.trail.has(cell): continue
				exterior.append(cell)
				for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]: queue.append(cell+d)
			for x in 12:
				for y in 6:
					var cell := Vector2i(x,y)
					if not exterior.has(cell) and not s.owned.has(cell): s.owned.append(cell)
			score+=s.trail.size()*10; s.trail.clear()
	else: s.trail.append(s.cell)
	s.enemy.x=8+int(elapsed*3)%3
	if s.trail.has(s.enemy): lose()
	if s.owned.size()>=20: win(score+100)

func platform_step(dt: float) -> void:
	var previous: Vector2 = s.p
	s.v.x=move_toward(s.v.x,axis.x*205,1000*dt); s.v.y+=650*dt
	s.p+=s.v*dt; s.p.x=clampf(s.p.x,40,920); s.grounded=false
	for platform in platform_rects():
		if s.v.y>=0 and previous.y+24<=platform.position.y+3 and s.p.y+24>=platform.position.y and s.p.x>platform.position.x-10 and s.p.x<platform.end.x+10:
			s.p.y=platform.position.y-24; s.v.y=0; s.grounded=true; s.coyote=0.1
	if not s.grounded: s.coyote=maxf(0,s.coyote-dt)
	if s.p.y>425: lose()
	if s.p.distance_to(Vector2(570,185))<40 and not s.core: s.core=true; earn(50,s.p)
	if s.core and s.p.x>865 and s.p.y<320: win(score+150)

func platform_rects() -> Array[Rect2]:
	return [Rect2(30,360,220,30),Rect2(270,300,180,25),Rect2(480,245,180,25),Rect2(690,300,230,25)]

func paint() -> void:
	if room!=null and game in ['impossible_parking','chaos_elevator']: draw_texture_rect(room,Rect2(30,75,900,320),false)
	hud(spec.name.to_upper())
	match game:
		'brainrot_button_panic':
			text_at(Vector2(270,140),('OPPOSITE OF ' if s.reverse else 'PRESS ')+['UP','RIGHT','DOWN','LEFT'][s.answer],34)
			for i in 4: disc(pad(i),65,[RED,BLUE,GREEN,GOLD][i]); text_at(pad(i)+Vector2(-40,8),['UP','RIGHT','DOWN','LEFT'][i],22)
			text_at(Vector2(350,445),'%d / 12 CORRECT' % s.n,25)
		'meme_dodge_arena':
			for item in s.items:
				draw_circle(item.pos,52,RED if item.t<=0 else GOLD,false,5)
				text_at(item.pos+Vector2(-25,8),'TOAST',15)
			hero(s.p,0.5); text_at(Vector2(180,445),'SPACE DASH / %d OF 25 WAVES' % s.n,25)
		'one_pixel_survival':
			for item in s.items:
				draw_line(Vector2(35,item.y),Vector2(item.gap-70,item.y),RED,8)
				draw_line(Vector2(item.gap+70,item.y),Vector2(925,item.y),RED,8)
			disc(s.p,7,BLUE); text_at(Vector2(270,445),'%d / 12 LASERS PASSED' % s.n,25)
		'impossible_parking':
			box(Rect2(350,85,55,145),INK); box(Rect2(510,250,160,45),INK); draw_rect(Rect2(740,290,130,80),GREEN,false,5)
			text_at(Vector2(748,282),'PARK >',25,GREEN)
			draw_set_transform(s.p,s.angle); box(Rect2(-32,-18,64,36),GOLD); draw_line(Vector2(0,0),Vector2(32,0),RED,5); draw_set_transform(Vector2.ZERO)
			buttons(['STEER LEFT','STEER RIGHT','REVERSE','GAS'])
		'reaction_relay':
			disc(Vector2(480,230),110,GREEN if s.go else RED); text_at(Vector2(435,240),'GO!' if s.go else 'WAIT',38)
			text_at(Vector2(240,435),'%d / 8 / EARLY TAPS COST A HEART' % s.n,24)
			if not s.reactions.is_empty(): text_at(Vector2(360,370),'LAST: %.0f ms' % (s.reactions.back()*1000),25)
		'chaos_elevator':
			for floor_index in 4:
				var y: float = 340-floor_index*70
				draw_line(Vector2(120,y),Vector2(800,y),INK,3); text_at(Vector2(120,y-10),'FLOOR %d' % (floor_index+1),22)
				for i in s.guests.size():
					if s.guests[i].floor==floor_index and s.onboard!=i: text_at(Vector2(630+i*45,y-12),str(s.guests[i].dest+1),32,RED)
			box(Rect2(385,285-s.floor*70,135,55),GOLD)
			if s.onboard>=0: text_at(Vector2(415,321-s.floor*70),'TO '+str(s.guests[s.onboard].dest+1),25)
			buttons(['FLOOR 1','FLOOR 2','FLOOR 3','FLOOR 4'])
		'dont_press_red':
			disc(Vector2(480,235),105,GREEN if s.green else RED); text_at(Vector2(420,245),'TAP' if s.green else 'WAIT',38)
			text_at(Vector2(280,438),'%d / 8 / THE COLORS NEVER LIE' % s.n,24)
		'fall_forever':
			for item in s.items:
				box(Rect2(35,item.y,item.gap-115,18),RED); box(Rect2(item.gap+80,item.y,845-item.gap,18),RED)
			hero(s.p,0.55); text_at(Vector2(200,443),'%d / 15 GAPS / SPACE BRAKES DESCENT' % s.n,24)
		'physics_disaster':
			for i in 3: draw_line(Vector2(270+i*210,75),Vector2(270+i*210,155),INK,7); text_at(Vector2(260+i*210,60),str(i+1),25)
			disc(s.p,25,GOLD); disc(s.ball,18,BLUE); disc(Vector2(710,260),30,GREEN); disc(Vector2(810,340),30,INK)
			text_at(Vector2(665,220),'BELL',22); text_at(Vector2(770,390),'BOMB',22)
			text_at(Vector2(180,445),'CUT SUPPORT 1, 2 OR 3 / ONE CHAIN REACTION',23)
		'paint_frontier':
			for x in 12:
				for y in 6:
					var cell := Vector2i(x,y)
					box(Rect2(150+x*55,65+y*55,53,53),BLUE if s.owned.has(cell) else (GOLD if s.trail.has(cell) else PAPER))
				disc(Vector2(177+s.cell.x*55,92+s.cell.y*55),12,GREEN); disc(Vector2(177+s.enemy.x*55,92+s.enemy.y*55),17,RED)
			text_at(Vector2(160,398),'%d / 20 CLAIMED / ERASER CUTS EXPOSED TRAILS' % s.owned.size(),20)
			buttons(['LEFT','RIGHT','DOWN','UP'])
		'notebook_platformer':
			for platform in platform_rects(): box(platform,Color('#9fcebb'))
			if not s.core: disc(Vector2(570,185),16,GOLD)
			box(Rect2(865,255,50,45),GREEN if s.core else INK); text_at(Vector2(860,240),'EXIT',23)
			hero(s.p,0.46); buttons(['LEFT','RIGHT','JUMP'])
