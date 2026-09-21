extends Node

const SAVE_PATH := "user://iron_mario_save.cfg"
const DEFAULT_LIVES := 5

var lives: int = DEFAULT_LIVES
var score: int = 0
var streak: int = 0
var best_streak: int = 0
var current_loop: int = 1
var current_minigame: int = 0
var completed_minigames: int = 0
var difficulty: float = 1.0
var muted: bool = false
var volume: float = 80.0
var flappy_best: int = 0

# Compatibility for the original scenes and their save data.
var loop: int:
	get: return current_loop - 1
	set(value):
		current_loop = maxi(1, value + 1)
		difficulty = minf(2.4, 1.0 + float(current_loop - 1) * 0.35)
var minigames_done: int:
	get: return completed_minigames
	set(value): completed_minigames = value

func reset() -> void:
	reset_run()

func win() -> void:
	streak += 1
	best_streak = maxi(best_streak, streak)
	save_data()

func lose() -> void:
	streak = 0
	save_data()

func save() -> void:
	save_data()

func load_save() -> void:
	load_data()

func _apply_volume() -> void:
	_apply_audio_setting()

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 100.0)
	_apply_audio_setting()
	save_data()


func _ready() -> void:
	load_data()
	_ensure_input_actions()
	_apply_audio_setting()
	Input.set_custom_mouse_cursor(load("res://assets/paint_cursor.svg"), Input.CURSOR_ARROW, Vector2(2,2))

func reset_run(harder: bool = false) -> void:
	var next_loop := current_loop + 1 if harder else 1
	lives = DEFAULT_LIVES
	score = 0
	streak = 0
	current_loop = next_loop
	current_minigame = 0
	completed_minigames = 0
	difficulty = minf(2.4, 1.0 + float(current_loop - 1) * 0.35)

func record_success() -> void:
	streak += 1
	best_streak = maxi(best_streak, streak)
	score += 100 + (streak - 1) * 25 + (current_loop - 1) * 50
	completed_minigames += 1
	save_data()

func record_failure() -> void:
	lives = maxi(0, lives - 1)
	streak = 0
	save_data()

func toggle_mute() -> bool:
	muted = not muted
	_apply_audio_setting()
	save_data()
	return muted

func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "best_streak", best_streak)
	config.set_value("settings", "muted", muted)
	config.set_value("settings", "volume", volume)
	config.set_value("progress", "flappy_best", flappy_best)
	if config.save(SAVE_PATH) != OK:
		push_warning("Could not save Iron-Mario progress.")

func load_data() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_streak = int(config.get_value("progress", "best_streak", 0))
		muted = bool(config.get_value("settings", "muted", false))
		volume = clampf(float(config.get_value("settings", "volume", 80.0)), 0.0, 100.0)
		flappy_best = maxi(0, int(config.get_value("progress", "flappy_best", 0)))
	elif FileAccess.file_exists("user://save.dat"):
		var legacy = JSON.parse_string(FileAccess.get_file_as_string("user://save.dat"))
		if legacy is Dictionary:
			best_streak = maxi(0, int(legacy.get("best_streak", 0)))
			volume = clampf(float(legacy.get("volume", 80.0)), 0.0, 100.0)
			flappy_best = maxi(0, int(legacy.get("flappy_best", 0)))
			save_data()
	_apply_audio_setting()

func _apply_audio_setting() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, muted or volume <= 0.0)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(volume, 0.001) / 100.0))

func _ensure_input_actions() -> void:
	_add_key_action("left", [KEY_A, KEY_LEFT])
	_add_key_action("right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("jump", [KEY_W, KEY_SPACE, KEY_UP])
	_add_key_action("action", [KEY_E, KEY_ENTER, KEY_KP_ENTER])
	_add_key_action("restart", [KEY_R])
	_add_mouse_action("click", MOUSE_BUTTON_LEFT)

func _add_key_action(action_name: StringName, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keys:
		var already_present := false
		for existing_event in InputMap.action_get_events(action_name):
			if existing_event is InputEventKey and existing_event.physical_keycode == keycode:
				already_present = true
				break
		if not already_present:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action_name, event)

func _add_mouse_action(action_name: StringName, button_index: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventMouseButton and existing_event.button_index == button_index:
			return
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)
