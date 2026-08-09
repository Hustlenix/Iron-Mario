extends SceneTree

var flappy: Node

func _initialize() -> void:
	var scene := load("res://scenes/flappy_bird.tscn") as PackedScene
	flappy = scene.instantiate()
	root.add_child(flappy)
	var args := OS.get_cmdline_user_args()
	if args.has("--medal"):
		await _test_medal()
	elif args.has("--ramp"):
		await _test_ramp()
	elif args.has("--flap"):
		await _test_flap()
	else:
		_run_frames(30)
		if flappy.get_state() == "title":
			print("FLAPPY BOOT OK")
			quit(0)
		else:
			print("FLAPPY BOOT FAIL: state=%s" % flappy.get_state())
			quit(1)

func _test_ramp() -> void:
	await process_frame
	flappy.flap()
	flappy.set("score", 0)
	await process_frame
	var ramp_0: float = flappy.call("_ramp_speed")
	flappy.set("score", 25)
	await process_frame
	var ramp_25: float = flappy.call("_ramp_speed")
	if ramp_0 == 240.0 and ramp_25 == 330.0:
		flappy.set("score", 0)
		flappy.call("_score")
		flappy.call("_score")
		if flappy.get("score") == 2:
			print("RAMP TEST OK")
			quit(0)
			return
	print("RAMP TEST FAIL: speed %f -> %f" % [ramp_0, ramp_25])
	quit(1)

func _test_medal() -> void:
	await process_frame
	flappy.flap()
	flappy.set("best", 0)
	flappy.set("new_best_fired", false)
	flappy.set("score", 4)
	flappy.call("_score")
	if flappy.get("medals").size() == 0:
		flappy.set("score", 5)
		flappy.call("_score")
	var medal_text: String = flappy.get_node("HUD/MedalLabel").text
	if medal_text != "BRONZE":
		print("MEDAL TEST FAIL: label=%s" % medal_text)
		quit(1)
		return
	flappy.set("best", 0)
	flappy.set("new_best_fired", false)
	flappy.set("score", 1)
	flappy.call("_score")
	var fired: bool = flappy.get("new_best_fired")
	var global_node: Node = root.get_node("Global")
	var saved: int = global_node.flappy_best
	if fired and saved == 2:
		print("MEDAL TEST OK")
		quit(0)
		return
	print("MEDAL TEST FAIL: new_best fired=%s saved=%d" % [fired, saved])
	quit(1)

func _test_flap() -> void:
	await process_frame
	flappy.flap()
	await process_frame
	_run_frames(30)
	if flappy.get_state() == "playing":
		print("FLAP TEST OK")
		quit(0)
	else:
		print("FLAP TEST FAIL: state=%s" % flappy.get_state())
		quit(1)

func _run_frames(count: int) -> void:
	for i in count:
		await process_frame
