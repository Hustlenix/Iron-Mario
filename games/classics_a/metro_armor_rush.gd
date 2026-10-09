extends ArcadeGame
var lane: int = 1
var jump: float = 0.0
var slide: float = 0.0
var distance: float = 0.0
var spawn: float = 1.3
var obstacles: Array[Dictionary] = []
var coins: Array[Dictionary] = []
var speed: float = 180.0
var collected: int = 0
var lane_bag: Array[int] = []

func configure() -> void:
	lane=1; jump=0; slide=0; distance=0; spawn=1.3; collected=0
	obstacles.clear(); coins.clear(); goal=12; speed=175+12*difficulty
	lane_bag.clear()

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if action=='move': axis=value
	if action=='direction' or action=='swipe':
		if value.x<0: lane=maxi(0,lane-1)
		elif value.x>0: lane=mini(2,lane+1)
		elif value.y<0: jump=0.85
		elif value.y>0: slide=0.85
	if action=='action': jump=0.85
	if action=='press':
		match pressed_button(point):
			0: lane=maxi(0,lane-1)
			1: lane=mini(2,lane+1)
			2: slide=0.85
			3: jump=0.85

func simulate(dt: float) -> void:
	distance+=speed*dt; speed=minf(310,speed+dt*2)
	jump=maxf(0,jump-dt); slide=maxf(0,slide-dt); spawn-=dt
	if spawn<=0:
		spawn=1.25
		# One obstacle at a time always leaves two safe lanes.
		# A seeded lane bag tests every lane once per trio and prevents idle-win
		# seeds where the center lane happens to receive no meaningful threats.
		if lane_bag.is_empty():
			lane_bag.assign([0,1,2])
			for i in range(2,0,-1):
				var other: int = rng.randi_range(0,i)
				var saved: int = lane_bag[i]
				lane_bag[i]=lane_bag[other]; lane_bag[other]=saved
		obstacles.append({'lane':lane_bag.pop_back(),'y':60.0,'kind':rng.randi_range(0,2),'hit':false})
		coins.append({'lane':rng.randi_range(0,2),'y':60.0})
	for o in obstacles:
		o.y+=speed*dt
		if not o.hit and absf(o.y-325)<20:
			o.hit=true
			if o.lane==lane and not (o.kind==1 and jump>0.12) and not (o.kind==2 and slide>0.12): damage(Vector2(240+lane*240,325))
			else: score+=10
	for c in coins:
		c.y+=speed*dt
		if c.lane==lane and absf(c.y-325)<24:
			c.y=600; collected+=1; earn(5,Vector2(240+lane*240,325))
	obstacles=obstacles.filter(func(o: Dictionary)->bool:return o.y<410)
	coins=coins.filter(func(c: Dictionary)->bool:return c.y<410)
	if distance>=6000 and collected>=6: win(score+100)

func paint() -> void:
	hud('METRO ARMOR RUSH / 6000m + 6 CORES'); text_at(Vector2(22,63),'%dm / %d CORES / JUMP LOW, SLIDE HIGH' % [int(distance),collected],20)
	for i in 3:
		box(Rect2(145+i*240,80,190,315),Color('#d9e4e5'))
	for o in obstacles:
		var center := Vector2(240+o.lane*240,o.y)
		box(Rect2(center-Vector2(65,15),Vector2(130,30)),[RED,GOLD,BLUE][o.kind])
		text_at(center+Vector2(-48,-22),['DODGE','JUMP','SLIDE'][o.kind],18)
	for c in coins: disc(Vector2(240+c.lane*240,c.y),12,GOLD)
	hero(Vector2(240+lane*240,310-sin(jump/0.85*PI)*65),0.65 if slide>0 else 0.9)
	buttons(['LEFT','RIGHT','SLIDE','JUMP'])
