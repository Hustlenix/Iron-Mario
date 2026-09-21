extends Node
const Capture = preload("res://tools/paint_capture.gd")

func _ready() -> void:
	call_deferred("capture")

func capture_node(node: Node) -> void:
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	if node.has_method("_draw"):
		node.call("_draw")
	var ordered := node.get_children()
	ordered.sort_custom(func(a,b): return (a.z_index if a is CanvasItem else 0) < (b.z_index if b is CanvasItem else 0))
	for child in ordered:
		capture_node(child)

func capture() -> void:
	for path in ["title_screen","intermission","minigames/arc_reactor_dash","minigames/target_lock","minigames/laser_tunnel","minigames/reactor_parry","minigames/armor_repair","minigames/rocket_rescue","minigames/power_core_sequence","winner_scene","death_scene"]:
		var scene = load("res://scenes/" + path + ".tscn").instantiate()
		add_child(scene)
		scene.set_process(false)
		scene.set_physics_process(false)
		Capture.items.clear()
		capture_node(scene)
		var file := FileAccess.open("res://docs/paint_" + path.get_file() + ".svg", FileAccess.WRITE)
		file.store_string('<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">'+''.join(Capture.items)+'</svg>')
		scene.free()
	get_tree().quit()
