extends Node

var lives: int = 5
var minigames_done: int = 0
var loop: int = 0
var streak: int = 0
var best_streak: int = 0
var flappy_best: int = 0
var volume: float = 80.0
## Music sits lower than SFX by default: it is continuous, so it would
## otherwise crowd out the effects the player needs to hear.
var music_volume: float = 70.0

## Device / player preferences. These are deliberately NOT cleared by reset(),
## which only clears per-run state.
var touch_controls_enabled: bool = true
var low_quality: bool = false

const SAVE_PATH := "user://save.dat"
const MUSIC_BUS := "Music"

func _ready() -> void:
	load_save()
	_apply_volume()
	_apply_music_volume()

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

## Music has its own bus so its slider cannot disturb effect levels. Guarded on
## the bus actually existing: without default_bus_layout.tres there is nothing
## to address, and falling back to Master would double-apply the slider.
func _apply_music_volume() -> void:
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx == -1:
		return
	var linear := maxf(music_volume, 0.0) / 100.0
	AudioServer.set_bus_volume_db(idx, -80.0 if linear <= 0.0 else linear_to_db(linear))

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify({
		"best_streak": best_streak,
		"volume": volume,
		"music_volume": music_volume,
		"flappy_best": flappy_best,
		"touch_controls_enabled": touch_controls_enabled,
		"low_quality": low_quality,
	}))

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
		music_volume = float(data.get("music_volume", 70.0))
		flappy_best = int(data.get("flappy_best", 0))
		touch_controls_enabled = bool(data.get("touch_controls_enabled", true))
		low_quality = bool(data.get("low_quality", false))
