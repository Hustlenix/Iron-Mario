extends ArcadeGame
var y: float = 240.0
var vy: float = 0.0
var distance: float = 0.0
var spawn: float = 1.6
var hazards: Array[Dictionary] = []
var coins: Array[Vector2] = []
var immunity: float = 0.0
var speed: float = 180.0
var floor_time: float = 0.0

func configure() -> void:
	y=240; vy=0; distance=0; spawn=1.6; immunity=0; floor_time=0; hazards.clear(); coins.clear(); health=3; speed=180+10*difficulty

func handle_action(action: String, _point: Vector2, _value: Vector2) -> void:
	if action in ['press','action']: held=true
	elif action=='release': held=false

func simulate(dt: float) -> void:
	vy=clampf(vy+( -780 if held else 520)*dt,-260,280)
	y=clampf(y+vy*dt,95,365)
	if y in [95.0,365.0]: vy=0
	floor_time=floor_time+dt if y>=364 else 0
	if floor_time>1.5:
		damage(Vector2(180,y)); floor_time=0
	distance+=speed*dt; immunity=maxf(0,immunity-dt); spawn-=dt
	if spawn<=0:
		spawn=1.55
		var center: float = rng.randf_range(130,310)
		hazards.append({'x':960.0,'y':center,'warn':0.6,'missile':rng.randf()<0.4})
		for i in 4: coins.append(Vector2(920+i*36,95 if center>220 else 365))
	for h in hazards:
		h.warn=maxf(0,h.warn-dt); h.x-=speed*dt*(1.3 if h.missile else 1)
		if immunity<=0 and absf(h.x-180)<32 and absf(h.y-y)<(25 if h.missile else 45):
			damage(Vector2(180,y)); immunity=1
	for i in range(coins.size()-1,-1,-1):
		coins[i].x-=speed*dt
		if coins[i].distance_to(Vector2(180,y))<34: earn(5,coins[i]); coins.remove_at(i)
		elif coins[i].x<0: coins.remove_at(i)
	hazards=hazards.filter(func(h:Dictionary)->bool:return h.x>-60)
	if distance>3000: win(score+150)

func paint() -> void:
	hud('JETPACK TEST LAB / HOLD TO FLY, RELEASE TO FALL')
	text_at(Vector2(22,63),'%dm / 3000m' % int(distance),23)
	box(Rect2(10,75,940,315),Color('#e3eef1'))
	draw_line(Vector2(10,388),Vector2(950,388),RED,7)
	text_at(Vector2(350,383),'HOT FLOOR: KEEP MOVING',16,RED)
	for h in hazards:
		box(Rect2(h.x-15,h.y-20,30,40 if h.missile else 75),RED)
		if h.warn>0: text_at(Vector2(840,h.y),'!',36,RED)
	for c in coins: disc(c,10,GOLD)
	hero(Vector2(180,y),0.8)
	if held: draw_line(Vector2(158,y+10),Vector2(115,y+30),GOLD,12)
	box(Rect2(280,410,400,55),GOLD); text_at(Vector2(325,446),'HOLD / SPACE TO BOOST',25)
