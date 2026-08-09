extends SceneTree

var flappy: Node

func _initialize() -> void:
	var scene := load("res://scenes/flappy_bird.tscn") as PackedScene
	flappy = scene.instantiate()
	root.add_child(flappy)
	_run_frames(30)
	if flappy.get_state() == "title":
		print("FLAPPY BOOT OK")
		quit(0)
	else:
		print("FLAPPY BOOT FAIL: state=%s" % flappy.get_state())
		quit(1)

func _run_frames(count: int) -> void:
	for i in count:
		await process_frame
