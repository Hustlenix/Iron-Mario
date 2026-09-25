extends Node2D

const Paint = preload("res://scripts/ui/Paint.gd")

const Hero = preload("res://scripts/ui/IronHero.gd")
const PixelButton = preload("res://scripts/ui/PixelButton.gd")

var hero
var elapsed := 0.0
var sparks: Array[Dictionary] = []

func _ready() -> void:
	Music.play_theme(Global.hero_id, "winner")
	hero = Hero.new()
	hero.pose = "victory"
	hero.scale = Vector2(2.5, 2.5)
	hero.position = Vector2(640, 315)
	add_child(hero)
	for index in range(42):
		sparks.append({
			"position": Vector2(40 + (index * 137) % 1200, 100 + (index * 79) % 520),
			"speed": 28.0 + float(index % 7) * 9.0,
			"color": [Color("ffe064"), Color("7bd9df"), Color("ff5360")][index % 3]
		})
	_build_buttons()
	SoundFX.play_success()

func _process(delta: float) -> void:
	elapsed += delta
	hero.position.y = 315.0 + sin(elapsed * 2.4) * 13.0
	hero.rotation = sin(elapsed * 1.3) * 0.035
	for spark in sparks:
		var point: Vector2 = spark["position"]
		point.y += float(spark["speed"]) * delta
		point.x += sin(elapsed * 2.0 + point.y * 0.02) * 18.0 * delta
		if point.y > 710.0:
			point.y = 105.0
		spark["position"] = point
	queue_redraw()

func _build_buttons() -> void:
	var play_again := PixelButton.make("PLAY AGAIN", Vector2(280, 615), Vector2(220, 62), Color("f4a090"))
	play_again.pressed.connect(func() -> void: GameManager.start_run(false))
	add_child(play_again)
	play_again.focus_when_ready.call_deferred()
	var harder := PixelButton.make("HARDER MODE", Vector2(530, 615), Vector2(220, 62), Color("ffd13c"))
	harder.pressed.connect(func() -> void: GameManager.start_run(true))
	add_child(harder)
	var title := PixelButton.make("BACK TO TITLE", Vector2(780, 615), Vector2(220, 62), Color("a4d5df"))
	title.pressed.connect(func() -> void: GameManager.return_to_title())
	add_child(title)

func _draw() -> void:
	Paint.background(self, "city")
	Paint.burst(self, Vector2(640,315), 118, Paint.GOLD)
	_draw_city()
	for spark in sparks:
		var point: Vector2 = spark["position"]
		Paint.rect(self, Rect2(point, Vector2(7, 13)), spark["color"])
	var font := ThemeDB.fallback_font
	Paint.string(self, font, Vector2(0, 92), "MISSION COMPLETE", HORIZONTAL_ALIGNMENT_CENTER, 1280, 55, Color("ffe06a"))
	Paint.string(self, font, Vector2(0, 138), "REACTOR STABLE!", HORIZONTAL_ALIGNMENT_CENTER, 1280, 25, Color("71eaff"))
	Paint.rect(self, Rect2(250, 502, 780, 78), Color("fff6dc"))
	Paint.rect(self, Rect2(250, 502, 780, 78), Color("f1bd44"), false, 5.0)
	Paint.string(self, font, Vector2(265, 550), "SCORE %05d     STREAK x%d     LOOP %d" % [Global.score, Global.streak, Global.current_loop], HORIZONTAL_ALIGNMENT_CENTER, 750, 24, Color("ffffff"))
	Paint.rect(self, Rect2(415,571,450,27), Paint.PAPER)
	Paint.string(self, font, Vector2(265, 588), "HARDER MODE CONTINUES TO LOOP %d" % (Global.current_loop + 1), HORIZONTAL_ALIGNMENT_CENTER, 750, 16, Color("9eb5d3"))

func _draw_city() -> void:
	for index in range(15):
		var height := 55.0 + float((index * 41) % 130)
		var rect := Rect2(index * 90.0 - 20.0, 610.0 - height, 80, height)
		Paint.rect(self, rect, Color("769bad"))
		Paint.rect(self, rect, Color("202022"), false, 4.0)
		for wy in range(int(rect.position.y + 14.0), int(rect.end.y - 5.0), 26):
			Paint.rect(self, Rect2(rect.position.x + 14, wy, 10, 9), Color("ffd85d"))
