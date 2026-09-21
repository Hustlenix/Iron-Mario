extends Node2D

const Paint = preload("res://scripts/ui/Paint.gd")

const Hero = preload("res://scripts/ui/IronHero.gd")
const PixelButton = preload("res://scripts/ui/PixelButton.gd")

var hero
var elapsed := 0.0
var flicker := true

func _ready() -> void:
	hero = Hero.new()
	hero.pose = "damaged"
	hero.scale = Vector2(2.7, 2.7)
	hero.position = Vector2(640, 370)
	hero.reactor_color = Color("ff3448")
	add_child(hero)
	var retry := PixelButton.make("TRY AGAIN", Vector2(390, 610), Vector2(230, 64), Color("f4a090"))
	retry.pressed.connect(func() -> void: GameManager.start_run(false))
	add_child(retry)
	retry.grab_focus.call_deferred()
	var title := PixelButton.make("BACK TO TITLE", Vector2(660, 610), Vector2(230, 64), Color("a4d5df"))
	title.pressed.connect(func() -> void: GameManager.return_to_title())
	add_child(title)
	SoundFX.play_failure()

func _process(delta: float) -> void:
	elapsed += delta
	flicker = fmod(elapsed, 0.85) < 0.55 or fmod(elapsed, 2.3) > 2.12
	hero.visible = true
	hero.reactor_color = Color("ff3345") if flicker and elapsed < 2.5 else Color("301c27")
	queue_redraw()

func _draw() -> void:
	Paint.background(self, "death")
	for index in range(13):
		var x := float(index) * 105.0
		var height := 65.0 + float((index * 37) % 115)
		Paint.rect(self, Rect2(x, 720.0 - height, 86, height), Color("17253f"))
	for index in range(20):
		var x := float((index * 157) % 1280)
		var y := 120.0 + float((index * 83) % 450)
		var alpha := 0.22 if (index + int(elapsed * 4.0)) % 3 else 0.04
		Paint.rect(self, Rect2(x, y, 5, 5), Color(1.0, 0.22, 0.28, alpha))
	var font := ThemeDB.fallback_font
	Paint.string(self, font, Vector2(0, 100), "SUIT POWERED DOWN", HORIZONTAL_ALIGNMENT_CENTER, 1280, 52, Color("ff5663"))
	Paint.string(self, font, Vector2(0, 144), "MISSION FAILED", HORIZONTAL_ALIGNMENT_CENTER, 1280, 24, Color("8494ae"))
	Paint.rect(self, Rect2(330, 505, 620, 70), Color("273b61"))
	Paint.rect(self, Rect2(330, 505, 620, 70), Color("efa093"), false, 5.0)
	Paint.string(self, font, Vector2(345, 548), "SCORE %05d     CLEARED %d / 7" % [Global.score, Global.completed_minigames], HORIZONTAL_ALIGNMENT_CENTER, 590, 22, Color("dce7f6"))
