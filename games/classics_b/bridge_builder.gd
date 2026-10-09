extends "res://microgames/microgame_base.gd"

var island := Rect2(120, 330, 110, 110)
var destination := Rect2()
var builder := Vector2(175, 305)
var plank_length: float = 0.0
var plank_angle: float = -PI * 0.5
var phase: String = 'ready'
var holding: bool = false
var crossings: int = 0
var supported: bool = false
var perfect: bool = false

func setup() -> void:
	island = Rect2(120,330,110,110)
	builder = Vector2(175,305)
	crossings = 0
	new_gap()

func new_gap() -> void:
	destination = Rect2(island.end.x+rng.randf_range(100,220),330,rng.randf_range(65,100),110)
	plank_length = 0
	plank_angle = -PI*0.5
	phase = 'ready'
	holding = false
	supported = false
	perfect = false

func handle_action(action: String, _point: Vector2, _value: Vector2) -> void:
	if finished: return
	if action == 'cancel':
		holding = false
		return
	if action in ['press','action'] and phase in ['ready','growing']:
		phase = 'growing'
		holding = true
	elif action == 'release' and phase == 'growing' and holding:
		holding = false
		phase = 'falling'
		var end_x: float = island.end.x + plank_length
		supported = end_x >= destination.position.x and end_x <= destination.end.x
		perfect = absf(end_x-destination.get_center().x)<12

func tick(delta: float) -> void:
	match phase:
		'growing':
			if holding: plank_length = minf(620,plank_length+(185+difficulty*5)*delta)
		'falling':
			plank_angle = minf(0,plank_angle+4*delta)
			if plank_angle >= 0: phase = 'walking'
		'walking':
			builder.x += 210*delta
			if not supported and builder.x > island.end.x+plank_length:
				phase = 'fall'
			elif supported and builder.x >= destination.get_center().x:
				crossings += 1
				points += 60 + (40 if perfect else 0)
				feedback(builder)
				if crossings == 6:
					win(points)
					return
				var w: float = destination.size.x
				island = Rect2(175-w*0.5,330,w,110)
				builder = Vector2(175,305)
				new_gap()
		'fall':
			builder.y += 350*delta
			if builder.y > 470: lose()

func paint() -> void:
	text_at(Vector2(24,35),'BUILD SIX BRIDGES   '+str(crossings)+'/6',26)
	text_at(Vector2(24,65),'Hold / Space grows the plank. Release when it reaches the roof.',18)
	box(island,BLUE)
	box(destination,GREEN)
	box(Rect2(destination.get_center().x-12,325,24,10),GOLD)
	var pivot := Vector2(island.end.x,330)
	var end := pivot+Vector2(cos(plank_angle),sin(plank_angle))*plank_length
	draw_line(pivot,end,INK,9)
	draw_line(pivot,end,GOLD,4)
	hero(builder-Vector2(0,15),0.5)
	if phase in ['ready','growing']:
		text_at(Vector2(560,180),'HOLD -> RELEASE',28)
		text_at(Vector2(560,216),'Gold center = perfect bonus',19)
	elif phase == 'walking' and perfect: text_at(Vector2(600,180),'PERFECT!',30,GREEN)

