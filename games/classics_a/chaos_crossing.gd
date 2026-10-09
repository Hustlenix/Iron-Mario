extends ArcadeGame
var row: int = 0
var x: float = 480.0
var crossings: int = 0
var cooldown: float = 0.0
var clock: float = 0.0
var hazards: Array[Dictionary] = []
var invulnerability: float = 0.0

func configure() -> void:
	row=0; x=480; crossings=0; cooldown=0; clock=0; invulnerability=0; health=3; setup_lanes()

func setup_lanes() -> void:
	hazards.clear()
	for r in [2,3,4,5,7,8]:
		hazards.append({'row':r,'offset':rng.randf_range(0,500),'speed':(50+r*7)*(1 if r%2==0 else -1),'water':r in [4,5]})

func lane_centers(lane: Dictionary) -> Array[float]:
	var result: Array[float] = []
	for i in 4: result.append(fposmod(lane.offset+clock*lane.speed+i*310,1240)-140)
	return result

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	var d := Vector2.ZERO
	if action in ['direction','swipe']: d=value.normalized()
	elif action=='action': d=Vector2.UP
	elif action=='press':
		var b: int = pressed_button(point)
		if b>=0: d=[Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN,Vector2.UP][b]
	if cooldown>0 or d==Vector2.ZERO: return
	cooldown=0.16
	if absf(d.x)>absf(d.y): x=clampf(x+signf(d.x)*70,70,890)
	else: row=clampi(row-int(signf(d.y)),0,9)
	if row==9:
		crossings+=1; earn(100,Vector2(x,100)); row=0; x=480; clock=0; invulnerability=0.3; setup_lanes()
		if crossings>=3: win(score)

func simulate(dt: float) -> void:
	clock+=dt; cooldown=maxf(0,cooldown-dt); invulnerability=maxf(0,invulnerability-dt)
	for lane in hazards:
		if lane.row!=row or invulnerability>0: continue
		var aboard: bool = false
		for center in lane_centers(lane):
			if absf(x-center)<(90 if lane.water else 42): aboard=true
		if lane.water and aboard: x+=lane.speed*dt
		if (lane.water and (not aboard or x<45 or x>915)) or (not lane.water and aboard):
			damage(Vector2(x,380-row*30)); row=0; x=480; invulnerability=0.8

func paint() -> void:
	hud('CHAOS CROSSING / THREE SAFE CROSSINGS')
	text_at(Vector2(22,60),'%d / 3 / CARS HURT; RIDE THE WOODEN LOGS' % crossings,22)
	for r in 10:
		box(Rect2(35,339-r*27,890,26),GREEN if r in [0,1,6,9] else (BLUE if r in [4,5] else Color('#d8d7d4')))
	for lane in hazards:
		for center in lane_centers(lane):
			box(Rect2(center-(90 if lane.water else 35),344-lane.row*27,180 if lane.water else 70,20),Color('#be8c59') if lane.water else RED)
	hero(Vector2(x,350-row*27),0.36)
	buttons(['LEFT','RIGHT','BACK','HOP'])
