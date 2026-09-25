extends "res://scripts/MiniGameBase.gd"

const ACTIONS := ["move_left", "jump", "move_down", "move_right"]
const LABELS := ["LEFT / A", "UP / W", "DOWN / S", "RIGHT / D"]
const CENTERS := [Vector2(360,430),Vector2(640,225),Vector2(640,625),Vector2(920,430)]

var sequence: Array[int] = []
var phase := "show"
var show_elapsed := 0.0
var show_index := 0
var input_index := 0
var flash_success := 0.0
var rng := RandomNumberGenerator.new()

func _init() -> void:
	game_title = "POWER CORE SEQUENCE"
	instruction = "WATCH, THEN REPEAT WITH ARROWS OR TAPS!"
	duration = 11.5

func setup_game() -> void:
	rng.randomize()
	var length := mini(7, 3 + Global.current_loop)
	for index in range(length):
		sequence.append(rng.randi_range(0, ACTIONS.size() - 1))

func update_game(delta: float) -> void:
	flash_success = maxf(0.0, flash_success - delta)
	if phase == "show":
		show_elapsed += delta
		show_index = int(show_elapsed / 0.62)
		if show_index >= sequence.size():
			phase = "input"
			show_index = -1
			SoundFX.play_start()
	queue_redraw()

func handle_game_input(event: InputEvent) -> void:
	if phase != "input" or not event.is_pressed():
		return
	if event is InputEventKey and event.echo:
		return
	var entered := -1
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		for index in range(CENTERS.size()):
			if Rect2(CENTERS[index]-Vector2(95,51),Vector2(190,102)).has_point(event.position):
				entered = index
				break
	for index in range(ACTIONS.size()):
		if event.is_action_pressed(ACTIONS[index]):
			entered = index
			break
	if entered < 0:
		return
	if entered != sequence[input_index]:
		finish(false)
		return
	input_index += 1
	flash_success = 0.22
	SoundFX.play_collect()
	if input_index >= sequence.size():
		finish(true)

func _draw() -> void:
	Paint.background(self, "space")
	draw_reactor(Vector2(640, 430), 82, Color("6feaff"))
	var centers := CENTERS
	for index in range(4):
		var active := phase == "show" and show_index >= 0 and show_index < sequence.size() and sequence[show_index] == index and fmod(show_elapsed, 0.62) < 0.38
		var correct_flash := phase == "input" and flash_success > 0.0 and input_index > 0 and sequence[input_index - 1] == index
		_draw_key(centers[index], ["LEFT","UP","DOWN","RIGHT"][index] if Global.uses_touch() else LABELS[index], active or correct_flash)
	var state_text := "WATCH!" if phase == "show" else "REPEAT!  %d / %d" % [input_index, sequence.size()]
	pixel_text(state_text, Vector2(430, 175), 34, Color("ffe06a" if phase == "show" else "75f1ff"), 420, HORIZONTAL_ALIGNMENT_CENTER)

func _draw_key(center: Vector2, label_text: String, active: bool) -> void:
	var rect := Rect2(center - Vector2(95, 51), Vector2(190, 102))
	draw_pixel_panel(rect, Color("ffd13c") if active else Color("fff6dc"), Color("202022"), 6.0)
	pixel_text(label_text, Vector2(rect.position.x, center.y + 9), 19, Color("08142c") if active else Color("ffffff"), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
