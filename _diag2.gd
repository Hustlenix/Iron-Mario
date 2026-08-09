extends SceneTree

var flappy: Node

func _initialize() -> void:
	var scene := load("res://scenes/flappy_bird.tscn") as PackedScene
	flappy = scene.instantiate()
	root.add_child(flappy)
	await process_frame
	flappy.flap()
	flappy.set("best", 0)
	flappy.set("new_best_fired", false)
	flappy.call("_score")
	flappy.set("new_best_fired", false)
	flappy.call("_score")
	flappy.set("bird_y", 700.0)
	flappy.set("velocity", 900.0)
	for i in 600:
		await process_frame
		if flappy.get_state() == "game_over":
			break
	print("death state=%s best=%s" % [flappy.get_state(), flappy.get("best")])
	var ev := InputEventAction.new()
	ev.action = "jump"
	ev.pressed = true
	Input.parse_input_event(ev)
	for i in 4:
		await process_frame
		print("frame %d: just_pressed=%s state=%s bird_y=%s" % [i, Input.is_action_just_pressed("jump"), flappy.get_state(), flappy.get("bird_y")])
	quit(0)
