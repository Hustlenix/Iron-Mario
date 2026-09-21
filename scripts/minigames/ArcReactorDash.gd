extends "res://scripts/MiniGameBase.gd"

const Motor = preload("res://scripts/PlayerMotor.gd")
const Hero = preload("res://scripts/ui/IronHero.gd")

var motor = Motor.new()
var hero
var platforms: Array[Rect2] = [
	Rect2(0, 620, 1280, 100),
	Rect2(470, 505, 280, 24),
	Rect2(890, 390, 280, 24)
]
var shards: Array[Dictionary] = [
	{"position": Vector2(245, 567), "collected": false},
	{"position": Vector2(610, 452), "collected": false},
	{"position": Vector2(1030, 337), "collected": false}
]
var collected := 0
var pulse := 0.0

func _init() -> void:
	game_title = "ARC REACTOR DASH"
	instruction = "MOVE, JUMP, AND GRAB 3 REACTOR SHARDS!"
	duration = maxf(8.3, 11.0 - float(Global.current_loop - 1) * 0.65)

func setup_game() -> void:
	motor.position = Vector2(55, 556)
	motor.speed = 360.0
	hero = Hero.new()
	hero.position = motor.position + motor.size * 0.5
	add_child(hero)

func update_game(delta: float) -> void:
	pulse += delta * 5.0
	motor.step(delta, platforms)
	hero.position = motor.position + motor.size * 0.5
	hero.pose = "jump" if not motor.grounded else "idle"
	if absf(motor.velocity.x) > 1.0:
		hero.facing = signf(motor.velocity.x)
	for shard in shards:
		if not bool(shard["collected"]) and hero.position.distance_to(shard["position"]) < 48.0:
			shard["collected"] = true
			collected += 1
			SoundFX.play_collect()
			if collected >= 3:
				hero.pose = "victory"
				finish(true)
	queue_redraw()

func handle_game_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		motor.request_jump()

func _draw() -> void:
	Paint.background(self, "city")
	for index in range(12):
		var x := float(index) * 112.0 - 20
		var height := 140.0 + float((index * 41) % 170)
		Paint.rect(self, Rect2(x, 620 - height, 95, height), Color("8ebdc9"))
		for y in range(int(642 - height), 605, 35):
			Paint.rect(self, Rect2(x + 16, y, 12, 15), Paint.PAPER)
			Paint.rect(self, Rect2(x + 57, y + 2, 13, 14), Paint.PAPER)
	for platform in platforms:
		draw_pixel_panel(platform, Color("c78868"), Color("202022"), 5.0)
		for x in range(int(platform.position.x + 12), int(platform.end.x), 32):
			Paint.rect(self, Rect2(x, platform.position.y + 6, 14, 6), Color("f3b63d"))
	for shard in shards:
		if bool(shard["collected"]):
			continue
		var pos: Vector2 = shard["position"]
		var glow := 5.0 + sin(pulse) * 2.0
		Paint.burst(self, pos, 20.0 + glow, Paint.GOLD)
		Paint.polygon(self, PackedVector2Array([pos + Vector2(0, -22), pos + Vector2(15, -5), pos + Vector2(9, 20), pos + Vector2(-12, 17), pos + Vector2(-17, -7)]), PackedColorArray([Color("62e6ff")]))
		Paint.polyline(self, PackedVector2Array([pos + Vector2(0, -22), pos + Vector2(15, -5), pos + Vector2(9, 20), pos + Vector2(-12, 17), pos + Vector2(-17, -7), pos + Vector2(0, -22)]), Color("202022"), 4.0)
	pixel_text("SHARDS  %d / 3" % collected, Vector2(520, 175), 28, Color("ffffff"), 240, HORIZONTAL_ALIGNMENT_CENTER)
