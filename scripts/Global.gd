extends Node

var lives: int = 5
var minigames_done: int = 0
var loop: int = 0
var streak: int = 0
var best_streak: int = 0
var volume: float = 80.0

const SAVE_PATH := "user://save.dat"

func _ready() -> void:
	load_save()
	_apply_volume()

func reset() -> void:
	lives = 5
	minigames_done = 0
	loop = 0
	streak = 0

func win() -> void:
	streak += 1
	best_streak = maxi(best_streak, streak)

func lose() -> void:
	streak = 0

func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001) / 100.0))

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify({"best_streak": best_streak, "volume": volume}))

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not read save file: %s" % FileAccess.get_open_error())
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		best_streak = int(data.get("best_streak", 0))
		volume = float(data.get("volume", 80.0))
