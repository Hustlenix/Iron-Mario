extends Node
var failures := 0

func check(value: bool, message: String) -> void:
	print(("PASS " if value else "FAIL ") + message)
	if not value:
		failures += 1

func _ready() -> void:
	call_deferred("run_tests")

func touch(at: Vector2, index: int = 0, pressed: bool = true) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.index = index
	event.pressed = pressed
	return event

func fresh(index: int):
	Global.reset_run()
	GameManager.transition_locked = true
	var game = load(GameManager.MINIGAMES[index]["scene"]).instantiate()
	add_child(game)
	game.set_physics_process(false)
	return game

func run_tests() -> void:
	Global.touch_controls = true
	var catalog = preload("res://scripts/HeroCatalog.gd")
	for id in catalog.IDS:
		Global.save_hero_profile("PHONE PILOT",id)
		Global.hero_id = "invalid"
		Global.load_data()
		check(Global.hero_id == id, "Hero save: " + id)
		var actor = preload("res://scripts/ui/IronHero.gd").new()
		add_child(actor)
		check(actor.hero_id == id, "Shared actor equips " + id)
		for pose in ["idle","jump","victory","damaged"]:
			actor.pose = pose
			actor.queue_redraw()
			await get_tree().process_frame
		actor.free()
		var music = load("res://assets/audio/heroes/" + id + ".wav")
		check(music is AudioStreamWAV and music.get_length() > 10, "Original music available: " + id)
	var config := ConfigFile.new()
	config.load(Global.SAVE_PATH)
	config.erase_section_key("profile","hero_id")
	config.set_value("progress","best_streak",42)
	config.save(Global.SAVE_PATH)
	Global.load_data()
	check(Global.hero_id == "ember" and Global.best_streak == 42, "Legacy saves keep records and select default hero")
	Global.save_hero_profile("PHONE PILOT","invalid")
	check(Global.hero_id == "ember", "Unknown saved hero falls back safely")
	if OS.has_feature("linux"):
		check(OS.get_user_data_dir().ends_with("godot/app_userdata/Iron-Mario"), "Rename retains original Linux save directory")
	elif OS.has_feature("windows"):
		check(OS.get_user_data_dir().replace("\\","/").ends_with("Godot/app_userdata/Iron-Mario"), "Rename retains original Windows save directory")

	var game = fresh(0)
	game.motor.grounded = true
	var pad = game.touch_controls
	pad._input(touch(Vector2(245,650),0))
	pad._input(touch(Vector2(1140,650),1))
	await get_tree().process_frame
	game.update_game(1.0/60.0)
	check(game.motor.velocity.x > 0 and game.motor.velocity.y < 0, "Two fingers move and jump simultaneously")
	pad._input(touch(Vector2(1140,650),1,false))
	check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("jump"), "Releasing jump keeps movement held")
	pad._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not Input.is_action_pressed("move_right"), "Focus loss releases all touch actions")
	pad._input(touch(Vector2(90,650),0))
	game.free()
	check(not Input.is_action_pressed("move_left"), "Scene exit clears held movement")

	game = fresh(1)
	var at: Vector2 = game.targets[0]["position"]
	game._unhandled_input(touch(at))
	var hits: int = game.hits
	var emulated := InputEventMouseButton.new()
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	emulated.button_index = MOUSE_BUTTON_LEFT
	emulated.pressed = true
	emulated.position = game.targets[0]["position"]
	game._unhandled_input(emulated)
	check(hits == 1 and game.hits == 1, "Target taps score once even with emulated mouse")
	game._unhandled_input(touch(at,0,false))
	game.free()

	game = fresh(4)
	for index in range(3):
		var source: Vector2 = game.chips[index]["position"]
		var destination: Vector2 = game.sockets[index]["position"]
		game._unhandled_input(touch(source,0))
		game._unhandled_input(touch(destination,1,false))
		check(game.dragging == index, "Other finger cannot drop repair chip")
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = destination
		game._unhandled_input(drag)
		game._unhandled_input(touch(destination,0,false))
	check(game.placed_count == 3 and game.ended, "Touch drag repairs all three sockets")
	game.free()

	game = fresh(3)
	for index in range(3):
		game.marker = game.zone_start + game.zone_width*0.5
		game.touch_controls._input(touch(Vector2(1140,650)))
		game.touch_controls._input(touch(Vector2(1140,650),0,false))
	check(game.parries == 3 and game.ended, "Touch PARRY button completes timing mission")
	game.free()

	game = fresh(6)
	game.phase = "input"
	for value in game.sequence:
		game._unhandled_input(touch(game.CENTERS[value]))
		game._unhandled_input(touch(game.CENTERS[value],0,false))
	check(game.ended and game.input_index == game.sequence.size(), "Touch arrow tiles complete memory sequence")
	game.free()

	game = fresh(5)
	var initial_x: float = game.hero_x
	game.touch_controls._input(touch(Vector2(245,650)))
	game.update_game(0.1)
	check(game.hero_x > initial_x, "Touch arrows steer rescue hero")
	game.free()
	MobileSession._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	MobileSession._process(0)
	check(get_tree().paused, "Focus loss pauses mission timers")
	MobileSession._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	MobileSession._process(0)
	check(not get_tree().paused, "Focus restore resumes timers")
	Music.stop_music()
	await get_tree().create_timer(0.5).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	print("MOBILE TESTS: %d failures" % failures)
	get_tree().quit(0 if failures == 0 else 1)
