extends Node

## Runtime and persistence coverage for the standalone arcade cabinets.
## This stays headless: it drives the same scene methods the keyboard and
## touch controls call, then asserts the visible state transitions and saved
## score fields.

var _checks := 0
var _failed := 0
var _save_path := ""
var _had_save := false
var _save_backup := ""

func _ready() -> void:
	await _run()

func _check(label: String, ok: bool, detail: String = "") -> void:
	_checks += 1
	if ok:
		print("  PASS  %s  %s" % [label, detail])
	else:
		_failed += 1
		print("  FAIL  %s  %s" % [label, detail])

func _run() -> void:
	print("\n=== ARCADE CABINET VERIFICATION ===")
	await _verify_backward_compatible_save()
	await _verify_gauntlet_escape_contract()
	await _verify_flappy()
	await _verify_tower_bounce()
	await _verify_brick_reactor()
	await _verify_arc_snake()
	print("\n--- %d checks, %d failed ---" % [_checks, _failed])
	get_tree().quit(1 if _failed > 0 else 0)

func _verify_backward_compatible_save() -> void:
	print("\n--- backward-compatible save ---")
	_save_path = ProjectSettings.globalize_path(Global.SAVE_PATH)
	_had_save = FileAccess.file_exists(_save_path)
	_save_backup = FileAccess.get_file_as_string(_save_path) if _had_save else ""
	var legacy := FileAccess.open(Global.SAVE_PATH, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({
		"best_streak": 7,
		"volume": 55.0,
		"flappy_best": 17,
		"touch_controls_enabled": false,
		"selected_hero": "not-a-real-hero",
	}))
	legacy.close()
	Global.arcade_games_played = 99
	Global.arcade_bests = {"stale": 100}
	Global.tower_bounce_best = 99
	Global.brick_reactor_best = 99
	Global.load_save()

func _verify_gauntlet_escape_contract() -> void:
	print("\n--- standalone gauntlet escape ---")
	for id in ["minigame_1", "minigame_2", "minigame_3", "minigame_4"]:
		var definition = GameLauncher.registry.get_game(id)
		var scene := (load(definition.scene_path) as PackedScene).instantiate()
		add_child(scene)
		await get_tree().process_frame
		_check("%s exposes arcade return" % id, scene.has_method("_return_to_library"))
		scene.queue_free()
		await get_tree().process_frame
	_check("legacy save keeps existing best streak", Global.best_streak == 7)
	_check("legacy save keeps existing Flappy best", Global.flappy_best == 17)
	_check("legacy save defaults missing arcade profile", Global.arcade_games_played == 0)
	_check("legacy save defaults missing cabinet bests", Global.arcade_bests.is_empty())
	_check("legacy save defaults missing new best fields", Global.tower_bounce_best == 0 and Global.brick_reactor_best == 0 and Global.arc_snake_best == 0)
	_check("legacy save keeps preferences", not Global.touch_controls_enabled and Global.selected_hero == "not-a-real-hero")
	_restore_save(_save_path, _had_save, _save_backup)
	Global.load_save()

func _verify_flappy() -> void:
	print("\n--- Flappy Bonus ---")
	var scene := (load("res://scenes/flappy_bird.tscn") as PackedScene).instantiate()
	add_child(scene)
	await get_tree().process_frame
	_check("Flappy starts on its title state", scene.get_state() == "title")
	scene.score = 9
	scene.best = 0
	scene.call("_check_new_best")
	_check("Flappy writes a new best", Global.flappy_best == 9 and scene.best == 9)
	scene.flap()
	_check("Flappy launch enters play", scene.get_state() == "playing")
	scene.queue_free()
	await get_tree().process_frame

func _verify_tower_bounce() -> void:
	print("\n--- Tower Bounce ---")
	var scene := (load("res://scenes/tower_bounce.tscn") as PackedScene).instantiate()
	add_child(scene)
	await get_tree().process_frame
	_check("Tower starts playable", scene.state == "playing")
	scene.height_climbed = 1234.0
	scene.call("_die")
	_check("Tower loss enters game over", scene.state == "game_over")
	_check("Tower loss persists its best height", Global.tower_bounce_best == 1234)
	scene.call("_restart")
	_check("Tower restart returns to play", scene.state == "playing" and is_zero_approx(scene.height_climbed))
	scene.queue_free()
	await get_tree().process_frame

func _verify_brick_reactor() -> void:
	print("\n--- Brick Reactor ---")
	var old_played := Global.arcade_games_played
	var old_wins := Global.arcade_total_wins
	var old_bests := Global.arcade_bests.duplicate()
	var old_recent := Global.arcade_recent_games.duplicate()
	var old_unique := Global.arcade_unique_games.duplicate()
	var old_achievements := Global.achievements_unlocked.duplicate()
	var old_return_scene := GameLauncher.return_scene_path
	GameLauncher.return_scene_path = "res://scenes/arcade_menu.tscn"
	Global.arcade_games_played = 0
	Global.arcade_total_wins = 0
	Global.arcade_bests = {}
	Global.arcade_recent_games = []
	Global.arcade_unique_games = []
	Global.achievements_unlocked = []
	Global.record_arcade_start("brick_reactor")
	_check("Arcade profile counts a run", Global.arcade_games_played == 1)
	_check("Arcade profile tracks a unique game", Global.arcade_unique_games == ["brick_reactor"])
	_check("First cabinet achievement unlocks", Global.achievements_unlocked.has("first_arcade_game"))
	var scene := (load("res://scenes/brick_reactor.tscn") as PackedScene).instantiate()
	add_child(scene)
	await get_tree().process_frame
	_check("Brick Reactor starts ready", scene.state == "ready")
	scene.call("_start_ball")
	_check("Brick Reactor launch enters play", scene.state == "playing")
	scene.score = 500
	scene.call("_end_round", true)
	_check("Brick Reactor win enters win state", scene.state == "win")
	_check("Brick Reactor win persists its best", Global.brick_reactor_best == 500)
	scene.call("_restart")
	_check("Brick Reactor restart returns to ready", scene.state == "ready" and scene.score == 0)
	scene.call("_start_ball")
	scene.call("_end_round", false)
	_check("Brick Reactor loss enters game over", scene.state == "game_over")
	scene.call("_restart")
	_check("Brick Reactor can restart after loss", scene.state == "ready")
	scene.queue_free()
	await get_tree().process_frame
	_check("Arcade profile records a win", Global.arcade_total_wins == 1)
	_check("Arcade profile stores a best score", Global.arcade_best("brick_reactor") == 500)
	Global.arcade_games_played = old_played
	Global.arcade_total_wins = old_wins
	Global.arcade_bests = old_bests
	Global.arcade_recent_games = old_recent
	Global.arcade_unique_games = old_unique
	Global.achievements_unlocked = old_achievements
	GameLauncher.return_scene_path = old_return_scene
	Global.save()

func _verify_arc_snake() -> void:
	print("\n--- Arc Snake ---")
	var old_best := Global.arc_snake_best
	var old_return_scene := GameLauncher.return_scene_path
	GameLauncher.return_scene_path = "res://scenes/arcade_menu.tscn"
	var scene := (load("res://scenes/arc_snake.tscn") as PackedScene).instantiate()
	add_child(scene)
	await get_tree().process_frame
	_check("Arc Snake starts playable", scene.state == "playing" and scene.snake.size() == 3)
	scene.score = 700
	scene.call("_die")
	_check("Arc Snake loss enters game over", scene.state == "game_over")
	_check("Arc Snake loss persists its best", Global.arc_snake_best == 700)
	scene.call("_restart")
	_check("Arc Snake restart returns to play", scene.state == "playing" and scene.score == 0)
	scene.queue_free()
	await get_tree().process_frame
	Global.arc_snake_best = old_best
	GameLauncher.return_scene_path = old_return_scene
	Global.save()

func _restore_save(path: String, had_save: bool, backup: String) -> void:
	if had_save:
		var file := FileAccess.open(Global.SAVE_PATH, FileAccess.WRITE)
		file.store_string(backup)
		file.close()
	else:
		DirAccess.remove_absolute(path)
