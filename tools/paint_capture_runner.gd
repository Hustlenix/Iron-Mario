extends Node
const Capture = preload("res://tools/paint_capture.gd")

func _ready() -> void:
	# Geometry capture does not need synthesized audio playback.
	SoundFX.voices.clear()
	call_deferred("capture")

func capture_node(node: Node) -> void:
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	if node.name == "RepairParts":
		node.get_parent().call("_draw_parts")
	if node.has_method("_draw"):
		node.call("_draw")
	var ordered := node.get_children()
	ordered.sort_custom(func(a,b):
		var az: int = a.z_index if a is CanvasItem else 0
		var bz: int = b.z_index if b is CanvasItem else 0
		return a.get_index() < b.get_index() if az == bz else az < bz
	)
	for child in ordered:
		capture_node(child)

func capture() -> void:
	for path in ["title_screen","intermission","minigames/arc_reactor_dash","minigames/target_lock","minigames/laser_tunnel","minigames/reactor_parry","minigames/armor_repair","minigames/rocket_rescue","minigames/power_core_sequence","winner_scene","death_scene","profile_scene","settings_scene","flappy_bird"]:
		var scene = load("res://scenes/" + path + ".tscn").instantiate()
		add_child(scene)
		scene.set_process(false)
		scene.set_physics_process(false)
		Capture.items.clear()
		capture_node(scene)
		var file := FileAccess.open("res://docs/paint_" + path.get_file() + ".svg", FileAccess.WRITE)
		file.store_string('<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">'+''.join(Capture.items)+'</svg>')
		scene.free()
	for index in range(GameManager.MINIGAMES.size()):
		GameManager.round_order.assign([index])
		GameManager.round_index = 0
		var briefing = load("res://scenes/intermission.tscn").instantiate()
		add_child(briefing)
		briefing.set_process(false)
		briefing.countdown = 1.5
		briefing.load_progress = 1.0
		Capture.items.clear()
		capture_node(briefing)
		var mission: String = GameManager.MINIGAMES[index]["scene"].get_file().get_basename()
		var output := FileAccess.open("res://docs/paint_loading_" + mission + ".svg",FileAccess.WRITE)
		output.store_string('<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">'+''.join(Capture.items)+'</svg>')
		briefing.free()
	await get_tree().process_frame
	await get_tree().process_frame
	for hero_id in preload("res://scripts/HeroCatalog.gd").IDS:
		Global.hero_id = hero_id
		var profile = load("res://scenes/profile_scene.tscn").instantiate()
		add_child(profile)
		Capture.items.clear()
		capture_node(profile)
		var output := FileAccess.open("res://docs/paint_hero_" + hero_id + ".svg",FileAccess.WRITE)
		output.store_string('<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">'+''.join(Capture.items)+'</svg>')
		profile.free()
	await get_tree().process_frame
	get_tree().quit()
