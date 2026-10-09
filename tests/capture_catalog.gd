extends SceneTree
## Actual GPU-rendered Godot viewports. Capture artifacts are excluded from export.
var output := "res://build/catalog-qa"
var errors: Array[String] = []
var captured := 0
var viewport: SubViewport

func _initialize() -> void:
	call_deferred("capture_all")

func settle() -> void:
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw

func capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var registry := GameRegistry.new()
	viewport = SubViewport.new()
	viewport.size = Vector2i(960, 480)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var manifest: Array[Dictionary] = []
	for spec in registry.games:
		var game: MicrogameBase = registry.create(spec.id)
		if game == null: errors.append(spec.id + " could not instantiate"); continue
		viewport.add_child(game)
		game.set_process(false)
		game.start(spec, 1.0, 28)
		# Capture a deterministic initial playable board; no synthetic art stand-ins.
		await settle()
		var image: Image = viewport.get_texture().get_image()
		var result: Error = image.save_png(output + "/" + spec.id + "_board.png")
		if result != OK: errors.append(spec.id + " board save error " + str(result))
		image.resize(240, 120, Image.INTERPOLATE_LANCZOS)
		result = image.save_png(output + "/" + spec.id + "_thumbnail.png")
		if result != OK: errors.append(spec.id + " thumbnail save error " + str(result))
		manifest.append({"id": spec.id, "board": spec.id + "_board.png", "thumbnail": spec.id + "_thumbnail.png", "viewport": "960x480 native Godot GL compatibility rendering", "seed": 28})
		captured += 1
		game.free()
	viewport.queue_free()
	await process_frame
	await capture_sheets(manifest)
	await capture_app_samples()
	var file: FileAccess = FileAccess.open(output + "/capture_manifest.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"engine": Engine.get_version_info().string,
			"module_count": captured, "screenshots": manifest, "errors": errors,
			"limitation": "Native GPU-rendered screenshots, not browser or physical-phone gameplay verification."}, "\t"))
		file.close()
	else: errors.append("Capture manifest could not open")
	print("CATALOG_CAPTURES=", captured, " ERRORS=", errors.size(), " OUTPUT=", ProjectSettings.globalize_path(output))
	for detail in errors: print(detail)
	quit(0 if errors.is_empty() else 1)

func capture_sheets(manifest: Array[Dictionary]) -> void:
	for sheet_number in range(int(ceil(manifest.size() / 25.0))):
		var sheet_viewport := SubViewport.new()
		sheet_viewport.size = Vector2i(1200, 750)
		sheet_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(sheet_viewport)
		var sheet := Node2D.new()
		sheet_viewport.add_child(sheet)
		var tiles: Array[Dictionary] = []
		for index in range(sheet_number * 25, mini(manifest.size(), (sheet_number + 1) * 25)):
			var item: Dictionary = manifest[index]
			var image := Image.load_from_file(output + "/" + item.thumbnail)
			tiles.append({"id": item.id, "texture": ImageTexture.create_from_image(image), "position": Vector2((index % 25) % 5 * 240, (index % 25) / 5 * 150)})
		sheet.draw.connect(func() -> void:
			sheet.draw_rect(Rect2(0, 0, 1200, 750), Color("fff4d7"))
			for tile in tiles:
				sheet.draw_texture(tile.texture, tile.position)
				sheet.draw_string(ThemeDB.fallback_font, tile.position + Vector2(5, 140), tile.id, HORIZONTAL_ALIGNMENT_LEFT, 230, 16, Color("242333")))
		sheet.queue_redraw()
		await settle()
		var result: Error = sheet_viewport.get_texture().get_image().save_png(output + "/contact_sheet_" + str(sheet_number + 1) + ".png")
		if result != OK: errors.append("Contact sheet save error " + str(result))
		sheet_viewport.queue_free()
		await process_frame

func save_screen(name: String) -> void:
	await settle()
	var result: Error = root.get_texture().get_image().save_png(output + "/" + name + ".png")
	if result != OK: errors.append(name + " screenshot error " + str(result))

func activate(app: Control) -> void:
	app.manual_pause = false
	app.transitioning = false
	app.close_modal()
	app.refresh_pause()
	if is_instance_valid(app.current_game): app.current_game.set_process(false)

func capture_app_samples() -> void:
	var profile: Node = root.get_node("Profile")
	var saved_data: Dictionary = profile.data.duplicate(true)
	var saved_path: String = profile.profile_path
	profile.profile_path = output + "/capture_profile.json"
	profile.data = profile._defaults()
	profile.data.onboarded = true
	profile.data.settings.shake = false
	profile._refresh_daily()
	var app: Control = load("res://ui/main.tscn").instantiate()
	root.add_child(app)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(960, 540)
	app.show_page("HOME")
	await save_screen("app_home_1280x720")
	app.show_page("GAMES")
	await save_screen("app_catalog_1280x720")
	app.start_run("single", "armor_repair")
	await settle()
	activate(app)
	await save_screen("app_gameplay_1280x720")
	app.toggle_pause()
	await save_screen("app_pause_1280x720")
	app.toggle_pause()
	var game: MicrogameBase = app.current_game
	for i in range(3):
		app.route_action("press", game.items[i], Vector2.ZERO)
		app.route_action("drag", game.marks[i], Vector2.ZERO)
		app.route_action("release", game.marks[i], Vector2.ZERO)
	await create_timer(0.75).timeout
	await save_screen("app_victory_1280x720")
	app.start_run("single", "armor_repair")
	await settle()
	activate(app)
	app.current_game.advance(app.current_game.duration + 0.1)
	await create_timer(0.75).timeout
	await save_screen("app_game_over_1280x720")
	for dimensions in [Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = dimensions
		app.show_page("HOME")
		await save_screen("app_home_" + str(dimensions.x) + "x" + str(dimensions.y))
		app.start_run("single", "arc_snake")
		await settle()
		activate(app)
		app.layout_game()
		await save_screen("app_cabinet_" + str(dimensions.x) + "x" + str(dimensions.y))
	app.queue_free()
	await process_frame
	profile.data = saved_data
	profile.profile_path = saved_path
