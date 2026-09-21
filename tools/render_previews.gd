extends SceneTree

func _init() -> void:
	for name in DirAccess.get_files_at("res://docs"):
		if not name.begins_with("paint_") or not name.ends_with(".svg"):
			continue
		var picture := Image.new()
		if picture.load_svg_from_string(FileAccess.get_file_as_string("res://docs/" + name)) != OK:
			quit(1)
			return
		picture.save_png("res://docs/" + name.get_basename() + ".png")
	quit()
