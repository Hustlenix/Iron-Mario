extends Node

signal achievement_unlocked(id: String, title: String)

var lives: int = 5
var minigames_done: int = 0
var loop: int = 0
var streak: int = 0
var best_streak: int = 0
var flappy_best: int = 0
var tower_bounce_best: int = 0
var brick_reactor_best: int = 0
var arc_snake_best: int = 0
var arcade_games_played: int = 0
var arcade_total_wins: int = 0
var arcade_bests: Dictionary = {}
var arcade_recent_games: Array[String] = []
var arcade_unique_games: Array[String] = []
var achievements_unlocked: Array[String] = []

const ACHIEVEMENTS := {
	"first_arcade_game": "FIRST CABINET",
	"five_unique_games": "ARCADE TOURIST",
	"first_personal_best": "BEAT THE BOARD",
	"tower_100m": "TOWER CLIMBER",
	"random_encounter": "RANDOM ENCOUNTER",
}
var volume: float = 80.0
## Music sits lower than SFX by default: it is continuous, so it would
## otherwise crowd out the effects the player needs to hear.
var music_volume: float = 70.0

## Device / player preferences. These are deliberately NOT cleared by reset(),
## which only clears per-run state.
var touch_controls_enabled: bool = true
var low_quality: bool = false

## The chosen hero (Phase 4). Like the preferences above this survives reset():
## picking a character is a device preference, not per-run state, so a player
## does not have to re-pick on every loop of the gauntlet. Empty means "no
## pick yet", which PowerBus reads as "use the random pick".
var selected_hero: String = ""

const SAVE_PATH := "user://save.dat"
const MUSIC_BUS := "Music"
const DEFAULT_HERO := "dart"

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
		"tower_bounce_best": tower_bounce_best,
		"brick_reactor_best": brick_reactor_best,
		"arc_snake_best": arc_snake_best,
		"arcade_games_played": arcade_games_played,
		"arcade_total_wins": arcade_total_wins,
		"arcade_bests": arcade_bests,
		"arcade_recent_games": arcade_recent_games,
		"arcade_unique_games": arcade_unique_games,
		"achievements_unlocked": achievements_unlocked,
		"touch_controls_enabled": touch_controls_enabled,
		"low_quality": low_quality,
		"selected_hero": selected_hero,
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
		tower_bounce_best = int(data.get("tower_bounce_best", 0))
		brick_reactor_best = int(data.get("brick_reactor_best", 0))
		arc_snake_best = int(data.get("arc_snake_best", 0))
		arcade_games_played = maxi(0, int(data.get("arcade_games_played", 0)))
		arcade_total_wins = maxi(0, int(data.get("arcade_total_wins", 0)))
		var loaded_bests: Variant = data.get("arcade_bests", {})
		arcade_bests = loaded_bests.duplicate() if loaded_bests is Dictionary else {}
		var loaded_recent: Variant = data.get("arcade_recent_games", [])
		arcade_recent_games = _clean_string_list(loaded_recent, 8)
		var loaded_unique: Variant = data.get("arcade_unique_games", [])
		arcade_unique_games = _clean_string_list(loaded_unique, 1000)
		var loaded_achievements: Variant = data.get("achievements_unlocked", [])
		achievements_unlocked = _clean_string_list(loaded_achievements, ACHIEVEMENTS.size())
		touch_controls_enabled = bool(data.get("touch_controls_enabled", true))
		low_quality = bool(data.get("low_quality", false))
		selected_hero = str(data.get("selected_hero", ""))

func record_arcade_start(game_id: String) -> void:
	if game_id.is_empty():
		return
	arcade_games_played += 1
	arcade_unique_games.erase(game_id)
	arcade_unique_games.push_front(game_id)
	arcade_recent_games.erase(game_id)
	arcade_recent_games.push_front(game_id)
	if arcade_recent_games.size() > 8:
		arcade_recent_games.resize(8)
	if arcade_games_played == 1:
		unlock_achievement("first_arcade_game")
	if arcade_unique_games.size() >= 5:
		unlock_achievement("five_unique_games")
	save()

func record_arcade_result(game_id: String, score: int, won: bool) -> void:
	if game_id.is_empty():
		return
	var old_best := int(arcade_bests.get(game_id, 0))
	arcade_bests[game_id] = maxi(old_best, score)
	if score > old_best and old_best > 0:
		unlock_achievement("first_personal_best")
	if game_id == "tower_bounce" and score >= 100:
		unlock_achievement("tower_100m")
	if won:
		arcade_total_wins += 1
	save()

func arcade_best(game_id: String) -> int:
	return int(arcade_bests.get(game_id, 0))

func unlock_achievement(id: String) -> void:
	if not ACHIEVEMENTS.has(id) or achievements_unlocked.has(id):
		return
	achievements_unlocked.append(id)
	achievement_unlocked.emit(id, str(ACHIEVEMENTS[id]))

func _clean_string_list(value: Variant, max_items: int) -> Array[String]:
	var cleaned: Array[String] = []
	if not value is Array:
		return cleaned
	for item in value:
		if item is String and not item.is_empty() and not cleaned.has(item):
			cleaned.append(item)
			if cleaned.size() >= max_items:
				break
	return cleaned

## The hero the player will actually play as. An unset or stale id resolves to a
## random pick rather than failing, so a save written by an older build -- or one
## with a hero id that no longer exists -- still boots into a playable game.
func active_hero_id() -> String:
	if selected_hero != "" and HeroData.is_selectable(selected_hero):
		return selected_hero
	return HeroData.random_id()
