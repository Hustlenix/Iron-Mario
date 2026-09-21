extends "res://scripts/MiniGameBase.gd"

const Hero = preload("res://scripts/ui/IronHero.gd")

var hero
var hero_x := 640.0
var pods: Array[Dictionary] = []
var spawn_timer := 0.2
var caught := 0
var missed := 0
var rng := RandomNumberGenerator.new()

func _init() -> void:
	game_title = "ROCKET RESCUE"
	instruction = "MOVE LEFT AND RIGHT TO CATCH 5 PODS!"
	duration = 11.5

func setup_game() -> void:
	rng.randomize()
	hero = Hero.new()
	hero.scale = Vector2(1.15, 1.15)
	hero.position = Vector2(hero_x, 610)
	add_child(hero)

func update_game(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	hero_x = clampf(hero_x + axis * 520.0 * delta, 65.0, 1215.0)
	hero.position.x = hero_x
	if absf(axis) > 0.01:
		hero.facing = signf(axis)
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = maxf(0.82, 1.15 / Global.difficulty)
		_spawn_pod()
	for pod in pods:
		var pos: Vector2 = pod["position"]
		pos.y += float(pod["speed"]) * delta
		pod["position"] = pos
		var catch_width := maxf(40.0, 62.0 / Global.difficulty)
		if not bool(pod["done"]) and pos.y >= 545.0 and pos.y <= 650.0 and absf(pos.x - hero_x) < catch_width:
			pod["done"] = true
			caught += 1
			SoundFX.play_collect()
			if caught >= 5:
				hero.pose = "victory"
				finish(true)
		elif not bool(pod["done"]) and pos.y > 710.0:
			pod["done"] = true
			missed += 1
			SoundFX.play_click()
			if missed >= 3:
				hero.pose = "damaged"
				finish(false)
	pods = pods.filter(func(pod: Dictionary) -> bool: return not bool(pod["done"]))
	queue_redraw()

func _spawn_pod() -> void:
	var horizontal_range := 390.0 if Global.current_loop == 1 else 520.0
	pods.append({
		"position": Vector2(clampf(hero_x + rng.randf_range(-horizontal_range, horizontal_range), 90.0, 1190.0), 145.0),
		"speed": rng.randf_range(205.0, 245.0) * Global.difficulty,
		"done": false
	})

func _draw() -> void:
	Paint.background(self, "sky")
	for index in range(25):
		var point := Vector2(float((index * 157) % 1260), 145.0 + float((index * 67) % 250))
		Paint.rect(self, Rect2(point, Vector2(3, 3)), Color("dff8ff"))
	_draw_city()
	for pod in pods:
		_draw_pod(pod["position"])
	pixel_text("SAVED  %d / 5" % caught, Vector2(435, 178), 28, Color("ffffff"), 260, HORIZONTAL_ALIGNMENT_CENTER)
	pixel_text("MISSED  %d / 3" % missed, Vector2(720, 178), 22, Color("ff9a77"), 220, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_city() -> void:
	for index in range(14):
		var width := 92.0
		var height := 90.0 + float((index * 41) % 150)
		var rect := Rect2(index * 94.0 - 10.0, 720.0 - height, width, height)
		Paint.rect(self, rect, Color("81a3b4"))
		Paint.rect(self, rect, Color("202022"), false, 4.0)
		for wy in range(int(rect.position.y + 15.0), 700, 28):
			Paint.rect(self, Rect2(rect.position.x + 18, wy, 12, 10), Color("f4ba3d"))

func _draw_pod(pos: Vector2) -> void:
	Paint.polygon(self, PackedVector2Array([pos + Vector2(0, -24), pos + Vector2(20, -5), pos + Vector2(15, 25), pos + Vector2(-15, 25), pos + Vector2(-20, -5)]), PackedColorArray([Color("f4b83e")]))
	Paint.polyline(self, PackedVector2Array([pos + Vector2(0, -24), pos + Vector2(20, -5), pos + Vector2(15, 25), pos + Vector2(-15, 25), pos + Vector2(-20, -5), pos + Vector2(0, -24)]), Color("202022"), 4.0)
	Paint.circle(self, pos, 8, Color("7bd9df"))
	Paint.line(self, pos + Vector2(-9, 31), pos + Vector2(-14, 44), Color("ff704f"), 6.0)
	Paint.line(self, pos + Vector2(9, 31), pos + Vector2(14, 44), Color("ff704f"), 6.0)
