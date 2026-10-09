extends "res://microgames/microgame_base.gd"

var jumper := Vector2(480, 360)
var velocity := Vector2.ZERO
var axis: float = 0.0
var camera_y: float = 0.0
var best_height: float = 0.0
var target_height: float = 0.0
var platforms: Array[Dictionary] = []
var landings: int = 0

func setup() -> void:
	jumper = Vector2(480, 360)
	velocity = Vector2(0, -445)
	axis = 0
	camera_y = 0
	best_height = 0
	landings = 0
	target_height = 1050 + difficulty * 65
	platforms.clear()
	var x: float = 480
	for i in 25:
		if i > 0: x = clampf(x + rng.randf_range(-100,100), 150, 810)
		platforms.append({'base_x':x,'x':x,'y':400.0-i*65,'moving':i>2 and i%5==0,'fragile':i>2 and i%4==0,'gone':false})

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if finished: return
	if action == 'cancel': axis = 0
	elif action == 'move': axis = value.x
	elif action in ['press','drag']: axis = -1 if point.x < 480 else 1
	elif action == 'release': axis = 0

func tick(delta: float) -> void:
	for p in platforms:
		p.x = p.base_x + (sin(elapsed * 1.25) * 32 if p.moving else 0)
	var steps: int = maxi(1, int(ceil(delta / 0.008)))
	for _i in steps:
		var dt: float = delta / steps
		var previous_y: float = jumper.y
		velocity.x = move_toward(velocity.x, axis * 265, 2200 * dt)
		velocity.y += 1000 * dt
		jumper += velocity * dt
		jumper.x = clampf(jumper.x, 20, 940)
		if velocity.y > 0:
			for p in platforms:
				if not p.gone and previous_y + 14 <= p.y and jumper.y + 14 >= p.y and absf(jumper.x - p.x) < 68:
					jumper.y = p.y - 14
					velocity.y = -445
					landings += 1
					if p.fragile: p.gone = true
					feedback(Vector2(jumper.x, jumper.y - camera_y))
					break
		best_height = maxf(best_height, 400 - jumper.y)
		camera_y = minf(camera_y, jumper.y - 190)
		points = int(best_height / 5)
		if best_height >= target_height:
			win(points + 100)
			return
		if jumper.y - camera_y > 475:
			lose()
			return

func paint() -> void:
	text_at(Vector2(20,35), 'CLIMB ' + str(int(best_height)) + ' / ' + str(int(target_height)) + 'm', 25)
	text_at(Vector2(20,65), 'Arrows / hold screen halves. Blue moves; red crumbles.', 19)
	for p in platforms:
		var y: float = p.y - camera_y
		if p.gone or y < 75 or y > 460: continue
		box(Rect2(p.x-62,y,124,13), RED if p.fragile else (BLUE if p.moving else GREEN))
		if p.fragile: text_at(Vector2(p.x-10,y+5),'!',18)
	hero(Vector2(jumper.x,jumper.y-camera_y-23),0.5)
	draw_line(Vector2(480, 425), Vector2(480, 475), Color(INK,0.3), 2)
	text_at(Vector2(30,465), '< LEFT',22)
	text_at(Vector2(800,465),'RIGHT >',22)

