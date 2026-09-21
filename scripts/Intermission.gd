extends Node2D

const Paint = preload("res://scripts/ui/Paint.gd")

var countdown := 3.0
var launched := false
var game_data: Dictionary
var last_count := 4

func _ready() -> void:
	game_data = GameManager.get_upcoming_game()
	SoundFX.play_start()
	queue_redraw()

func _process(delta: float) -> void:
	countdown -= delta
	var visible_count := maxi(1, ceili(countdown))
	if visible_count != last_count:
		last_count = visible_count
		SoundFX.play_countdown(visible_count)
	queue_redraw()
	if countdown <= 0.0 and not launched:
		launched = true
		GameManager.launch_current_minigame()

func _draw() -> void:
	Paint.background(self, "briefing")
	for index in range(18):
		var x := float((index * 97 + 45) % 1280)
		var y := float((index * 61 + 120) % 720)
		Paint.rect(self, Rect2(x, y, 8, 8), Color("a5b398"))
	Paint.rect(self, Rect2(165, 158, 950, 430), Color("fff6dc"))
	Paint.rect(self, Rect2(165, 158, 950, 430), Color("f0b842"), false, 7.0)
	var font := ThemeDB.fallback_font
	Paint.string(self, font, Vector2(165, 228), "MISSION %d / 7" % (GameManager.round_index + 1), HORIZONTAL_ALIGNMENT_CENTER, 950, 24, Color("71eaff"))
	Paint.string(self, font, Vector2(165, 310), String(game_data.get("name", "MICROGAME")), HORIZONTAL_ALIGNMENT_CENTER, 950, 48, Color("ffe06c"))
	Paint.string(self, font, Vector2(205, 374), String(game_data.get("instruction", "MOVE FAST!")), HORIZONTAL_ALIGNMENT_CENTER, 870, 23, Color("ffffff"))
	var count_text := str(maxi(1, ceili(countdown)))
	Paint.string(self, font, Vector2(165, 505), count_text, HORIZONTAL_ALIGNMENT_CENTER, 950, 78, Color("ff4d57" if count_text == "GO!" else "ffffff"))
	Paint.string(self, font, Vector2(165, 558), "LIVES %d   •   SCORE %05d   •   STREAK x%d" % [Global.lives, Global.score, Global.streak], HORIZONTAL_ALIGNMENT_CENTER, 950, 19, Color("a9bbd8"))
