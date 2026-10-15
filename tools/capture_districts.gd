extends SceneTree
func _initialize() -> void: call_deferred('capture')
func capture() -> void:
	root.min_size=Vector2i.ZERO
	root.size=Vector2i(960,432)
	root.content_scale_size=Vector2i.ZERO
	var node:=Node2D.new();root.add_child(node)
	var ids=['sky_foundry','neon_workshop','reactor_works','fungus_underworks','training_yard','chaos_carnival']
	for i in ids.size():
		var source: String='res://assets/shared_foundation/town_library/'+ids[i]+'/exterior.png'
		if not FileAccess.file_exists(source): source=source.replace('exterior','interior')
		var sprite:=Sprite2D.new()
		sprite.texture=ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(source)))
		sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position=Vector2(i%3*320,i/3*216)
		node.add_child(sprite)
		var label:=Label.new();label.text=ids[i].replace('_',' ').to_upper()
		label.position=sprite.position+Vector2(8,184);node.add_child(label)
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png('res://build/visual-after/districts_godot.png')==OK)
	print('DISTRICT_CAPTURE: six native 320x180 compositions rendered in Godot')
	quit()
