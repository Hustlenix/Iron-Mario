extends "res://scripts/MiniGameBase.gd"

var targets: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var hits := 0
var required_hits := 5
var target_radius := 30.0

func _init() -> void:
	game_title = "TARGET LOCK"
	instruction = "TAP OR CLICK THE FLYING TARGETS!"
	duration = maxf(8.0, 9.5 - float(Global.current_loop - 1) * 0.35)

func setup_game() -> void:
	rng.randomize()
	required_hits = 5 if Global.current_loop == 1 else 6
	target_radius = maxf(19.0, 31.0 - float(Global.current_loop - 1) * 3.0)
	for index in range(4):
		targets.append(_new_target(index))

func update_game(delta: float) -> void:
	for target in targets:
		var pos: Vector2 = target["position"]
		var velocity: Vector2 = target["velocity"]
		pos += velocity * delta * Global.difficulty
		if pos.x < 70.0 or pos.x > 1210.0:
			velocity.x *= -1.0
		if pos.y < 180.0 or pos.y > 650.0:
			velocity.y *= -1.0
		target["position"] = pos
		target["velocity"] = velocity
	for effect in effects:
		effect["life"] = float(effect["life"]) - delta
	effects = effects.filter(func(effect: Dictionary) -> bool: return float(effect["life"]) > 0.0)
	queue_redraw()

func handle_game_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_action_pressed("click"):
		for target in targets:
			if event.position.distance_to(target["position"]) <= target_radius + 8.0:
				effects.append({"position": target["position"], "life": 0.28})
				hits += 1
				SoundFX.play_collect()
				target["position"] = _random_position()
				target["velocity"] = _random_velocity()
				if hits >= required_hits:
					finish(true)
				get_viewport().set_input_as_handled()
				break

func _new_target(index: int) -> Dictionary:
	return {
		"position": Vector2(180 + index * 275, 240 + (index % 2) * 210),
		"velocity": _random_velocity()
	}

func _random_position() -> Vector2:
	return Vector2(rng.randf_range(90.0, 1190.0), rng.randf_range(190.0, 640.0))

func _random_velocity() -> Vector2:
	return Vector2(rng.randf_range(-110.0, 110.0), rng.randf_range(-80.0, 80.0)).normalized() * rng.randf_range(80.0, 140.0)

func _draw() -> void:
	Paint.background(self, "sky")
	for target in targets:
		_draw_drone(target["position"])
	for effect in effects:
		var pos: Vector2 = effect["position"]
		var life: float = effect["life"]
		for angle in range(0, 360, 45):
			var direction := Vector2.RIGHT.rotated(deg_to_rad(float(angle)))
			Paint.line(self, pos + direction * 15.0, pos + direction * (42.0 - life * 20.0), Color("ffe167"), 5.0)
	pixel_text("TARGETS  %d / %d" % [hits, required_hits], Vector2(490, 175), 28, Color("ffffff"), 300, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_drone(pos: Vector2) -> void:
	Paint.circle(self, pos, target_radius + 9.0, Color("202022"))
	Paint.circle(self, pos, target_radius, Color("e34838"))
	Paint.circle(self, pos, target_radius * 0.52, Color("ffd13c"))
	Paint.circle(self, pos, target_radius * 0.24, Color("7bd9df"))
	Paint.line(self, pos + Vector2(-target_radius - 18, -5), pos + Vector2(-target_radius + 2, -5), Color("eefaff"), 6.0)
	Paint.line(self, pos + Vector2(target_radius - 2, -5), pos + Vector2(target_radius + 18, -5), Color("eefaff"), 6.0)
