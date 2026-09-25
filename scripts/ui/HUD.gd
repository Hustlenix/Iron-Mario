extends Control

const Paint = preload("res://scripts/ui/Paint.gd")

var title_text := "MICROGAME"
var instruction_text := "MOVE FAST!"
var time_left := 10.0
var total_time := 10.0
var feedback_text := ""
var feedback_success := false
var feedback_age := 0.0

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	queue_redraw()

func _process(delta: float) -> void:
	if not feedback_text.is_empty():
		feedback_age += delta
		queue_redraw()

func configure(game_title: String, instruction: String, duration: float) -> void:
	title_text = game_title
	instruction_text = instruction
	total_time = maxf(duration, 0.01)
	time_left = duration
	queue_redraw()

func update_time(value: float) -> void:
	time_left = maxf(value, 0.0)
	queue_redraw()

func show_feedback(won: bool) -> void:
	feedback_success = won
	feedback_text = "MISSION CLEAR!" if won else "MISSION MISSED!"
	feedback_age = 0.0
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var panel_color := Color("fff6dc")
	Paint.rect(self, Rect2(18, 16, 1244, 88), panel_color)
	Paint.rect(self, Rect2(18, 16, 1244, 88), Color("202022"), false, 4.0)
	Paint.string(self, font, Vector2(42, 49), title_text, HORIZONTAL_ALIGNMENT_LEFT, 340, 24, Color("ffd13c"))
	Paint.string(self, font, Vector2(42, 82), instruction_text, HORIZONTAL_ALIGNMENT_LEFT, 700, 18, Color("f5f8ff"))
	Paint.string(self, font, Vector2(800, 48), "SCORE %05d" % Global.score, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f5f8ff"))
	Paint.string(self, font, Vector2(800, 78), "STREAK x%d" % Global.streak, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("72eaff"))
	Paint.string(self, font, Vector2(1054, 78), "%d / 7" % Global.current_minigame, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f5f8ff"))
	_draw_lives(Vector2(1055, 30))
	var ratio := clampf(time_left / total_time, 0.0, 1.0)
	Paint.rect(self, Rect2(20, 111, 1240, 18), Color("202022"))
	Paint.rect(self, Rect2(24, 115, 1232.0 * ratio, 10), Color(Global.hero_data()["light"]) if ratio > 0.3 else Color("ff4d4d"))
	Paint.string(self, font, Vector2(600, 126), "%0.1f" % time_left, HORIZONTAL_ALIGNMENT_CENTER, 80, 16, Color("ffffff"))
	if not feedback_text.is_empty():
		var flash_alpha := maxf(0.0, 0.18 - feedback_age * 0.12)
		Paint.rect(self, Rect2(0, 0, 1280, 720), Color(0.35, 1.0, 0.65, flash_alpha) if feedback_success else Color(1.0, 0.12, 0.16, flash_alpha))
		Paint.rect(self, Rect2(325, 280, 630, 130), Color("fff6dc"))
		Paint.rect(self, Rect2(325, 280, 630, 130), Color("ffffff" if feedback_success else "ff5560"), false, 6.0)
		Paint.string(self, font, Vector2(325, 360), feedback_text, HORIZONTAL_ALIGNMENT_CENTER, 630, 42, Color("7dffb2" if feedback_success else "ff6570"))
		_draw_feedback_sparks()

func _draw_lives(at: Vector2) -> void:
	for index in range(Global.DEFAULT_LIVES):
		var center := at + Vector2(index * 44, 0)
		var active := index < Global.lives
		var fill := Color(Global.hero_data()["light"]) if active else Color("b4b0a1")
		Paint.circle(self, center, 14, Color("202022"))
		Paint.circle(self, center, 10, fill)
		Paint.line(self, center + Vector2(-6, 0), center + Vector2(6, 0), Color("ffffff") if active else Color("53617a"), 3.0)
		Paint.line(self, center + Vector2(0, -6), center + Vector2(0, 6), Color("ffffff") if active else Color("53617a"), 3.0)

func _draw_feedback_sparks() -> void:
	var spark_color := Color("ffe16a") if feedback_success else Color("ff6d76")
	for index in range(18):
		var angle := float(index) / 18.0 * TAU
		var travel := 95.0 + minf(feedback_age, 0.8) * (90.0 + float(index % 4) * 22.0)
		var center := Vector2(640, 345) + Vector2.RIGHT.rotated(angle) * travel
		var size_value := 5.0 + float(index % 3) * 3.0
		Paint.rect(self, Rect2(center - Vector2.ONE * size_value * 0.5, Vector2.ONE * size_value), spark_color)
