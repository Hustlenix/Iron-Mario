extends SceneTree
func _initialize() -> void:
	call_deferred('capture')
func capture() -> void:
	root.size=Vector2i(960,540)
	var stage: Control = load('res://ui/hero_stage.gd').new()
	stage.size=Vector2(960,540)
	root.add_child(stage)
	for i in 30: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute('res://build/visual-after')
	var result := root.get_texture().get_image().save_png('res://build/visual-after/pixel-foundry.png')
	print('PIXEL_SCENE_CAPTURE=',result)
	quit(result)
