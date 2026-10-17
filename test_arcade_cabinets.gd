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
var _profile_snapshot: Dictionary = {}

func _ready() -> void:
	_save_path = ProjectSettings.globalize_path(Global.SAVE_PATH)
	_had_save = FileAccess.file_exists(_save_path)
	_save_backup = FileAccess.get_file_as_string(_save_path) if _had_save else ""
	_profile_snapshot = _capture_profile()
	await _run()
	_restore_save(_save_path, _had_save, _save_backup)
	_restore_profile(_profile_snapshot)
	get_tree().quit(1 if _failed > 0 else 0)

func _capture_profile() -> Dictionary:
	return {
		"best_streak": Global.best_streak,
		"volume": Global.volume,
		"music_volume": Global.music_volume,
		"flappy_best": Global.flappy_best,
		"tower_bounce_best": Global.tower_bounce_best,
		"brick_reactor_best": Global.brick_reactor_best,
		"arc_snake_best": Global.arc_snake_best,
		"arc_break_best": Global.arc_break_best,
		"arcade_games_played": Global.arcade_games_played,
		"arcade_total_wins": Global.arcade_total_wins,
		"arcade_bests": Global.arcade_bests.duplicate(),
		"arcade_recent_games": Global.arcade_recent_games.duplicate(),
		"arcade_unique_games": Global.arcade_unique_games.duplicate(),
		"achievements_unlocked": Global.achievements_unlocked.duplicate(),
		"touch_controls_enabled": Global.touch_controls_enabled,
		"low_quality": Global.low_quality,
		"selected_hero": Global.selected_hero,
	}

func _restore_profile(snapshot: Dictionary) -> void:
	Global.best_streak = snapshot.best_streak
	Global.volume = snapshot.volume
	Global.music_volume = snapshot.music_volume
	Global.flappy_best = snapshot.flappy_best
	Global.tower_bounce_best = snapshot.tower_bounce_best
	Global.brick_reactor_best = snapshot.brick_reactor_best
	Global.arc_snake_best = snapshot.arc_snake_best
	Global.arc_break_best = snapshot.arc_break_best
	Global.arcade_games_played = snapshot.arcade_games_played
	Global.arcade_total_wins = snapshot.arcade_total_wins
	Global.arcade_bests = snapshot.arcade_bests
	Global.arcade_recent_games = snapshot.arcade_recent_games
	Global.arcade_unique_games = snapshot.arcade_unique_games
	Global.achievements_unlocked = snapshot.achievements_unlocked
	Global.touch_controls_enabled = snapshot.touch_controls_enabled
	Global.low_quality = snapshot.low_quality
	Global.selected_hero = snapshot.selected_hero

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
	await _verify_polled_escape_wiring()
	await _verify_flappy()
	await _verify_tower_bounce()
	await _verify_brick_reactor()
	await _verify_arc_snake()
	await _verify_arc_break()
	print("\n--- %d checks, %d failed ---" % [_checks, _failed])

func _verify_backward_compatible_save() -> void:
	print("\n--- backward-compatible save ---")
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
	_check("legacy save defaults missing new best fields", Global.tower_bounce_best == 0 and Global.brick_reactor_best == 0 and Global.arc_snake_best == 0 and Global.arc_break_best == 0)
	_check("legacy save keeps preferences", not Global.touch_controls_enabled and Global.selected_hero == "not-a-real-hero")
	_restore_save(_save_path, _had_save, _save_backup)
	Global.load_save()

func _verify_polled_escape_wiring() -> void:
	# The polled cabinets (arc_break and friends) read ui_cancel at the top of
	# their physics/process loop, before any stage or state guard. This asserts
	# that wiring still sits at the function's top level, so an "ESC ARCADE"
	# hint can never again advertise a return that only works on an end screen.
	print("\n--- polled escape wiring ---")
	var pattern := RegEx.new()
	pattern.compile('(?m)^\\tif Input\\.is_action_just_pressed\\("ui_cancel"\\):\\r?\\n\\t\\t_return_to_library\\(\\)')
	for id in ["arc_break", "arc_snake", "brick_reactor", "tower_bounce"]:
		var definition = GameLauncher.registry.get_game(id)
		var script_path: String = definition.scene_path.get_basename() + ".gd"
		var source := FileAccess.get_file_as_string(script_path)
		_check("%s polls escape before any stage/state guard" % id, not source.is_empty() and pattern.search(source) != null, script_path)

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

func _verify_arc_break() -> void:
	print("\n--- Arc Break ---")
	var old_best := Global.arc_break_best
	var old_return_scene := GameLauncher.return_scene_path
	var old_achievements := Global.achievements_unlocked.duplicate()
	GameLauncher.return_scene_path = "res://scenes/arcade_menu.tscn"
	var scene := (load("res://scenes/arc_break.tscn") as PackedScene).instantiate()
	add_child(scene)
	await get_tree().process_frame
	_check("Arc Break starts in containment lab", scene.stage == scene.Stage.LAB and scene.relay_nodes.size() == 3)
	var controls: Node = scene.get_node("TouchControls")
	var touch_buttons: Dictionary = controls.get("_buttons")
	var up_button := touch_buttons.get("arc_up") as Button
	up_button.emit_signal("button_down")
	_check("Touch up button holds the movement action", Input.is_action_pressed("arc_up"))
	up_button.emit_signal("button_up")
	_check("Touch up button releases movement cleanly", not Input.is_action_pressed("arc_up"))
	Input.action_press("arc_up")
	var move_input: Vector2 = scene.call("_movement_input")
	Input.action_release("arc_up")
	_check("Keyboard up action maps to north movement", move_input.y < -0.9 and is_zero_approx(move_input.x))
	var old_energy: float = scene.energy
	scene.call("_fire_repulsor")
	_check("Repulsor consumes energy and spawns a bolt", scene.energy < old_energy and scene.bolts.size() == 1)
	for i in 3:
		scene.call("_charge_relay", i)
	_check("Lab relays open cave hatch", scene.stage == scene.Stage.LAB and scene._all_relays_charged())
	scene.call("_enter_cave")
	_check("Player enters the fungus cave", scene.stage == scene.Stage.CAVE)
	for i in 3:
		scene.call("_charge_relay", i)
	_check("Cave network exposes the breach core", scene.stage == scene.Stage.BOSS)
	for _hit in 3:
		scene.call("_hit_boss")
	_check("Three repulsor hits end the boss encounter", scene.stage == scene.Stage.WON)
	_check("Arc Break unlocks its completion achievement", Global.achievements_unlocked.has("arc_break_clear"))
	_check("Arc Break stores a best score", Global.arc_break_best == scene.score)
	scene.queue_free()
	await get_tree().process_frame
	Global.arc_break_best = old_best
	Global.achievements_unlocked = old_achievements
	GameLauncher.return_scene_path = old_return_scene
	Global.save()

func _restore_save(path: String, had_save: bool, backup: String) -> void:
	if had_save:
		var file := FileAccess.open(Global.SAVE_PATH, FileAccess.WRITE)
		file.store_string(backup)
		file.close()
	else:
		DirAccess.remove_absolute(path)
