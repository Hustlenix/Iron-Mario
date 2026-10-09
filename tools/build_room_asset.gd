extends SceneTree
## Flatten a small authored room from the licensed full Modern Interiors pack.
## Raw source atlases are never copied to the repository or release.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty(): quit(1); return
	var atlas := Image.load_from_file(args[0])
	if atlas==null: quit(1); return
	var room := Image.create(320,160,false,Image.FORMAT_RGBA8)
	for y in 10:
		for x in 20:
			var source := Rect2i(736,592,16,16)
			if y==0: source=Rect2i(16,224,16,16)
			room.blit_rect(atlas,source,Vector2i(x*16,y*16))
	DirAccess.make_dir_recursive_absolute('res://assets/rooms')
	room.save_png('res://assets/rooms/reactor_garage.png')
	quit()
