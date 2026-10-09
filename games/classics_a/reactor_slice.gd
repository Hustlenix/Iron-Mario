extends ArcadeGame
var fruit: Array[Dictionary] = []
var spawn: float = 0.4
var last_point := Vector2.ZERO
var slicing: bool = false
var combo: int = 0
var sliced: int = 0
var missed: int = 0
var wave: int = 0

func configure() -> void:
	fruit.clear(); spawn=0.4; slicing=false; combo=0; sliced=0; missed=0; wave=0; health=3; goal=18

func handle_action(action: String, point: Vector2, _value: Vector2) -> void:
	if action=='cancel': slicing=false; return
	if action=='press': last_point=point; slicing=true; combo=0
	elif action=='drag' and slicing:
		for f in fruit:
			if not f.cut and segment_distance(f.pos,last_point,point)<f.radius+5:
				f.cut=true
				if f.bomb: damage(f.pos); combo=0
				else:
					combo+=1; sliced+=1; earn(10+mini(combo,5)*3,f.pos)
		last_point=point
		if sliced>=goal: win(score+100)
	elif action=='release': slicing=false

func simulate(dt: float) -> void:
	spawn-=dt
	if spawn<=0:
		spawn=0.8; wave+=1
		for i in 2:
			var x: float = rng.randf_range(180,780)
			fruit.append({'pos':Vector2(x,395),'v':Vector2((480-x)*0.28,-370-rng.randf()*60),'radius':25.0,'bomb':i==1 and wave%3==0,'cut':false})
	for f in fruit:
		f.v.y+=460*dt; f.pos+=f.v*dt
		if not f.cut and f.pos.y>410 and f.v.y>0:
			f.cut=true
			if not f.bomb: missed+=1; damage(Vector2(f.pos.x,380))
	fruit=fruit.filter(func(f:Dictionary)->bool:return not f.cut and f.pos.y<430)

func paint() -> void:
	hud('REACTOR SLICE / DRAG THROUGH FRUIT, AVOID BOMBS')
	text_at(Vector2(22,63),'SLICED %d / %d / COMBO %d' % [sliced,goal,combo],23)
	for f in fruit:
		disc(f.pos,f.radius,INK if f.bomb else RED)
		text_at(f.pos+Vector2(-8,8),'!' if f.bomb else '+',23,PAPER)
	if slicing: disc(last_point,8,GOLD)
	text_at(Vector2(200,448),'KEYBOARD: HOLD SPACE, MOVE CROSSHAIR, RELEASE',22)
