extends "res://scripts/MiniGameBase.gd"

var marker := 0.08
var direction := 1.0
var zone_start := 0.52
var zone_width := 0.22
var parries := 0
var flash_time := 0.0
var miss_time := 0.0
var rng := RandomNumberGenerator.new()

func _init() -> void:
	game_title = "REACTOR PARRY"
	instruction = "PRESS JUMP INSIDE THE GREEN ZONE 3 TIMES!"
	duration = 10.0

func setup_game() -> void:
	rng.randomize()
	zone_width = maxf(0.12, 0.22 / Global.difficulty)
	_pick_zone()

func update_game(delta: float) -> void:
	marker += direction * delta * 0.76 * Global.difficulty
	if marker >= 1.0:
		marker = 1.0
		direction = -1.0
	elif marker <= 0.0:
		marker = 0.0
		direction = 1.0
	flash_time = maxf(0.0, flash_time - delta)
	miss_time = maxf(0.0, miss_time - delta)
	queue_redraw()

func handle_game_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		if event is InputEventKey and event.echo:
			return
		if marker >= zone_start and marker <= zone_start + zone_width:
			parries += 1
			flash_time = 0.25
			SoundFX.play_collect()
			if parries >= 3:
				finish(true)
			else:
				marker = 0.05 if direction > 0.0 else 0.95
				_pick_zone()
		else:
			miss_time = 0.35
			penalize_time(0.8)
			SoundFX.play_click()

func _pick_zone() -> void:
	zone_start = rng.randf_range(0.25, 0.76 - zone_width)

func _draw() -> void:
	Paint.background(self, "workshop")
	for index in range(8):
		var center := Vector2(110 + index * 155, 255 + (index % 2) * 260)
		Paint.circle(self, center, 42, Color("efc89d"))
		Paint.circle(self, center, 26, Color("e9ae7d"))
	var gauge := Rect2(160, 340, 960, 82)
	draw_pixel_panel(gauge, Color("eee5cf"), Color("202022"), 8.0)
	Paint.rect(self, Rect2(gauge.position.x + zone_start * gauge.size.x, gauge.position.y + 8, zone_width * gauge.size.x, gauge.size.y - 16), Color("73ca78"))
	var marker_x := gauge.position.x + marker * gauge.size.x
	Paint.polygon(self, PackedVector2Array([Vector2(marker_x, 310), Vector2(marker_x - 18, 335), Vector2(marker_x + 18, 335)]), PackedColorArray([Color("ffe16c")]))
	Paint.line(self, Vector2(marker_x, 330), Vector2(marker_x, 435), Paint.INK, 6.0)
	if flash_time > 0.0:
		Paint.rect(self, Rect2(140, 320, 1000, 122), Color(0.4, 1.0, 0.7, flash_time))
	if miss_time > 0.0:
		Paint.rect(self, Rect2(140, 320, 1000, 122), Color(1.0, 0.1, 0.2, miss_time))
	pixel_text("PARRIES  %d / 3" % parries, Vector2(460, 205), 32, Color("ffffff"), 360, HORIZONTAL_ALIGNMENT_CENTER)
	pixel_text("SPACE / W", Vector2(490, 505), 26, Color("7bd9df"), 300, HORIZONTAL_ALIGNMENT_CENTER)
