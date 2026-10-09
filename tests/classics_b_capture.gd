extends SceneTree

func _initialize() -> void:
	call_deferred('capture')

func capture() -> void:
	var output: String = 'res://build/qa/classics_b'
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(1280,640)
	root.content_scale_size = Vector2i(960,480)
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string('res://games/classics_b.json'))
	for e in entries:
		var g: Node = load(e.script).new()
		root.add_child(g)
		g.set_process(false)
		g.start(e,1,1204)
		if e.id=='rooftop_defense':
			g.handle_action('select',Vector2.ZERO,Vector2(1,0))
			g.handle_action('press',g.cell_point(Vector2i(0,0)),Vector2.ZERO)
			g.handle_action('select',Vector2.ZERO,Vector2(2,0))
			g.handle_action('press',g.cell_point(Vector2i(1,0)),Vector2.ZERO)
			g.advance(3)
		elif e.id=='bridge_builder':
			g.handle_action('action',Vector2.ZERO,Vector2.ZERO)
			g.advance(0.8)
		elif e.id=='mini_reactor_buddy':
			g.handle_action('select',Vector2.ZERO,Vector2(3,0))
		elif e.id=='neon_rhythm_escape': g.advance(1.1)
		for frame in 6: await process_frame
		await RenderingServer.frame_post_draw
		var err: Error = root.get_texture().get_image().save_png(output+'/'+e.id+'.png')
		print('CLASSIC_CAPTURE ',e.id,' ',err)
		g.free()
	quit()
