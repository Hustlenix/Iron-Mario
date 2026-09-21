extends "res://scripts/MiniGameBase.gd"

const Motor = preload("res://scripts/PlayerMotor.gd")
const Hero = preload("res://scripts/ui/IronHero.gd")

var motor = Motor.new()
var hero
var floor_surface: Array[Rect2] = [Rect2(0, 620, 1280, 100)]
var lasers: Array[Dictionary] = []
var spawn_timer := 1.5
var rng := RandomNumberGenerator.new()

func _init() -> void:
	game_title = "LASER TUNNEL"
	instruction = "JUMP OVER THE LASERS UNTIL TIME RUNS OUT!"
	duration = 9.0

func setup_game() -> void:
	rng.randomize()
	motor.position = Vector2(135, 556)
	motor.speed = 325.0
	hero = Hero.new()
	hero.position = motor.position + motor.size * 0.5
	add_child(hero)
	lasers.append({"rect": Rect2(940, 576, 150, 18), "speed": 265.0 * Global.difficulty})

func update_game(delta: float) -> void:
	motor.step(delta, floor_surface)
	hero.position = motor.position + motor.size * 0.5
	hero.pose = "jump" if not motor.grounded else "idle"
	if absf(motor.velocity.x) > 1.0:
		hero.facing = signf(motor.velocity.x)
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = maxf(1.55, 2.45 / Global.difficulty)
		lasers.append({"rect": Rect2(1300, 576, rng.randf_range(105.0, 140.0), 18), "speed": rng.randf_range(265.0, 295.0) * Global.difficulty})
	for laser in lasers:
		var rect: Rect2 = laser["rect"]
		rect.position.x -= float(laser["speed"]) * delta
		laser["rect"] = rect
		if rect.intersects(motor.rect().grow(-7.0)):
			hero.pose = "damaged"
			finish(false)
			break
	lasers = lasers.filter(func(laser: Dictionary) -> bool: return Rect2(laser["rect"]).end.x > -20.0)
	queue_redraw()

func on_time_expired() -> void:
	hero.pose = "victory"
	finish(true)

func handle_game_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		motor.request_jump()

func _draw() -> void:
	Paint.background(self, "tunnel")
	for x in range(0, 1280, 96):
		Paint.line(self, Vector2(x, 140), Vector2(x + 220, 620), Color("b9b8aa"), 4.0)
	Paint.rect(self, Rect2(0, 620, 1280, 100), Color("90918e"))
	Paint.rect(self, Rect2(0, 620, 1280, 100), Color("202022"), false, 6.0)
	for x in range(0, 1280, 64):
		Paint.rect(self, Rect2(x, 636, 34, 9), Color("ffd13c"))
	for laser in lasers:
		var rect: Rect2 = laser["rect"]
		Paint.line(self, rect.position - Vector2(6,8), rect.end - Vector2(0,rect.size.y+9), Paint.RED, 2.0)
		Paint.rect(self, rect, Color("e34838"))
		Paint.line(self, rect.position, Vector2(rect.end.x, rect.position.y), Color("ffffff"), 3.0)
	pixel_text("SURVIVE!", Vector2(500, 185), 34, Color("ffdf67"), 280, HORIZONTAL_ALIGNMENT_CENTER)
