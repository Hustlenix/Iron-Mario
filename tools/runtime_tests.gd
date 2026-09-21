extends Node

var failures: Array[String] = []
var result := false
var saved_config := ""
var had_config := false

func check(condition: bool, message: String) -> void:
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		failures.append(message)

func _ready() -> void:
	had_config = FileAccess.file_exists(Global.SAVE_PATH)
	if had_config:
		saved_config = FileAccess.get_file_as_string(Global.SAVE_PATH)
	call_deferred("run_tests")

func fresh(index: int):
	Global.reset_run()
	GameManager.transition_locked = true
	var game = load(GameManager.MINIGAMES[index]["scene"]).instantiate()
	add_child(game)
	game.set_physics_process(false)
	result = false
	game.minigame_won.connect(func(): result = true)
	return game

func click(at: Vector2, pressed: bool = true) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	return event

func key(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event

func run_tests() -> void:
	for menu in ["TitleScreen", "WinnerScene", "DeathScene"]:
		var scene_path := {"TitleScreen": GameManager.TITLE_SCENE, "WinnerScene": GameManager.WINNER_SCENE, "DeathScene": GameManager.DEATH_SCENE}
		var screen = load(scene_path[menu]).instantiate()
		check(screen.get_script().resource_path == "res://scripts/" + menu + ".gd", "Painted %s wired to current implementation" % menu)
		screen.free()
	var game = fresh(0)
	# Walk to shard 1, jump onto the middle ledge, then the high ledge.
	var stage := 0
	Input.action_press("move_right")
	for frame in range(660):
		var x: float = game.motor.position.x
		if stage == 0 and x >= 375.0 and game.motor.grounded:
			game.handle_game_input(key("jump"))
			stage = 1
		elif stage == 1 and x >= 705.0 and game.motor.grounded:
			game.handle_game_input(key("jump"))
			stage = 2
		game.update_game(1.0 / 60.0)
		Input.action_release("jump")
		# Allow just-pressed state to reset between simulated physics ticks.
		await get_tree().process_frame
		if game.ended:
			break
	Input.action_release("move_right")
	check(result and game.collected == 3, "Dash: all three shards reachable with movement and jump")
	game.free()

	game = fresh(1)
	for index in range(game.required_hits):
		game.handle_game_input(click(game.targets[0]["position"]))
	check(result, "Target Lock: mouse clicks clear five moving targets")
	game.free()

	game = fresh(2)
	game.rng.seed = 415
	game.motor.step(0.01, game.floor_surface)
	for frame in range(540):
		for laser in game.lasers:
			var beam: Rect2 = laser["rect"]
			if beam.position.x > game.motor.position.x and beam.position.x - game.motor.position.x < 70.0 and game.motor.grounded:
				game.handle_game_input(key("jump"))
		game.update_game(1.0 / 60.0)
		Input.action_release("jump")
		await get_tree().process_frame
		if game.ended:
			break
	if not game.ended:
		game.on_time_expired()
	check(result, "Laser Tunnel: survive nine seconds with timed jumps")
	game.free()
	game = fresh(2)
	game.lasers[0]["rect"] = game.motor.rect()
	game.update_game(0.0)
	check(game.ended and not result, "Laser Tunnel: collision fails once")
	game.free()

	game = fresh(3)
	game.marker = 0.0
	game.handle_game_input(key("jump"))
	check(is_equal_approx(game.time_left, 9.2), "Parry: miss consumes 0.8 seconds")
	for index in range(3):
		for tick in range(240):
			game.update_game(1.0 / 60.0)
			if game.marker >= game.zone_start and game.marker <= game.zone_start + game.zone_width:
				game.handle_game_input(key("jump"))
				break
	check(result, "Parry: three input-triggered hits win")
	game.free()

	game = fresh(4)
	game.handle_game_input(click(game.chips[0]["position"]))
	game.handle_game_input(click(Vector2(500, 500), false))
	check(game.placed_count == 0, "Repair: incorrect drop is rejected")
	for index in range(3):
		game.handle_game_input(click(game.chips[index]["position"]))
		game.handle_game_input(click(game.sockets[index]["position"], false))
	check(result, "Repair: three correct mouse drops win")
	game.free()

	game = fresh(5)
	game.rng.seed = 415
	for frame in range(690):
		if not game.pods.is_empty():
			var target_x: float = game.pods[0]["position"].x
			Input.action_release("move_left")
			Input.action_release("move_right")
			if absf(target_x - game.hero_x) > 5.0:
				Input.action_press("move_left" if target_x < game.hero_x else "move_right")
		game.update_game(1.0 / 60.0)
		if game.ended:
			break
	Input.action_release("move_left")
	Input.action_release("move_right")
	check(result and game.caught == 5, "Rescue: five pods caught using movement within timer")
	game.free()
	game = fresh(5)
	game.spawn_timer = 100.0
	for index in range(3):
		game.pods.append({"position": Vector2(50, 712), "speed": 0.0, "done": false})
		game.update_game(0.0)
	check(game.ended and not result, "Rescue: three misses fail")
	game.free()

	game = fresh(6)
	game.update_game(3.0)
	for symbol in game.sequence:
		game.handle_game_input(key(game.ACTIONS[symbol]))
	check(result, "Sequence: repeated pattern wins")
	game.free()
	game = fresh(6)
	game.update_game(3.0)
	game.handle_game_input(key(game.ACTIONS[(game.sequence[0] + 1) % 4]))
	check(game.ended and not result, "Sequence: wrong input fails immediately")
	game.free()

	for index in [0, 1, 3, 4, 5, 6]:
		game = fresh(index)
		game.on_time_expired()
		check(game.ended and not result, "Timeout fails mission %d" % (index + 1))
		game.free()
	Global.reset_run()
	Global.record_success()
	Global.record_success()
	check(Global.score == 225 and Global.streak == 2, "Score and streak accumulate correctly")
	Global.record_failure()
	check(Global.lives == Global.DEFAULT_LIVES - 1 and Global.streak == 0, "Failure costs one life and resets streak")
	Global.toggle_mute()
	var mute_saved := Global.muted
	Global.muted = not mute_saved
	Global.load_data()
	check(Global.muted == mute_saved, "Sound preference persists")
	Global.set_volume(37.0)
	Global.flappy_best = 42
	Global.save_data()
	Global.volume = 0
	Global.flappy_best = 0
	Global.load_data()
	check(Global.volume == 37.0 and Global.flappy_best == 42, "Volume and bonus record persist")
	check(InputMap.has_action("left") and InputMap.has_action("right"), "Original movement actions remain available")
	var legacy_path := "user://save.dat"
	var had_legacy := FileAccess.file_exists(legacy_path)
	var old_legacy := FileAccess.get_file_as_string(legacy_path) if had_legacy else ""
	var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"best_streak": 12, "volume": 29.0, "flappy_best": 42}))
	legacy_file.close()
	DirAccess.remove_absolute(Global.SAVE_PATH)
	Global.load_data()
	check(Global.best_streak == 12 and Global.volume == 29.0 and Global.flappy_best == 42, "Original JSON save migrates with all records intact")
	if had_legacy:
		legacy_file = FileAccess.open(legacy_path, FileAccess.WRITE)
		legacy_file.store_string(old_legacy)
		legacy_file.close()
	else:
		DirAccess.remove_absolute(legacy_path)
	var bonus = load("res://scenes/flappy_bird.tscn").instantiate()
	add_child(bonus)
	bonus.set_process(false)
	bonus.set_physics_process(false)
	bonus._unhandled_input(click(Vector2(500, 300)))
	check(bonus.state == "playing" and bonus.velocity < 0, "Bonus Flappy starts and flaps with mouse input")
	bonus.score = 43
	bonus._check_new_best()
	bonus.score = 44
	bonus._check_new_best()
	check(Global.flappy_best == 44, "Bonus record tracks every new point, not just the first")
	var bounded_gaps := true
	var last_center: float = bonus.last_gap_center
	for sample in range(100):
		for pair in bonus.pipes_node.get_children():
			pair.visible = false
		bonus._spawn_pair()
		for pair in bonus.pipes_node.get_children():
			if pair.visible:
				var meta: Dictionary = bonus._pipe_meta[pair]
				bounded_gaps = bounded_gaps and meta.gap_y-meta.gap/2 >= 90.0 and meta.gap_y+meta.gap/2 <= bonus.GROUND_Y-36.0 and absf(meta.gap_y-last_center) <= 95.01
				last_center = meta.gap_y
	check(bounded_gaps, "Flappy: 100 generated gaps stay above floor and within reachable vertical steps")
	bonus._restart()
	bonus.velocity = 0
	bonus._unhandled_input(key("jump"))
	check(bonus.velocity == bonus.FLAP_VELOCITY, "Flappy: keyboard and mouse share immediate flap input")
	bonus.state = "game_over"
	bonus._unhandled_input(key("restart"))
	check(bonus.state == "playing" and bonus.score == 0 and bonus._spawned == 0, "Flappy: R cleanly resets a finished flight")
	bonus.bird_y = bonus.GROUND_Y - bonus.BIRD_SIZE - 1
	bonus.velocity = 100
	bonus.feathers = 1
	bonus._physics_process(1.0/60.0)
	check(bonus.state == "dying", "Flappy: shield cannot allow flight below floor")
	bonus.free()
	Global.update_profile("  ace-42  ", 2)
	Global.pilot_name = "UNSAVED"
	Global.reactor_style = 0
	Global.load_data()
	check(Global.pilot_name == "ACE-42" and Global.reactor_style == 2, "Profile: callsign and reactor color persist")
	var old_total := Global.total_clears
	Global.record_success()
	Global.load_data()
	check(Global.total_clears == old_total+1 and Global.high_score >= Global.score, "Profile: mission and score records persist")
	var profile = load("res://scenes/profile_scene.tscn").instantiate()
	add_child(profile)
	profile.name_edit.text = "test pilot"
	profile.selected_style = 1
	profile._save_profile()
	check(Global.pilot_name == "TEST PILOT" and Global.reactor_style == 1, "Profile screen: save button applies entered data")
	profile.free()
	Global.reset_run(true)
	check(Global.current_loop == 2 and Global.difficulty > 1.0, "Harder mode increments loop and difficulty")
	# Keep this test runner alive while testing actual scene transitions.
	get_tree().current_scene = null
	GameManager.transition_locked = false
	GameManager.start_run(false)
	await get_tree().create_timer(0.1).timeout
	check(get_tree().current_scene.scene_file_path == GameManager.INTERMISSION_SCENE, "Play starts the countdown")
	check(GameManager.round_order.size() == 7, "Run queues all seven missions")
	var briefing = get_tree().current_scene
	for tick in range(180):
		if briefing.prepared != null:
			break
		await get_tree().process_frame
	check(briefing.prepared != null and briefing.load_progress == 1.0 and not briefing.launched, "Briefing loads scene before countdown completes")
	GameManager.launch_current_minigame()
	await get_tree().create_timer(0.1).timeout
	var scene_before: String = get_tree().current_scene.scene_file_path
	GameManager.restart_current_minigame()
	await get_tree().create_timer(0.1).timeout
	check(get_tree().current_scene.scene_file_path == scene_before, "Restart returns to the same minigame")
	get_tree().current_scene.set_physics_process(false)
	GameManager.resolve_round(false)
	await get_tree().create_timer(0.9).timeout
	check(GameManager.round_index == 0 and Global.completed_minigames == 0 and Global.lives == Global.DEFAULT_LIVES - 1, "Failed round stays queued and costs one life")
	for index in range(7):
		GameManager.launch_current_minigame()
		await get_tree().create_timer(0.05).timeout
		get_tree().current_scene.set_physics_process(false)
		get_tree().current_scene.finish(true)
		await get_tree().create_timer(0.9).timeout
	check(get_tree().current_scene.scene_file_path == GameManager.WINNER_SCENE and Global.completed_minigames == 7, "Winner reachable only after seven clears")
	GameManager.start_run(true)
	await get_tree().create_timer(0.1).timeout
	check(Global.current_loop == 2, "Winner harder-mode starts next loop")
	for index in range(Global.DEFAULT_LIVES):
		GameManager.launch_current_minigame()
		await get_tree().create_timer(0.05).timeout
		get_tree().current_scene.set_physics_process(false)
		get_tree().current_scene.finish(false)
		await get_tree().create_timer(0.9).timeout
	check(get_tree().current_scene.scene_file_path == GameManager.DEATH_SCENE and Global.lives == 0, "All reactor lives lost reaches Death Scene")
	GameManager.return_to_title()
	await get_tree().create_timer(0.1).timeout
	check(get_tree().current_scene.scene_file_path == GameManager.TITLE_SCENE, "Back to title returns correctly")
	if had_config:
		var file := FileAccess.open(Global.SAVE_PATH, FileAccess.WRITE)
		file.store_string(saved_config)
	else:
		DirAccess.remove_absolute(Global.SAVE_PATH)
	print("RUNTIME TESTS: %d failures" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
