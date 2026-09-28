extends "res://microgames/microgame_base.gd"

# Movement workshop: every game owns a distinct physical rule and readable goal.
var game: String = ""
var p: Vector2 = Vector2.ZERO
var v: Vector2 = Vector2.ZERO
var target: Vector2 = Vector2.ZERO
var items: Array = []
var marks: Array = []
var t: float = 0.0
var progress: int = 0
var need: int = 3
var held: bool = false
var launched: bool = false
var charge: float = 0.0
var angle: float = 0.0
var axis: Vector2 = Vector2.ZERO
var selected: int = -1
var success_seen: bool = false
var failure_seen: bool = false
var banked: bool = false
var level_speed: float = 1.0

func setup() -> void:
	items.clear()
	marks.clear()
	t = 0.0
	progress = 0
	held = false
	launched = false
	charge = 0.0
	angle = 0.0
	axis = Vector2.ZERO
	v = Vector2.ZERO
	selected = -1
	success_seen = false
	failure_seen = false
	banked = false
	game = str(spec.get("id", "arc_dash"))
	level_speed = 1.0 + (difficulty - 1.0) * 0.055
	p = Vector2(160, 240)
	target = Vector2(810, 240)
	match game:
		"arc_dash":
			p = Vector2(180, 300)
			for i in range(4): items.append(Vector2(500 + i * 260, 300 if i % 2 == 0 else 170))
		"laser_tunnel":
			p = Vector2(200, 320)
			for i in range(4): items.append(Vector2(530 + i * 260, 275 if i % 2 == 0 else 390))
		"armor_repair":
			items = [Vector2(180, 140), Vector2(170, 270), Vector2(190, 390)]
			marks = [Vector2(650, 140), Vector2(650, 270), Vector2(650, 390)]
		"rocket_rescue":
			p = Vector2(100, 360)
			items = [Vector2(290, 170), Vector2(510, 310), Vector2(730, 150)]
			target = Vector2(870, 360)
		"flappy_bonus":
			p = Vector2(120, 240)
			for i in range(3): items.append(Vector2(430 + i * 280, 210 + i * 25))
		"swing_rescue":
			p = Vector2(210, 240)
			target = Vector2(740, 350)
		"meteor_dodge":
			p = Vector2(480, 380)
			for i in range(6): items.append(Vector2(130 + i * 117, -i * 110))
		"parcel_catch":
			p = Vector2(480, 390)
			need = 4
			for i in range(4): items.append(Vector2(180 + (i * 197) % 600, -i * 140))
		"ice_slide":
			p = Vector2(130, 240)
			target = Vector2(730, 240)
		"rail_grind":
			p = Vector2(180, 340)
			for i in range(3): items.append(Vector2(510 + i * 360, 340))
		"balloon_lift":
			p = Vector2(150, 365)
			target = Vector2(810, 130)
		"magnet_haul":
			p = Vector2(150, 150)
			items = [Vector2(480, 350)]
			target = Vector2(800, 150)
		"rope_bridge":
			p = Vector2(110, 240)
			marks = [Vector2(270, 175), Vector2(430, 310), Vector2(590, 175), Vector2(760, 240)]
		"paint_skate":
			p = Vector2(120, 330)
			marks = [Vector2(280, 130), Vector2(450, 350), Vector2(600, 120), Vector2(800, 300)]
		"shield_surf":
			p = Vector2(480, 370)
			for i in range(3): items.append(Vector2(480, -i * 270))
		"boulder_push":
			p = Vector2(180, 300)
			target = Vector2(770, 300)
			need = 5
		"river_hop":
			p = Vector2(130, 350)
			marks = [Vector2(300, 240), Vector2(480, 140), Vector2(660, 260), Vector2(830, 150)]
		"glider_gust":
			p = Vector2(120, 190)
			target = Vector2(825, 255)
		"orbit_escape":
			p = Vector2(480, 240)
			target = Vector2(825, 240)
			angle = -PI
		"spring_vault":
			p = Vector2(160, 365)
			target = Vector2(720, 365)
		"cloud_ferry":
			p = Vector2(150, 340)
			items = [Vector2(310, 260)]
			target = Vector2(800, 150)
		"parachute_drop":
			p = Vector2(160, 75)
			target = Vector2(760, 390)
		"pinball_rescue":
			p = Vector2(480, 110)
			v = Vector2(60, 165)
		"conveyor_sort":
			items = [Vector2(290, 130), Vector2(470, 230), Vector2(650, 130)]
			marks = [Vector2(140, 370), Vector2(820, 370), Vector2(140, 370)]
		"comet_curl":
			p = Vector2(160, 350)
			target = Vector2(745, 350)
	queue_redraw()

func succeed() -> void:
	if finished: return
	success_seen = true
	win(100 + maxi(0, int((duration - t) * 8)))

func fail() -> void:
	if finished: return
	failure_seen = true
	lose()

func timeout() -> void:
	fail()

func tick(delta: float) -> void:
	if finished: return
	t += delta
	var dt: float = delta * level_speed
	match game:
		"arc_dash", "laser_tunnel", "rail_grind":
			if game == "rail_grind":
				v.y += 1100 * dt
				p.y = minf(340, p.y + v.y * dt)
				if p.y >= 340: v.y = 0
			for i in range(items.size()):
				items[i].x -= 215 * dt
				if absf(items[i].x - p.x) < 35:
					if game == "arc_dash" and absf(items[i].y - p.y) < 65: fail()
					if game == "laser_tunnel" and ((items[i].y == 275 and not held) or (items[i].y == 390 and held)): fail()
					if game == "rail_grind" and p.y > 283: fail()
			if items.back().x < p.x - 70: succeed()
		"rocket_rescue":
			p = p.clamp(Vector2(35, 65), Vector2(925, 420))
			collect_near(60)
			if progress == 3 and p.distance_to(target) < 60: succeed()
		"flappy_bonus":
			v.y += 440 * dt
			p.y += v.y * dt
			for i in range(items.size()):
				items[i].x -= 175 * dt
				if absf(items[i].x - p.x) < 39 and absf(p.y - items[i].y) > 100 - difficulty * 3: fail()
			if p.y < 30 or p.y > 440: fail()
			if items.back().x < 65: succeed()
		"swing_rescue":
			if not launched:
				angle = sin(t * 2) * 0.6
				p = Vector2(220 + sin(angle) * 140, 90 + cos(angle) * 150)
			else:
				v.y += 520 * dt
				p += v * dt
				if p.distance_to(target) < 76: succeed()
				elif p.y > 430 or p.x > 960: fail()
		"meteor_dodge":
			p.x = clampf(p.x + axis.x * 480 * delta, 40, 920)
			for i in range(items.size()):
				items[i].y += 155 * dt
				if items[i].y > 520: items[i].y = -120
				if items[i].distance_to(p) < 40: fail()
			if t > 6: succeed()
		"parcel_catch":
			p.x = clampf(p.x + axis.x * 500 * delta, 35, 925)
			for i in range(items.size()):
				if items[i].x < 0: continue
				items[i].y += 150 * dt
				if absf(items[i].y - p.y) < 30 and absf(items[i].x - p.x) < 78:
					items[i] = Vector2(-1000, -1000)
					progress += 1
					feedback(p)
				elif items[i].y > 445: fail()
			if progress >= need: succeed()
		"ice_slide", "comet_curl":
			if launched:
				p += v * dt
				v = v.move_toward(Vector2.ZERO, (150 if game == "ice_slide" else 180) * dt)
				if game == "comet_curl":
					if p.y < 100 and v.y < 0:
						p.y = 200 - p.y
						v.y *= -1
						banked = true
						feedback(p)
					if p.x > 405 and p.x < 455 and p.y > 210: fail()
				if p.x < 25 or p.x > 935 or p.y < 70 or p.y > 420: fail()
				if v.length() < 4:
					if p.distance_to(target) < (88 if game == "ice_slide" else 70) and (game == "ice_slide" or banked): succeed()
					else: fail()
		"balloon_lift":
			p.x += 105 * dt
			p.y += (-82 if held else 55) * dt
			if p.y < 35 or p.y > 425: fail()
			if p.x > 765:
				if absf(p.y - target.y) < 78: succeed()
				elif p.x > 890: fail()
		"magnet_haul":
			if p.distance_to(items[0]) < 130: launched = true
			if launched:
				items[0] = items[0].move_toward(p + Vector2(0, 45), 310 * delta)
				if items[0].distance_to(target + Vector2(0, 45)) < 55: succeed()
		"shield_surf":
			for i in range(items.size()):
				if items[i].x < 0: continue
				items[i].y += 145 * dt
				if items[i].y > 410: fail()
		"boulder_push":
			if progress > 0: p.x = maxf(180, p.x - 21 * dt)
			if p.x >= 755: succeed()
		"glider_gust":
			p.x += 113 * dt
			v.y += 40 * dt
			p.y += v.y * dt
			if p.y < 35 or p.y > 420: fail()
			if p.x > 780:
				if absf(p.y - target.y) < 90: succeed()
				elif p.x > 930: fail()
		"orbit_escape":
			if not launched:
				angle += 1.45 * dt
				p = Vector2(480, 240) + Vector2(cos(angle), sin(angle)) * 130
			else:
				p += v * dt
				if p.distance_to(target) < 65: succeed()
				elif p.x < 0 or p.x > 960 or p.y < 0 or p.y > 480: fail()
		"spring_vault":
			if held and not launched: charge = minf(charge + delta, 1.6)
			if launched:
				v.y += 650 * dt
				p += v * dt
				if p.y >= 365:
					if absf(p.x - target.x) < 90: succeed()
					else: fail()
		"cloud_ferry":
			if not launched and p.distance_to(items[0] + Vector2(0, 35)) < 75: launched = true
			if launched:
				items[0] = p - Vector2(0, 35)
				if p.distance_to(target) < 65: succeed()
		"parachute_drop":
			p.y += 53 * dt
			p.x = clampf(p.x + axis.x * 230 * delta + sin(t * 2) * 16 * delta, 35, 925)
			if p.y >= 385:
				if absf(p.x - target.x) < 85: succeed()
				else: fail()
		"pinball_rescue":
			v.y += 120 * dt
			p += v * dt
			if p.x < 290 or p.x > 670: v.x *= -1
			if p.y < 90 and v.y < 0:
				progress += 1
				v.y = 165
				feedback(p)
				if progress >= 3: succeed()
			if p.y > 435: fail()
		"conveyor_sort":
			for i in range(items.size()):
				if items[i].x > 0 and i != selected: items[i].y += (15 + difficulty * 2) * delta
				if items[i].y > 440: fail()
	if t >= duration and not finished: fail()
	queue_redraw()

func collect_near(radius: float) -> void:
	for i in range(items.size()):
		if p.distance_to(items[i]) < radius:
			feedback(items[i])
			items[i] = Vector2(-1000, -1000)
			progress += 1

func handle_action(action: String, point: Vector2, value: Vector2) -> void:
	if finished: return
	var tap: bool = action == "press" or action == "action"
	if action == "move": axis = value
	if action == "release": held = false
	match game:
		"arc_dash":
			if tap: p.y = 170 if p.y > 200 else 300
		"laser_tunnel", "balloon_lift":
			if tap: held = true
		"armor_repair", "conveyor_sort":
			if tap:
				selected = -1
				for i in range(items.size()):
					if point.distance_to(items[i]) < 75: selected = i
			if selected >= 0 and (action == "drag" or action == "release" or action == "action"):
				items[selected] = point
				if point.distance_to(marks[selected]) < 70:
					feedback(point)
					items[selected] = Vector2(-1000, -1000)
					progress += 1
					selected = -1
					if progress >= 3: succeed()
			if action == "release": selected = -1
		"rocket_rescue", "magnet_haul", "cloud_ferry":
			if tap or action == "drag": p = point
		"flappy_bonus":
			if tap: v.y = -190
		"swing_rescue":
			if action == "swipe" and not launched:
				launched = true
				v = Vector2(clampf(value.x * 2, 200, 680), clampf(value.y * 2, -360, 0))
		"meteor_dodge", "parcel_catch", "parachute_drop":
			if tap or action == "drag": p.x = clampf(point.x, 35, 925)
		"ice_slide", "comet_curl":
			if action == "swipe" and not launched:
				launched = true
				v = value.limit_length(400) * (1.3 if game == "ice_slide" else 1.5)
		"rail_grind":
			if tap and p.y >= 335: v.y = -470
		"rope_bridge", "paint_skate":
			if tap or action == "drag":
				p = point
				if progress < marks.size() and p.distance_to(marks[progress]) < 75:
					feedback(p)
					progress += 1
					if progress >= marks.size(): succeed()
				elif game == "rope_bridge" and not near_bridge(point): fail()
		"shield_surf":
			if action == "swipe" and value.y < -30:
				for i in range(items.size()):
					if items[i].x > 0 and items[i].y > 245 and items[i].y < 410:
						feedback(items[i])
						items[i] = Vector2(-1000, -1000)
						progress += 1
						if progress >= 3: succeed()
		"boulder_push":
			if action == "swipe":
				if value.x > 50:
					p.x += 130
					progress += 1
					feedback(p)
				elif value.x < -50: p.x -= 100
		"river_hop":
			if action == "direction" or action == "swipe" or tap:
				var desired: Vector2 = (marks[progress] - p).normalized()
				var input_direction: Vector2 = (point - p).normalized() if tap else value.normalized()
				if input_direction.dot(desired) > 0.65:
					p = marks[progress]
					progress += 1
					feedback(p)
					if progress >= marks.size(): succeed()
				else: fail()
		"glider_gust":
			if action == "swipe" and value.y < -25: v.y = -85
		"orbit_escape":
			if tap and not launched:
				launched = true
				v = Vector2(cos(angle), sin(angle)) * 420
		"spring_vault":
			if tap and not launched: held = true
			if action == "release" and not launched:
				launched = true
				v = Vector2(140 + charge * 340, -420)
		"pinball_rescue":
			if tap and p.y > 295:
				v.y = -450
				feedback(p)
	queue_redraw()

func near_bridge(point: Vector2) -> bool:
	var previous: Vector2 = Vector2(110, 240)
	for next in marks:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, previous, next)
		if point.distance_to(closest) < 70: return true
		previous = next
	return false

func stroke(a: Vector2, b: Vector2, color: Color = INK, width: float = 5.0) -> void:
	draw_line(a, b, color, width, true)

func badge(pos: Vector2, label: String, color: Color = GOLD) -> void:
	disc(pos, 39, INK)
	disc(pos, 33, color)
	text_at(pos + Vector2(-13, 11), label, 30, INK)

func goal(pos: Vector2, label: String = "HOME") -> void:
	box(Rect2(pos - Vector2(80, 35), Vector2(160, 70)), GREEN)
	draw_rect(Rect2(pos - Vector2(80, 35), Vector2(160, 70)), INK, false, 5)
	text_at(pos + Vector2(-62, 9), label, 25, INK)

func paint() -> void:
	box(Rect2(0, 0, 960, 480), PAPER)
	for i in range(16): stroke(Vector2(i * 65, 450), Vector2(i * 65 + 28, 453), Color("dbcdaa"), 3)
	match game:
		"arc_dash":
			stroke(Vector2(50, 215), Vector2(910, 215), BLUE, 7)
			stroke(Vector2(50, 345), Vector2(910, 345), BLUE, 7)
			for obstacle in items:
				box(Rect2(obstacle - Vector2(28, 40), Vector2(56, 80)), RED)
				text_at(obstacle + Vector2(-15, 10), "!", 34)
			hero(p)
			text_at(Vector2(45, 70), "TAP = SWITCH RAIL", 28)
		"laser_tunnel":
			box(Rect2(55, 90, 850, 28), INK)
			box(Rect2(55, 420, 850, 18), INK)
			for beam in items: stroke(Vector2(beam.x, beam.y - 30), Vector2(beam.x, beam.y + 30), RED, 15)
			hero(Vector2(p.x, 390 if held else 320), 0.65 if held else 1.0)
			text_at(Vector2(65, 70), "HOLD = DUCK   RELEASE = STAND", 26)
		"armor_repair":
			hero(Vector2(650, 265), 3.6)
			for i in range(3):
				badge(marks[i], str(i + 1), Color("d4d0c5"))
				if items[i].x > 0: badge(items[i], str(i + 1), BLUE)
			text_at(Vector2(55, 60), "DRAG EACH PLATE TO ITS NUMBER", 27)
		"rocket_rescue":
			for person in items:
				if person.x > 0:
					box(Rect2(person + Vector2(-48, 30), Vector2(96, 14)), INK)
					hero(person, 0.6)
			goal(target, "EXIT")
			badge(p, "^", RED)
			stroke(p + Vector2(-15, 39), p + Vector2(0, 66), GOLD, 10)
			text_at(Vector2(40, 55), "PICK UP 3 FRIENDS, THEN EXIT", 28)
		"flappy_bonus":
			for gate in items:
				box(Rect2(gate.x - 25, 0, 50, gate.y - 95), GREEN)
				box(Rect2(gate.x - 25, gate.y + 95, 50, 480 - gate.y - 95), GREEN)
			disc(p, 24, GOLD)
			stroke(p - Vector2(20, 0), p - Vector2(45, 17), INK, 6)
			disc(p + Vector2(9, -7), 5, INK)
			text_at(Vector2(30, 55), "TAP TO FLAP", 28)
		"swing_rescue":
			if not launched: stroke(Vector2(220, 90), p, INK, 7)
			goal(target, "MATTRESS")
			hero(p)
			text_at(Vector2(40, 50), "SWIPE RIGHT TO LEAP TO SAFETY", 26)
		"meteor_dodge":
			for meteor in items:
				stroke(meteor - Vector2(20, 45), meteor, GOLD, 15)
				disc(meteor, 24, RED)
			hero(p)
			text_at(Vector2(40, 55), "DRAG TO DODGE THE FALLING ROCKS", 27)
		"parcel_catch":
			for parcel in items:
				box(Rect2(parcel - Vector2(22, 22), Vector2(44, 44)), GOLD)
				stroke(parcel - Vector2(22, 0), parcel + Vector2(22, 0))
			box(Rect2(p - Vector2(70, 10), Vector2(140, 35)), BLUE)
			stroke(p - Vector2(70, 20), p + Vector2(70, -20), INK, 7)
			text_at(Vector2(35, 55), "CATCH ALL 4 PARCELS", 29)
		"ice_slide", "comet_curl":
			box(Rect2(35, 90, 890, 310), Color("dcebf3"))
			disc(target, 82 if game == "ice_slide" else 65, GREEN)
			disc(target, 38, PAPER)
			text_at(target + Vector2(-42, 10), "STOP", 26)
			badge(p, "*", BLUE if game == "ice_slide" else GOLD)
			if game == "comet_curl":
				stroke(Vector2(100, 95), Vector2(890, 95), GOLD, 12)
				box(Rect2(405, 210, 50, 220), RED)
				text_at(Vector2(35, 55), "BANK OFF THE GOLD WALL; STOP ON GREEN", 26)
				stroke(Vector2(180, 300), Vector2(310, 185), INK, 5)
				text_at(Vector2(40, 460), "SWIPE DIAGONALLY UP-RIGHT TO BOUNCE OVER RED", 22)
			else:
				text_at(Vector2(35, 55), "SWIPE RIGHT: STOP INSIDE THE RING", 27)
				stroke(Vector2(160, 350), Vector2(500, 350), INK, 4)
				text_at(Vector2(160, 385), "LONG SWIPE = MORE SPEED", 22)
		"rail_grind":
			stroke(Vector2(25, 380), Vector2(935, 380), INK, 9)
			for hurdle in items: box(Rect2(hurdle - Vector2(24, 12), Vector2(48, 52)), RED)
			hero(p)
			stroke(p + Vector2(-28, 29), p + Vector2(28, 29), BLUE, 9)
			text_at(Vector2(35, 55), "TAP TO JUMP THE BARRIERS", 28)
		"balloon_lift":
			goal(target, "ROOF")
			box(Rect2(765, 170, 140, 260), BLUE)
			disc(p - Vector2(0, 37), 31, RED)
			stroke(p, p - Vector2(0, 15))
			hero(p + Vector2(0, 20), 0.55)
			text_at(Vector2(35, 55), "HOLD TO RISE. RELEASE TO SINK.", 27)
		"magnet_haul":
			goal(target + Vector2(0, 45), "SCRAP")
			badge(p, "U", RED)
			box(Rect2(items[0] - Vector2(28, 25), Vector2(56, 50)), BLUE)
			if launched: stroke(p, items[0], INK, 3)
			text_at(Vector2(35, 55), "DRAG MAGNET NEAR SCRAP, THEN HOME", 25)
		"rope_bridge", "paint_skate":
			var previous: Vector2 = Vector2(110, 240) if game == "rope_bridge" else Vector2(120, 330)
			for i in range(marks.size()):
				stroke(previous, marks[i], Color("d9c28e") if game == "rope_bridge" else BLUE, 35)
				badge(marks[i], str(i + 1), GREEN if i < progress else GOLD)
				previous = marks[i]
			hero(p, 0.7)
			text_at(Vector2(30, 55), "FOLLOW THE BRIDGE IN ORDER" if game == "rope_bridge" else "SKATE THROUGH EVERY NUMBER IN ORDER", 26)
		"shield_surf":
			for bolt in items:
				stroke(bolt - Vector2(0, 28), bolt + Vector2(0, 28), RED, 13)
			draw_arc(p, 65, PI, TAU, 22, BLUE, 14)
			hero(p + Vector2(0, 20), 0.7)
			box(Rect2(360, 245, 240, 8), GOLD)
			text_at(Vector2(30, 55), "SWIPE UP WHEN BOLTS PASS THE GOLD LINE", 24)
		"boulder_push":
			stroke(Vector2(80, 358), Vector2(890, 358), INK, 8)
			goal(target, "PARK")
			disc(p, 53, BLUE)
			draw_arc(p, 33, 0, 4.5, 15, INK, 4)
			hero(p - Vector2(75, -20), 0.7)
			text_at(Vector2(35, 55), "SWIPE RIGHT REPEATEDLY TO PUSH", 27)
		"river_hop":
			box(Rect2(0, 90, 960, 350), BLUE)
			for i in range(marks.size()): badge(marks[i], str(i + 1), GREEN)
			hero(p)
			text_at(Vector2(35, 55), "SWIPE TOWARD THE NEXT LILY PAD", 27)
		"glider_gust":
			goal(target, "ISLAND")
			stroke(p - Vector2(50, 5), p + Vector2(50, 5), RED, 15)
			stroke(p - Vector2(50, 5), p - Vector2(0, 32), RED, 8)
			stroke(p + Vector2(50, 5), p - Vector2(0, 32), RED, 8)
			hero(p + Vector2(0, 23), 0.55)
			text_at(Vector2(35, 55), "SWIPE UP FOR A GUST. REACH THE ISLAND.", 25)
		"orbit_escape":
			draw_arc(Vector2(480, 240), 130, 0, TAU, 48, BLUE, 5)
			disc(Vector2(480, 240), 66, GOLD)
			goal(target, "DOCK")
			stroke(Vector2(595, 240), Vector2(745, 240), GREEN, 12)
			badge(p, "^", RED)
			text_at(Vector2(35, 55), "TAP WHEN THE SHIP LINES UP WITH THE DOCK", 24)
		"spring_vault":
			goal(target, "LAND")
			for i in range(4): stroke(Vector2(135, 405 - i * 12), Vector2(185, 393 - i * 12), BLUE, 5)
			hero(p)
			box(Rect2(275, 130, 400, 28), INK)
			box(Rect2(275, 130, minf(charge, 1.6) * 250, 28), GOLD)
			box(Rect2(465, 120, 55, 48), Color(0.3, 0.8, 0.4, 0.6))
			text_at(Vector2(35, 55), "HOLD, RELEASE WITH THE BAR IN GREEN", 26)
		"cloud_ferry":
			goal(target, "HOME")
			for offset in [-35, 0, 35]: disc(p + Vector2(offset, 0), 32, BLUE)
			hero(items[0], 0.65)
			text_at(Vector2(35, 55), "DRAG CLOUD UNDER FRIEND, THEN HOME", 26)
		"parachute_drop":
			goal(target, "LAND")
			draw_arc(p - Vector2(0, 25), 45, PI, TAU, 20, RED, 14)
			stroke(p - Vector2(45, 25), p)
			stroke(p + Vector2(45, -25), p)
			hero(p + Vector2(0, 20), 0.6)
			text_at(Vector2(35, 40), "DRAG LEFT OR RIGHT TO LAND ON GREEN", 25)
		"pinball_rescue":
			box(Rect2(275, 70, 410, 380), Color("e0eaf5"))
			for i in range(3): badge(Vector2(360 + i * 120, 95), "*", GREEN if i < progress else GOLD)
			stroke(Vector2(325, 390), Vector2(470, 365), BLUE, 17)
			stroke(Vector2(490, 365), Vector2(635, 390), BLUE, 17)
			disc(p, 19, RED)
			text_at(Vector2(35, 45), "TAP NEAR FLIPPERS. HIT THE TOP 3 TIMES.", 24)
		"conveyor_sort":
			goal(Vector2(140, 370), "A")
			goal(Vector2(820, 370), "B")
			stroke(Vector2(235, 430), Vector2(725, 430), INK, 12)
			for i in range(3):
				if items[i].x > 0: badge(items[i], "B" if i == 1 else "A", BLUE if i == 1 else GOLD)
			text_at(Vector2(35, 55), "DRAG PARCELS INTO THE MATCHING BINS", 25)
	if game in ["armor_repair", "rocket_rescue", "parcel_catch", "shield_surf", "pinball_rescue", "conveyor_sort", "river_hop", "paint_skate", "rope_bridge"]:
		text_at(Vector2(810, 463), str(progress) + " / " + str(4 if game in ["parcel_catch", "river_hop", "paint_skate", "rope_bridge"] else 3), 26)
