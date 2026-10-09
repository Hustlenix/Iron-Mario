extends "res://microgames/microgame_base.gd"

var anchor := Vector2.ZERO
var battery := Vector2.ZERO
var velocity := Vector2.ZERO
var receiver := Rect2()
var rope_length: float = 200.0
var angle: float = -1.0
var angular_velocity: float = 0.0
var attached: bool = true
var brace_attached: bool = false
var brace_anchor := Vector2.ZERO
var active_rope: int = 0
var stage: int = 0
var lives: int = 3
var deliveries: int = 0
var spark_taken: bool = false
var spark := Vector2.ZERO

func setup() -> void:
	stage = 0
	lives = 3
	deliveries = 0
	new_puzzle()

func new_puzzle() -> void:
	anchor = Vector2(430 + stage * 20, 65)
	rope_length = 185 + stage * 10
	angle = 1.0 if stage==2 else -1.0
	angular_velocity = 0.0
	attached = true
	active_rope = 0
	brace_attached = stage==1
	brace_anchor = Vector2(230,80)
	battery = anchor + Vector2(sin(angle), cos(angle)) * rope_length
	velocity = Vector2.ZERO
	var goal_width: float = 150-difficulty*4
	receiver = Rect2(anchor.x-150-goal_width if stage==2 else anchor.x+150,365,goal_width,55)
	spark = receiver.get_center() + Vector2(70 if stage==2 else -70,-100)
	spark_taken = false

func tick(delta: float) -> void:
	# Substeps keep released trajectories and the pendulum independent of render FPS.
	var count: int = maxi(1, int(ceil(delta / 0.008)))
	for _step in count:
		var dt: float = delta / count
		if attached:
			if brace_attached: continue
			angular_velocity += (-450.0 / rope_length * sin(angle) - angular_velocity * 0.012) * dt
			angle += angular_velocity * dt
			battery = anchor + Vector2(sin(angle), cos(angle)) * rope_length
			velocity = Vector2(cos(angle), -sin(angle)) * angular_velocity * rope_length
		else:
			velocity.y += 450 * dt
			battery += velocity * dt
			if not spark_taken and battery.distance_to(spark) < 34:
				spark_taken = true
				points += 25
				feedback(spark)
			if receiver.grow(-5).has_point(battery) and velocity.y > 0:
				feedback(battery)
				deliveries += 1
				points += 100
				stage += 1
				if deliveries == 3:
					win(points + int(maxf(0, duration - elapsed)))
					return
				new_puzzle()
			elif battery.y > 460 or battery.x < 10 or battery.x > 950:
				lives -= 1
				feedback(battery, false)
				if lives <= 0:
					lose()
					return
				new_puzzle()

func cut_rope(index: int = -1) -> void:
	if index<0: index = active_rope
	if brace_attached:
		if index==1:
			brace_attached = false
			feedback(brace_anchor.lerp(battery,0.5))
		else:
			# The other support survives: cutting order changes the swing geometry.
			anchor = brace_anchor
			rope_length = anchor.distance_to(battery)
			angle = atan2(battery.x-anchor.x,battery.y-anchor.y)
			angular_velocity = 0
			brace_attached = false
			active_rope = 1
		return
	if attached and index==active_rope:
		attached = false
		feedback(anchor.lerp(battery, 0.5))

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if finished: return
	if action == 'action': cut_rope()
	elif action == 'select': cut_rope(int(value.x)-1)
	elif action == 'secondary': cut_rope(1)
	elif action == 'swipe':
		if brace_attached and Geometry2D.segment_intersects_segment(point-value,point,brace_anchor,battery)!=null: cut_rope(1)
		elif Geometry2D.segment_intersects_segment(point-value,point,anchor,battery)!=null: cut_rope()
	elif action == 'press':
		if brace_attached and point.distance_to(Geometry2D.get_closest_point_to_segment(point,brace_anchor,battery))<30:
			cut_rope(1)
			return
		var closest := Geometry2D.get_closest_point_to_segment(point, anchor, battery)
		if point.distance_to(closest) < 40: cut_rope()

func paint() -> void:
	text_at(Vector2(24, 35), 'SWING -> CUT -> DELIVER   ' + str(deliveries) + '/3', 25)
	text_at(Vector2(24,467),'Space cuts; 1/2 choose ropes. Swipe a rope toward the green goal!',19)
	text_at(Vector2(750, 35), 'TRIES ' + str(lives), 24)
	draw_line(Vector2(0, 430), Vector2(960, 430), INK, 4)
	box(receiver, GREEN)
	text_at(receiver.position + Vector2(10, 36), 'FEED', 26)
	disc(anchor, 12, INK)
	if attached:
		draw_line(anchor,battery,INK,5)
		text_at(anchor.lerp(battery,0.5)+Vector2(12,-8),str(active_rope+1),23)
	if brace_attached:
		disc(brace_anchor,12,INK)
		draw_line(brace_anchor,battery,BLUE,5)
		text_at(brace_anchor.lerp(battery,0.5)+Vector2(-25,8),'2',23)
		text_at(Vector2(35,115),'Two supports: choose the useful swing.',20)
	if not spark_taken: disc(spark, 12, GOLD)
	box(Rect2(battery - Vector2(19, 15), Vector2(38, 30)), GOLD)
	text_at(battery + Vector2(-9, 8), '+', 28)

