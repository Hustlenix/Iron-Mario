extends ArcadeGame
var anchor := Vector2(170,315)
var aim := Vector2(170,315)
var pulling: bool = false
var balls: Array[Dictionary] = []
var blocks: Array[Dictionary] = []
var targets: Array[Dictionary] = []
var ammo: int = 5
var settle: float = 0.0
var destroyed: int = 0

func configure() -> void:
	ammo=5; settle=0; pulling=false; destroyed=0; health=1; balls.clear(); blocks.clear(); targets.clear(); aim=anchor
	for tower in 2:
		var x: float = 650+tower*150
		for level in 3:
			blocks.append({'pos':Vector2(x,355-level*36),'v':Vector2.ZERO,'hp':1.0,'alive':true})
		targets.append({'pos':Vector2(x,235),'v':Vector2.ZERO,'alive':true})

func handle_action(action: String, point: Vector2, _value: Vector2) -> void:
	if action=='cancel': pulling=false; aim=anchor; return
	if action=='press' and point.distance_to(anchor)<110 and ammo>0: pulling=true; aim=point
	elif action=='drag' and pulling: aim=anchor+(point-anchor).limit_length(100)
	elif action=='release' and pulling:
		pulling=false
		if anchor.distance_to(aim)<12: return
		balls.append({'pos':anchor,'v':(anchor-aim)*7.5,'age':0.0})
		ammo-=1; settle=0; aim=anchor

func supported_y(object: Dictionary, radius: float) -> float:
	var floor_y: float = 380-radius
	for b in blocks:
		if b==object or not b.alive: continue
		if absf(object.pos.x-b.pos.x)<27 and b.pos.y>object.pos.y+10:
			floor_y=minf(floor_y,b.pos.y-18-radius)
	return floor_y

func simulate(dt: float) -> void:
	settle+=dt
	for b in blocks:
		if not b.alive: continue
		b.v.y+=550*dt; b.pos+=b.v*dt
		var floor_y: float = supported_y(b,18)
		if b.pos.y>floor_y: b.pos.y=floor_y; b.v.y=0; b.v.x*=0.9
	for t in targets:
		if not t.alive: continue
		t.v.y+=550*dt; t.pos+=t.v*dt
		var floor_y: float = supported_y(t,18)
		if t.pos.y>floor_y:
			if t.v.y>160: t.alive=false; destroyed+=1; earn(100,t.pos)
			t.pos.y=floor_y; t.v.y=0
	for ball in balls:
		ball.age+=dt; ball.v.y+=500*dt; ball.pos+=ball.v*dt
		for b in blocks:
			if b.alive and Rect2(b.pos-Vector2(25,26),Vector2(50,52)).has_point(ball.pos):
				if ball.v.length()>120:
					b.alive=false; earn(15,b.pos); ball.v*=0.75
		for t in targets:
			if t.alive and t.pos.distance_to(ball.pos)<30:
				t.alive=false; destroyed+=1; earn(100,t.pos); ball.v*=0.6
		if ball.pos.y>365: ball.pos.y=365; ball.v.y=-absf(ball.v.y)*0.35; ball.v.x*=0.7
	balls=balls.filter(func(b:Dictionary)->bool:return b.age<5 and b.pos.x<1000 and b.pos.x>-50)
	if destroyed>=targets.size(): win(score+100)
	elif ammo==0 and balls.is_empty() and settle>4: lose()

func paint() -> void:
	hud('CATAPULT CHAOS / TOPPLE BOTH REACTORS')
	text_at(Vector2(22,64),'%d SHOTS / %d OF 2 TARGETS / PULL LEFT-DOWN, RELEASE' % [ammo,destroyed],20)
	draw_line(Vector2(30,382),Vector2(930,382),INK,5)
	box(Rect2(anchor.x-8,anchor.y,16,66),Color('#ba8758'))
	draw_line(anchor,aim,INK,6); disc(aim,15,RED)
	if pulling:
		var v := (anchor-aim)*7.5
		for i in 10:
			var t: float = i*0.08
			disc(anchor+v*t+Vector2(0,250*t*t),3,BLUE)
	for b in blocks:
		if b.alive: box(Rect2(b.pos-Vector2(20,18),Vector2(40,36)),GOLD)
	for t in targets:
		if t.alive: disc(t.pos,18,GREEN)
	for b in balls: disc(b.pos,14,RED)
	text_at(Vector2(150,448),'DRAG THE RED BALL / ARROWS + HOLD SPACE',24)
