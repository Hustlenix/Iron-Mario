extends "res://microgames/microgame_base.gd"

var flyer := Vector2(170, 240)
var vertical_speed: float = 0.0
var travel: float = 0.0
var speed: float = 185.0
var gates: Array[Dictionary] = []
var cleared: int = 0
var cells: int = 0
var shield: bool = false
var invulnerability: float = 0.0
var last_flap: float = -1

func setup() -> void:
	flyer = Vector2(170,240)
	vertical_speed = 0
	travel = 0
	speed = 175 + difficulty * 8
	cleared = 0
	cells = 0
	shield = false
	invulnerability = 0
	last_flap = -1
	gates.clear()
	for i in 12:
		gates.append({'base_x':700.0+i*330,'x':700.0+i*330,'base_y':235.0+sin(i*1.8)*60,'y':235.0+sin(i*1.8)*60,'moving':i>2 and i%3==0,'gap':170.0-difficulty*5,'passed':false,'cell':false})

func handle_action(action: String, _point: Vector2, _value: Vector2) -> void:
	if finished: return
	if action in ['action','press'] and elapsed - last_flap > 0.12:
		vertical_speed = -245
		last_flap = elapsed
		feedback(flyer)

func hit() -> void:
	if invulnerability > 0: return
	if shield:
		shield = false
		invulnerability = 1.2
		feedback(flyer,false)
	else:
		lose()

func tick(delta: float) -> void:
	var steps: int = maxi(1,int(ceil(delta/0.008)))
	for _i in steps:
		var dt: float = delta / steps
		invulnerability = maxf(0, invulnerability - dt)
		travel += speed * dt
		# Wind begins after training gates; visual windsock uses the same force.
		var gravity: float = 650 + (sin(elapsed*1.6)*85 if cleared>2 else 0)
		vertical_speed += gravity * dt
		flyer.y += vertical_speed * dt
		if flyer.y < 87 or flyer.y > 442:
			hit()
			flyer.y = clampf(flyer.y,90,440)
		if finished: return
		for g in gates:
			g.x = g.base_x - travel
			g.y = g.base_y + (sin(elapsed*1.3)*18 if g.moving else 0)
			if absf(g.x-flyer.x)<38 and (flyer.y-13<g.y-g.gap*0.5 or flyer.y+13>g.y+g.gap*0.5): hit()
			if not g.cell and flyer.distance_to(Vector2(g.x,g.y+25))<30:
				g.cell = true
				cells += 1
				points += 20
				if cells % 3 == 0: shield = true
				feedback(flyer)
			if not g.passed and g.x+35<flyer.x-14:
				g.passed = true
				cleared += 1
				points += 30
		if finished: return
		if cleared == 12:
			win(points+100)
			return

func paint() -> void:
	text_at(Vector2(20,35),'FLAP QUEST  '+str(cleared)+'/12  CELLS '+str(cells),25)
	text_at(Vector2(20,64),'Tap / Space. Three cells earn a shield. Moving gates + wind!',18)
	for g in gates:
		if g.x < -60 or g.x > 1020: continue
		box(Rect2(g.x-23,80,46,maxf(0,g.y-g.gap*0.5-80)),BLUE)
		box(Rect2(g.x-23,g.y+g.gap*0.5,46,450-g.y-g.gap*0.5),BLUE)
		if not g.cell: disc(Vector2(g.x,g.y+25),10,GOLD)
	hero(flyer-Vector2(0,16),0.48)
	if shield: draw_arc(flyer,28,0,TAU,24,GREEN,4)
	text_at(Vector2(735,35),'SHIELD' if shield else 'NO SHIELD',21)
	draw_line(Vector2(895,58),Vector2(925,58+sin(elapsed*1.6)*13),RED,5)
